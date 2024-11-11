{
  abbreviations = {
    adb-reverse =
      "adb reverse tcp:8081 tcp:8081; adb reverse tcp:8080 tcp:8080";
    ssh-forcePass =
      "ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no";
    sv = "sudo nvim";
  };
  aliases = {
    dots = "cd ~/.dotfiles";
    ll = "ls -al";
    # cwd = ''pwd | tr -d "\n" | wl-copy'';
    # pwdc = "pwd | trim.newlines | wl-copy";
    duh = "du -h";
    murder = "kill -9";
    # ndots = "cd ~/.dotfiles/; nvim .";
    getmyip = "dig +short myip.opendns.com @resolver1.opendns.com";
    pingtest = "ping -D -O google.com";
    ytdl = "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3";
    nv = "nvim";
    "nv." = "nvim .";
    v = "nvim";
    vi = "nvim";
    whatthecommit = "curl -s https://whatthecommit.com/index.txt";
  };
  env = {

  };
}
