function nrf
    argparse -n nrf r/remote -- $argv; or return

    set -l url $HOME/.dotfiles
    if set -q _flag_remote
        set url github:rykugur/dotfiles
    end

    nix repl --expr "builtins.getFlake \"$url\""
end
