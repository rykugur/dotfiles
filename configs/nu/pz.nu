def "pz copy mod config" [host: string = "jezrien"] {
  use std/log

  
  let hostname = (hostname)
  if ($hostname | str starts-with $host) {
    log info "Can't copy from current host, exiting."
    return
  }

  const luaDir = "~/Zomboid/Lua"

  const files = ["saved_outfits.txt" "pz_modlist_settings.cfg"]
  log info $"Copying PZ files: ($files)"
  $files | each {|file|
    let filePath = $"($luaDir)/($file)"
    let cmd = $"scp ($host):($filePath) ($filePath)"
    log debug $"cmd=($cmd)"
    do { nu -c $cmd }
  }

  log info "Done"
}
