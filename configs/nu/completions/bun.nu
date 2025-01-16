def "nu-complete bun run" [] {
  let userScripts = try {
    open ./package.json 
    | get scripts 
    | transpose 
    | rename value description
  } catch {[]}

  let commands = [
    {value: 'add', description: 'Add dependencies to the project'} ]

  $userScripts | append $commands
}

export extern "bun run" [
  command?: string@"nu-complete bun run"
]

def "nu-complete bun add" [] {
  {value: 'test', description: 'test'}
}

# Add dependencies to the project
export extern "bun add" [
  --dev(-D) # Add a package as a dev dependency
  command?: string@"nu-complete bun add"
]
