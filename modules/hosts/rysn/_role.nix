{ pkgs, ... }:
let
  sshKeys = import ../../misc/_dusty-ssh-keys.nix;
in
{
  networking.hostName = "rysn";
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = sshKeys;
  users.users.dusty = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
  };
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = [ pkgs.btrfs-progs ];
  system.stateVersion = "26.05";
}
