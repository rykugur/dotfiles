

# git aliases
alias gbn = git branch | cut -d' ' -f2
alias glg = git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative
alias gll = git log --pretty=format:'%Cgreen[%H]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative
alias git.back = git reset HEAD~1
alias git.branch = git symbolic-ref --short HEAD
alias git.clean = git branch --merged (git.branch) | grep -v (git.branch) | xargs git branch -d
alias git.lastcommit = git log | head -n1 | awk '{print \$2}'
alias git.head = gll | head -n1
alias git.track = git branch -vv
alias git.tree = git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative
alias jedi = git push --force

# misc linux aliases
alias tmat = sesh connect (sesh list -t | fzf)

$env.config = {
    keybindings: [
      {
        name: abbr_menu
        modifier: none
        keycode: enter
        mode: [emacs, vi_normal, vi_insert]
        event: [
            { send: menu name: abbr_menu }
            { send: enter }
        ]
      }
      {
        name: abbr_menu
        modifier: none
        keycode: space
        mode: [emacs, vi_normal, vi_insert]
        event: [
            { send: menu name: abbr_menu }
            { edit: insertchar value: ' '}
        ]
      }
    ]

    menus: [
        {
            name: abbr_menu
            only_buffer_difference: false
            marker: none
            type: {
                layout: columnar
                columns: 1
                col_width: 20
                col_padding: 2
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
            source: { |buffer, position|
                let match = $abbreviations | columns | where $it == $buffer
                if ($match | is-empty) {
                    { value: $buffer }
                } else {
                    { value: ($abbreviations | get $match.0) }
                }
            }
        }
    ]
}
