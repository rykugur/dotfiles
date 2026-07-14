# Mic Noise Chain (DeepFilterNet → Gate) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single RNNoise input stage in EasyEffects with a DeepFilterNet → Gate chain so background TV stops triggering Discord's voice activation in speech gaps and bleeding under speech.

**Architecture:** `modules/audio/easyeffects.nix` writes one EasyEffects input preset via `home.file`. Change it to a renamed preset (`mic-chain.json`) whose `plugins_order` is `[ "deepfilternet#0", "gate#0" ]`, dropping the `rnnoise#0` block and its model fetch. All plugin keys/defaults come verbatim from EasyEffects 8.2.5's kcfg definitions and preset serialization.

**Tech Stack:** Nix, home-manager (`services.easyeffects` + `home.file`), EasyEffects 8.2.5 (DeepFilterNet + LSP Gate, both native), `builtins.toJSON`.

## Global Constraints

- Plugin tokens are exactly `deepfilternet#0` and `gate#0` (lowercase tags, verified in EasyEffects `tags_plugin_name.hpp`). `plugins_order = [ "deepfilternet#0", "gate#0" ]` — denoise before gate.
- Preset filename is `mic-chain.json`, written to the existing dir `~/.local/share/easyeffects/input/` (the location known to work on this host). Do NOT keep the `rnnoise.json` name.
- Each plugin block must be COMPLETE (every key EasyEffects serializes), matching a native export, so the preset isn't partially applied. Keys and defaults are fixed by EasyEffects 8.2.5's kcfg — use the exact values in Task 1.
- Gate units: `curve-threshold`/`curve-zone`/`hysteresis-*`/`reduction`/`makeup` in dB; `attack`/`release` in ms; enum fields (`sidechain.type/mode/source/stereo-split-source`, `hpf-mode`, `lpf-mode`) are STRINGS (the label). DeepFilterNet `attenuation-limit` is 0–100 (100 = max suppression).
- Tuned (non-default) gate values only: `attack=2.0`, `release=200.0`, `curve-threshold=-40.0`, `reduction=-60.0`. Every other gate key is its kcfg default. DeepFilterNet uses all kcfg defaults.
- Minimal comments — terse non-obvious "why" only.
- No unit-test framework: verification is `nix eval` of the rendered preset JSON + `nix flake check`. A live step (rebuild + load preset in EasyEffects) is user-run.
- EasyEffects applies effects from its dconf state, not by reading the JSON each launch — the preset must be LOADED once in EasyEffects for the new chain to take effect. This is why the change needs the live Task 2.

---

### Task 1: Replace RNNoise stage with DeepFilterNet → Gate chain

**Files:**
- Modify (full rewrite): `modules/audio/easyeffects.nix`

**Interfaces:**
- Consumes: nothing new (home-manager `services.easyeffects`, `home.file`).
- Produces: preset at `~/.local/share/easyeffects/input/mic-chain.json` with `plugins_order = [ "deepfilternet#0", "gate#0" ]`. No `rnnoise` anywhere; the `pkgs.fetchurl` model download is gone (module no longer needs `pkgs`).

- [ ] **Step 1: Rewrite the module**

Replace the entire contents of `modules/audio/easyeffects.nix` with:

```nix
{ ... }:
{
  flake.modules.homeManager.easyeffects =
    { ... }:
    {
      services.easyeffects.enable = true;

      # DeepFilterNet (deep noise suppression) -> Gate. Denoise the TV out from
      # under speech, then gate the residual so Discord's VAD sees silence in
      # the gaps. Keys/defaults are EasyEffects 8.2.5's; only attack/release/
      # curve-threshold/reduction are tuned from default.
      home.file.".local/share/easyeffects/input/mic-chain.json".text = builtins.toJSON {
        input = {
          blocklist = [ ];
          plugins_order = [ "deepfilternet#0" "gate#0" ];
          "deepfilternet#0" = {
            bypass = false;
            input-gain = 0.0;
            output-gain = 0.0;
            attenuation-limit = 100.0;
            min-processing-threshold = -10.0;
            max-erb-processing-threshold = 30.0;
            max-df-processing-threshold = 20.0;
            min-processing-buffer = 0;
            post-filter-beta = 0.02;
          };
          "gate#0" = {
            bypass = false;
            input-gain = 0.0;
            output-gain = 0.0;
            dry = -80.01;
            wet = 0.0;
            attack = 2.0;
            release = 200.0;
            curve-threshold = -40.0;
            curve-zone = -6.0;
            hysteresis = false;
            hysteresis-threshold = -12.0;
            hysteresis-zone = -6.0;
            reduction = -60.0;
            makeup = 0.0;
            stereo-split = false;
            sidechain = {
              type = "Internal";
              mode = "Peak";
              source = "Middle";
              stereo-split-source = "Left/Right";
              preamp = 0.0;
              reactivity = 10.0;
              lookahead = 0.0;
            };
            hpf-mode = "Off";
            hpf-frequency = 10.0;
            lpf-mode = "Off";
            lpf-frequency = 20000.0;
            input-to-sidechain = -80.01;
            input-to-link = -80.01;
            sidechain-to-input = -80.01;
            sidechain-to-link = -80.01;
            link-to-input = -80.01;
            link-to-sidechain = -80.01;
          };
        };
      };
    };
}
```

