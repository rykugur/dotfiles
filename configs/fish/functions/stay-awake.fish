function stay-awake
    systemd-inhibit --what=idle:sleep --who=me --why=watching sleep infinity
end
