#TODO: move to ./commands

def "zellij exists" [session: string] {
  zellij ls | lines | parse "{name} {description}" | where name =~ $session | is-not-empty
}

def "zellij create-or-attach" [session: string, --layout: string = nil] {
  let exists = (zellij exists $session)
  if $exists {
    zellij attach $session
  } else {
    if ($layout | path exists) {
      zellij --layout $layout
    } else {
      zellij -s $session
    }
  }
}

def "zellij fzf" [] {
  zellij attach (zellij ls | lines | parse "{name} {description}" | get name | ansi strip | to text | fzf)
}

# leaving this here for now until I'm not lazy and want to add it to the
# nu-scripts zellij completions
def "zellij delete-all-sessions" [] {
  ^zellij delete-all-sessions
}

def "zellij murder-all-sessions" [] {
  ^zellij kill-all-sessions; zellij delete-all-sessions
}
