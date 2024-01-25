function death --description murder
    kill -9 (ps aux | grep -v grep | grep -i $argv | awk2)
end
