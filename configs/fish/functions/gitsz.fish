function gits --description 'cd wrapper for known gits'
    set -l argc (count $argv)

    if test $argc -eq 0
        cd $HOME/gits; and return
    end

    set -l _gits_dir $HOME/gits/
    if test ! -d $_gits_dir
        echo "$HOME/gits doesn't exist"
    end

    set -l options (fish_opt -s e -l eve) (fish_opt -s d -l dots) (fish_opt -s l -l lug)

    argparse $options -- $argv
    or return

    test -n "$_flag_e"; or test -n "$_flag_eve"; and cd $HOME/gits/eve-settings; and return
    test -n "$_flag_d"; or test -n "$_flag_dots"; and cd $HOME/gits/dotfiles; and return
    test -n "$_flag_l"; or test -n "$_flag_lug"; and cd $HOME/gits/lug-helper; and return
end
