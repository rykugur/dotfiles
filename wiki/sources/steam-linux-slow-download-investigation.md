---
title: Steam-for-Linux Slow Download Investigation (jezrien)
category: source
date: 2026-07-09
tags: [jezrien, steam, networking, r8125, debugging, troubleshooting]
sources: ["modules/hosts/jezrien/_configuration.nix", "live ss -tinO measurements", "ValveSoftware/steam-for-linux#13024", "ValveSoftware/steam-for-linux#13378"]
related: ["hosts.md", "architecture.md"]
---

# Steam-for-Linux Slow Download Investigation (jezrien)

Steam game downloads on jezrien crawl at **~50–110 Mbps** while a Windows box on the *same LAN* sustains **917 Mbps** and raw non-Steam downloads on jezrien hit **780 Mbps**. A full systematic-debugging pass (2026-07-09) proved **every host layer is fast and clean** and pinned the cause on a **known Valve Steam-for-Linux client defect** ([steam-for-linux#13024](https://github.com/ValveSoftware/steam-for-linux/issues/13024)) — receiver-side application throttling, not the network stack, driver, DNS, disk, or any NixOS config. **No config change fixes it.** This page exists so the `r8125` driver code in jezrien's config is understood as an *attempted* fix that did **not** work.

## Key Facts

- **Root cause: the Steam client, not jezrien.** Kernel `TCP_INFO` on every CDN connection showed `app_limited` + `rcv_wnd` pinned at **~177 KB** + `delivery_rate ~1.2 Mbps/conn`. Steam's single-threaded read→decompress→write loop (with multi-hundred-ms idle gaps) never drains the socket, so the receive window collapses and each of ~100 connections is throttled to ~1.2 Mbps → ~100 Mbps aggregate ceiling. Matches #13024 to the digit.
- **The `r8125` driver swap did NOT fix it.** `modules/hosts/jezrien/_configuration.nix` blacklists in-kernel `r8169` and loads Realtek's vendor `r8125` for the RTL8125 2.5GbE NIC, with a comment blaming slow Steam downloads. The driver *is* active and clean (0 rx drops / retrans / reorder under load), but the slowness persists. Keep the module (it's a legitimate offload/driver improvement) but **do not treat it as the Steam fix**.
- **Not a networking-stack conflict.** jezrien runs a single, plain **dhcpcd scripted-networking** stack (`networking.useDHCP` in `_hardware-configuration.nix`); no NetworkManager/networkd. The `networkmanager` group on the user is dead weight (daemon not enabled).

## What was measured (all ruled out)

| Layer | Result | Verdict |
|---|---|---|
| Raw non-Steam download (Cloudflare 50 MB) | 780 Mbps | ✅ fast |
| Path to Steam CDN (`ord1`) | 11 ms RTT, 0% loss | ✅ excellent |
| `r8125` driver under live load | 0 drops / retrans / reorder | ✅ clean |
| Disk write (btrfs zstd:3, incompressible) | 829 MB/s | ✅ fast |
| DNS | local LAN resolver `10.3.9.5/.6` (= Windows) | ✅ same |
| Steam library backing store | local NVMe (not the `dusty-nfs` automount) | ✅ n/a |
| Steam throttle setting | `DownloadThrottleKbps = 0` | ✅ none |

## Dead ends (do not retry)

Region change (`CellIDServerOverride 76`→Chicago/`1` — a symptom, not cause), clear download cache (×2), `steam_dev.cfg` HTTP/2 disable (already present), Steam Client Beta (also froze the UI), BBR, NIC-offload toggles, IPv6 disable, dnsmasq. All confirmed useless here — the same list the upstream #13378 reporter exhausted before finding it was client-side.

## CDN-blackhole workaround: rejected for jezrien

[#13378](https://github.com/ValveSoftware/steam-for-linux/issues/13378) blackholes slow Valve CDN IPs to force better node selection, and a NixOS module was considered. The kernel `app_limited` evidence **disproves it for jezrien**: the throttle is receiver-side (177 KB window), not CDN selection, so swapping nodes or forcing more connections can't break the single-read-loop ceiling. **Do not build the blackhole module.**

## Only real workaround

For large pulls, use **[DepotDownloader](https://github.com/SteamRE/DepotDownloader)** — proper parallel async I/O that saturates the line (#13024 confirms aria2c-class downloaders hit full rate on the same path). Otherwise tolerate it or wait for a Valve client fix. Tracked upstream: #13024, #12082, #13378.

### Cross-references

- [Hosts](../hosts.md) — jezrien
- [Architecture](../architecture.md)
- Upstream: [steam-for-linux#13024](https://github.com/ValveSoftware/steam-for-linux/issues/13024), [#13378](https://github.com/ValveSoftware/steam-for-linux/issues/13378)
