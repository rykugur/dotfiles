#

function owncloud --description "Simple wrapper to start/stop owncloud docker."
  set -l argc (count $argv)
  set -l _usage "Usage: owncloud [start|stop]"

  if test $argc -lt 1
    echo $_usage
    return 1
  end

  if test $argv[1] = "start"
    docker run -d -p 32114:80 -v /var/lib/owncloud:/var/www/html owncloud:latest
  else if test $argv[1] = "stop"
    docker stop (docker ps | grep owncloud | awk '{print $1}')
  else
    echo $_usage
  end
end
