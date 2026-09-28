#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$root"

nix build --no-link '.#nixosConfigurations.vasher.config.systemd.units."vasher-prebuild-monitor.service".unit'

exec_start=$(nix eval --raw '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.serviceConfig.ExecStart')
monitor_path=${exec_start%%/bin/*}
while IFS= read -r path; do
  case ${path##*/} in
    *openssh*)
      printf 'monitor closure contains OpenSSH: %s\n' "$path" >&2
      exit 1
      ;;
  esac
done < <(nix-store -qR -- "$monitor_path")

monitor_env=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.environment')
jq -e 'has("GIT_SSH_COMMAND") | not' <<< "$monitor_env" >/dev/null

denied=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.serviceConfig.IPAddressDeny')
jq -e 'contains([
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16",
  "fc00::/7"
])' <<< "$denied" >/dev/null

retry_exec=$(nix eval --raw '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-retry.serviceConfig.ExecStart')
case $retry_exec in
  */bin/vasher-prebuild-retry) ;;
  *)
    printf 'unexpected retry command: %s\n' "$retry_exec" >&2
    exit 1
    ;;
esac
