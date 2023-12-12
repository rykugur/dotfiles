#!/usr/bin/env fish

function try_kill --description "tries to kill the named process nicely; usage: try_kill processname"
    kill (ps aux | grep -v grep | grep -i $argv | awk2)
end
