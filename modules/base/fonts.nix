{ ... }:
let
  fontsModule =
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
in
{
  flake.modules.nixos.fonts = fontsModule;
  flake.modules.darwin.fonts = fontsModule;
}
