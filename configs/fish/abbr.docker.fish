abbr --add --global dc docker-compose
abbr --add --global dcr docker-compose restart
abbr --add --global dcru docker-compose up
abbr --add --global dcrud docker-compose up -d
abbr --add --global dcrd docker-compose down

abbr --add --global drit 'docker run -it'
abbr --add --global docker.clean 'docker rmi (docker images -f dangling=true -q)'

abbr --add --global lzd lazydocker
