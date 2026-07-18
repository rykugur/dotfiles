function gas
    git status --porcelain=v1 -z | while read --null entry
        set -l porcelain_status (string sub --length 2 -- $entry)
        if string match --quiet --regex '[RC]' -- $porcelain_status
            set -l source_path
            read --null source_path
            or break
        end
        if test "$porcelain_status" = AM -o "$porcelain_status" = MM
            git add -- "$(string sub --start 4 -- $entry)"
        end
    end
end
