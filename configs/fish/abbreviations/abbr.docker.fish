abbr --add --global dc docker-compose
abbr --add --global dcb docker-compose build
abbr --add --global dcr docker-compose restart
abbr --add --global dcu docker-compose up
abbr --add --global dcud docker-compose up -d
abbr --add --global dcd docker-compose down

abbr --add --global drit 'docker run -it'
abbr --add --global docker.clean 'docker rmi (docker images -f dangling=true -q)'

abbr --add --global lzd lazydocker
