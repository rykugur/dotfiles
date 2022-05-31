#!/usr/bin/fish

function edit_local_config --description "cd to local fish config dir"
  set -l _local_dir "$HOME/.local/fish/"

  if test ! -d $_local_dir
    echo "$_local_dir didn't exist, creating"
    mkdir -p $_local_dir
  end

  cd $_local_dir
end
