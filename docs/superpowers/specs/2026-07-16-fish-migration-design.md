# Fish Dual-Shell Migration Design

## Goal

Prepare Fish as the primary interactive shell while keeping Nushell as the active login shell until the Fish configuration is functionally verified. The migration addresses persistent external-command completion friction and ports every interactive Nushell helper to a Fish equivalent or records an intentional exception.

## Activation and cutover

`ryk.defaultShell` remains `"nushell"` during the trial. Add a focused trial option that enables `programs.fish` and sources `configs/fish/config.fish` without changing the login shell or disabling `programs.nushell`.

The existing Carapace module already enables its Fish and Nushell integrations independently whenever the corresponding shell is enabled. During the trial both integrations are active.

After verification, set:

```nix
ryk.defaultShell = "fish";
```

Remove the temporary trial option in the same change. `modules/ai/herdr.nix` derives Herdr's `terminal.default_shell` from `ryk.defaultShell`, so Herdr follows the cutover automatically.

## Fish command organization

Use the established Fish layout:

- `configs/fish/ez/*.fish`: abbreviations and simple aliases.
- `configs/fish/functions/*.fish`: one behaviorful helper per file.
- `configs/fish/config.fish`: startup sourcing order only.

Reconcile behavior from all files sourced by `configs/nu/config.nu`; do not mechanically translate Nu syntax and do not invoke `nu -c` from Fish.

| Nushell area | Fish destination |
| --- | --- |
| Docker, Git, Linux, Nix, and simple miscellany | Update existing `ez/*.fish` modules. |
| Kubernetes and Zellij helpers | New dashed Fish functions in `functions/`. |
| 1Password and SOPS age helpers | New dashed Fish functions in `functions/`. |
| Nu-only structured helpers | Fish-native pipelines or purpose-built functions. |
| Project/game commands | Port individually before declaring the trial complete. |

Nushell commands containing spaces become dashed Fish function names. Examples: `sops-kaf`, `zellij-create-or-attach`, `op-ssh-public-key`, and `sops-age-private-key`. Optional short abbreviations may preserve muscle memory, but the implementation must not shadow `sops`, `zellij`, or `op` with namespace dispatcher functions.

## 1Password and SOPS design

The port preserves these capabilities:

1. Select an SSH key with `op item list` and `fzf` when no key ID is supplied.
2. Retrieve the selected key's public or private SSH material with `op item get`.
3. Convert public and private SSH material to age keys through `nix run nixpkgs#ssh-to-age`.
4. Create the local SOPS age key after interactive confirmation or `--yes`.

Function contracts:

- Public/private helper functions accept an explicit SSH-key ID or select one.
- Private key material is only piped to `ssh-to-age` or written directly to the SOPS key file. It is never displayed, logged, or stored in a universal Fish variable.
- The provisioning function creates `~/.config/sops/age` with mode `0700` and writes `keys.txt` with mode `0600`.
- Do not port Nushell's current debug log of `privateAgeKey`; it discloses a secret while `NU_LOG_LEVEL` is `DEBUG`.

## Completion design

Fish receives native completion support and existing Carapace integration. Retain Carapace for its native completers and the repository's `kubecolor` and `flux` bridge specs.

Install Herdr's generated Fish completion into Fish's completion directory. Do not rely on a Nushell/Carapace shell bridge for Herdr.

Provide Fish `complete` declarations for custom helper flags and positional arguments where necessary. Dashed Fish function names are available in normal Fish command completion.

## Trial acceptance criteria

The trial is complete only when:

1. Every helper sourced by `configs/nu/config.nu` has a documented Fish equivalent or an explicit intentional Nu-only disposition.
2. The 1Password/SOPS functions complete and work end-to-end with a selected SSH key, without leaking private material to stdout or logs.
3. Herdr, Kubecolor, and Flux completion work interactively in Fish.
4. Nushell remains the configured login/default shell until all preceding checks pass.
5. The final default-shell flip sets Fish as the login shell and Herdr's default shell, then removes the trial-only activation option.

## Command-equivalence matrix

Every interactive function, alias, and abbreviation sourced by `configs/nu/config.nu` has a Fish command below. A dashed command names its Fish function. A bare command names the existing Fish alias or abbreviation. Entries expressed as a Fish pipeline are directly runnable Fish replacements where a separate helper is not warranted. There are no intentionally Nu-only entries.

