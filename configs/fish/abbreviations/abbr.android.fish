abbr --add --global adb.reverse 'adb reverse tcp:8081 tcp:8081; adb reverse tcp:8080 tcp:8080'
abbr --add --global adb.start adb shell am start
abbr --add --global adb.reset-perms adb shell pm reset-permissions
abbr --add --global .gw ./gradlew

