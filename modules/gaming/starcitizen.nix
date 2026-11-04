{ inputs, self, ... }:
{
  flake.modules.nixos.starcitizen =
    { config, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      username = config.ryk.username;
      nixCitizenPkgs = inputs.nix-citizen.packages.${system};
      # Graphics userspace from nix-citizen's *pinned* nixpkgs, so it shares
      # wine-astral's glibc. See the VK_DRIVER_FILES note below.
      nixCitizenNixpkgs = inputs.nix-citizen.inputs.nixpkgs.legacyPackages.${system};
    in
    {
      imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

      security.pam.loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "16777216";
        }
      ];

      nix.settings = {
        substituters = [
          "https://nix-citizen.cachix.org"
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };

      programs.rsi-launcher = {
        enable = true;

        # nix-citizen's overlay defines wine-astral via callPackage against
        # *our* nixpkgs, and smartPackage prefers pkgs.wine-astral whenever it
        # exists - so every nixpkgs bump rebuilt wine-astral, and the mingw
        # gcc under it, from source while the byte-identical version sat in
        # nix-citizen.cachix.org unused. Point both options at nix-citizen's
        # own package set instead: built against their pinned nixpkgs, which
        # is what cachix actually has.
        #
        # includeOverlay = false would be the tidier fix, but it is broken
        # upstream - modules/nixos/star-citizen/default.nix:20 reads
        # `self.packages.${pkgs.stdenv.hostPlatform}`, indexing with the
        # platform attrset rather than its .system string, so the fallback
        # throws "expected a string but found a set".
        wine = nixCitizenPkgs.wine-astral;
        package = nixCitizenPkgs.rsi-launcher;
        enableNTsync = false; # Jezrien imports the standalone ntsync module.

        # Launch OpenTrack alongside RSI Launcher in the same Wine environment.
        preCommands = ''
          ${pkgs.opentrack}/bin/opentrack &
          scOpentrackPid=$!
          export MESA_VK_WSI_PRESENT_MODE=mailbox
          export DXVK_HUD=compiler
          export MANGO_HUD=1
          export MANGOHUD=1

          # Wine comes from nix-citizen's pinned nixpkgs (glibc 2.42) while
          # this host is on glibc 2.44. Wine's own glibc is loaded first, so
          # dlopen of the *system* mesa ICD fails - "libm.so.6: version
          # `GLIBC_2.44' not found (required by libLLVM.so.21.1)" - the loader
          # finds no GPU and DXVK aborts in DxvkInstance::createInstance.
          # Feed it the ICD and implicit layers from the same pinned nixpkgs
          # instead; RADV is userspace only, so a minor version skew against
          # the system mesa is harmless. Drop these two exports once
          # nix-citizen's nixpkgs pin reaches glibc >= this host's.
          export VK_DRIVER_FILES=${nixCitizenNixpkgs.mesa}/share/vulkan/icd.d/radeon_icd.x86_64.json
          export VK_ADD_IMPLICIT_LAYER_PATH=${nixCitizenNixpkgs.mangohud}/share/vulkan/implicit_layer.d
          export WINE_HIDE_NVIDIA_GPU=1
          export PROTON_ENABLE_WAYLAND=1
          export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winewayland.drv=n,b"
        '';
        postCommands = ''
          kill "$scOpentrackPid" 2>/dev/null || true
        '';

        patchXwayland = true;
        enforceWaylandDrv = true;
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen ];
    };

  flake.modules.homeManager.starcitizen =
    { pkgs, ... }:
    let
      sys = pkgs.stdenv.hostPlatform.system;
      lug-helper = inputs.nix-citizen.packages.${sys}.lug-helper;
      wineAstralPkg = inputs.nix-citizen.packages.${sys}.wine-astral;
    in
    {
      home.packages = with pkgs; [
        opentrack
        lug-helper
      ];

      # lazy-mode - for opentrack
      home.file.".wine-astral".source = wineAstralPkg;
    };
}
