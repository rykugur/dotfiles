function proxmox-install-helix --description "Install Helix on a Proxmox host"
    if test (count $argv) -ne 1
        echo "usage: proxmox-install-helix HOST" >&2
        return 2
    end

    command ssh "$argv[1]" 'curl -L https://shlink.ryk.sh/helix-deb | sh'
end
