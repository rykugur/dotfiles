[1mdiff --git a/configs/fish/abbr.misc.fish b/configs/fish/abbr.misc.fish[m
[1mindex a5cc258..3cd2710 100644[m
[1m--- a/configs/fish/abbr.misc.fish[m
[1m+++ b/configs/fish/abbr.misc.fish[m
[36m@@ -16,6 +16,7 @@[m [mabbr --add --global grc 'gource --stop-at-end -c 2 --disable-auto-rotate --hide[m
 abbr --add --global grn 'grep -n'[m
 abbr --add --global grin 'grep -ni'[m
 abbr --add --global grine 'grep -niRE'[m
[32m+[m[32mabbr --add --global gw './gradlew'[m
 abbr --add --global pagi 'ps aux | grep -v grep | grep -i'[m
 abbr --add --global pwdc 'pwd | trim.newlines | cmd.copy'[m
 abbr --add --global sv 'sudo vim'[m
[1mdiff --git a/configs/i3/assigns.conf b/configs/i3/assigns.conf[m
[1mindex 49b2fc0..ff48d47 100644[m
[1m--- a/configs/i3/assigns.conf[m
[1m+++ b/configs/i3/assigns.conf[m
[36m@@ -39,7 +39,6 @@[m [massign [class="(?i)prusaslicer"] $ws6[m
 assign [class="(?i)superslicer"] $ws6[m
 [m
 assign [class="(?i)Steam"] $ws9[m
[31m-for_window [class="(?i)Steam" title="(?i)Friends List"] floating enable[m
 [m
 ### games[m
 set $dota_class "(?i)dota2"[m
[36m@@ -53,8 +52,3 @@[m [massign [class=$sc_class] $ws10[m
 for_window [class=$sc_class] fullscreen enable[m
 assign [class=$rimworld_class] $ws10[m
 assign [class="(?i)steam_app_975370" title="(?i)Dwarf Fortress"] $ws10[m
[31m-## eve[m
[31m-for_window [class="(?i)steam_app_8500" title="(?i)EVE Launcher"] floating disable[m
[31m-for_window [class="(?i)steam_app_8500" title="(?i)EVE Launcher"] fullscreen disable[m
[31m-assign [class="(?i)steam_app_8500" title="(?i)EVE - Ryk"] $ws10[m
[31m-for_window [class="(?i)steam_app_8500" title="(?i)EVE - Ryk"] fullscreen enable[m
[1mdiff --git a/configs/i3/config b/configs/i3/config[m
[1mindex 2c037be..c8e0b95 100644[m
[1m--- a/configs/i3/config[m
[1m+++ b/configs/i3/config[m
[36m@@ -541,6 +541,8 @@[m [mworkspace_auto_back_and_forth yes[m
 # update key repeat rate[m
 exec_always "xset r rate 190 40"[m
 [m
[32m+[m[32mfocus_follows_mouse no[m
[32m+[m
 include assigns.conf[m
 include startup.conf[m
 include binds.conf[m
\ No newline at end of file[m
[1mdiff --git a/configs/rofi/rofi.blor.xresources b/configs/rofi/rofi.blor.xresources[m
[1mdeleted file mode 100644[m
[1mindex 5b3ad8b..0000000[m
[1m--- a/configs/rofi/rofi.blor.xresources[m
[1m+++ /dev/null[m
[36m@@ -1,15 +0,0 @@[m
[31m-! ------------------------------------------------------------------------------[m
[31m-! ROFI Color theme[m
[31m-! ------------------------------------------------------------------------------[m
[31m-! Use extended color scheme[m
[31m-rofi.color-enabled:                  true[m
[31m-! Color scheme for normal row[m
[31m-rofi.color-normal:                   argb:00000000,  #D8DEE9 , argb:00000000,  #FAC863 ,  #1B2B34[m
[31m-! Color scheme for urgent row[m
[31m-rofi.color-urgent:                   argb:00000000,  #F99157 , argb:00000000,  #F99157 ,  #1B2B34[m
[31m-! Color scheme for active row[m
[31m-rofi.color-active:                   argb:00000000,  #6699CC , argb:00000000,  #6699CC ,  #1B2B34[m
[31m-! Color scheme window[m
[31m-rofi.color-window:                   argb:ee222222,  #FAC863 ,  #FAC863[m
[31m-! Separator style (none, dash, solid)[m
[31m-rofi.separator-style:                solid[m
[1mdiff --git a/configs/rofi/rofi.glue_pro_blue.xresources b/configs/rofi/rofi.glue_pro_blue.xresources[m
[1mdeleted file mode 100644[m
[1mindex b24cd82..0000000[m
[1m--- a/configs/rofi/rofi.glue_pro_blue.xresources[m
[1m+++ /dev/null[m
[36m@@ -1,8 +0,0 @@[m
[31m-! ------------------------------------------------------------------------------[m
[31m-! ROFI Color theme[m
[31m-! ------------------------------------------------------------------------------[m
[31m-rofi.color-enabled: true[m
[31m-rofi.color-window: #393939, #393939, #268bd2[m
[31m-rofi.color-normal: #393939, #ffffff, #393939, #268bd2, #ffffff[m
[31m-rofi.color-active: #393939, #268bd2, #393939, #268bd2, #205171[m
[31m-rofi.color-urgent: #393939, #f3843d, #393939, #268bd2, #ffc39c[m
[1mdiff --git a/configs/rofi/rofi.solarized.xresources b/configs/rofi/rofi.solarized.xresources[m
[1mdeleted file mode 100644[m
[1mindex 8e81979..0000000[m
[1m--- a/configs/rofi/rofi.solarized.xresources[m
[1m+++ /dev/null[m
[36m@@ -1,8 +0,0 @@[m
[31m-! ------------------------------------------------------------------------------[m
[31m-! ROFI Color theme[m
[31m-! ------------------------------------------------------------------------------[m
[31m-rofi.color-enabled: true[m
[31m-rofi.color-window: #002b37, #002b37, #003642[m
[31m-rofi.color-normal: #002b37, #819396, #002b37, #003642, #819396[m
[31m-rofi.color-active: #002b37, #008ed4, #002b37, #003642, #008ed4[m
[31m-rofi.color-urgent: #002b37, #da4281, #002b37, #003642, #da4281[m
[1mdiff --git a/configs/rofi/rofi.solarized_alternate.xresources b/configs/rofi/rofi.solarized_alternate.xresources[m
[1mdeleted file mode 100644[m
[1mindex 5a673d1..0000000[m
[1m--- a/configs/rofi/rofi.solarized_alternate.xresources[m
[1m+++ /dev/null[m
[36m@@ -1,8 +0,0 @@[m
[31m-! ------------------------------------------------------------------------------[m
[31m-! ROFI Color theme[m
[31m-! ------------------------------------------------------------------------------[m
[31m-rofi.color-enabled: true[m
[31m-rofi.color-window: #002b37, #002b37, #003642[m
[31m-rofi.color-normal: #002b37, #819396, #003643, #008ed4, #ffffff[m
[31m-rofi.color-active: #002b37, #008ed4, #003643, #008ed4, #66c6ff[m
[31m-rofi.color-urgent: #002b37, #da4281, #003643, #008ed4, #890661[m
[1mdiff --git a/configs/rofi/rofi.xresources b/configs/rofi/rofi.xresources[m
[1mdeleted file mode 100644[m
[1mindex 842d2bc..0000000[m
[1m--- a/configs/rofi/rofi.xresources[m
[1m+++ /dev/null[m
[36m@@ -1,233 +0,0 @@[m
[31m-! "Enabled modi" Set from: Default[m
[31m-rofi.modi:                           window,ssh,run[m
[31m-! "Window width" Set from: Default[m
[31m-! rofi.width:                          50[m
[31m-! "Number of lines" Set from: Default[m
[31m-! rofi.lines:                          15[m
[31m-! "Number of columns" Set from: Default[m
[31m-! rofi.columns:                        1[m
[31m-! "Font to use" Set from: Default[m
[31m-rofi.font:                           artwiz lemon 8[m
[31m-! "Color scheme for normal row" Set from: Default[m
[31m-! rofi.color-normal:                   #fdf6e3,#002b36,#eee8d5,#586e75,#eee8d5[m
[31m-! "Color scheme for urgent row" Set from: Default[m
[31m-! rofi.color-urgent:                   #fdf6e3,#dc322f,#eee8d5,#dc322f,#fdf6e3[m
[31m-! "Color scheme for active row" Set from: Default[m
[31m-! rofi.color-active:                   #fdf6e3,#268bd2,#eee8d5,#268bd2,#fdf6e3[m
[31m-! "Color scheme window" Set from: Default[m
[31m-! rofi.color-window:                   #fdf6e3,#002b36[m
[31m-! "Border width" Set from: Default[m
[31m-! rofi.bw:                             1[m
[31m-! "Location on screen" Set from: Default[m
[31m-! rofi.location:                       0[m
[31m-! "Padding" Set from: Default[m
[31m-! rofi.padding:                        5[m
[31m-! "Y-offset relative to location" Set from: Default[m
[31m-! rofi.yoffset:                        0[m
[31m-! "X-offset relative to location" Set from: Default[m
[31m-! rofi.xoffset:                        0[m
[31m-! "Always show number of lines" Set from: Default[m
[31m-! rofi.fixed-num-lines:                true[m
[31m-! "Terminal to use" Set from: Default[m
[31m-! rofi.terminal:                       rofi-sensible-terminal[m
[31m-! "Ssh client to use" Set from: Default[m
[31m-! rofi.ssh-client:                     ssh[m
[31m-! "Ssh command to execute" Set from: Default[m
[31m-! rofi.ssh-command:                    {terminal} -e {ssh-client} {host}[m
[31m-! "Run command to execute" Set from: Default[m
[31m-! rofi.run-command:                    {cmd}[m
[31m-! "Command to get extra run targets" Set from: Default[m
[31m-! rofi.run-list-command:[m
[31m-! "Run command to execute that runs in shell" Set from: Default[m
[31m-! rofi.run-shell-command:              {terminal} -e {cmd}[m
[31m-! "Command executed on accep-entry-custom for window modus" Set from: Default[m
[31m-! rofi.window-command:                 xkill -id {window}[m
[31m-! "Disable history in run/ssh" Set from: Default[m
[31m-! rofi.disable-history:                false[m
[31m-! "Use levenshtein sorting" Set from: Default[m
[31m-! rofi.levenshtein-sort:               false[m
[31m-! "Set case-sensitivity" Set from: Default[m
[31m-! rofi.case-sensitive:                 false[m
[31m-! "Cycle through the results list" Set from: Default[m
[31m-! rofi.cycle:                          true[m
[31m-! "Enable sidebar-mode" Set from: Default[m
[31m-! rofi.sidebar-mode:                   false[m
[31m-! "Row height (in chars)" Set from: Default[m
[31m-! rofi.eh:                             1[m
[31m-! "Enable auto select mode" Set from: Default[m
[31m-! rofi.auto-select:                    false[m
[31m-! "Parse hosts file for ssh mode" Set from: Default[m
[31m-! rofi.parse-hosts:                    false[m
[31m-! "Parse known_hosts file for ssh mode" Set from: Default[m
[31m-! rofi.parse-known-hosts:              true[m
[31m-! "Set the modi to combine in combi mode" Set from: Default[m
[31m-! rofi.combi-modi:                     window,run[m
[31m-! "Set the matching algorithm. (normal, regex, glob, fuzzy)" Set from: Default[m
[31m-! rofi.matching:                       normal[m
[31m-! "Tokenize input string" Set from: Default[m
[31m-! rofi.tokenize:                       true[m
[31m-! "Monitor id to show on" Set from: Default[m
[31m-! rofi.m:                              -5[m
[31m-! "Margin between rows" Set from: Default[m
[31m-! rofi.line-margin:                    2[m
[31m-! "Padding within rows" Set from: Default[m
[31m-! rofi.line-padding:                   1[m
[31m-! "Pre-set filter" Set from: Default[m
[31m-! rofi.filter:[m
[31m-! "Separator style (none, dash, solid)" Set from: Default[m
[31m-! rofi.separator-style:                dash[m
[31m-! "Hide scroll-bar" Set from: Default[m
[31m-! rofi.hide-scrollbar:                 false[m
[31m-! "Fullscreen" Set from: Default[m
[31m-! rofi.fullscreen:                     false[m
[31m-! "Fake transparency" Set from: Default[m
[31m-! rofi.fake-transparency:              false[m
[31m-! "DPI" Set from: Default[m
[31m-! rofi.dpi:                            -1[m
[31m-! "Threads to use for string matching" Set from: Default[m
[31m-! rofi.threads:                        0[m
[31m-! "Scrollbar width" Set from: Default[m
[31m-! rofi.scrollbar-width:                8[m
[31m-! "Scrolling method. (0: Page, 1: Centered)" Set from: Default[m
[31m-! rofi.scroll-method:                  0[m
[31m-! "Background to use for fake transparency. (background or screenshot)" Set from: Default[m
[31m-! rofi.fake-background:                screenshot[m
[31m-! "Window Format. w (desktop name), t (title), n (name), r (role), c (class)" Set from: Default[m
[31m-! rofi.window-format:                  {w}   {c}   {t}[m
[31m-! "Click outside the window to exit" Set from: Default[m
[31m-! rofi.click-to-exit:                  true[m
[31m-! "Indicate how it match by underlining it." Set from: Default[m
[31m-! rofi.show-match:                     true[m
[31m-! "Pidfile location" Set from: Default[m
[31m-! rofi.pid:                            /run/user/1000/rofi.pid[m
[31m-! "Paste primary selection" Set from: Default[m
[31m-! rofi.kb-primary-paste:               Control+V,Shift+Insert[m
[31m-! "Paste clipboard" Set from: Default[m
[31m-! rofi.kb-secondary-paste:             Control+v,Insert[m
[31m-! "Clear input line" Set from: Default[m
[31m-! rofi.kb-clear-line:                  Control+w[m
[31m-! "Beginning of line" Set from: Default[m
[31m-! rofi.kb-move-front:                  Control+a[m
[31m-! "End of line" Set from: Default[m
[31m-! rofi.kb-move-end:                    Control+e[m
[31m-! "Move back one word" Set from: Default[m
[31m-! rofi.kb-move-word-back:              Alt+b[m
[31m-! "Move forward one word" Set from: Default[m
[31m-! rofi.kb-move-word-forward:           Alt+f[m
[31m-! "Move back one char" Set from: Default[m
[31m-! rofi.kb-move-char-back:              Left,Control+b[m
[31m-! "Move forward one char" Set from: Default[m
[31m-! rofi.kb-move-char-forward:           Right,Control+f[m
[31m-! "Delete previous word" Set from: Default[m
[31m-! rofi.kb-remove-word-back:            Control+Alt+h,Control+BackSpace[m
[31m-! "Delete next word" Set from: Default[m
[31m-! rofi.kb-remove-word-forward:         Control+Alt+d[m
[31m-! "Delete next char" Set from: Default[m
[31m-! rofi.kb-remove-char-forward:         Delete,Control+d[m
[31m-! "Delete previous char" Set from: Default[m
[31m-! rofi.kb-remove-char-back:            BackSpace,Control+h[m
[31m-! "Delete till the end of line" Set from: Default[m
[31m-! rofi.kb-remove-to-eol:               Control+k[m
[31m-! "Delete till the start of line" Set from: Default[m
[31m-! rofi.kb-remove-to-sol:               Control+u[m
[31m-! "Accept entry" Set from: Default[m
[31m-! rofi.kb-accept-entry:                Control+j,Control+m,Return,KP_Enter[m
[31m-! "Use entered text as command (in ssh/run modi)" Set from: Default[m
[31m-! rofi.kb-accept-custom:               Control+Return[m
[31m-! "Use alternate accept command." Set from: Default[m
[31m-! rofi.kb-accept-alt:                  Shift+Return[m
[31m-! "Delete entry from history" Set from: Default[m
[31m-! rofi.kb-delete-entry:                Shift+Delete[m
[31m-! "Switch to the next mode." Set from: Default[m
[31m-! rofi.kb-mode-next:                   Shift+Right,Control+Tab[m
[31m-! "Switch to the previous mode." Set from: Default[m
[31m-! rofi.kb-mode-previous:               Shift+Left,Control+Shift+Tab[m
[31m-! "Go to the previous column" Set from: Default[m
[31m-! rofi.kb-row-left:                    Control+Page_Up[m
[31m-! "Go to the next column" Set from: Default[m
[31m-! rofi.kb-row-right:                   Control+Page_Down[m
[31m-! "Select previous entry" Set from: Default[m
[31m-! rofi.kb-row-up:                      Up,Control+p,Shift+Tab,Shift+ISO_Left_Tab[m
[31m-! "Select next entry" Set from: Default[m
[31m-! rofi.kb-row-down:                    Down,Control+n[m
[31m-! "Go to next row, if one left, accept it, if no left next mode." Set from: Default[m
[31m-! rofi.kb-row-tab:                     Tab[m
[31m-! "Go to the previous page" Set from: Default[m
[31m-! rofi.kb-page-prev:                   Page_Up[m
[31m-! "Go to the next page" Set from: Default[m
[31m-! rofi.kb-page-next:                   Page_Down[m
[31m-! "Go to the first entry" Set from: Default[m
[31m-! rofi.kb-row-first:                   Home,KP_Home[m
[31m-! "Go to the last entry" Set from: Default[m
[31m-! rofi.kb-row-last:                    End,KP_End[m
[31m-! "Set selected item as input text" Set from: Default[m
[31m-! rofi.kb-row-select:                  Control+space[m
[31m-! "Take a screenshot of the rofi window" Set from: Default[m
[31m-! rofi.kb-screenshot:                  Alt+S[m
[31m-! "Toggle case sensitivity" Set from: Default[m
[31m-! rofi.kb-toggle-case-sensitivity:     grave,dead_grave[m
[31m-! "Toggle sort" Set from: Default[m
[31m-! rofi.kb-toggle-sort:                 Alt+grave[m
[31m-! "Quit rofi" Set from: Default[m
[31m-! rofi.kb-cancel:                      Escape,Control+g,Control+bracketleft[m
[31m-! "Custom keybinding 1" Set from: Default[m
[31m-! rofi.kb-custom-1:                    Alt+1[m
[31m-! "Custom keybinding 2" Set from: Default[m
[31m-! rofi.kb-custom-2:                    Alt+2[m
[31m-! "Custom keybinding 3" Set from: Default[m
[31m-! rofi.kb-custom-3:                    Alt+3[m
[31m-! "Custom keybinding 4" Set from: Default[m
[31m-! rofi.kb-custom-4:                    Alt+4[m
[31m-! "Custom Keybinding 5" Set from: Default[m
[31m-! rofi.kb-custom-5:                    Alt+5[m
[31m-! "Custom keybinding 6" Set from: Default[m
[31m-! rofi.kb-custom-6:                    Alt+6[m
[31m-! "Custom Keybinding 7" Set from: Default[m
[31m-! rofi.kb-custom-7:                    Alt+7[m
[31m-! "Custom keybinding 8" Set from: Default[m
[31m-! rofi.kb-custom-8:                    Alt+8[m
[31m-! "Custom keybinding 9" Set from: Default[m
[31m-! rofi.kb-custom-9:                    Alt+9[m
[31m-! "Custom keybinding 10" Set from: Default[m
[31m-! rofi.kb-custom-10:                   Alt+0[m
[31m-! "Custom keybinding 11" Set from: Default[m
[31m-! rofi.kb-custom-11:                   Alt+exclam[m
[31m-! "Custom keybinding 12" Set from: Default[m
[31m-! rofi.kb-custom-12:                   Alt+at[m
[31m-! "Csutom keybinding 13" Set from: Default[m
[31m-! rofi.kb-custom-13:                   Alt+numbersign[m
[31m-! "Custom keybinding 14" Set from: Default[m
[31m-! rofi.kb-custom-14:                   Alt+dollar[m
[31m-! "Custom keybinding 15" Set from: Default[m
[31m-! rofi.kb-custom-15:                   Alt+percent[m
[31m-! "Custom keybinding 16" Set from: Default[m
[31m-! rofi.kb-custom-16:                   Alt+dead_circumflex[m
[31m-! "Custom keybinding 17" Set from: Default[m
[31m-! rofi.kb-custom-17:                   Alt+ampersand[m
[31m-! "Custom keybinding 18" Set from: Default[m
[31m-! rofi.kb-custom-18:                   Alt+asterisk[m
[31m-! "Custom Keybinding 19" Set from: Default[m
[31m-! rofi.kb-custom-19:                   Alt+parenleft[m
[31m-! "The display name of this browser" Set from: Default[m
[31m-! rofi.display-ssh:[m
[31m-! "The display name of this browser" Set from: Default[m
[31m-! rofi.display-run:[m
[31m-! "The display name of this browser" Set from: Default[m
[31m-! rofi.display-drun:[m
[31m-! "The display name of this browser" Set from: Default[m
[31m-! rofi.display-window:[m
[31m-! "The display name of this browser" Set from: Default[m
[31m-! rofi.display-windowcd:[m
[31m-! "The display name of this browser" Set from: Default[m
[31m-! rofi.display-combi:[m
[31m-[m
[31m-[m
[31m-! android theme[m
[31m-! ------------------------------------------------------------------------------[m
[31m-! ROFI Color theme[m
[31m-! ------------------------------------------------------------------------------[m
[31m-rofi.color-enabled: true[m
[31m-rofi.color-window: #273238, #273238, #1e2529[m
[31m-rofi.color-normal: #273238, #c1c1c1, #273238, #394249, #ffffff[m
[31m-rofi.color-active: #273238, #80cbc4, #273238, #394249, #80cbc4[m
[31m-rofi.color-urgent: #273238, #ff1844, #273238, #394249, #ff1844[m
