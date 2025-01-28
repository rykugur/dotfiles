def --env dots [--local (-l)] {
  if $local {
    cd ($env.LOCAL_CONFIG_FILE | path dirname)
  } else {
    cd $env.DOTFILES_DIR
  }
}

def --env ndots [--local (-l)] {
  if $local {
    let configFile = $env.LOCAL_CONFIG_FILE
    let dirName = $configFile | path dirname
    if (not ($configFile | path exists)) {
      mkdir $dirName
      touch $configFile
    }
    cd $dirName; nvim config.nu
  } else {
    cd $env.DOTFILES_DIR; nvim
  }
}

def is-os [os: string] {
  let os_lowercase = ($nu.os-info.name | str downcase)
  match $os {
    "linux" => ($os_lowercase == "linux"),
    "macos" => ($os_lowercase == "macos"),
    "darwin" => ($os_lowercase == "macos")
  }
}

def is-darwin [] {
  is-os "macos"
}

def is-macos [] {
  is-os "macos"
}

def is-linux [] {
  is-os "linux"
}

def "cmd.copy" [] {
  if (is-linux) {
    $in | wl-copy
  } else if (is-darwin) {
    $in | pbcopy
  }
}

def "cmd.paste" [] {
  if (is-linux) {
    wl-paste
  } else if (is-darwin) {
    pbpaste
  }
}
