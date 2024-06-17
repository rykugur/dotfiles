{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.gaming.starsector;
  # leaving this for now; dunno wtf I was doing with it but it was un-used
  # modsDrv = with pkgs.starsectorMods.starsectorMods;
  #   mkModDirDrv [
  #     lazylib
  #     magiclib
  #     nexerelin
  #     graphicslib
  #   ];
in {
  options.modules.gaming.starsector = {
    enable = lib.mkEnableOption "Enable Starsector.";
    mods.enable = lib.mkEnableOption "Enable starsector mods.";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home = {
        packages = [ pkgs.starsector ];
      } // lib.mkIf cfg.mods.enable {
        file = lib.mkIf cfg.mods.enable {
          ".local/share/starsector/mods/lazylib" = {
            source = "${pkgs.starsectorMods.starsectorMods.lazylib}";
          };
          ".local/share/starsector/mods/magiclib" = {
            source = "${pkgs.starsectorMods.starsectorMods.magiclib}";
          };
          ".local/share/starsector/mods/nexerelin" = {
            source = "${pkgs.starsectorMods.starsectorMods.nexerelin}";
          };
          ".local/share/starsector/mods/graphicslib" = {
            source =
              "${pkgs.starsectorMods.starsectorMods.graphicslib}/GraphicsLib"; # temporary workaround
          };
        };
      };
    };
  };
}
