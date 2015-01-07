#

function vim_notes --description "opens the given file name in vim notes plugin, uses dmenu as input; usage: vim_notes"
  # ensure we have a notes directory variable defined
  if test -z $NOTES_DIR
    return
  end

  # ensure notes dir exists, else return right away
  if test ! -e $NOTES_DIR
    return
  end

  # cd to this dir to make searching eas(y|ier)
  cd $NOTES_DIR

  # pass an empty string to dmenu to trick it, but also so it won't return anything if nothing is entered
  # use basename to get the file name only
  set -l note_file (find -L $NOTES_DIR -type f | grep -v '^\.$' | sed 's!\.\/!!' | /usr/bin/dmenu -l 10)

  if test -z $note_file
    # escape was likely pressed, run away
    return
  end

  if test -n $note_file
    #urxvt -e vim note:(basename $note_file)
    urxvt -e vim $note_file
    #echo $note_file
  end
end
