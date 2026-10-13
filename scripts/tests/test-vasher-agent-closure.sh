#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$root"

# The option default is empty, so every key assertion runs against a
# configuration extended with one test key.
extended='c: (c.extendModules {
  modules = [ { ryk.vasherPrebuild.agentKeys = [ "ssh-ed25519 AAAATESTKEY agent@jezrien" ]; } ];
})'

keys=$(nix eval --json '.#nixosConfigurations.vasher' \
  --apply "$extended.config.users.users.vasher-agent.openssh.authorizedKeys.keys")
jq -e 'length == 1' <<< "$keys" > /dev/null
jq -e 'all(.[]; test("^command=\"/nix/store/[a-z0-9]+-vasher-agent-verb/bin/vasher-agent-verb\",restrict "))' \
  <<< "$keys" > /dev/null

# Building the key file realises the channel program, which runs its flake8
# check, and proves the forced command points at a path that exists.
drv=$(nix eval --raw '.#nixosConfigurations.vasher' \
  --apply "$extended.config.environment.etc.\"ssh/authorized_keys.d/vasher-agent\".source.drvPath")
nix build --no-link "$drv^*"

agent_path=$(jq -r '.[0] | capture("^command=\"(?<path>[^\"]+)/bin/vasher-agent-verb\"") | .path' <<< "$keys")
while IFS= read -r path; do
  case ${path##*/} in
    *openssh*)
      printf 'agent closure contains OpenSSH: %s\n' "$path" >&2
      exit 1
      ;;
  esac
done < <(nix-store -qR -- "$agent_path")

# The channel user holds no supplementary groups, so it cannot read the deploy
# key or the GitHub token, both owned by vasher and mode 0400.
primary=$(nix eval --raw '.#nixosConfigurations.vasher.config.users.users.vasher-agent.group')
[[ $primary == vasher-agent ]] || {
  printf 'unexpected primary group: %s\n' "$primary" >&2
  exit 1
}
extra=$(nix eval --json '.#nixosConfigurations.vasher.config.users.users.vasher-agent.extraGroups')
jq -e 'length == 0' <<< "$extra" > /dev/null
members=$(nix eval --json '.#nixosConfigurations.vasher.config.users.groups.vasher.members')
jq -e 'index("vasher-agent") == null' <<< "$members" > /dev/null
system_user=$(nix eval --json '.#nixosConfigurations.vasher.config.users.users.vasher-agent.isSystemUser')
[[ $system_user == true ]]

enabled=$(nix eval --json '.#nixosConfigurations.vasher.config.security.polkit.enable')
[[ $enabled == true ]]
rule=$(nix eval --raw '.#nixosConfigurations.vasher.config.security.polkit.extraConfig')
grep -q 'subject.user !== "vasher-agent"' <<< "$rule"
grep -q 'org.freedesktop.systemd1.manage-units' <<< "$rule"
units=$(grep -o 'vasher-prebuild-[a-z-]*\.service' <<< "$rule" | sort -u | tr '\n' ' ')
[[ $units == 'vasher-prebuild-narrow.service vasher-prebuild-retry.service ' ]] || {
  printf 'polkit rule names unexpected units: %s\n' "$units" >&2
  exit 1
}

rules=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.tmpfiles.rules')
jq -e 'index("d /var/lib/vasher/agent 0755 vasher-agent vasher-agent -")' <<< "$rules" > /dev/null
