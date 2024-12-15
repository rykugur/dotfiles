def "nu-complete yarn" [] {
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

export extern "yarn" [
  command?: string@"nu-complete yarn"
]

def "nu-complete yarn add" [] {
  {value: 'test', description: 'test'}
}

# Add dependencies to the project
export extern "yarn add" [
  --dev(-D) # Add a package as a dev dependency
  command?: string@"nu-complete yarn add"
]
