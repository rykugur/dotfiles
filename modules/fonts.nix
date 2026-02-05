{ ... }:
{
  flake.nixosModules.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        nerd-fonts.zed-mono
        nerd-fonts.caskaydia-cove
        nerd-fonts.caskaydia-mono
        nerd-fonts.fira-mono
        nerd-fonts.fira-code
      ];
    };
}
