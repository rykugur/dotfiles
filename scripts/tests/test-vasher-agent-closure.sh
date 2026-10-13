#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$root"

# The option default is empty, so every key assertion runs against a
# configuration extended with one test key.
extended='(c.extendModules {
  modules = [ { ryk.vasherPrebuild.agentKeys = [ "ssh-ed25519 AAAATESTKEY agent@jezrien" ]; } ];
}).config'
# The same configuration with a key that smuggles a second authorized_keys
# line. The module must refuse it.
smuggled='(c.extendModules {
  modules = [ { ryk.vasherPrebuild.agentKeys = [ "ssh-ed25519 AAAATESTKEY agent@jezrien\nssh-ed25519 AAAASHELL attacker@elsewhere" ]; } ];
}).config'

keys=$(nix eval --json '.#nixosConfigurations.vasher' \
  --apply "c: $extended.users.users.vasher-agent.openssh.authorizedKeys.keys")
jq -e 'length == 1' <<< "$keys" > /dev/null
jq -e 'all(.[]; test("^command=\"/nix/store/[a-z0-9]+-vasher-agent-verb/bin/vasher-agent-verb\",restrict "))' \
  <<< "$keys" > /dev/null

# A newline in a key is rejected at evaluation time, by an assertion that names
# the option. Only failing assertions are forced: a passing one may carry a
# message that cannot be evaluated here.
failing='builtins.filter (a: !a.assertion)'
failed=$(nix eval --json '.#nixosConfigurations.vasher' \
  --apply "c: builtins.map (a: a.message) ($failing $smuggled.assertions)" \
  | jq -r 'join("\n")')
grep -q 'ryk.vasherPrebuild.agentKeys' <<< "$failed"
ok=$(nix eval --json '.#nixosConfigurations.vasher' \
  --apply "c: builtins.length ($failing $extended.assertions)")
[[ $ok == 0 ]] || {
  printf 'a well formed key tripped an assertion\n' >&2
  exit 1
}

# Building the key file realises the channel program, which runs its flake8
# check, and proves the forced command points at a path that exists.
drv=$(nix eval --raw '.#nixosConfigurations.vasher' \
  --apply "c: $extended.environment.etc.\"ssh/authorized_keys.d/vasher-agent\".source.drvPath")
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

# The polkit rule is pinned as a whole, so neither a widened condition nor an
# extra unit name can hide in a comment.
expected_rule='polkit.addRule(function(action, subject) {
  if (subject.user !== "vasher-agent") {
    return polkit.Result.NOT_HANDLED;
  }
  if (action.id !== "org.freedesktop.systemd1.manage-units") {
    return polkit.Result.NO;
  }
  var unit = action.lookup("unit");
  if (action.lookup("verb") === "start" &&
      (unit === "vasher-prebuild-retry.service" ||
       unit === "vasher-prebuild-narrow.service")) {
    return polkit.Result.YES;
  }
  return polkit.Result.NO;
});'
enabled=$(nix eval --json '.#nixosConfigurations.vasher.config.security.polkit.enable')
[[ $enabled == true ]]
rule=$(nix eval --raw '.#nixosConfigurations.vasher.config.security.polkit.extraConfig')
diff <(printf '%s\n' "$expected_rule") <(printf '%s\n' "$rule") > /dev/null || {
  printf 'polkit rule does not match the pinned text:\n%s\n' "$rule" >&2
  exit 1
}

# Exact rules, so any widening of the channel user's write permission shows up
# as a diff in this test.
rules=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.tmpfiles.rules')
expected_rules='[
  "d /var/lib/vasher/dashboard 0775 vasher vasher -",
  "d /var/lib/vasher/monitor 0755 root root -",
  "d /var/lib/vasher/agent 0755 vasher-agent vasher-agent -",
  "f /var/lib/vasher/dashboard/events.json 0644 root root - []"
]'
vasher_rules=$(jq -c '[.[] | select(contains("/var/lib/vasher"))]' <<< "$rules")
jq -e --argjson expected "$expected_rules" '. == $expected' <<< "$vasher_rules" > /dev/null || {
  printf 'tmpfiles rules do not match the pinned list:\n%s\n' "$vasher_rules" >&2
  exit 1
}

# The retry request and the agent event file live in the agent directory, the
# only directory the channel user may write.
nix build --no-link '.#nixosConfigurations.vasher.config.systemd.units."vasher-prebuild-retry.service".unit'
retry_exec=$(nix eval --raw '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-retry.serviceConfig.ExecStart')
grep -q '^/var/lib/vasher/agent/retry.json$' <<< "$(sed -n 's/^ *request=//p' "${retry_exec%%/bin/*}/bin/vasher-prebuild-retry")"
grep -q 'RETRY_PATH = Path("/var/lib/vasher/agent/retry.json")' modules/nixos/vasher-prebuild-monitor.py
grep -q 'AGENT_DIR = Path("/var/lib/vasher/agent")' modules/nixos/vasher-agent-verb.py

# The monitor may write the shared agent directory, because it writes the same
# retry request during its own recovery.
monitor_rw=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.serviceConfig.ReadWritePaths')
jq -e 'contains(["/var/lib/vasher/agent"])' <<< "$monitor_rw" > /dev/null
