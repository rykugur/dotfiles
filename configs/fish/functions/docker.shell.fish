function docker.shell --description "Starts a shell within a docker container; pass container name as a standard un-named arg"
  docker exec -i -t $argv /bin/bash
end
