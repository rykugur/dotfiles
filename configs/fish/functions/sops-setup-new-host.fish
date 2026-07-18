function sops-setup-new-host
    argparse -n sops-setup-new-host y/yes -- $argv
    or return

    set -l item_id (__op-select-ssh-key $argv)
    or return
    set -l key_dir "$HOME/.config/sops/age"
    set -l key_file "$key_dir/keys.txt"

    if not set -q _flag_yes
        read --local --prompt-str "Write private age key to $key_file? (y/N): " response
        or return
        string match -qr '^[Yy]$' -- "$response"
        or return
    end

    if test -L "$key_dir"
        printf 'Refusing symlinked SOPS age directory: %s\n' "$key_dir" >&2
        return 1
    end
    if test -e "$key_dir"
        if not test -d "$key_dir"
            printf 'Refusing non-directory SOPS age destination: %s\n' "$key_dir" >&2
            return 1
        end
    else
        mkdir -p -m 700 "$key_dir"
        or return
    end
    chmod 700 "$key_dir"
    or return

    if test -L "$key_file"
        printf 'Refusing symlinked SOPS age key destination: %s\n' "$key_file" >&2
        return 1
    end
    if test -e "$key_file"
        if not test -f "$key_file"
            printf 'Refusing non-regular SOPS age key destination: %s\n' "$key_file" >&2
            return 1
        end
    end

    set -l old_umask (umask)
    umask 077
    set -l temporary_key_file (mktemp "$key_dir/.keys.txt.XXXXXX")
    set -l temporary_status $status
    umask $old_umask

    if test $temporary_status -ne 0; or test -z "$temporary_key_file"; or not test -f "$temporary_key_file"
        command rm -f -- "$temporary_key_file"
        return 1
    end
    if not chmod 600 "$temporary_key_file"
        command rm -f -- "$temporary_key_file"
        return 1
    end

    op item get "$item_id" --fields 'label=private key' --reveal \
        | nix run nixpkgs#ssh-to-age -- -private-key >"$temporary_key_file"
    set -l pipeline_status $pipestatus
    if test $pipeline_status[1] -ne 0; or test $pipeline_status[2] -ne 0
        command rm -f -- "$temporary_key_file"
        return 1
    end

    if test -L "$key_file"
        command rm -f -- "$temporary_key_file"
        return 1
    end
    if test -e "$key_file"
        if not test -f "$key_file"
            command rm -f -- "$temporary_key_file"
            return 1
        end
    end
    if not command mv -fT -- "$temporary_key_file" "$key_file"
        command rm -f -- "$temporary_key_file"
        return 1
    end
end
