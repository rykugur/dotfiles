# infra/unifi

OpenTofu for the isolated VLAN, firewall zone, and firewall policies behind
the OpenRig agent world VM (`elantris`, not yet created). Kept in its own
state, separate from `infra/proxmox`, so a UniFi apply never touches the
Proxmox guest and vice versa.

State lives beside this file, ignored by Git but plaintext on disk. Treat
it as sensitive. Run `umask 077` before any manual `tofu` command here.
The API key comes from the environment, never a Terraform variable or a
saved plan:

```sh
export UNIFI_API="https://10.3.8.1"
export UNIFI_API_KEY="$(op read 'op://Private/elantris opentofu api key/api_key')"
```

## What this creates

- `unifi_network.world` — VLAN 199, subnet `10.3.199.1/24`, DHCP
  `10.3.199.100`–`.254` (leaving `.2`–`.99` free for elantris's static
  address and a disposable test VM), public DNS only (`1.1.1.1`,
  `9.9.9.9`), IPv6 disabled, client isolation on.
- `unifi_firewall_zone.world` — a new "World" zone containing that network.
- Nine firewall policies: admin SSH in from `10.3.8.42/32` only, DHCP out
  to the Gateway zone only, and an explicit block for every other
  direction (Internal, Gateway, VPN, Hotspot, DMZ). `World → External`
  relies on UniFi's built-in "Other Zones to External: Allow All" default;
  this plan does not create or touch that default policy.

Nothing here imports or modifies the `Default`, `Homelab (K8s)`,
`Homelab (Proxmox)`, `Work`, or `AI Fun` networks or zones. VLAN 99
(`AI Fun`) is deliberately left alone — see
[[OpenRig Agent World]] in Arcanum for why a shared zone was rejected.

## Known gaps before relying on this plan

- **Policy order isn't reorderable through the API.** The provider always
  appends a new policy to the end of its zone pair, so each allow policy
  above uses `depends_on` to force its matching block policy to be created
  second. Confirm the effective order in the UniFi UI (Settings → Policy
  Table) after apply.
- **No documented API exposes switch port VLAN/trunk configuration**, so
  this plan cannot assert that the UniFi switch ports between the gateway
  and roshar (`Proxmox Homelab Switch`) carry VLAN 199. roshar's `vmbr0` is
  already VLAN-aware (`bridge-vlan-aware yes`, `bridge-vids 2-4094`), so the
  gap is purely on the switch side. The disposable test VM in the sequence
  below is the actual proof: if it fails to get a DHCP lease, the trunk
  does not carry the VLAN and the port profile needs a manual UI check.
- **`World → External` is implicit**, not declared here. Confirm in the UI
  that the built-in default still applies to a new custom zone before
  treating outbound WAN as working.

## Sequence

1. `tofu init`, then `tofu plan`. Read every proposed change; it must only
   create new `World`-scoped resources.
2. `tofu apply`.
3. Attach a disposable VM to `vmbr0` on roshar with `vlan_id = 199` (no
   agents, no secrets). Confirm it gets a `10.3.199.0/24` DHCP lease,
   reaches the public internet, and cannot reach `10.3.8.1` management
   HTTPS, any `Internal`-zone host, or any other VLAN. Confirm SSH from
   jezrien succeeds and SSH from any other host is blocked.
4. Only after every check in step 3 passes, move on to creating `elantris`
   in `infra/proxmox`.

## Rollback

Detach or destroy the test/production VM first — `tofu destroy` here
while a guest is still attached to VLAN 199 cuts that guest off from its
network. Removing the VLAN or zone after elantris exists needs Dusty's
consent per the project plan.
