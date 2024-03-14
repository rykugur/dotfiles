abbr --add --global nb nix build
abbr --add --global n-b nix-build
abbr --add --global n-s nix-shell --command fish

abbr --add --global nd nix develop $DOTFILES_DIR --command fish

abbr --add --global snr 'sudo nixos-rebuild'
abbr --add --global snrs 'sudo nixos-rebuild switch'
abbr --add --global snrsf 'sudo nixos-rebuild switch --flake $DOTFILES_DIR'

abbr --add --global hms 'home-manager switch'
abbr --add --global hmsf 'home-manager switch --flake $DOTFILES_DIR'

alias chrome "NIXPKGS_ALLOW_UNFREE=1 nix-shell -p google-chrome --run google-chrome-stable"
alias plexff "firefox --new-window http://tanavast:32400/web/index.html"
