function eve-settings --description "Change to the EVE settings directory"
    if test (uname) = Linux
        cd "$HOME/.local/share/Steam/steamapps/compatdata/8500/pfx/drive_c/users/steamuser/AppData/Local/CCP/EVE/c_ccp_eve_tq_tranquility"
    else
        cd "$HOME/Library/Application Support/CCP/EVE/_users_$USER_library_application_support_eve_online_sharedcache_tq_eve.app_contents_resources_build_tranquility"
    end
end
