function eve-eanm --description "Run EVE asset name manager"
    set -l hostname_without_local (string replace .local '' (hostname))
    set -l settings_dir "$HOME/gits/games/eve/eve-settings"

    cd "$settings_dir/$hostname_without_local"; and nix run nixpkgs#zulu -- -jar "$settings_dir/EANM.jar"
end