- [ ] **Step 2: Verify the rendered preset JSON is correct**

Run:
```bash
nix eval --raw .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.file.'".local/share/easyeffects/input/mic-chain.json"'.text | python3 -m json.tool
```
Expected: valid JSON printing an `input` object with
`"plugins_order": ["deepfilternet#0", "gate#0"]`, a `deepfilternet#0` block with
`"attenuation-limit": 100.0`, and a `gate#0` block with `"curve-threshold": -40.0`,
`"reduction": -60.0`, `"attack": 2.0`, `"release": 200.0`, and a nested
`"sidechain"` object. No `rnnoise` key present.

- [ ] **Step 3: Verify the old preset is no longer produced**

Run:
```bash
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.file --apply 'f: builtins.hasAttr ".local/share/easyeffects/input/rnnoise.json" f'
```
Expected: `false`.

- [ ] **Step 4: Verify the flake still evaluates**

Run: `nix flake check`
Expected: `all checks passed!` (exit 0).

- [ ] **Step 5: Commit**

```bash
git add modules/audio/easyeffects.nix
git commit -m "feat(easyeffects): replace rnnoise with DeepFilterNet -> Gate mic chain"
```

---

### Task 2: Live activation, verification & tuning on jezrien (user-run)

This is manual — it needs the jezrien machine, the EasyEffects GUI, and audible TV. It also resolves the dconf-load and autoload details the repo change can't.

**Files:** none (may produce a follow-up tuning commit to `modules/audio/easyeffects.nix`).

- [ ] **Step 1: Rebuild**

Run: `sudo nixos-rebuild switch --flake .#jezrien`
Expected: activates cleanly; `~/.local/share/easyeffects/input/mic-chain.json` now exists and the old `rnnoise.json` symlink is gone.

- [ ] **Step 2: Remove the stale home-manager backup**

The old preset may have left a home-manager backup. Remove it if present:
```bash
rm -f ~/.local/share/easyeffects/input/rnnoise.json.bak
```

- [ ] **Step 3: Load the preset in EasyEffects**

Open EasyEffects → Presets → Input → load **mic-chain** (EasyEffects applies from
dconf, so the preset must be loaded for the chain to become active). Confirm the
Input pipeline now shows **Deep Noise Suppression** and **Gate**, in that order,
and no RNNoise.

- [ ] **Step 4: Check autoload for the mic device**

If an autoload entry exists for the microphone, repoint it so the chain
auto-applies on device connect:
```bash
ls ~/.config/easyeffects/autoload/input/ 2>/dev/null
```
If a file there references the old `rnnoise` preset, re-create the autoload in the
EasyEffects UI (Presets → the autoload/target-device control) pointing at
`mic-chain`. If the directory is empty/absent, no action needed.

- [ ] **Step 5: Verify gating with the TV on**

With the TV audible in the other room and you silent, watch EasyEffects' input
level meter (post-chain). Expected: it drops to (near-)silence when you're not
talking, and Discord's mic indicator no longer activates in your gaps. Speak and
confirm your voice opens the gate cleanly with no clipped word starts/ends.

- [ ] **Step 6: Tune if needed (then commit the change)**

Adjust in EasyEffects live, then mirror the final value into
`modules/audio/easyeffects.nix` (the module is the source of truth):
- TV still trips the gate in gaps → raise `gate#0.curve-threshold` toward `-30.0`.
- Gate clips your quiet speech / word tails → lower `curve-threshold` toward
  `-45.0` and/or raise `release` toward `300.0`.
- Gate chatters at the threshold → set `hysteresis = true` and
  `hysteresis-threshold` a few dB below `curve-threshold` (e.g. threshold `-40.0`
  → hysteresis-threshold `-46.0`).
- TV still bleeds under your voice while talking → DeepFilterNet is already at
  max (`attenuation-limit = 100.0`); little more to give there.

If you changed values, commit:
```bash
git add modules/audio/easyeffects.nix
git commit -m "tune(easyeffects): dial in mic gate thresholds"
```

---

## Notes for the implementer

- **Why a full gate block:** EasyEffects serializes ~30 gate keys plus a nested
  `sidechain` object; providing the complete set (defaults except the four tuned
  values) matches a native export so the preset applies deterministically. Do not
  trim keys.
- **Enum fields are label strings**, not indices: `sidechain.type = "Internal"`,
  `sidechain.mode = "Peak"`, `sidechain.source = "Middle"`,
  `sidechain.stereo-split-source = "Left/Right"`, `hpf-mode = "Off"`,
  `lpf-mode = "Off"`. Wrong casing/label = ignored key.
- **Hysteresis starts off** deliberately: a single clean threshold is more
  predictable for the first live test; it's a documented tuning lever (Task 2
  Step 6), enabled correctly only with `hysteresis-threshold` below
  `curve-threshold`.
- **`services.easyeffects` package** is the flake's nixpkgs `easyeffects` (8.2.5),
  built with `deepfilternet`, `rnnoise`, and `speexdsp` — DeepFilterNet is native,
  no extra wiring.
```
