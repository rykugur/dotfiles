function bak --description 'creates a backup (.bak) file of the file(s) specified by the args'
  for file in $argv
    cp -rf $file "$file.bak"
  end
end
