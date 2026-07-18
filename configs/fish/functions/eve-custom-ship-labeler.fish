function eve-custom-ship-labeler --description "Run EVE CustomShipLabeler"
    nix run nixpkgs#zulu24 -- -jar "$HOME/gits/games/eve/eve-settings/EVE_CustomShipLabelerV1.jar"
end
