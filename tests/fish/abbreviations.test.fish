#!/usr/bin/env fish
set -l repo (path resolve (path dirname (path dirname (path dirname (status filename)))))
set -gx DOTFILES_DIR $repo
source $repo/configs/fish/config.fish

for abbreviation in dc ga k nb
    abbr --query $abbreviation
    or begin
        echo "missing abbreviation: $abbreviation" >&2
        exit 1
    end
end
