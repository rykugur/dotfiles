#!/usr/bin/env sh
set -eu

nix eval --json .#nixosConfigurations."$(hostname -s)".config.home-manager.users.dusty.programs.fish.enable \
  | jq -e '. == true'
nix eval --json .#nixosConfigurations."$(hostname -s)".config.home-manager.users.dusty.programs.nushell.enable \
  | jq -e '. == true'
