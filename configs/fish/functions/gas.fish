function gas
    git status --porcelain=v1 -z | while read --local --nchars 3 header
        set -l porcelain_status (string sub --length 2 -- $header)
        set -l pathname
        read --local --null pathname
        or break
        if string match --quiet --regex '[RC]' -- $porcelain_status
            set -l source_path
            read --null source_path
            or break
        end
        if test "$porcelain_status" = AM -o "$porcelain_status" = MM
            git add -- "$pathname"
        end
    end
end
