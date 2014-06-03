# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# source powerline
#if [[ -r ~/dotfiles/powerline/powerline/bindings/zsh/powerline.zsh ]]; then
    #. ~/.dotfiles/powerline/powerline/bindings/zsh/powerline.zsh
#fi

autoload -Uz promptinit
promptinit

# don't underline directories on syntax highlight (super annoying)
ZSH_HIGHLIGHT_STYLES[path]='bold'

# exports
export EDITOR=vim
export VISUAL=vim
#export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# linux aliases
alias ..='cd ..'
alias cd..='cd ..'
alias cd....='cd ../../'
alias dfh='df -h'
alias dircount='ls -l | wc -l'
alias dircountall='ls -al | wc -l'
alias dotfiles='cd ~/.dotfiles'
alias dush='du -sh'
alias findy='find . -name'
alias less='less -N'
#alias ls='ls++ --potsf'
alias lso='/bin/ls'
alias ssj='ssh'
alias xrdbhate='xrdb ~/.Xresources'
alias watchy="watch 'ls -l .'"

# arch aliases
alias pacman_deps="pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias mirror_update="sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
