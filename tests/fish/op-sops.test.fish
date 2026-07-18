#!/usr/bin/env fish

set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -l test_root (mktemp -d)
set -l stub_dir $test_root/bin
set -gx HOME $test_root/home
set -gx DOTFILES_DIR $repo
set -gx PATH $stub_dir $PATH
mkdir -p $stub_dir $HOME

function fail
    echo $argv >&2
    rm -rf -- $test_root
    exit 1
end

printf '%s\n' '#!/bin/sh' \
    'if [ "$1" = item ] && [ "$2" = list ]; then' \
    '  printf "%s\n" '\''[{"id":"item-1","title":"Test SSH Key","vault":{"name":"Test Vault"}}]'\''' \
    'elif [ "$1" = item ] && [ "$2" = get ]; then' \
    '  case "$*" in' \
    '    *private*) printf "PRIVATE\n" ;;' \
    '    *) printf "PUBLIC\n" ;;' \
    '  esac' \
    'fi' >$stub_dir/op
chmod +x $stub_dir/op

printf '%s\n' '#!/bin/sh' \
    'if [ "$FZF_CANCEL" = 1 ]; then' \
    '  exit 0' \
    'fi' \
    'cat' >$stub_dir/fzf
chmod +x $stub_dir/fzf

printf '%s\n' '#!/bin/sh' \
    'if [ "$NIX_FAIL" = 1 ]; then' \
    '  exit 1' \
    'fi' \
    'if [ "$NIX_MAKE_DEST_DIR" = 1 ]; then' \
    '  rm -f "$KEY_FILE_TO_RACE"' \
    '  mkdir "$KEY_FILE_TO_RACE"' \
    'fi' \
    'printf "converted:"' \
    'cat' >$stub_dir/nix
chmod +x $stub_dir/nix

source $repo/configs/fish/config.fish

op-ssh-public-key item-1 | string match -q PUBLIC
or fail 'op-ssh-public-key did not retrieve the public key'
sops-age-public-key item-1 | string match -q converted:PUBLIC
or fail 'sops-age-public-key did not convert the public key'
sops-age-private-key item-1 | string match -q converted:PRIVATE
or fail 'sops-age-private-key did not convert the private key'

set -l key_dir $HOME/.config/sops/age
set -l key_file $key_dir/keys.txt
not string match -q '*PRIVATE*' -- (sops-setup-new-host --yes item-1 2>&1)
or fail 'sops-setup-new-host leaked private material'
test -f $key_file
or fail 'sops-setup-new-host did not write keys.txt'
string match -q converted:PRIVATE < $key_file
or fail 'sops-setup-new-host wrote an unexpected key'
test (stat -c '%a' $key_dir) = 700
or fail 'sops-setup-new-host did not set the age directory to mode 700'
test (stat -c '%a' $key_file) = 600
or fail 'sops-setup-new-host did not set keys.txt to mode 600'

rm -rf -- $HOME/.config
printf 'n\n' | sops-setup-new-host item-1 >/dev/null 2>&1
test ! -e $key_file
or fail 'sops-setup-new-host wrote a key after a negative response'

set -lx FZF_CANCEL 1
set -l cancellation_output (sops-setup-new-host --yes 2>&1)
set -l cancellation_status $status
set -e FZF_CANCEL
test $cancellation_status -ne 0
or fail 'sops-setup-new-host accepted a cancelled key selection'
not string match -q '*PRIVATE*' -- $cancellation_output
or fail 'sops-setup-new-host leaked private material after a cancelled selection'
test ! -e $key_file
or fail 'sops-setup-new-host wrote a key after a cancelled selection'

mkdir -p -m 700 $key_dir
printf 'existing-key\n' >$key_file
chmod 600 $key_file
set -lx NIX_FAIL 1
set -l failure_output (sops-setup-new-host --yes item-1 2>&1)
set -l failure_status $status
set -e NIX_FAIL
test $failure_status -ne 0
or fail 'sops-setup-new-host succeeded after a failed conversion'
not string match -q '*PRIVATE*' -- $failure_output
or fail 'sops-setup-new-host leaked private material after a failed conversion'
string match -q existing-key < $key_file
or fail 'sops-setup-new-host replaced a key after a failed conversion'
test (stat -c '%a' $key_file) = 600
or fail 'sops-setup-new-host changed the existing key mode after a failed conversion'
test -z (command find $key_dir -maxdepth 1 -name '.keys.txt.*' -print)
or fail 'sops-setup-new-host left a temporary key file after a failed conversion'

rm $key_file
set -l symlink_target $test_root/symlink-target
printf 'original-target\n' >$symlink_target
chmod 600 $symlink_target
ln -s $symlink_target $key_file
set -l symlink_output (sops-setup-new-host --yes item-1 2>&1)
set -l symlink_status $status
test $symlink_status -ne 0
or fail 'sops-setup-new-host accepted a symlink destination'
not string match -q '*PRIVATE*' -- $symlink_output
or fail 'sops-setup-new-host leaked private material for a symlink destination'
test -L $key_file
or fail 'sops-setup-new-host replaced a rejected symlink destination'
string match -q original-target < $symlink_target
or fail 'sops-setup-new-host wrote through a symlink destination'

rm $key_file
mkfifo $key_file
set -l fifo_output (sops-setup-new-host --yes item-1 2>&1)
set -l fifo_status $status
test $fifo_status -ne 0
or fail 'sops-setup-new-host accepted a FIFO destination'
not string match -q '*PRIVATE*' -- $fifo_output
or fail 'sops-setup-new-host leaked private material for a FIFO destination'
test -p $key_file
or fail 'sops-setup-new-host replaced a rejected FIFO destination'

rm $key_file
set -lx NIX_MAKE_DEST_DIR 1
set -lx KEY_FILE_TO_RACE $key_file
set -l rename_output (sops-setup-new-host --yes item-1 2>&1)
set -l rename_status $status
set -e NIX_MAKE_DEST_DIR
set -e KEY_FILE_TO_RACE
test $rename_status -ne 0
or fail 'sops-setup-new-host accepted a destination changed to a directory'
not string match -q '*PRIVATE*' -- $rename_output
or fail 'sops-setup-new-host leaked private material after a rename failure'
test -d $key_file
or fail 'sops-setup-new-host did not preserve the replacement destination'
test -z (command find $key_dir -maxdepth 1 -name '.keys.txt.*' -print)
or fail 'sops-setup-new-host left a temporary key file after a rename failure'

rm -rf -- $test_root
