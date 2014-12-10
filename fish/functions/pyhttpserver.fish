#

function pyhttpserver --description 'starts a python SimpleHttpServer that serves up the contents of the current directory. If you pass an argument, it is assumed that argument is the name of a directory.'
  if test (count $argc) -eq 1
    cd $argv
  end

  python2 -m SimpleHTTPServer 8080
end
