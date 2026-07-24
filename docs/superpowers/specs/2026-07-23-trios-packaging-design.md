# TriOS packaging design

## Goal

Package upstream TriOS release artifacts as a Nix package, use it from the existing Starsector Home Manager module, remove that module's declarative mod links, and enable the module on the Apple-Silicon Darwin host `taln`.

## Scope

The package targets only platforms for which upstream publishes release artifacts:

- `x86_64-linux` from `TriOS-Linux.zip`
- `aarch64-darwin` from `TriOS-MacOS-AppleSilicon.zip`

The first packaged version is `1.6.1`. Both downloads are fixed-output sources with pinned hashes.

No source build, Flutter SDK, mod migration, or TriOS configuration is included.

## Package architecture

`pkgs/trios.nix` will define `trios` and `pkgs/default.nix` will export it through the existing custom-package overlay.

The derivation selects its release archive from the host platform. Unsupported platforms fail during evaluation rather than selecting an incompatible binary.

### Linux

The Linux ZIP contains the `TriOS` Flutter launcher, `lib/` shared libraries, and `data/` assets. The derivation preserves that layout below its output, patches native ELF dependencies with Nix-provided GTK, GL, curl, font, and related libraries, and exposes `trios` from `$out/bin`.

### macOS

The Apple-Silicon ZIP contains an application `Contents` tree. The derivation installs it as `Applications/TriOS.app`, preserving the Frameworks-relative paths expected by the signed application bundle, and exposes `$out/bin/trios` as a launcher for `TriOS.app/Contents/MacOS/TriOS`.

Package metadata identifies TriOS as the main program, records its homepage, marks its community license as unfree, and limits `meta.platforms` to the two supported target systems.

## Home Manager integration

`modules/gaming/starsector.nix` will add `pkgs.trios` to `home.packages`.

The module will remove all existing declarative mod sources and `home.file` entries:

- LazyLib
- MagicLib
- Nexerelin
- GraphicsLib

TriOS becomes the mod-management interface. This package installation does not preconfigure TriOS or restore the removed mods.

`modules/hosts/taln/default.nix` will import `starsector`, enabling TriOS immediately for the existing `aarch64-darwin` host.

## Verification

- Build `.#trios` on Linux.
- Confirm the Linux executable has Nix-resolved dynamic dependencies and can start.
- Evaluate the `taln` Darwin configuration, confirming it selects the Apple-Silicon artifact without evaluating Linux-only dependencies.
- Native macOS launch remains an on-host validation step on `taln`.