| Nushell source | Nushell command → exact Fish command |
| --- | --- |
| `docker.nu` | `dc` → `dc`; `dcb` → `dcb`; `dcl` → `dcl`; `dclf` → `dclf`; `dcr` → `dcr`; `dcu` → `dcu`; `dcud` → `dcud`; `dcd` → `dcd`; `drit` → `drit`; `docker.clean` → `docker.clean`; `lzd` → `lzd` |
| `git.nu` functions | `gas` → `gas`; `gcz` → `gcoz`; `gcu` → `gcu`; `gbz` → `gbz`; `gcoz` → `gcoz` |
| `git.nu` aliases | `gits` → `gits`; `gll` → `gll`; `gbn` → `gbn`; `git head` → `git.head`; `git.back` → `git.back`; `git.branch` → `git.branch`; `git.lastcommit` → `git.lastcommit`; `git.track` → `git.track`; `git.tree` → `git.tree`; `jedi` → `jedi` |
| `git.nu` abbreviations 1 | `ga` → `ga`; `ga.` → `ga.`; `gau` → `gau`; `gb` → `gb`; `gbc` → `gbc`; `gbD` → `gbD`; `gbm` → `gbm`; `gbr` → `gbr`; `gc` → `gc`; `gca` → `gca`; `gcm` → `gcm`; `gcmwip` → `gcmwip`; `gco` → `gco`; `gco.` → `gco.`; `gcob` → `gcob`; `gcof` → `gcof`; `gcp` → `gcp`; `gcy` → `gcy`; `gd` → `gd`; `gds` → `gds`; `gdstat` → `gdstat`; `gf` → `gf`; `gitch` → `gitch`; `gfp` → `gfp` |
| `git.nu` abbreviations 2 | `gg` → `gg`; `ggi` → `ggi`; `gl` → `gl`; `glo` → `glo`; `glss` → `glss`; `gpl` → `gpl`; `gps` → `gps`; `gpsf` → `gpsf`; `gpssuo` → `gpssuo`; `gpls` → `gpls`; `gpub` → `gpub`; `grb` → `grb`; `grbc` → `grbc`; `grpo` → `grpo`; `gr` → `gr`; `grh` → `grh`; `grhh` → `grhh`; `grho` → `grho`; `grm` → `grm`; `grv` → `grv`; `gss` → `gss`; `gssg` → `gssg`; `gsub` → `gsub`; `gw` → `gw`; `gwa` → `gwa`; `gwr` → `gwr`; `gwls` → `gwls`; `turtles` → `turtles` |
| `k8s.nu` abbreviations | `k` → `k`; `ka` → `ka`; `kaf` → `kaf`; `kd` → `kd`; `kdel` → `kdel`; `kdes` → `kdes`; `kg` → `kg`; `kgn` → `kgn`; `kgp` → `kgp`; `kgs` → `kgs`; `kgw` → `kgw`; `kgwn` → `kgwn`; `kgwp` → `kgwp`; `kgws` → `kgws`; `kpf` → `kpf`; `ktx` → `ktx`; `kns` → `kns` |
| `k8s.nu` | `kubectl` → `kubectl`; `kubemerge` → `kubemerge`; `talosmerge` → `talosmerge`; `keit` → `kubectl exec -it`; `shlink create` → `kubectl --namespace shlink exec -it deployments/shlink -- bin/cli short-url:create --custom-slug $slug $url`; `shlink list` → `kubectl --namespace shlink exec -it deployments/shlink -- bin/cli short-url:list`; `hf` → `helmfile`; `fgk` → `flux get kustomization`; `mk` → `minikube`; `sops kaf` → `sops-kaf`; `k8s base64` → `k8s-base64` |
| `linux.nu` aliases 1 | `awk1` → `awk1`; `awk2` → `awk2`; `awk3` → `awk3`; `awk4` → `awk4`; `awk5` → `awk5`; `awk6` → `awk6`; `awk7` → `awk7`; `awk8` → `awk8`; `awk9` → `awk9`; `db` → `distrobox`; `cat` → `cat`; `dfh` → `dfh`; `duh` → `du -h`; `e` → `$EDITOR`; `getmyip` → `getmyip`; `grep` → `grep`; `ll` → `ll`; `murder` → `murder`; `nv` → `nv`; `v` → `v`; `vi` → `vi`; `pingtest` → `pingtest`; `replace.newlines` → `replace.newlines`; `tmat` → `tmat`; `top` → `top`; `whatthecommit` → `whatthecommit`; `ytdl` → `ytdl` |
| `linux.nu` function | `stay-awake` → `stay-awake` |
| `misc.nu` functions 1 | `dots` → `dots`; `is-os` → `test (string lower $argv[1]) = linux; or test (string lower $argv[1]) = macos; or test (string lower $argv[1]) = darwin`; `is-darwin` → `test (uname) = Darwin`; `is-macos` → `test (uname) = Darwin`; `is-linux` → `test (uname) = Linux`; `cmd.copy` → `cmd-copy`; `cmd.paste` → `cmd-paste`; `replace-multiline` → `replace-multiline`; `paste-multiline-nu` → `paste-multiline`; `curl multiline` → `curl (edit-multiline \| replace-multiline \| string replace -r '^curl\\s' '')`; `edit-multiline` → `edit-multiline` |
| `misc.nu` functions 2 | `ghostty fix terminfo` → `infocmp -x xterm-ghostty \| ssh $host -- tic -x -`; `1password copy-ssh-pub-key` → `op-ssh-public-key \| ssh $host 'mkdir ~/.ssh 2>/dev/null; cat >>~/.ssh/authorized_keys'`; `1password get-ssh-pub-key` → `op-ssh-public-key`; `1password get-private-age-key` → `sops-age-private-key`; `1password get-public-age-key` → `sops-age-public-key`; `proxmox install helix` → `ssh $host 'curl -L https://shlink.ryk.sh/helix-deb \| sh'`; `mo2installer` → `cd $HOME/gits/modorganizer2-linux-installer` |
| `misc.nu` abbreviations 1 | `adb.reverse` → `adb.reverse`; `adb.start` → `adb.start`; `adb.reset-perms` → `adb.reset-perms`; `.gw` → `.gw`; `agb` → `agb`; `agbt` → `agbt`; `fish.profile` → `fish.profile`; `pyhttp` → `pyhttp`; `pyjson` → `pyjson`; `cwd` → `cwd`; `gri` → `gri`; `grin` → `grin`; `grine` → `grine`; `pwdc` → `pwdc`; `ssh.forcePass` → `ssh.forcePass`; `taill` → `taill`; `pn` → `pn`; `psw` → `psw`; `pagi` → `pagi` |
| `misc.nu` abbreviations 2 | `pac` → `pac`; `pacs` → `pacs`; `supac` → `supac`; `supacr` → `supacr`; `supacrs` → `supacrs`; `supacrcs` → `supacrcs`; `supacs` → `supacs`; `supac.update` → `supac.update`; `sc` → `sc`; `sc.list` → `sc.list`; `sc.enabled` → `sc.enabled`; `ssc` → `ssc`; `tm` → `tm`; `tmls` → `tmls`; `tmf` → `tmf`; `za` → `za`; `zj` → `zj` |
| `nix.nu` functions | `rbld` → `rbld`; `rbld switch` → `rbld-switch`; `rbld boot` → `rbld-boot`; `nd` → `nd`; `nix get-hash` → `nix-get-hash`; `shash` → `shash`; `nr.` → `nr.`; `nrd` → `nrd`; `nrn` → `nrn`; `nrf` → `nrf`; `nrun` → `nrun`; `mkenvrc` → `mkenvrc`; `mkflake` → `mkflake`; `mkflake electrobun` → `mkflake-electrobun` |
| `nix.nu` abbreviations | `nb` → `nb`; `ndb` → `ndb`; `nf` → `nf`; `nfc` → `nfc`; `nfu` → `nfu`; `ns` → `ns`; `nds` → `nds`; `ndsp` → `ndsp`; `snrb` → `snrb`; `snrbf` → `snrbf`; `snrbfu` → `snrbfu`; `snb` → `snb`; `snr` → `snr`; `snrs` → `snrs`; `snrsf` → `snrsf`; `snrsfu` → `snrsfu` |
| `zellij.nu` | `zellij exists` → `zellij-exists`; `zellij create-or-attach` → `zellij-create-or-attach`; `zellij fzf` → `zellij-fzf`; `zellij delete-all-sessions` → `zellij-delete-all-sessions`; `zellij murder-all-sessions` → `zellij-murder-all-sessions` |
| `eve.nu` | `eve pfx` → `eve-pfx`; `eve settings` → `eve-settings`; `eve pi templates` → `eve-pi-templates`; `eve gits` → `eve-gits`; `eve EANM` → `eve-eanm`; `eve CustomShipLabeler` → `eve-custom-ship-labeler`; `eve pi get name` → `eve-pi-template-name` |
| `pz.nu` | `pz copy mod config` → `pz-copy-mod-config`; `pz mods` → `pz-mods` |
| `stalker2.nu` | `stalker2 pfx` → `stalker2-pfx`; `stalker2 cd` → `stalker2-cd`; `stalker2 mods` → `stalker2-mods` |
| `starcitizen.nu` | `starcitizen getWinePath` → `starcitizen-wine-path`; `starcitizen controllerSettings` → `starcitizen-controller-settings` |
