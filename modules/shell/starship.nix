{ self, ... }:
{
  flake.modules.homeManager.starship =
    { config, lib, ... }:
    {
      imports = [ self.modules.homeManager.starshipFormat ];

      config.programs.starship = {
        enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;

        settings = {
          format = lib.concatStrings (
            config.programs.starship.prependFormat
            ++ [
              # Spell out $all so $vcs replaces, rather than duplicates, its VCS modules.
              "$username$hostname$localip$shlvl$singularity$nats$directory$vcsh$vcs"
              "$docker_context$package"
              "$bun$c$cmake$cobol$cpp$daml$dart$deno$dotnet$elixir$elm$erlang"
              "$fennel$fortran$gleam$golang$gradle$haskell$haxe$helm$java$julia"
              "$kotlin$lua$maven$mojo$nim$nodejs$ocaml$odin$opa$perl$php$pulumi"
              "$purescript$python$quarto$raku$rlang$red$ruby$rust$scala$solidity"
              "$swift$terraform$typst$vlang$vagrant$xmake$zig$buf"
              "$guix_shell$nix_shell$conda$pixi$meson$spack$memory_usage"
              "$aws$gcloud$openstack$azure$direnv$env_var$mise$crystal$custom$sudo"
              "$cmd_duration$jobs$battery$time$status$container$netns$os$shell"
              "$line_break$kubernetes$line_break$character"
            ]
          );
          vcs = {
            order = [ "jj" "git" "hg" "pijul" "fossil" ];
            jj_modules = "$jj_change$jj_bookmark$jj_status";
          };
          jj_change.format = "[jj](bold purple) $change ";
          hostname = {
            ssh_symbol = "";
          };
          nix_shell = {
            format = "[$name]($style)";
            heuristic = true;
          };
          kubernetes = {
            disabled = false;
            format = "[$symbol$context( \\($namespace\\))]($style)";
          };
        };
      };
    };
}
