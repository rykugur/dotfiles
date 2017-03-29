#

function nvpy_notes --description "opens the selected note set in nvpy, uses rofi as input if no arg passed; usage: nvpy_notes [personal|work]"
  # make sure nvpy isn't already running... this could cause problems!
  if test (count (pgrep nvpy)) -ne 0
    echo 'nvpy already running, not continuing'
    return
  end

  # ensure we have a notes directory variable defined
  if test -z $NOTES_DIR
    return
  end

  # ensure notes dir exists, else return right away
  if test ! -e $NOTES_DIR
    return
  end

  # present a list of note sets with which to work?
  if test -z $argv[1]
    set selected_note_dir (echo personal\nwork | /usr/bin/rofi -dmenu)
  else
    set selected_note_dir $argv[1]
  end

  if test -z $selected_note_dir
    # escape was likely pressed, run away
    return
  end


  # kind of hacky... create a symlink to the nvpy cfg file in each respective work/personal dotfile repo
  if test $selected_note_dir = "work"
    rm $HOME/.nvpy
    rm $HOME/.nvpy.cfg

    ln -s $WORK_NOTES_DIR/.nvpy $HOME/.nvpy
    ln -s $HOME/.workdotfiles/nvpy.cfg $HOME/.nvpy.cfg
  else
    rm $HOME/.nvpy
    rm $HOME/.nvpy.cfg

    ln -s $PERSONAL_NOTES_DIR/.nvpy $HOME/.nvpy
    ln -s $HOME/.dotfiles/configs/nvpy.cfg $HOME/.nvpy.cfg
  end

  nvpy &
end
