variable "api_url" {
  description = "UniFi controller base URL. UNIFI_API env var also works; this default matches the local gateway."
  type        = string
  default     = "https://10.3.8.1"
}

variable "world_vlan_id" {
  description = "VLAN ID for the agent world network. 199 is unused as of the 2026-10-22 inventory (existing: 1, 9, 10, 99, 200)."
  type        = number
  default     = 199
}

variable "world_gateway_ip" {
  type    = string
  default = "10.3.199.1"
}

variable "world_prefix_length" {
  type    = number
  default = 24
}

variable "world_dhcp_start" {
  description = "DHCP range starts at .100, leaving .2-.99 free for elantris's static address and any disposable test VM."
  type        = string
  default     = "10.3.199.100"
}

variable "world_dhcp_stop" {
  type    = string
  default = "10.3.199.254"
}

variable "world_dns_servers" {
  description = "Public resolvers only; *.local.ryk.sh and LAN names must not resolve from this VLAN."
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]
}

variable "admin_ssh_source_cidr" {
  description = "Only this source may initiate SSH into the world network (jezrien)."
  type        = string
  default     = "10.3.8.42/32"
}
