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

  # present a list of note sets with which to work
  set -l selected_note_dir (echo personal\nwork | /usr/bin/dmenu)

  if test -z $selected_note_dir
    # escape was likely pressed, run away
    return
  end

  # kind of hacky... create a symlink to the nvpy cfg file in each respective work/personal dotfile repo
  if test $selected_note_dir = "work"
    rm $HOME/.nvpy.cfg
    ln -s $HOME/.workdotfiles/nvpy.cfg $HOME/.nvpy.cfg
  else
    rm $HOME/.nvpy.cfg
    ln -s $HOME/.dotfiles/configs/nvpy.cfg $HOME/.nvpy.cfg
  end

  nvpy &
end
