function rbld-switch
    if test (uname) = Darwin
        nh darwin switch $DOTFILES_DIR
    else
        nh os switch $DOTFILES_DIR
    end
end
