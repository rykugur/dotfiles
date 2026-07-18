function gcu
    git status --porcelain=v1 -z | while read --null entry
        if test (string sub --length 2 -- $entry) = '??'
            rm -rf -- (string sub --start 4 -- $entry)
        end
    end
end
