#

function vim_notes --description "opens the given file name in vim notes plugin, uses dmenu as input; usage: vim_notes"
  # for now, just open up a vim session in the right directory... get this working at some point
  #cd $OWNCLOUD_NOTES
  #urxvt -e vim

  if test -z $OWNCLOUD_NOTES
    return
  end

  # ensure notes dir exists, else return right away
  if test ! -e $OWNCLOUD_NOTES
    return
  end

  # pass an empty string to dmenu to trick it, but also so it won't return anything if nothing is entered
  # use basename to get the file name only
  set -l note_file (basename (find -L $OWNCLOUD_NOTES -type f | grep -v '^\.$' | sed 's!\.\/!!' | /usr/bin/dmenu -l 10))

  urxvt -e vim note:$note_file
end
