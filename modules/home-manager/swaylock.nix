{ config, lib, ... }:
let cfg = config.rhx.swaylock;
in {
  options.rhx.swaylock = {
    enable = lib.mkEnableOption "Enable swaylock home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      enable = true;

      settings = {
        color = "1e1e2e";
        bs-hl-color = "f5e0dc";
        caps-lock-bs-hl-color = "f5e0dc";
        caps-lock-key-hl-color = "a6e3a1";
        inside-color = 0;
        inside-clear-color = 0;
        inside-caps-lock-color = 0;
        inside-ver-color = 0;
        inside-wrong-color = 0;
        key-hl-color = "a6e3a1";
        layout-bg-color = 0;
        layout-border-color = 0;
        layout-text-color = "cdd6f4";
        line-color = 0;
        line-clear-color = 0;
        line-caps-lock-color = 0;
        line-ver-color = 0;
        line-wrong-color = 0;
        ring-color = "b4befe";
        ring-clear-color = "f5e0dc";
        ring-caps-lock-color = "fab387";
        ring-ver-color = "89b4fa";
        ring-wrong-color = "eba0ac";
        separator-color = 0;
        text-color = "cdd6f4";
        text-clear-color = "f5e0dc";
        text-caps-lock-color = "fab387";
        text-ver-color = "89b4fa";
        text-wrong-color = "eba0ac";
      };
    };
  };
}
