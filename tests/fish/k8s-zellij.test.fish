set -l root (cd (dirname (status filename))/../..; and pwd)
set -l tempdir (mktemp -d)
set -l bin "$tempdir/bin"
set -gx STUB_LOG "$tempdir/log"
mkdir -p "$bin" "$STUB_LOG"
set -gx PATH "$bin" $PATH

function cleanup --on-event fish_exit
    rm -rf "$tempdir"
end

printf '%s\n' \
    '#!/usr/bin/env fish' \
    'printf sops > "$STUB_LOG/sops"' \
    'printf "decrypted:%s" "$argv[2]"' \
    > "$bin/sops"
printf '%s\n' \
    '#!/usr/bin/env fish' \
    'printf kubectl > "$STUB_LOG/kubectl"' \
    'printf "%s\\n" $argv > "$STUB_LOG/args"' \
    'read --null content' \
    'printf "%s" "$content" > "$STUB_LOG/stdin"' \
    > "$bin/kubectl"
printf '%s\n' \
    '#!/usr/bin/env fish' \
    'read --null token' \
    'printf "encoded:%s" "$token"' \
    > "$bin/base64"
chmod +x "$bin/sops" "$bin/kubectl" "$bin/base64"

source "$root/configs/fish/functions/k8s-base64.fish"
source "$root/configs/fish/functions/sops-kaf.fish"

printf token | k8s-base64 | string match -q 'encoded:token'; or exit 1

if sops-kaf missing.yaml
    exit 1
end
test ! -e "$STUB_LOG/sops"; or exit 1
test ! -e "$STUB_LOG/kubectl"; or exit 1

set -l manifest "$tempdir/manifest.yaml"
printf 'kind: ConfigMap\n' > "$manifest"
sops-kaf "$manifest"; or exit 1

set -l args (string split \n < "$STUB_LOG/args")
test "$args[1]" = apply; or exit 1
test "$args[2]" = -f; or exit 1
test "$args[3]" = -; or exit 1
test (string collect < "$STUB_LOG/stdin") = "decrypted:$manifest"; or exit 1

set -gx HOME "$tempdir/home"
mkdir -p "$HOME"
set -gx DOTFILES_DIR "$root"
source "$root/configs/fish/config.fish"
complete -c zellij-create-or-attach | string match -q -- '*zellij-create-or-attach -l layout*'; or exit 1
complete -c sops-kaf | string match -q -- '*sops-kaf*'; or exit 1
complete -c k8s-base64 | string match -q -- '*--no-files*k8s-base64*'; or exit 1
