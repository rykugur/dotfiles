function rbld-boot
    if test (uname) = Darwin
        echo 'darwin-rebuild does not support boot' >&2
        return 1
    end
    nh os boot $DOTFILES_DIR
end
