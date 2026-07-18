function zellij-fzf
    zellij attach (zellij ls | string replace -ra '\e\[[0-9;]*m' '' | string replace -r '\s.*$' '' | fzf)
end
