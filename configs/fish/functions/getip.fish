#

function getip --description "gets the primary ip for the specified ip; Usage: getip [interface]"
  set argc (count $argv)
  set usage "Usage: getip [interface]"

  if test $argc -eq 1
    set -l _interface $argv[1]

    set _ip_addr (ifconfig $_interface inet ^/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1)

    echo $_ip_addr
  else if test $argc -eq 0
    # assume en0
    set _ip_addr (ifconfig en0 inet ^/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1)

    echo $_ip_addr
  else
    echo $usage
    return 1
  end
end
