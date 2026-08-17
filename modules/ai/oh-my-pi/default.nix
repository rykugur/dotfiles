{ ... }:
let
  release = builtins.fromJSON (builtins.readFile ./release.json);
  inherit (release) version sources;

  mkOhMyPi =
    pkgs:
    let
      inherit (pkgs) lib;


      srcInfo =
        sources.${pkgs.stdenv.hostPlatform.system}
          or (throw "oh-my-pi is not packaged for ${pkgs.stdenv.hostPlatform.system}");

      linuxLibPath = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.glibc
        pkgs.openssl
        pkgs.zlib
      ];
    in
    pkgs.stdenv.mkDerivation {
      pname = "oh-my-pi";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${srcInfo.asset}";
        sha256 = srcInfo.hash;
      };

      dontUnpack = true;
      dontStrip = pkgs.stdenv.hostPlatform.isLinux;
      dontPatchELF = pkgs.stdenv.hostPlatform.isLinux;

      nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.makeWrapper
        pkgs.patchelf
      ];

      installPhase =
        if pkgs.stdenv.hostPlatform.isLinux then
          ''
            runHook preInstall

            install -Dm755 "$src" "$out/libexec/omp"
            patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" "$out/libexec/omp"
            makeWrapper "$out/libexec/omp" "$out/bin/omp" \
              --prefix LD_LIBRARY_PATH : "${linuxLibPath}"

            runHook postInstall
          ''
        else
          ''
            runHook preInstall

            install -Dm755 "$src" "$out/bin/omp"

            runHook postInstall
          '';

      doInstallCheck = pkgs.stdenv.hostPlatform.isLinux;
      installCheckPhase = ''
        runHook preInstallCheck

        HOME="$TMPDIR" "$out/bin/omp" --version >/dev/null

        runHook postInstallCheck
      '';

      meta = {
        description = "Oh My Pi coding agent";
        homepage = "https://github.com/can1357/oh-my-pi";
        license = lib.licenses.mit;
        mainProgram = "omp";
        platforms = builtins.attrNames sources;
      };
    };

  mkCompletion =
    pkgs: ohMyPi: shell:
    pkgs.runCommand "omp-${shell}-completion" { nativeBuildInputs = [ ohMyPi ]; } ''
      export HOME="$TMPDIR"
      omp completions ${shell} > "$out"
    '';

in
{
  flake.modules.homeManager.oh-my-pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ohMyPi = mkOhMyPi pkgs;
      mcp = import ../_mcp.nix { inherit pkgs; };
      modelRoles = {
        default = "anthropic/claude-sonnet-5";
        smol = "anthropic/claude-haiku-4-5";
        slow = "anthropic/claude-opus-5";
      };

      fallbackChains = {
        default = [
          "openai-codex/gpt-5.6-terra"
          "xai-oauth/grok-4.5"
          "openrouter/deepseek/deepseek-v4-flash-0731"
        ];
        smol = [
          "openai-codex/gpt-5.6-luna"
          "xai-oauth/grok-4.5"
          "openrouter/deepseek/deepseek-v4-flash-0731"
        ];
        slow = [
          "openai-codex/gpt-5.6-sol"
          "xai-oauth/grok-4.5"
          "openrouter/deepseek/deepseek-v4-flash-0731"
        ];
      };

      symbolPreset = "nerd";

      themeDark = "dark-catppuccin";

      memoryBackend = "mnemopi";
      mnemopiScoping = "per-project-tagged";

      cycleOrder = [
        "smol"
        "slow"
        "default"
      ];
    in
    lib.mkMerge [
      {
        home.packages = [ ohMyPi ];

        home.file.".omp/agent/mcp.json".text = builtins.toJSON {
          mcpServers = mcp.toOhMyPi (mcp.pick [ "arcanum" ]);
        };
        home.activation.ohMyPiModelConfiguration =
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${ohMyPi}/bin/omp config set modelRoles ${
              lib.escapeShellArg (builtins.toJSON modelRoles)
            }
            run ${ohMyPi}/bin/omp config set retry.fallbackChains ${
              lib.escapeShellArg (builtins.toJSON fallbackChains)
            }
            run ${ohMyPi}/bin/omp config set symbolPreset ${
              lib.escapeShellArg symbolPreset
            }
            run ${ohMyPi}/bin/omp config set theme.dark ${
              lib.escapeShellArg themeDark
            }
            run ${ohMyPi}/bin/omp config set memory.backend ${
              lib.escapeShellArg memoryBackend
            }
            run ${ohMyPi}/bin/omp config set mnemopi.scoping ${
              lib.escapeShellArg mnemopiScoping
            }
            run ${ohMyPi}/bin/omp config set cycleOrder ${
              lib.escapeShellArg (builtins.toJSON cycleOrder)
            }
          '';
      }

      (lib.mkIf (config.ryk.defaultShell == "fish") {
        xdg.configFile."fish/completions/omp.fish".source = mkCompletion pkgs ohMyPi "fish";
      })


      (lib.mkIf (config.ryk.defaultShell == "bash") {
        programs.bash = {
          enable = true;
          enableCompletion = true;
        };

        home.file.".local/share/bash-completion/completions/omp".source = mkCompletion pkgs ohMyPi "bash";
      })
    ];

  perSystem =
    { pkgs, ... }:
    let
      updateOhMyPi = pkgs.writeShellApplication {
        name = "update-oh-my-pi";
        runtimeInputs = [ pkgs.curl pkgs.git pkgs.jq pkgs.nix ];
        text = ''
          exec ${./update-omp.sh} "$@"
        '';
      };
    in
    {
      packages = {
        oh-my-pi = mkOhMyPi pkgs;
        update-oh-my-pi = updateOhMyPi;
      };

      checks.oh-my-pi-update = pkgs.runCommand "oh-my-pi-update-test" {
        nativeBuildInputs = [ pkgs.bash pkgs.jq pkgs.nix ];
      } ''
        NIX_CONFIG='experimental-features = nix-command' ${pkgs.bash}/bin/bash ${./.}/update-omp.test.sh
        touch $out
      '';
    };
}
