#!/usr/bin/env bash
set -euo pipefail

# Invoked by `wl-paste --type text --watch` with the selected text on stdin.
# Mirror it into PRIMARY for middle-click paste. Only watches CLIPBOARD,
# so writing PRIMARY here cannot recurse. The watcher prefers plain text
# and skips non-text offers.
#
# Consume this stream directly: requesting the clipboard again leaves the
# original pipe unread and can deadlock the browser on large copies.

case "${CLIPBOARD_STATE:-data}" in
  data|sensitive)
    exec wl-copy --primary --type 'text/plain;charset=utf-8'
    ;;
esac
