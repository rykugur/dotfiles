{ lib, pkgs, ... }: {
  programs.starship =
    let
      flavor = "mocha";
    in
    {
      enable = true;
      enableFishIntegration = true;
      settings = {
        # Other config here
        format = "$all"; # Remove this line to disable the default prompt format
        # format = lib.concatStrings [
        #   "[](peach)"
        #   "$os"
        #   "$username"
        #   "[](bg:yellow fg:peach)"
        #   "$directory"
        #   "[](fg:yellow bg:sky)"
        #   "$git_branch"
        #   "$git_status"
        #   "[](fg:sky bg:blue)"
        #   "$c"
        #   "$rust"
        #   "$golang"
        #   "$nodejs"
        #   "$php"
        #   "$java"
        #   "$kotlin"
        #   "$haskell"
        #   "$python"
        #   "[](fg:blue bg:maroon)"
        #   "$docker_context"
        #   "$conda"
        #   "[](fg:maroon bg:mauve)"
        #   "$time"
        #   "[ ](fg:mauve)"
        #   "$line_break$character"
        # ];
        # os = lib.concatStrings [
        #   "disabled=false"
        #   "style = bg:peach fg:blue"
        # ];
        palette = "catppuccin_${flavor}";
      }
      # } // builtins.fromTOML (builtins.readFile ../../configs/starship/starship.toml)
      // builtins.fromTOML (builtins.readFile
        (pkgs.fetchFromGitHub
          {
            owner = "catppuccin";
            repo = "starship";
            rev = "5629d2356f62a9f2f8efad3ff37476c19969bd4f";
            sha256 = "sha256-nsRuxQFKbQkyEI4TXgvAjcroVdG+heKX5Pauq/4Ota0=";
          } + /palettes/${flavor}.toml));
    };

}

