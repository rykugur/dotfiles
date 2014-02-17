dotfiles
========

Various linux dot and config files.

Be sure to call 'git submodule update --init --recursive' # apparently deprecated?

Will need to cp ls++ binary to /usr/bin or some other location.

Note: for issues where urxvt will display unicode characters but urxvtc will not, add to /etc/profile:
export LC_CTYPE="en_US.UTF-8"

TODO: create install script

TODO: add to install script:
    "vim +BundleInstall +qall" to install vim "vundle" bundles

    git remote add upstream git://github.com/sorin-ionescu/prezto.git

    git remote add upstream git://github.com/gmarik/vundle.git

    git remote add upstream git://github.com/Lokaltog/powerline.git

    git remote add upstream git://github.com/Lokaltog/powerline-fonts.git

    git remote add upstream git://github.com/zsh-users/antigen.git

    git remote add upstream git://github.com/trapd00r/ls--.git

    git remote add upstream git://github.com/cpbotha/nvpy

    To pull upstream changes:

        cd to each submodule dir, "git pull upstream {master|develop}"

        cd .. to main repo, git add ./submodule, git commit -m
