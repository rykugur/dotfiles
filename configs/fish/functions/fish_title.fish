#

function fish_title --description 'Override the default fish title'
  #echo $_ '|' (whoami)'@'(hostname)

  set -l cur_prog $_

  set -l prompt (whoami)'@'(hostname)

  if test $cur_prog = "fish"
    set prompt $prompt '|' (prompt_pwd)
  else
    set prompt $prompt '|' $_
  end

  echo $prompt
end
