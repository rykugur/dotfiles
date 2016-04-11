# restarts the network service; tries to use the default env variable if set,
# otherwise attempts to use a sane'ish default.

function restart_networking --description "Restarts the 'default' network service. The default is dhcpcd@eth0.service."
  set -l network_stack "dhcpcd"
  if test -n $DEFAULT_NETWORK_STACK
    set network_stack $DEFAULT_NETWORK_STACK
  end

  set -l network_interface "eth0"
  if test -n $DEFAULT_NETWORK_INTERFACE
    set network_interface $DEFAULT_NETWORK_INTERFACE
  end

  sudo systemctl restart $network_stack@$network_interface.service
end
