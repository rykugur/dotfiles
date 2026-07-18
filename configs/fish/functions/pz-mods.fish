function pz-mods --description "Change to Project Zomboid Steam Workshop mods"
    if test (uname) = Linux
        cd "$HOME/.local/share/Steam/steamapps/workshop/content/108600"
    else
        cd "$HOME/Library/Application Support/Steam/steamapps/workshop/content/108600"
    end
end
