# dotfiles / nixOS config

> [!WARNING]
> THIS IS A(LWAYS A) WORK IN PROGRESS

My personal nixOS config + dotfiles.

The nixOS config is contained within a flake, with home-manager installed as a
nixOS module. Most configs are contained within the `./configs` directory, and
are symlinked into place by home-manager.

## Modules

Modules come in two flavors: `nixos` and `home-manager`. The `nixos` modules
are used to configure the system, while the `home-manager` modules are used to
configure the user's home directory.

## Roles

Roles are abstractions around modules.

## TODO

- Figure out wtf is going on with zellij and nushell paths.
