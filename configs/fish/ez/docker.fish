### docker
set -l DOCKER_COMPOSE_COMMAND "docker compose"
abbr --add --global dc $DOCKER_COMPOSE_COMMAND
abbr --add --global dcb $DOCKER_COMPOSE_COMMAND build
abbr --add --global dcl $DOCKER_COMPOSE_COMMAND logs
abbr --add --global dclf $DOCKER_COMPOSE_COMMAND logs -f
abbr --add --global dcr $DOCKER_COMPOSE_COMMAND restart
abbr --add --global dcu $DOCKER_COMPOSE_COMMAND up
abbr --add --global dcud $DOCKER_COMPOSE_COMMAND up -d
abbr --add --global dcd $DOCKER_COMPOSE_COMMAND down
abbr --add --global drit 'docker run -it'
abbr --add --global docker.clean 'docker rmi (docker images -f dangling=true -q)'
abbr --add --global lzd lazydocker
