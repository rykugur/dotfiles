{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.ryk.dankMaterialShell;
  screenshotBackends = (import ../shared.nix).screenshotBackends;
  coreutils = "${pkgs.coreutils}/bin";
  grep = "${pkgs.gnugrep}/bin/grep";
  sed = "${pkgs.gnused}/bin/sed";
in
{
  options.ryk.dankMaterialShell = {
    enable = lib.mkEnableOption "Enable dankMaterialShell custom quickshell module.";

    screenshotBackend = lib.mkOption {
      type = lib.types.enum screenshotBackends;
      default = "none";
    };

    avatar = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ./avatar.png;
      description = "Avatar image to expose to DMS through AccountsService.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.accounts-daemon.enable = lib.mkIf (cfg.avatar != null) true;

    systemd.user.services.niri-flake-polkit.enable = false;

    system.activationScripts.dankMaterialShellAvatar = lib.mkIf (cfg.avatar != null) (
      lib.concatStringsSep "\n" [
        "${coreutils}/install -D -m 0644 ${cfg.avatar} /var/lib/AccountsService/icons/${username}"
        "${coreutils}/install -d -m 0755 /var/lib/AccountsService/users"
        ""
        "user_file=/var/lib/AccountsService/users/${username}"
        "icon_line=Icon=/var/lib/AccountsService/icons/${username}"
        ""
        ''if [ -f "$user_file" ]; then''
        ''if ${grep} -q '^Icon=' "$user_file"; then''
        ''${sed} -i "s|^Icon=.*|$icon_line|" "$user_file"''
        ''elif ${grep} -q '^\[User\]' "$user_file"; then''
        ''${sed} -i "/^\[User\]/a $icon_line" "$user_file"''
        "  else"
        ''printf '\n[User]\n%s\n' "$icon_line" >> "$user_file"''
        "  fi"
        "else"
        ''printf '[User]\n%s\n' "$icon_line" > "$user_file"''
        "fi"
        ""
        ''${coreutils}/chmod 0600 "$user_file"''
        ""
      ]
    );

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
