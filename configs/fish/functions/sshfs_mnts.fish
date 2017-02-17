#

function sshfs_mnts --description "mounts stuff"
  set -l _dirs ~/mnt/anime ~/mnt/movies ~/mnt/tv ~/mnt/music ~/mnt/misc
  set -l _remote_dirs /media/misc/anime /media/movies /media/tv /media/misc/music /media/misc
  for i in (seq (count $_dirs))
    set -l _dir $_dirs[$i]
    echo _dir=$dir
    set -l _remote_dir $_remote_dirs[$i]
    echo _remote_dir=$_remote_dir
  end

  # for dir in $_dirs
  #   if test ! -d $dir
  #     mkdir $dir
  #   end

  #   finmdnt $dir > /dev/null
  #   if test $status -eq 1
  #     # not mounted
  #   end
  # end

  # findmnt ~/mnt/music > /dev/null
  # if test $status -eq 1
  #   echo mounting music...
  #   # sshfs balescream:/media/misc/music ~/mnt/music
  # end

  # findmnt ~/mnt/movies > /dev/null
  # if test $status -eq 1
  #   echo mounting movies...
  #   # sshfs balescream:/media/movies ~/mnt/movies
  # end

  # findmnt ~/mnt/tv > /dev/null
  # if test $status -eq 1
  #   echo mounting tv...
  # end

  # findmnt ~/mnt/anime > /dev/null
  # if test $status -eq 1
  #   echo mounting anime...
  # end

  # findmnt ~/mnt/misc > /dev/null
  # if test $status -eq 1
  #   echo mounting misc...
  # end

  # sshfs balescream:/media/misc/music ~/mnt/music
  # sshfs balescream:/media/movies ~/mnt/movies
  # sshfs balescream:/media/tv ~/mnt/tv
  # sshfs balescream:/media/misc/anime ~/mnt/anime
  # sshfs balescream:/media/misc/vm ~/mnt/vm
  # sshfs balescream:/media/misc/vm ~/mnt/vm
end
