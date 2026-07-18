#!/usr/bin/fish

function dots --description "Open the dotfiles or local Fish configuration directory"
    set -l options (fish_opt -s e -l edit) (fish_opt -s l -l local)
    argparse $options -- $argv
    or return

    set -l editing
    if set -q _flag_e; or set -q _flag_edit
        set editing 1
    end

    if set -q _flag_l; or set -q _flag_local
        set -l config_file $FISH_LOCAL_CONFIG_FILE
        set -l config_dir (path dirname "$config_file")

        if not test -e "$config_file"
            mkdir -p "$config_dir"; and touch "$config_file"; or return
        end

        cd "$config_dir"; or return
        if test -n "$editing"
            command $EDITOR (path basename "$config_file")
        end
        return
    end

    cd "$DOTFILES_DIR"; or return
    if test -n "$editing"
        command $EDITOR
    end
end

complete -f -c dots -s e -l edit
complete -f -c dots -s l -l local
