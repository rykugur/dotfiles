# TriOS desktop entry and archive fix design

## Goal

Expose TriOS as a Linux desktop application and repair its bundled 7-Zip helper so mod archive scanning can execute.

## Scope

Only `pkgs/trios.nix` changes. The package remains Linux x86_64 and Apple-Silicon Darwin capable; the desktop entry is Linux-only. No Home Manager, Starsector module, or taln host configuration changes are required.

## Linux desktop integration

The Linux install phase will install:

- `share/applications/trios.desktop`
- `share/icons/hicolor/128x128/apps/trios.png`

The desktop entry uses the package’s wrapped launcher (`Exec=trios`) and the installed icon name (`Icon=trios`). It identifies TriOS as a Starsector launcher, mod manager, and toolkit and places it in the `Game` category.

The icon is copied from the upstream release asset already included in TriOS’s Flutter data tree: `assets/images/telos_faction_crest.png`.

The existing `starsector.desktop` entry remains unchanged, preserving the direct game launcher alongside the new TriOS entry.

## Mod archive scanning repair

TriOS invokes its bundled Linux `7zzs` helper to inspect mod archives. The release ZIP stores this helper without executable permission. Nix therefore installs it as mode `0444`, and TriOS fails with `ProcessException: Permission denied` when scanning an archive such as `Nexerelin_0.11.3c.zip`.

After copying the Linux release data tree, the derivation will set executable permission on exactly:

```text
$out/libexec/trios/data/flutter_assets/assets/linux/7zip/x64/7zzs
```

No archive contents, wrapper behavior, or mod-manager logic changes.

## Verification

- Build `.#trios`.
- Confirm the generated output contains a valid `trios.desktop`, the icon, and executable `7zzs` permission.
- Launch TriOS from the desktop entry or its installed command, retry the Nexerelin archive scan, and confirm the prior permission error is absent.
- Evaluate the flake without building incompatible systems to confirm Darwin configuration remains valid.
