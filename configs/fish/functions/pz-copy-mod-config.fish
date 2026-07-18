function pz-copy-mod-config --description "Copy Project Zomboid mod configuration from a host"
    set -l host jezrien
    if test (count $argv) -gt 0
        set host $argv[1]
    end

    set -l current_host (hostname)
    if string match --quiet -- "$host*" "$current_host"
        echo "Can't copy from current host, exiting."
        return 1
    end

    set -l lua_dir "$HOME/Zomboid/Lua"
    echo "Copying PZ files: saved_outfits.txt pz_modlist_settings.cfg"
    scp "$host:$lua_dir/saved_outfits.txt" "$lua_dir/saved_outfits.txt"
    scp "$host:$lua_dir/pz_modlist_settings.cfg" "$lua_dir/pz_modlist_settings.cfg"
    echo "Done"
end
