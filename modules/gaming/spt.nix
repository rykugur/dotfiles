# Home Manager module bringing the SPT Linux tools onto PATH:
#   - spt-additions: installer / manager CLI (one-time setup)
#   - spt-server:    native Linux SPT.Server.Linux runner
#   - spt-launcher:  Windows SPT.Launcher.exe via umu/proton
#
# Derivations live in pkgs/default.nix, sourced from the rykugur/SPT-Linux-Guide
# flake input. DOTNET_ROOT is set so SPT.Server.Linux finds ASP.NET on NixOS —
# bump the package reference when SPT moves to a newer .NET runtime.
{ ... }:
{
  flake.modules.homeManager.spt =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        spt-additions
        spt-server
        spt-launcher
      ];

      home.sessionVariables.DOTNET_ROOT = "${pkgs.dotnet-aspnetcore_9}/share/dotnet";
    };
}
