# infra/unifi

OpenTofu for the isolated VLAN, firewall zone, and firewall policies behind
the OpenRig agent world VM (`elantris`, not yet created). Kept in its own
state, separate from `infra/proxmox`, so a UniFi apply never touches the
Proxmox guest and vice versa.

State lives beside this file, ignored by Git but plaintext on disk. Treat
it as sensitive. Run `umask 077` before any manual `tofu` command here.
The API key comes from the environment, never a Terraform variable or a
saved plan. It's cached at `~/.config/unifi/agent.key` (mode `0600`,
outside the repo, matching `pve_token` in `justfile`) so routine `tofu
plan`/`apply` don't need a 1Password prompt each time:

```sh
export UNIFI_API="https://10.3.8.1"
export UNIFI_API_KEY="$(cat ~/.config/unifi/agent.key)"
# Re-seed it after a rotation:
#   op read 'op://Private/elantris opentofu api key/api_key' > ~/.config/unifi/agent.key
#   chmod 600 ~/.config/unifi/agent.key
```

## Status: applied 2026-10-22, isolation verified

- `unifi_network.world` — VLAN 199, subnet `10.3.199.1/24`, DHCP
  `10.3.199.100`–`.254` (leaving `.2`–`.99` free for elantris's static
  address and any future disposable test VM), public DNS only (`1.1.1.1`,
  `9.9.9.9`), IPv6 disabled, client isolation on.
- `unifi_firewall_zone.world` — the "World" zone containing that network.
- Ten firewall policies: admin SSH in from `10.3.8.42/32` only (with its
  auto-generated return leg), DHCP out to the Gateway zone and the
  matching DHCP-reply leg back in, and an explicit NEW/INVALID-only block
  for every other direction (Internal, Gateway, VPN, Hotspot, DMZ, AI
  Fun). `World → External` is still implicit, relying on UniFi's built-in
  "Other Zones to External: Allow All" default — confirmed working by the
  live test below, not independently verified beyond that.

Nothing here imports or modifies the `Default`, `Homelab (K8s)`,
`Homelab (Proxmox)`, `Work`, or `AI Fun` networks or zones — `AI Fun`
(VLAN 99) was deleted by Dusty independently of this plan; its empty
firewall zone is still referenced (by id) so a future network placed back
in that zone stays blocked by default. See
[[OpenRig Agent World]] in Arcanum for why a shared zone was rejected.

## Gotchas found applying this (all fixed in the resources above)

- **`setting_preference` must be `"manual"`, never left unset.** The
  0.59.0 provider serializes an unset field as `""`, and the controller
  rejects that with `api.err.InvalidValue`. `"auto"` plans fine but
  silently drops the explicit DNS override — confirmed live, the network
  came back with `dhcpd_dns_enabled: false` despite requesting `true`.
- **`create_allow_respond = true` isn't just rejected for ICMP** (the
  provider docs' only documented restriction) — the controller also
  rejected it for the UDP/67 DHCP-request policy
  (`api.err.FirewallPolicyCreateRespondTrafficPolicyNotAllowed`). Fixed by
  adding `allow_gateway_dhcp_to_world` (UDP/68) as an explicit reverse
  policy instead.
- **A `BLOCK` policy with the default `connection_state_type` ("ALL")
  also blocks return traffic of flows a *different*, lower-priority ALLOW
  policy let in** — not just new connection attempts. `Block Internal to
  World` (index 10000) sat below the SSH allow's auto-generated return
  policy (index 30000, named `... (Return)`), so it silently dropped the
  SSH session's reply packets and `ssh` timed out despite the explicit
  allow being present and correctly ordered ahead of the block for *new*
  connections. Every manually-written `BLOCK` policy here now sets
  `connection_state_type = "CUSTOM"` with `connection_states = ["NEW",
  "INVALID"]` so it only stops fresh access, never return traffic of an
  already-permitted flow.
- **No documented API exposes switch port VLAN/trunk configuration** —
  confirmed instead by the live disposable-VM test: roshar's uplink does
  carry VLAN 199 (DHCP lease `10.3.199.132` observed).

## Live test performed (2026-10-22, VM destroyed after)

A disposable VM (no agents, no secrets, booted from the existing
`nale-installer.iso`, never installed to disk) on `vmbr0` tag 199:

| Check | Result |
|---|---|
| DHCP lease in `10.3.199.0/24` | ✅ `10.3.199.132` |
| `/etc/resolv.conf` is public-DNS only | ✅ `1.1.1.1`, `9.9.9.9` |
| WAN HTTPS + public DNS resolution | ✅ |
| Gateway mgmt HTTPS (`10.3.8.1`) | ✅ blocked |
| Ping to roshar (Internal zone) | ✅ blocked |
| Ping to jezrien itself (non-SSH) | ✅ blocked — only tcp/22 is allowed |
| TCP to a different Internal-zone DNS host | ✅ blocked |
| SSH in from jezrien (`10.3.8.42`) | ✅ succeeded |
| SSH attempt from roshar (non-admin Internal source) | ✅ blocked |

Only `World → AI Fun` and non-DHCP `Gateway ↔ World` traffic were not
separately live-tested (no second host available on those paths); both
use the same policy shape already proven correct above.

## Rollback

Detach or destroy the test/production VM first — `tofu destroy` here
while a guest is still attached to VLAN 199 cuts that guest off from its
network. Removing the VLAN or zone after elantris exists needs Dusty's
consent per the project plan.
