# Mic Noise Chain (DeepFilterNet → Gate) — Design

**Date:** 2026-07-13
**Status:** Approved (design)

## Goal

Stop the background TV in another room from being transmitted over Discord. Two
observed failure modes:

1. **Confirmed:** Discord's voice activation triggers on the TV during the
   user's speech gaps (mic "opens" while they aren't talking).
2. **Likely:** some TV bleed underneath the user's voice while actively talking.

Replace the current single RNNoise input stage with a two-stage chain —
**Deep Noise Suppression (DeepFilterNet) → Gate** — that attacks both.

## Current state

`modules/audio/easyeffects.nix` (`flake.modules.homeManager.easyeffects`,
imported on jezrien) enables `services.easyeffects` and writes one input preset
via `home.file`:

- Path: `~/.local/share/easyeffects/input/rnnoise.json`
- Single plugin: `rnnoise#0` using a fetched "marathon" RNNoise model, with VAD
  enabled and `vad-thres` recently raised to `93.0` (near the 100 ceiling — the
  reason we're adding a dedicated stage rather than pushing rnnoise harder).

EasyEffects version is **8.2.5**, compiled with `deepfilternet-0.5.6`,
`rnnoise-0.2`, and `speexdsp-1.2.1` in its buildInputs, and the LSP **Gate** is
part of core — so DeepFilterNet and Gate are both available natively with **no
extra packaging**.

## Why this approach

- **A Gate is required regardless of denoiser.** Denoisers *reduce* background
  but don't guarantee silence, so residual TV can still trip Discord's VAD. A
  Gate hard-clamps everything below a threshold when the user isn't speaking →
  Discord sees silence in the gaps. This directly fixes failure mode #1.
- **DeepFilterNet over RNNoise for the denoise stage.** RNNoise (2018-era) is
  tuned for *stationary* noise (fans, hum). The TV is *non-stationary*
  (dialogue/music); DeepFilterNet 0.5 is SOTA on exactly that, so it addresses
  failure mode #2 far better than pushing rnnoise's VAD. It runs real-time on a
  small fraction of one CPU core (CPU inference, no GPU) — negligible impact on
  this desktop — at the cost of ~40 ms added latency, imperceptible for Discord
  voice.
- **Chain order is denoise → gate.** Clean the signal first, then gate the
  residual so the gaps are truly silent.

### Rejected alternatives

- **Keep RNNoise, add only a Gate.** Fixes the gap problem but leaves
  during-speech bleed at today's rnnoise level. Considered as the minimal
  option; rejected because the user wants the best result and DeepFilterNet is
  the correct tool for non-stationary TV noise.
- **Stack RNNoise + DeepFilterNet + Gate.** Two denoisers is redundant and
  doubles latency for marginal gain. YAGNI.

## Design

### Plugin chain

The input preset's `plugins_order` becomes `[ "deepfilternet#0", "gate#0" ]`. The
`rnnoise#0` block and the `rnnoise-marathon` model fetch (`pkgs.fetchurl`) are
removed.

### Stage 1 — Deep Noise Suppression (`deepfilternet#0`)

Removes the TV underneath the voice during speech. Effectively one user-facing
control (an attenuation limit in dB). Start at strong/full suppression; tunable
down if it ever sounds over-processed.

- `bypass = false`
- attenuation limit: start at the strongest setting.

### Stage 2 — Gate (`gate#0`, LSP), after the denoiser

Closes the VAD-triggering gap. Starting parameters:

| Parameter | Start value | Why |
|-----------|-------------|-----|
| threshold | ≈ −40 dB | Just above the residual noise floor left after DeepFilterNet; below it the gate closes. |
| attack | ≈ 2 ms | Opens effectively instantly — never clips the start of a word. |
| release | ≈ 200 ms | Closes smoothly — no chatter, no chopped word tails. |
| reduction / range | ≈ −60 dB | When closed, attenuate enough that Discord's voice activation sees silence. |
| hysteresis | on (if exposed) | Prevents flutter right at the threshold. |

### Preset file & loading

**Rename** the preset from `rnnoise.json` to a name that reflects its contents —
`mic-chain.json` (preset name "mic-chain") — since it will no longer be rnnoise.

EasyEffects applies effects from its **dconf state**, not by reading the preset
JSON on every launch; a preset only takes effect when it is *loaded* (which
writes its settings into dconf). Confirmed on this host: dconf holds
`last-used-output-preset='Heavy Bass'` and there is no dconf value pinning an
input preset by content — the active input effects live in dconf, and the
module's JSON is the preset that gets loaded into it. Consequences of the
rename, all handled by the plan:

- After rebuild, the new `mic-chain` preset must be **loaded once** in
  EasyEffects (Settings → load preset, or via autoload) for the new chain to
  apply. This is also why prior `vad-thres` edits only took effect on reload.
- If an **autoload** entry exists for the mic device
  (`~/.config/easyeffects/autoload/input/`) pointing at `rnnoise`, it must be
  repointed to `mic-chain` (or created) so the chain auto-applies on device
  connect. The plan inspects this directory and decides.
- The stale `~/.local/share/easyeffects/input/rnnoise.json` (now an unmanaged
  dangling symlink once the module stops writing it) and the home-manager
  `rnnoise.json.bak` should be removed as cleanup.

## Implementation notes / risks

- **Exact JSON keys must be verified against the built gschema.** The EasyEffects
  preset key names and per-plugin setting keys (e.g. the exact spelling of the
  DeepFilterNet plugin tag and its attenuation setting, and the LSP Gate's
  threshold/attack/release/reduction/hysteresis keys) must be confirmed against
  EasyEffects 8.2.5's gsettings schemas before finalizing, or EasyEffects will
  silently reject/ignore unknown keys. The implementation plan will introspect
  the schema (build the package and read
  `share/glib-2.0/schemas/*.gschema.xml`, or the upstream `data/schemas` for the
  8.2.5 tag) to pin them.
- **No unit-test framework** (Nix repo). Verification is: `nix flake check` +
  eval that the rendered preset JSON contains the two plugins and expected keys,
  then a live check.

## Success criteria

- `modules/audio/easyeffects.nix` writes an input preset named `mic-chain.json`
  with `plugins_order = [ "deepfilternet#0", "gate#0" ]` and valid config blocks for
  both; no `rnnoise` block and no model fetch remain, and the old `rnnoise.json`
  is no longer written.
- `nix flake check` passes; the rendered JSON (via `nix eval`) shows both
  plugins with the intended parameters.
- Live: after rebuild + loading the `mic-chain` preset (and EasyEffects
  restart), EasyEffects shows Deep Noise Suppression and Gate both active in the
  input chain, and the input meter drops to (near-)silence when the user is
  quiet with the TV audible — enough that Discord's mic no longer activates in
  the gaps.

## Out of scope

- Tuning to final perfect values — the spec sets sane starting points; live
  tuning (mainly the Gate threshold) is expected afterward.
- Any output-chain (playback) effects.
- Speex/other denoisers.
