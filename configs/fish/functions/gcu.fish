function gcu
    git ls-files --others --exclude-standard -z | while read --null untracked_path
        rm -rf -- $untracked_path
    end
end
