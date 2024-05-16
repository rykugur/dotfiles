{ inputs, outputs, pkgs, system, ... }: {
  imports = [
    outputs.homeManagerModules.face-tracking
  ];

  home.packages = [
    inputs.nix-citizen.packages.x86_64-linux.star-citizen
    inputs.nix-citizen.packages.x86_64-linux.lug-helper
  ];
  # home.file = {
  #   ".drirc" = {
  #     text = ''
  #       <application name="Star Citizen" executable="StarCitizen.exe" >
  #         <option name="dual_color_blend_by_location" value="true" />
  #       </application>
  #     '';
  #   };
  # };
}
