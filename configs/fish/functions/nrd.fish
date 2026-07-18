function nrd
    set -l real_dots_dir (path resolve $DOTFILES_DIR)
    echo "realDotsDir=$real_dots_dir"
    nix repl --expr "builtins.getFlake \"$real_dots_dir\""
end
