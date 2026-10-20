{
  lib,
  writers,
  makeWrapper,
  runCommand,
  openssh,
  nix,
  sops,
}:
let
  program = writers.writePython3Bin "pve-provision" {
    flakeIgnore = [
      "E501"
      "W503"
    ];
  } (builtins.readFile ./pve-provision.py);
in
# `--build` shells out to nix, `--age-key-sops` to sops, and the post-create
# steps to ssh; keep all three on PATH so the tool works from a systemd unit
# or an agent's bash tool.
runCommand "pve-provision"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Build a NixOS LXC template, upload it, and provision a Proxmox CT";
      mainProgram = "pve-provision";
    };
  }
  ''
    mkdir -p "$out/bin"
    makeWrapper ${lib.getExe program} "$out/bin/pve-provision" \
      --prefix PATH : ${
        lib.makeBinPath [
          openssh
          nix
          sops
        ]
      }
  ''
