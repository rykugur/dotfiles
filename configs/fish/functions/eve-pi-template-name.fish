function eve-pi-template-name --description "Print an EVE PI template name"
    jq -r '.Cmt | gsub(" "; "")'
end
