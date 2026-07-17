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
