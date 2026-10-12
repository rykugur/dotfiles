#!/usr/bin/env bash
set -euo pipefail

# Invoked by `wl-paste --watch` on every CLIPBOARD change. Mirrors plain-text
# clipboard content into the PRIMARY selection so apps that only ever write
# CLIPBOARD (e.g. Herdr's copy-on-select) are also reachable via middle-click
# paste. Only watches CLIPBOARD, so writing PRIMARY here cannot recurse.
# Non-text content (images, etc.) is left alone rather than clobbering
# PRIMARY with an empty paste.

mime=$(wl-paste --list-types 2>/dev/null | head -n1 || true)

case "$mime" in
  text/*)
    wl-paste --no-newline --type "$mime" | wl-copy --primary --type "$mime"
    ;;
esac
