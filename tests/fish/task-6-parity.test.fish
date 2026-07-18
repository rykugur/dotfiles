#!/usr/bin/env fish

set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -l test_root (mktemp -d)
set -l stub_dir $test_root/bin
set -gx HOME $test_root/home
set -gx DOTFILES_DIR $repo
set -gx PATH $stub_dir $PATH
set -gx SCP_ARGS $test_root/scp-args
set -gx EANM_PWD $test_root/eanm-pwd
set -gx NIX_ARGS $test_root/nix-args
set -gx EDITOR_ARGS $test_root/editor-args
set -gx CURL_ARGS $test_root/curl-args
set -gx GIT_ARGS $test_root/git-args
set -gx LS_ARGS $test_root/ls-args
set -gx ZELLIJ_ARGS $test_root/zellij-args
set -gx KUBECTL_ARGS $test_root/kubectl-args
set -gx SSH_ARGS $test_root/ssh-args
set -gx SSH_INPUT $test_root/ssh-input
set -gx BAT_ARGS $test_root/bat-args
set -gx DUF_ARGS $test_root/duf-args
set -gx DF_ARGS $test_root/df-args
set -gx SESH_ARGS $test_root/sesh-args
set -gx TMAT_ARGS $test_root/tmat-args
set -gx BTOP_ARGS $test_root/btop-args
set -gx TOP_ARGS $test_root/top-args
set -gx FISH_PATH (status fish-path)
mkdir -p $stub_dir $HOME

function fail
    echo $argv >&2
    rm -rf -- $test_root
    exit 1
end

printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "$HOSTNAME_OUTPUT"' >$stub_dir/hostname
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" >> "$SCP_ARGS"' >$stub_dir/scp
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$NIX_ARGS"' 'printf "%s\\n" "$PWD" > "$EANM_PWD"' 'exit "${NIX_STATUS:-0}"' >$stub_dir/nix
printf '%s\n' '#!/bin/sh' 'if [ "$#" -gt 0 ]; then printf "%s\0" "$@" > "$EDITOR_ARGS"; else : > "$EDITOR_ARGS"; fi' >$stub_dir/editor
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$CURL_ARGS"' >$stub_dir/curl
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "$OS_NAME"' >$stub_dir/uname
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" >> "$GIT_ARGS"' >$stub_dir/git
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$LS_ARGS"' >$stub_dir/ls
printf '%s\n' '#!/bin/sh' 'printf "  101 alpha 2.5 0.1 /bin/alpha\n  202\tbusy 12.5 1.2 /usr/bin/busy --serve\n"' >$stub_dir/ps
printf '%s\n' '#!/bin/sh' 'case "$1" in' '  ls) printf "%s\\n" "work-main Created" ;;' '  *) printf "%s\\0" "$@" > "$ZELLIJ_ARGS" ;;' 'esac' >$stub_dir/zellij
printf '%s\n' '#!/bin/sh' 'exit 1' >$stub_dir/which
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$BAT_ARGS"' >$stub_dir/bat
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$DUF_ARGS"' >$stub_dir/duf
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$DF_ARGS"' >$stub_dir/df
printf '%s\n' '#!/bin/sh' 'if test "$1" = list; then printf "%s\n" review-session; else printf "%s\\0" "$@" > "$SESH_ARGS"; fi' >$stub_dir/sesh
printf '%s\n' '#!/bin/sh' 'printf "%s\n" review-session' >$stub_dir/fzf
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$TMAT_ARGS"' >$stub_dir/tmat
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$BTOP_ARGS"' >$stub_dir/btop
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$TOP_ARGS"' >$stub_dir/top
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$KUBECTL_ARGS"' >$stub_dir/kubectl
printf '%s\n' '#!/bin/sh' 'printf "%s\n" terminfo-payload' >$stub_dir/infocmp
printf '%s\n' '#!/bin/sh' 'printf "%s\\0" "$@" > "$SSH_ARGS"' 'IFS= read -r line; printf "%s\n" "$line" > "$SSH_INPUT"' >$stub_dir/ssh
printf '%s\n' '#!/bin/sh' 'exec "$FISH_PATH" "$@"' >$stub_dir/fish
chmod +x $stub_dir/*
set -l nu_local_config $test_root/nu/vendor/autoload/config.nu
set -l local_config $test_root/local/fish/config.fish
set -gx LOCAL_CONFIG_FILE $nu_local_config
set -gx FISH_LOCAL_CONFIG_FILE $local_config

source $repo/configs/fish/config.fish
set -gx EDITOR $stub_dir/editor

set -gx HOSTNAME_OUTPUT current-host
pz-copy-mod-config parity-remote >/dev/null
set -l scp_args (string split0 < $SCP_ARGS)
test (count $scp_args) -eq 4
or fail 'pz-copy-mod-config did not make both scp calls'
test "$scp_args[1]" = 'parity-remote:~/Zomboid/Lua/saved_outfits.txt'
or fail 'pz-copy-mod-config expanded the remote home directory'
test "$scp_args[3]" = 'parity-remote:~/Zomboid/Lua/pz_modlist_settings.cfg'
or fail 'pz-copy-mod-config expanded the second remote home directory'
test "$scp_args[2]" = "$HOME/Zomboid/Lua/saved_outfits.txt"
or fail 'pz-copy-mod-config changed the local destination path'

set -l caller $test_root/caller
set -l eve_settings $HOME/gits/games/eve/eve-settings/evehost
mkdir -p $caller $eve_settings
set -gx HOSTNAME_OUTPUT evehost.local
set -gx NIX_STATUS 0
cd $caller
eve-eanm
set -l eanm_success_status $status
test $eanm_success_status -eq 0
or fail 'eve-eanm did not return the JAR success status'
test "$PWD" = "$caller"
or fail 'eve-eanm leaked its successful directory change'
test (string collect < $EANM_PWD) = $eve_settings
or fail 'eve-eanm did not invoke the JAR from the host settings directory'
set -gx NIX_STATUS 23
eve-eanm >/dev/null 2>/dev/null
set -l eanm_failure_status $status
test $eanm_failure_status -eq 23
or fail 'eve-eanm did not preserve the JAR failure status'
test "$PWD" = "$caller"
or fail 'eve-eanm leaked its failed directory change'

dots --local
test -f $local_config
or fail 'dots --local did not create the missing local config'
test ! -e $nu_local_config
or fail 'dots --local used the inherited Nushell local config target'
test "$PWD" = (path dirname $local_config)
or fail 'dots --local did not enter the local config directory'
set -l default_child_nu_local_config $test_root/default-child-nu/vendor/autoload/config.nu
set -l default_child_command 'source "$DOTFILES_DIR/configs/fish/config.fish"; test "$FISH_LOCAL_CONFIG_FILE" = "$HOME/.local/fish/config.fish"; and dots --local; and test -f "$FISH_LOCAL_CONFIG_FILE"; and test ! -e "$LOCAL_CONFIG_FILE"'
env -u FISH_LOCAL_CONFIG_FILE HOME="$HOME" DOTFILES_DIR="$DOTFILES_DIR" PATH="$PATH" LOCAL_CONFIG_FILE="$default_child_nu_local_config" $FISH_PATH --no-config -c "$default_child_command"
or fail 'Fish did not default its local config independently of Nushell'

set -l child_nu_local_config $test_root/child-nu/vendor/autoload/config.nu
set -l child_fish_local_config $test_root/child-fish/config.fish
set -l child_command 'source "$DOTFILES_DIR/configs/fish/config.fish"; test "$FISH_LOCAL_CONFIG_FILE" = "$EXPECTED_FISH_LOCAL_CONFIG"; and dots --local; and test -f "$EXPECTED_FISH_LOCAL_CONFIG"; and test ! -e "$LOCAL_CONFIG_FILE"'
env HOME="$HOME" DOTFILES_DIR="$DOTFILES_DIR" PATH="$PATH" LOCAL_CONFIG_FILE="$child_nu_local_config" FISH_LOCAL_CONFIG_FILE="$child_fish_local_config" EXPECTED_FISH_LOCAL_CONFIG="$child_fish_local_config" $FISH_PATH --no-config -c "$child_command"
or fail 'Fish inherited the Nushell local config target'
cd $caller
dots -l
test "$PWD" = (path dirname $local_config)
or fail 'dots -l did not enter the local config directory'
dots --edit --local
test (string split0 < $EDITOR_ARGS) = config.fish
or fail 'dots --edit --local did not edit the local config file'
cd $caller
rm -f $EDITOR_ARGS
dots -e
test "$PWD" = "$DOTFILES_DIR"
or fail 'dots -e did not enter DOTFILES_DIR'
test ! -s $EDITOR_ARGS
or fail 'dots -e did not invoke the editor without a filename'
dots --configs >/dev/null 2>/dev/null
test $status -ne 0
or fail 'dots still accepts the unrelated --configs option'

set -gx OS_NAME Linux
is-os linux
or fail 'is-os linux did not match Linux'
is-os macos
and fail 'is-os macos matched Linux'
set -gx OS_NAME Darwin
is-os darwin
or fail 'is-os darwin did not match Darwin'
is-macos
or fail 'is-macos did not delegate to is-os'
is-darwin
or fail 'is-darwin did not delegate to is-os'
is-linux
and fail 'is-linux matched Darwin'

set -lx USER fish-parity-user
set -l darwin_eve_settings "$HOME/Library/Application Support/CCP/EVE/_users_{$USER}_library_application_support_eve_online_sharedcache_tq_eve.app_contents_resources_build_tranquility"
mkdir -p "$darwin_eve_settings"
cd $caller
eve-settings
test "$PWD" = "$darwin_eve_settings"
or fail 'eve-settings did not use the Darwin user settings path'

set -gx PASTE_MULTILINE_OUTPUT $test_root/paste-multiline-output
function cmd-paste
    printf '%s\0' "string join '' fish - syntax >$PASTE_MULTILINE_OUTPUT"
end
paste-multiline
test (string collect < $test_root/paste-multiline-output) = fish-syntax
or fail 'paste-multiline did not execute Fish syntax'

function edit-multiline
    printf '%s' "$CURL_MULTILINE"
end
set -gx CURL_MULTILINE (printf '%s\n%s' "curl -H 'X: y' --data '{\"a\":\"b\"}' \\" '  https://example.invalid/api' | string collect)
curl-multiline
set -l curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 5
or fail 'curl-multiline did not parse a five-argument curl invocation'
test "$curl_args[1]" = -H -a "$curl_args[2]" = 'X: y' -a "$curl_args[3]" = --data -a "$curl_args[4]" = '{"a":"b"}' -a "$curl_args[5]" = https://example.invalid/api
or fail 'curl-multiline did not preserve quoted arguments after line continuation removal'
set -gx API_URL https://expanded.invalid
set -gx CURL_MULTILINE 'curl $env.API_URL'
curl-multiline
set curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 1 -a "$curl_args[1]" = '$env.API_URL'
or fail 'curl-multiline unexpectedly evaluated a Nu expression'

set -gx CURL_MULTILINE 'curl --data "C:\Users\fish\payload" https://example.invalid/windows'
curl-multiline
set curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 3 -a "$curl_args[1]" = --data -a "$curl_args[2]" = 'C:\Users\fish\payload' -a "$curl_args[3]" = https://example.invalid/windows
or fail 'curl-multiline stripped a literal Windows backslash inside double quotes'
set -gx CURL_MULTILINE 'curl --data "a\"b" https://example.invalid/escaped-quote'
curl-multiline
set curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 3 -a "$curl_args[1]" = --data -a "$curl_args[2]" = 'a"b' -a "$curl_args[3]" = https://example.invalid/escaped-quote
or fail 'curl-multiline did not unescape a valid double-quoted escape'
set -gx CURL_MULTILINE 'curl --data "a\`b" https://example.invalid/escaped-backtick'
curl-multiline
set curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 3 -a "$curl_args[1]" = --data -a "$curl_args[2]" = 'a`b' -a "$curl_args[3]" = https://example.invalid/escaped-backtick
or fail 'curl-multiline did not unescape a valid double-quoted backtick escape'
set -l quoted_newline_body (printf '%s\n%s' first second | string collect --no-trim-newlines)
set -gx CURL_MULTILINE (printf '%s\n%s\n%s' 'curl --data "first' 'second" https://example.invalid/newline' '' | string collect --no-trim-newlines)
curl-multiline
set curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 3 -a "$curl_args[1]" = --data -a "$curl_args[2]" = "$quoted_newline_body" -a "$curl_args[3]" = https://example.invalid/newline
or fail 'curl-multiline stripped a literal newline inside a double-quoted body'
set -gx CURL_MULTILINE (printf '%s\n%s' 'curl --request GET' 'https://example.invalid/separate' | string collect --no-trim-newlines)
curl-multiline
set curl_args (string split0 < $CURL_ARGS)
test (count $curl_args) -eq 3 -a "$curl_args[1]" = --request -a "$curl_args[2]" = GET -a "$curl_args[3]" = https://example.invalid/separate
or fail 'curl-multiline did not split unquoted newline-separated arguments'

rm -f $GIT_ARGS
git.tree >/dev/null
git.head >/dev/null
set -l git_args (string split0 < $GIT_ARGS)
contains -- --graph $git_args
or fail 'git.tree did not execute git log --graph'
contains -- --oneline $git_args
and contains -- -1 $git_args
or fail 'git.head did not request one abbreviated one-line commit'
ll >/dev/null
set -l ll_args (string split0 < $LS_ARGS)
test (count $ll_args) -eq 1 -a "$ll_args[1]" = -al
or fail 'll did not include hidden files with ls -al'

set -l busy_record (printf '  202\tbusy 12.5 1.2 /usr/bin/busy --serve')
psw cpu '>' 10 >$test_root/psw-output
set -l psw_output (string collect < $test_root/psw-output)
test "$psw_output" = "$busy_record"
or fail 'psw did not parse padded records before filtering the cpu field'
psw mem '>=' 1 >$test_root/psw-output
test (string collect < $test_root/psw-output) = "$busy_record"
or fail 'psw did not filter the memory field in padded records'
psw command '=~' '^/usr/bin/busy --serve$' >$test_root/psw-output
test (string collect < $test_root/psw-output) = "$busy_record"
or fail 'psw did not filter the command field in padded records'

rm -f $CURL_ARGS
getmyip
test -f $CURL_ARGS
or fail 'getmyip did not use Nu-compatible curl'
set -l getmyip_args (string split0 < $CURL_ARGS)
test (string join '|' -- $getmyip_args) = '-L|ifconfig.me'
or fail 'getmyip did not request ifconfig.me through curl -L'

rm -f $BAT_ARGS
cat $EANM_PWD >/dev/null
test -f $BAT_ARGS
or fail 'cat did not use Nu-compatible bat'
set -l cat_args (string split0 < $BAT_ARGS)
test (count $cat_args) -eq 1 -a "$cat_args[1]" = $EANM_PWD
or fail 'cat did not forward file arguments to bat'

rm -f $DUF_ARGS $DF_ARGS
dfh --wide
test -f $DUF_ARGS
or fail 'dfh did not use Nu-compatible duf'
set -l dfh_args (string split0 < $DUF_ARGS)
test (string join '|' -- $dfh_args) = '--wide'
or fail 'dfh did not forward arguments to duf'
test ! -f $DF_ARGS
or fail 'dfh fell back to df'

rm -f $SESH_ARGS $TMAT_ARGS
tmat
test -f $SESH_ARGS
or fail 'tmat did not invoke sesh'
set -l sesh_args (string split0 < $SESH_ARGS)
test (string join '|' -- $sesh_args) = 'connect|review-session'
or fail 'tmat did not connect the fzf-selected sesh session'
test ! -f $TMAT_ARGS
or fail 'tmat fell back to tmux attachment'

rm -f $BTOP_ARGS $TOP_ARGS
top --demo
test -f $BTOP_ARGS
or fail 'top did not use Nu-compatible btop'
set -l top_args (string split0 < $BTOP_ARGS)
test (string join '|' -- $top_args) = '--demo'
or fail 'top did not forward arguments to btop'
test ! -f $TOP_ARGS
or fail 'top fell back to the system command'

shlink-create --slug parity --url https://example.invalid/parity
set -l kubectl_args (string split0 < $KUBECTL_ARGS)
test (string join '|' -- $kubectl_args) = '--namespace|shlink|exec|-it|deployments/shlink|--|bin/cli|short-url:create|--custom-slug|parity|https://example.invalid/parity'
or fail 'shlink-create did not pass slug and URL to the Shlink CLI'

ghostty-fix-terminfo parity-host
set -l ssh_args (string split0 < $SSH_ARGS)
test (string join '|' -- $ssh_args) = 'parity-host|--|tic|-x|-'
or fail 'ghostty-fix-terminfo did not target tic on the supplied host'
test (string collect < $SSH_INPUT) = terminfo-payload
or fail 'ghostty-fix-terminfo did not pipe terminfo to ssh'

function op-ssh-public-key
    printf '%s\n' 'ssh-ed25519 parity-key'
end
1password-copy-ssh-pub-key parity-host
set ssh_args (string split0 < $SSH_ARGS)
test (string join '|' -- $ssh_args) = 'parity-host|mkdir ~/.ssh 2>/dev/null; cat >>~/.ssh/authorized_keys'
or fail '1password-copy-ssh-pub-key did not target the supplied host'
test (string collect < $SSH_INPUT) = 'ssh-ed25519 parity-key'
or fail '1password-copy-ssh-pub-key did not pipe the public key to ssh'

proxmox-install-helix parity-host
set ssh_args (string split0 < $SSH_ARGS)
test (string join '|' -- $ssh_args) = 'parity-host|curl -L https://shlink.ryk.sh/helix-deb | sh'
or fail 'proxmox-install-helix did not target the supplied host'

pagi '^busy$' >$test_root/pagi-output
test (string collect < $test_root/pagi-output) = "$busy_record"
or fail 'pagi did not apply its regex to the process-name field'
pagi serve >$test_root/pagi-output
test ! -s $test_root/pagi-output
or fail 'pagi matched command arguments instead of process names'

zellij-exists work
or fail 'zellij-exists did not retain Nu regex/substring semantics'
zellij-create-or-attach work
set -l zellij_args (string split0 < $ZELLIJ_ARGS)
test (count $zellij_args) -eq 2 -a "$zellij_args[1]" = attach -a "$zellij_args[2]" = work
or fail 'zellij-create-or-attach did not attach a substring-matched session'

set -gx NIX_STATUS 0
nd task-6-shell
set -l nd_args (string split0 < $NIX_ARGS)
test (count $nd_args) -eq 2 -a "$nd_args[1]" = develop -a "$nd_args[2]" = "$DOTFILES_DIR#task-6-shell"
or fail 'nd did not develop the requested DOTFILES_DIR shell target'
set -l nr_dir $test_root/nr-flake
mkdir -p $nr_dir
cd $nr_dir
nr.
set -l nr_args (string split0 < $NIX_ARGS)
test (count $nr_args) -eq 3 -a "$nr_args[1]" = repl -a "$nr_args[2]" = --expr -a "$nr_args[3]" = "builtins.getFlake \"$nr_dir\""
or fail 'nr. did not pass the current directory to nix as a flake expression'

rm -rf -- $test_root
