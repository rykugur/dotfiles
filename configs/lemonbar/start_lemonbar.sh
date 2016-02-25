#!/bin/bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PANEL_HEIGHT="x34"
PANEL_FONT="GohuFont:12"
PANEL_FONT_ICON="FontAwesome:12"

. $SCRIPT_DIR/lemonbar_config.sh

./lemonbar_panel.sh | lemonbar -p -g $PANEL_HEIGHT -f $PANEL_FONT -f $PANEL_FONT_ICON -B $COLOR_BACKGROUND
