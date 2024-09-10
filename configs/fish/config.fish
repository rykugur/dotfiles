if status is-interactive
    # do stuff
end

set -q __fish_personal_dotfiles_sourced; and exit
set -g __fish_personal_dotfiles_sourced 1

set -gx DOTFILES_DIR $HOME/.dotfiles
set -l fish_conf_dir $DOTFILES_DIR/configs/fish

source $fish_conf_dir/exports.fish

for file in $fish_conf_dir/ez/*
    source $file
end

for file in $fish_conf_dir/functions/*
    source $file
end

# Load any local configs
# Do this last, since we might want to override abbreviations, aliases, etc.
for file in $HOME/.local/fish/*.fish
    source $file
end

if test -d $HOME/.local/fish/functions
    set -gx fish_function_path $HOME/.local/fish/functions $fish_function_path
end

if which -a tmuxifier &>/dev/null
    eval (tmuxifier init - fish)
end

if which -a oh-my-posh &>/dev/null
    alias omp oh-my-posh
    oh-my-posh init fish --config ~/.dotfiles/configs/oh-my-posh/config.catppuccin_mocha.json | source
    # oh-my-posh init fish | source
end
