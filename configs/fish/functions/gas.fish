function gas
    git status --porcelain=v1 -z | while read --null entry
        set -l porcelain_status (string sub --length 2 -- $entry)
        if test "$porcelain_status" = AM -o "$porcelain_status" = MM
            git add -- (string sub --start 4 -- $entry)
        end
    end
end
