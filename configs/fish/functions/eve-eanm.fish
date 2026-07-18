function eve-eanm --description "Run EVE asset name manager"
    set -l hostname_without_local (string replace .local '' (hostname))
    set -l settings_dir "$HOME/gits/games/eve/eve-settings"

    pushd "$settings_dir/$hostname_without_local" >/dev/null; or return
    nix run nixpkgs#zulu -- -jar "$settings_dir/EANM.jar"
    set -l command_status $status
    popd >/dev/null; or return $command_status
    return $command_status
end
