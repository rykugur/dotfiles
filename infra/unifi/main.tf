terraform {
  required_version = ">= 1.8"

  required_providers {
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "~> 0.59"
    }
  }
}

# Authentication comes from the environment, so no credential ever lands in
# this repo or in state:
#   export UNIFI_API="https://10.3.8.1"
#   export UNIFI_API_KEY="$(op read 'op://Private/elantris opentofu api key/api_key')"
provider "unifi" {
  api_url        = var.api_url
  allow_insecure = true # local gateway serves its own CA-signed cert
}

# Isolated VLAN for the OpenRig agent world (elantris). WAN-reachable, no LAN
# access: see the explicit deny policies below. network_isolation blocks
# client-to-client traffic within the VLAN too, even though only one guest
# is expected on it.
resource "unifi_network" "world" {
  name   = "World"
  subnet = "${var.world_gateway_ip}/${var.world_prefix_length}"
  vlan   = var.world_vlan_id

  # The provider's 0.59.0 payload sends setting_preference="" when unset,
  # which the controller rejects with api.err.InvalidValue (confirmed
  # live 2026-10-22). "manual" is required, not just preferred: "auto"
  # silently drops the explicit DNS override below (also confirmed live).
  setting_preference = "manual"

  network_isolation = true
  multicast_dns     = false
  igmp_snooping     = false

  # No IPv6 on this VLAN: no RA, no DHCPv6, no ULA escape route.
  ipv6_interface_type = "none"

  dhcp_server = {
    enabled     = true
    start       = var.world_dhcp_start
    stop        = var.world_dhcp_stop
    dns_enabled = true
    dns_servers = var.world_dns_servers
  }
}

resource "unifi_firewall_zone" "world" {
  name        = "World"
  network_ids = [unifi_network.world.id]
}

# Built-in zones, looked up by name so this state never imports or rewrites
# an existing zone's membership.
data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

data "unifi_firewall_zone" "gateway" {
  name = "Gateway"
}

data "unifi_firewall_zone" "vpn" {
  name = "Vpn"
}

data "unifi_firewall_zone" "hotspot" {
  name = "Hotspot"
}

data "unifi_firewall_zone" "dmz" {
  name = "Dmz"
}

# AI Fun is its own zone (not folded into Internal), confirmed live on
# 2026-10-22. Block it explicitly like every other existing zone.
data "unifi_firewall_zone" "ai_fun" {
  name = "AI Fun"
}

# --- Inbound: only the approved admin source may open SSH into the world ---

resource "unifi_firewall_policy" "allow_admin_ssh_to_world" {
  name                 = "Allow admin SSH to World"
  action               = "ALLOW"
  protocol             = "tcp"
  create_allow_respond = true
  logging              = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "IP"
    ips             = [var.admin_ssh_source_cidr]
  }

  destination = {
    zone_id            = unifi_firewall_zone.world.id
    matching_target    = "ANY"
    port               = "22"
    port_matching_type = "SPECIFIC"
  }
}

# Everything else from Internal to World is denied. Depends on the allow
# above so it is appended after it: the provider has no reorder operation,
# and policy order follows creation order within a zone pair.
resource "unifi_firewall_policy" "block_internal_to_world" {
  name     = "Block Internal to World"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  # Restricted to NEW/INVALID: a plain "ALL states" block (the omitted
  # default) also matches the auto-generated SSH return-traffic allow's
  # ESTABLISHED replies and silently drops them, since this policy's index
  # (10001) sits below that auto-rule's index (30000). Confirmed live
  # 2026-10-22 as the actual cause of SSH timing out despite the allow.
  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  depends_on = [unifi_firewall_policy.allow_admin_ssh_to_world]
}

# --- Outbound: the world may use the gateway only for DHCP, nothing else ---
# DNS is public (1.1.1.1 / 9.9.9.9), not the gateway, so no DNS exception
# is needed here.

resource "unifi_firewall_policy" "allow_world_dhcp_to_gateway" {
  name     = "Allow World DHCP to Gateway"
  action   = "ALLOW"
  protocol = "udp"
  logging  = true

  # The controller rejects create_allow_respond=true for this policy
  # (api.err.FirewallPolicyCreateRespondTrafficPolicyNotAllowed, confirmed
  # live 2026-10-22) — not just an ICMP restriction as the provider docs
  # suggest. Add the reverse DHCP-reply leg explicitly instead.
  create_allow_respond = false

  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id            = data.unifi_firewall_zone.gateway.id
    matching_target    = "ANY"
    port               = "67"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "allow_gateway_dhcp_to_world" {
  name     = "Allow Gateway DHCP to World"
  action   = "ALLOW"
  protocol = "udp"
  logging  = true

  source = {
    zone_id         = data.unifi_firewall_zone.gateway.id
    matching_target = "ANY"
  }

  destination = {
    zone_id            = unifi_firewall_zone.world.id
    matching_target    = "ANY"
    port               = "68"
    port_matching_type = "SPECIFIC"
  }
}

resource "unifi_firewall_policy" "block_world_to_gateway" {
  name     = "Block World to Gateway"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.gateway.id
    matching_target = "ANY"
  }

  depends_on = [unifi_firewall_policy.allow_world_dhcp_to_gateway]
}

# --- Outbound: no LAN, no VPN, no other private zone ---
# World -> External (public WAN) is not declared here: UniFi's built-in
# "Other Zones to External: Allow All" policy already covers it. Verify
# that default live before relying on it (see README).

resource "unifi_firewall_policy" "block_world_to_internal" {
  name     = "Block World to Internal"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "block_world_to_vpn" {
  name     = "Block World to VPN"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.vpn.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "block_world_to_hotspot" {
  name     = "Block World to Hotspot"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.hotspot.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "block_world_to_dmz" {
  name     = "Block World to DMZ"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.dmz.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "block_world_to_ai_fun" {
  name     = "Block World to AI Fun"
  action   = "BLOCK"
  protocol = "all"
  logging  = true

  connection_state_type = "CUSTOM"
  connection_states     = ["NEW", "INVALID"]
  source = {
    zone_id         = unifi_firewall_zone.world.id
    matching_target = "ANY"
  }

  destination = {
    zone_id         = data.unifi_firewall_zone.ai_fun.id
    matching_target = "ANY"
  }
}

output "world_network_id" {
  value = unifi_network.world.id
}

output "world_zone_id" {
  value = unifi_firewall_zone.world.id
}
