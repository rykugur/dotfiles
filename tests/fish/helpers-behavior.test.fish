#!/usr/bin/env fish

set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -l test_root (mktemp -d)
set -l stub_dir $test_root/bin
set -l work_dir $test_root/work
set -gx HOME $test_root/home
set -gx DOTFILES_DIR $repo
set -gx PATH $stub_dir $PATH
set -gx GIT_ADD_LOG $test_root/git-add.log
set -gx PREFETCH_ARG $test_root/prefetch-arg
set -gx NIX_ARGS $test_root/nix-args

mkdir -p $stub_dir $work_dir $HOME

function fail
    echo $argv >&2
    rm -rf -- $test_root
    exit 1
end

printf '%s\n' '#!/bin/sh' \
    'case "$1" in' \
    '  ls-files) printf "untracked victim\\0" ;;' \
    '  status) printf "R  renamed target\\0?? victim\\0?? untracked victim\\0C  copied target\\0AM payload\\0R  another target\\0MM payload\\0AM actual add\\0MM actual modify\\0" ;;' \
    '  add) printf "%s\\n" "$3" >> "$GIT_ADD_LOG" ;;' \
    'esac' >$stub_dir/git
chmod +x $stub_dir/git

printf '%s\n' '#!/bin/sh' \
    'printf "%s\\n" "$1" > "$PREFETCH_ARG"' \
    'printf "sha256-from-prefetch\\n"' >$stub_dir/nix-prefetch-url
chmod +x $stub_dir/nix-prefetch-url

printf '%s\n' '#!/bin/sh' \
    'printf "%s\\n" "$@" > "$NIX_ARGS"' \
    'input=$(cat)' \
    'printf "sri:%s\\n" "$input"' >$stub_dir/nix
chmod +x $stub_dir/nix

source $repo/configs/fish/config.fish

printf source >$work_dir/'?? victim'
printf sentinel >$work_dir/victim
printf untracked >$work_dir/'untracked victim'

pushd $work_dir >/dev/null
gcu
popd >/dev/null

test -e $work_dir/victim
or fail 'gcu acted on a rename source named ?? victim'
test ! -e $work_dir/'untracked victim'
or fail 'gcu did not delete the untracked path'

gas
set -l staged (cat $GIT_ADD_LOG)
contains -- 'actual add' $staged
or fail 'gas did not stage the AM pathname'
contains -- 'actual modify' $staged
or fail 'gas did not stage the MM pathname'
contains -- payload $staged
and fail 'gas acted on rename/copy sources named AM payload or MM payload'

set -l url https://example.invalid/archive.tar.gz
set -l shash_output (shash $url)
test "$shash_output" = sri:sha256-from-prefetch
or fail 'shash did not pipe nix-prefetch-url output through nix hash to-sri'
test (cat $PREFETCH_ARG) = $url
or fail 'shash did not pass its URL to nix-prefetch-url'
set -l nix_args (cat $NIX_ARGS)
test "$nix_args[1]" = hash -a "$nix_args[2]" = to-sri -a "$nix_args[3]" = --type -a "$nix_args[4]" = sha256
or fail 'shash did not invoke nix hash to-sri --type sha256'
rm -rf -- $test_root
