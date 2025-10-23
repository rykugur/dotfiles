# modules that are platform-agnostic (i.e. work on both nixos and darwin)
# eventually I'll move more modules over from ../home-manager/* to here
{
  imports = [ ./fonts.nix ./stylix.nix ];
}
