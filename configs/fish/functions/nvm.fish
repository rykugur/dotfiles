function nvm --description "nvm wrapped with bass"
    bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end
