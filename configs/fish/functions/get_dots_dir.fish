#!/usr/bin/fish

function get_dots_dir --description "gets the current dotfiles path, sets it to an environment variable, and returns it"
  set script_path (dirname (dirname (dirname (realpath (dirname (status -f))))))
  echo $script_path
end
