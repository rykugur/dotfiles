function eve-pfx --description "Change to the EVE Wine prefix"
    if test (uname) != Linux
        echo "This command is linux-only, doing nothing." >&2
        return 1
    end

    cd "$HOME/.local/share/Steam/steamapps/compatdata/8500/pfx"
end
