# based on: https://github.com/gotbletu/shownotes/blob/master/snippy.sh
# which was based on: https://bbs.archlinux.org/viewtopic.php?id=71938
# updated by me to be usable in fish, and also to use the primary selection instead of clipboard

# To use:
# First, create the ~/.snippets directory.
# Inside that directory, create multiple snippet files whose sole content is the text you wish to paste.
## Subdirectories are fine since we use 'find' in the script, but beware that duplicate names will be problematic.
## Note that the filename is used as the snippet title.

function snippets --description 'tool for pasting commonly used strings'
  set -l snippets_dir "$HOME/.snippets"

  # ensure snippets dir exists, else return right away
  if test ! -e $snippets_dir
    return
  end

  cd $snippets_dir

  set -l snippet_file (find -L . -type f | grep -v '^\.$' | sed 's!\.\/!!' | /usr/bin/rofi -dmenu)

  if test -f "$snippets_dir/$snippet_file"
    # Put the contents of the selected file into the paste buffer
    xsel --primary --input < "$snippets_dir/$snippet_file"

    # Paste into the current application
    #xdotool key Shift+Insert
    # Can't use Shift+Insert because chrome/chromium (or gtk?) doesn't pull form the primary selection, but rather from CLIPBOARD... stupid.
    xdotool type --delay 0 (xsel -o)
  end
end
