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
