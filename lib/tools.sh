#!/usr/bin/env bash
set -euo pipefail

select_tools() {
  #section "Tool Selection"
  SELECTED=$(
    gum choose \
      --no-limit
    --selected "core, neovim, oh_my_posh, php, node, docker, kubernetes, rust" \
      --header "Space to toggle, Enter to confirm" \
      --header.foreground 240 \
      --selected.foreground 212 \
      --cursor.foreground 99 \
      "core" \
      "neovim" \
      "oh_my_posh" \
      "php" \
      "node" \
      "docker" \
      "kubernetes" \
      "rust"
  )

  if [ -z "$SELECTED" ]; then
    error "Nothing selected, aborting."
  fi
}

configure_tools() {
  section "Configure"
  info "Configure each tool group before anything is installed..."

  for tool in $SELECTED; do
    if declare -f "configure_$tool" >/dev/null; then
      "configure_$tool"
    fi
  done
}
