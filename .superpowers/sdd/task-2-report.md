# Task 2 Report: Vasher LXC Image and Proxmox Bootstrap

## Changed files

- `modules/hosts/vasher/default.nix` — imports the image-output flake-parts module without changing the runtime role/platform composition.
- `modules/hosts/vasher/_seed.nix` — defines the minimal Proxmox LXC seed: DHCP, flakes, root SSH-key access, and state version. DHCP uses `lib.mkForce true` because the upstream Proxmox LXC module forces it off otherwise.
- `modules/hosts/vasher/_image.nix` — exports the x86_64-linux-only `vasher-lxc-image` package using the `proxmox-lxc` generator format.
- `scripts/bootstrap/proxmox-lxc-create.sh` — creates and starts CT `200` with the approved hostname, resources, DHCP bridge, nesting, unprivileged mode, and operator SSH authorized-keys path.

## Verification

Command:

```sh
nix build .#vasher-lxc-image --no-link --print-out-paths
```

Output:

```text
/nix/store/rdly5crfj4b2l178w3bjzmjrwxh7lpda-tarball
```

The generated output contains:

```text
tarball/nixos-image-lxc-proxmox-26.11.20260723.e2587ca-x86_64-linux.tar.xz
```

## Commits

- `2a34ed0d feat(vasher): add Proxmox LXC image and bootstrap`
- This report is committed separately as `docs(sdd): record Vasher image Task 2`.

## Self-review

- The image seed does not import the runtime role or platform module, so it remains a minimal bootstrap image and does not embed a cache endpoint.
- The runtime host remains composed from its independent role and LXC platform modules; `_image.nix` only contributes a flake package output.
- The image output is restricted to `x86_64-linux`, and the bootstrap has no overridable CT ID: it creates CT `200` as required.
- SSH accepts only root public-key authentication; password authentication and root password login are disabled.
