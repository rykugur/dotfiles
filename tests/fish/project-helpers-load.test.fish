#!/usr/bin/env fish

set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -gx DOTFILES_DIR $repo
source $repo/configs/fish/config.fish

for name in eve-pfx eve-settings eve-pi-templates eve-gits eve-eanm eve-custom-ship-labeler eve-pi-template-name pz-copy-mod-config pz-mods stalker2-pfx stalker2-cd stalker2-mods starcitizen-wine-path starcitizen-controller-settings
    functions --query $name
    or begin
        echo "missing function: $name" >&2
        exit 1
    end
end
