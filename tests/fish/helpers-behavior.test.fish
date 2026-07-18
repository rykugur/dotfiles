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
set -gx EDITOR true
mkdir -p $stub_dir $work_dir $HOME

function fail
    echo $argv >&2
    rm -rf -- $test_root
    exit 1
end

printf '%s\n' '#!/bin/sh' \
    'case "$1" in' \
    '  ls-files) printf "untracked victim\\0" ;;' \
    '  status) printf "R  renamed target\\0?? victim\\0?? untracked victim\\0C  copied target\\0AM payload\\0R  another target\\0MM payload\\0AM actual add\\0MM actual modify\\0AM actual\\nadd\\0" ;;' \
    '  add) test "$#" -eq 3 || { printf "invalid-argument-count:%s\\n" "$#" >> "$GIT_ADD_LOG"; exit 1; }; printf "%s\\0" "$3" >> "$GIT_ADD_LOG" ;;' \
    'esac' >$stub_dir/git
chmod +x $stub_dir/git

printf '%s\n' '#!/bin/sh' \
    'printf "%s\\n" "$1" > "$PREFETCH_ARG"' \
    'printf "sha256-from-prefetch\\n"' >$stub_dir/nix-prefetch-url
chmod +x $stub_dir/nix-prefetch-url

printf '%s\n' '#!/bin/sh' \
    'printf "%s\\0" "$@" > "$NIX_ARGS"' \
    'printf "sri:%s\\n" "$5"' >$stub_dir/nix
chmod +x $stub_dir/nix

printf '%s\n' '#!/bin/sh' \
    'printf "%s" "$CLIPBOARD_CONTENT"' >$stub_dir/wl-paste
chmod +x $stub_dir/wl-paste

source $repo/configs/fish/config.fish
set -gx EDITOR true

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
set -l staged (string split0 < $GIT_ADD_LOG)
contains -- 'actual add' $staged
or fail 'gas did not stage the AM pathname'
contains -- 'actual modify' $staged
or fail 'gas did not stage the MM pathname'
set -l newline_path (printf 'actual\nadd' | string collect --no-trim-newlines)
contains -- $newline_path $staged
or fail 'gas split a newline-containing pathname passed to git add'
contains -- payload $staged
and fail 'gas acted on rename/copy sources named AM payload or MM payload'

set -l url https://example.invalid/archive.tar.gz
set -l shash_output (shash $url)
test "$shash_output" = sri:sha256-from-prefetch
or fail 'shash did not pass nix-prefetch-url output to nix hash to-sri'
test (cat $PREFETCH_ARG) = $url
or fail 'shash did not pass its URL to nix-prefetch-url'
set -l nix_args (string split0 < $NIX_ARGS)
test (count $nix_args) -eq 5
and test "$nix_args[1]" = hash -a "$nix_args[2]" = to-sri -a "$nix_args[3]" = --type -a "$nix_args[4]" = sha256 -a "$nix_args[5]" = sha256-from-prefetch
or fail 'shash did not invoke nix hash to-sri --type sha256 with the prefetched hash argument'

set -gx CLIPBOARD_CONTENT 'clipboard replacement'
set -l piped_content (printf 'piped\ncontent' | string collect --no-trim-newlines)
printf '%s\0' "$piped_content" | replace-multiline >$test_root/replace-piped-output
set -l replace_piped (string collect --no-trim-newlines < $test_root/replace-piped-output)
set -l expected_replace_piped (printf '%s\n' "$piped_content" | string collect --no-trim-newlines)
test "$replace_piped" = "$expected_replace_piped"
or fail 'replace-multiline did not read piped stdin'

printf '%s\0' "$piped_content" | edit-multiline >$test_root/edit-piped-output
set -l edit_piped (string collect --no-trim-newlines < $test_root/edit-piped-output)
test "$edit_piped" = "$piped_content"
or fail 'edit-multiline did not read piped stdin'

set -l interactive_script $test_root/interactive-clipboard.fish
set -l interactive_replace_output $test_root/replace-interactive-output
set -l interactive_replace_expected $test_root/replace-interactive-expected
set -l interactive_edit_output $test_root/edit-interactive-output
set -l interactive_edit_expected $test_root/edit-interactive-expected
printf '%s\n' "$CLIPBOARD_CONTENT" >$interactive_replace_expected
printf '%s' "$CLIPBOARD_CONTENT" >$interactive_edit_expected
printf 'set -gx PATH %s $PATH\n' (string escape -- $stub_dir) >$interactive_script
printf 'set -gx CLIPBOARD_CONTENT %s\n' (string escape -- "$CLIPBOARD_CONTENT") >>$interactive_script
printf 'set -gx EDITOR true\n' >>$interactive_script
printf 'source %s\n' (string escape -- "$repo/configs/fish/functions/cmd-paste.fish") >>$interactive_script
printf 'source %s\n' (string escape -- "$repo/configs/fish/functions/replace-multiline.fish") >>$interactive_script
printf 'source %s\n' (string escape -- "$repo/configs/fish/functions/edit-multiline.fish") >>$interactive_script
printf 'replace-multiline >%s\n' (string escape -- $interactive_replace_output) >>$interactive_script
printf 'cmp --silent %s %s; or exit 1\n' (string escape -- $interactive_replace_output) (string escape -- $interactive_replace_expected) >>$interactive_script
printf 'edit-multiline >%s\n' (string escape -- $interactive_edit_output) >>$interactive_script
printf 'cmp --silent %s %s; or exit 1\n' (string escape -- $interactive_edit_output) (string escape -- $interactive_edit_expected) >>$interactive_script
set -l interactive_command (string join ' ' -- timeout --signal=KILL 2 fish --no-config (string escape -- $interactive_script))
script --quiet --return --command "$interactive_command" /dev/null >/dev/null
or fail 'replace-multiline or edit-multiline did not use the clipboard immediately on interactive stdin'

pushd $work_dir >/dev/null
printf original >.envrc
mkenvrc >/dev/null 2>$test_root/mkenvrc.stderr
set -l mkenvrc_status $status
test $mkenvrc_status -ne 0
or fail 'mkenvrc overwrote an existing .envrc'
test (cat .envrc) = original
or fail 'mkenvrc changed an existing .envrc'
rm .envrc
mkenvrc
test -f .envrc
or fail 'mkenvrc did not create a missing .envrc'
popd >/dev/null
rm -rf -- $test_root
