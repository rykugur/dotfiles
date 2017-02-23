#

function dev.android.copySharedPrefs --description "Copies shared prefs for the given package to current dir or specified dir. Usage: copy_shared_prefs [-p package] [-d output_dir]"
  set -l argc (count $argv)

  # sane defaults
  set -l package "io.rollhax"
  set -l target_dir "."

  if test $argc -ge 1
    getopts $argv | while read -l key value
      switch $key
        case p or package
          set package $value
        case d or dir or output
          set target_dir $value
      end # end switch
    end # end getopts
  end # end if

  # echo package=$package
  # echo target_dir=$target_dir

  if test ! -d $target_dir
    echo target_dir doesn\'t exist, exiting
    return 1
  end

  adb shell "run-as $package cp -rf shared_prefs/ /sdcard/Download/"
  adb pull /sdcard/Download/shared_prefs $target_dir
  adb shell "rm -rf /sdcard/Download/shared_prefs"
end
