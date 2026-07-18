function talosmerge
    set -l talosconfigs
    for config in "$HOME"/.talos/*.yaml
        test -f "$config"; and set --append talosconfigs "$config"
    end

    test (count $talosconfigs) -gt 0; or return 1
    set -lx TALOSCONFIG (string join : $talosconfigs)
    talosctl config view > "$HOME"/.talos/config
end
