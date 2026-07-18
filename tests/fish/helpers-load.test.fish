#!/usr/bin/env fish
set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -gx DOTFILES_DIR $repo
source $repo/configs/fish/config.fish

for name in gas gcu gbz gcoz rbld rbld-switch rbld-boot nix-get-hash nrd nrf nrun mkenvrc mkflake mkflake-electrobun stay-awake cmd-copy cmd-paste replace-multiline paste-multiline edit-multiline
    functions --query $name
    or begin
        echo "missing function: $name" >&2
        exit 1
    end
end
