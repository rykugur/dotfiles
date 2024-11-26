$env.config = ($env.config | upsert hooks {
  env_change: {
    PWD: [
      {
        condition: {|before, after| ls -a | where name == ".nvmrc" | is-not-empty }
        code: {|before, after| fnm use }
      }
    ]
  }
})
