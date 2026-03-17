#!/usr/bin/env bash

header() {
  gum style \
    --border rounded \
    --border-foreground 99 \
    --padding "1 4" \
    --margin "1 0" \
    --bold \
    --foreground 212 \
    "dotfiles bootstrap"
}

section() {
  echo ""
  gum style \
    --foreground 99 \
    --bold \
    --border-foreground 99 \
    "── $1 ──────────────────────────"
  echo ""
}

spin() {
  local title="$1"
  shift
  gum spin --spinner dot --title "$title" -- "$@"
}
