#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

# source powerline
#if [[ -r ~/dotfiles/powerline/powerline/bindings/zsh/powerline.zsh ]]; then
    #. ~/.dotfiles/powerline/powerline/bindings/zsh/powerline.zsh
#fi

autoload -Uz promptinit
promptinit

# enable antigen and whatnots
#source ~/dotfiles/antigen/antigen.zsh
#antigen bundle git
#antigen bundle zsh-users/zsh-syntax-highlighting
#antigen theme robbyrussel
#antigen use oh-my-zsh
#antigen apply

# don't underline directories on syntax highlight (super annoying)
ZSH_HIGHLIGHT_STYLES[path]='bold'

# exports
export EDITOR=vim
export VISUAL=vim
#export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="$PATH:/usr/local/lib:/Users/dustin.jerome/bin:/Users/dustin.jerome/Utils/adt/tools:/Users/dustin.jerome/Utils/adt/platform-tools:/opt/java6/bin"
export ANT_OPTS="-Xmx1024m -Xms512m"
export PGHOST=localhost

# linux aliases
alias ..='cd ..'
alias cd..='cd ..'
alias cd....='cd ../../'
alias dfh='df -h'
alias dircount='ls -l | wc -l'
alias dircountall='ls -al | wc -l'
alias dush='du -sh'
alias find='find . -name'
alias findo='find'
alias less='less -N'
#alias ls='ls++ --potsf'
alias lso='/bin/ls'
alias ssj='ssh'
alias xrdbhate='xrdb ~/.Xresources'
alias watchy="watch 'ls -l .'"

# arch aliases
alias pacman_deps="pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias mirror_update="sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"

# dev aliases
alias androidem='emulator -avd Nexus4 -scale .5 &'
alias ant_compile_tests='ant compile-unit-tests compile-integration-tests compile-backup-integration-tests compile-commerce-integration-tests compile-standalone-tests'
alias cd42='. ~/bin/cd42.sh'
alias eclipsehate='rm -rf .metadata/.plugins/org.eclipse.core.resources/.history'
alias gitdiff='git difftool --tool vimdiff -u'
alias gitdiffstaged='git difftool --staged -y --tool '
alias gaa='git add -A .'
alias gbvv='git branch -vv'
alias gdH='git diff HEAD~1..HEAD'
alias gds='git difftool --staged -y'
alias gdsv='git difftool --staged -y --tool vimdiff'
alias gdsk='git difftool --staged -y --tool kompare'
alias git_clean_local_branches='git branch -l > /tmp/branches; vim /tmp/branches; cat /tmp/branches | xargs git branch -D; rm /tmp/branches'
alias gitgrep='git grep -ni'
alias grva='grep -v Aggregate'
alias greppy='grep -niRE --include="*.java"'
alias h2web='java -cp /Users/dustin.jerome/Code/core/c42_lib/h2.jar -Xms28m -Xmx512m org.h2.tools.Server -web -webPort 4284'
alias taily='tail -Fn 999 com_backup42_app.log.0 | grva'

# mac aliases... ew
alias flushdns='sudo killall -HUP mDNSResponder'
alias home_vnc='open vnc://vendetta'
alias subl='open -a "Sublime Text 2.app"'
