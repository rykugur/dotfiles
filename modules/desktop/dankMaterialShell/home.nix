{ inputs, lib, nixosConfig, ... }:
let rhxCfg = nixosConfig.rhx;
in {
  imports = [ inputs.dankMaterialShell.homeModules.dankMaterialShell.default ]
    ++ lib.optionals (rhxCfg.niri.enable)
    [ inputs.dankMaterialShell.homeModules.dankMaterialShell.niri ];

  config = lib.mkIf rhxCfg.noctalia.enable {
    programs.dankMaterialShell = {
      enable = true;

      enableSystemMonitoring = true;
      enableClipboard = true;
      enableBrightnessControl = false;
      enableAudioWavelength = true;
      enableCalendarEvents = false;
      enableSystemSounds = false;
    };
  };
}
