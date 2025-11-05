{ config, inputs, lib, ... }:
let cfg = config.rhx.dank-material-shell;
in {
  imports =
    [ inputs.dank-material-shell.homeModules.dankMaterialShell.default ];

  options.rhx.dank-material-shell = {
    enable = lib.mkEnableOption "Enable dank-material-shell HM module";
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings =
      lib.mkIf config.rhx.hyprland.enable { };

    programs.niri.settings = lib.mkIf config.rhx.niri.enable {
      binds = with config.lib.niri.actions;
        {
          "Mod+Shift+V".action = spawn-sh "dms ipc call clipboard toggle";
          "Mod+R".action = spawn-sh "dms ipc call spotlight toggle";
          "Mod+Space".action = spawn-sh "dms ipc call spotlight toggle";
        } // {
          XF86AudioLowerVolume.action =
            spawn-sh "dms ipc call audio increment 5";
          XF86AudioRaiseVolume.action =
            spawn-sh "dms ipc call audio decrement 5";
          XF86AudioMute.action = spawn-sh "dms ipc call audio mute";
          XF86AudioPlay.action = spawn-sh "dms ipc call playPause";
          XF86AudioPause.action = spawn-sh "dms ipc call playPause";
          XF86AudioNext.action = spawn-sh "dms ipc call next";
          XF86AudioPrev.action = spawn-sh "dms ipc call previous";
          XF86MonBrightnessUp.action =
            spawn-sh "ims call brightness increment 5";
          XF86MonBrightnessDown.action =
            spawn-sh "ims call brightness decrement 5";
        };
    };
  };
}
