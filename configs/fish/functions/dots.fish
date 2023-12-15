#!/usr/bin/fish

function dots --description "cd wrapper for dots dir"
    set -l argc (count $argv)

    set -l _dots_dir $DOTFILES_DIR
    if test -d $_dots_dir
        set _dots_dir $DOTFILES_DIR
    else
        echo DOTFILES_DIR not set
    end

    if test $argc -eq 0
        cd $_dots_dir
        return
    end

    set -l options (fish_opt -s h -l help) (fish_opt -s c -l configs) (fish_opt -s f -l fish)

    argparse $options -- $argv
    or return

    test -n "$_flag_c"; or test -n "$_flag_configs"; and cd $_dots_dir/configs; and return
    test -n "$_flag_f"; or test -n "$_flag_fish"; and cd $_dots_dir/configs/fish; and return
end

complete -f -c dots -n dots -a --configs
complete -f -c dots -n dots -a --fish
