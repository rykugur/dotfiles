function eve-pi-templates --description "Change to EVE PI templates"
    if test (uname) = Linux
        cd "$HOME/.local/share/Steam/steamapps/compatdata/8500/pfx/drive_c/users/steamuser/Documents/EVE/PlanetaryInteractionTemplates"
    else
        cd "$HOME/Documents/EVE/PlanetaryInteractionTemplates"
    end
end
