#!/usr/bin/env bash
set -euo pipefail

# --------------------
# Setup
# --------------------

if ! command -v gum &>/dev/null; then
  echo "gum is not installed. Run: pacman -S gum"
  exit 1
fi

# -------------------
# Logging
# -------------------
info() { gum log --level info "$*"; }
success() { gum log --level info "✅ $*"; }
warn() { gum log --level warn "$*"; }
error() {
  gum log --level error "$*"
  exit 1
}

# ─────────────────────────────────────────────
# Root check
# ─────────────────────────────────────────────
require_root() {
  if [ "$EUID" -ne 0 ]; then
    warn "This script needs to run as root."
    gum confirm "Rerun the script with sudo?" && exec sudo bash "$(realpath "$0")" "$@" || error "Aborted."
  fi
  success "Running as root"
}

# ------------------
# Source libs
# ------------------

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/preflight.sh"

# ─────────────────────────────────────────────
# Tool group selection
# ─────────────────────────────────────────────
select_tools() {
  section "Tool Selection"

  SELECTED=$(
    gum choose \
      --no-limit \
      --selected "core,neovim,oh_my_posh,php,node,docker,kubernetes,rust" \
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

# ─────────────────────────────────────────────
# Configure pass — each installer runs its own submenu
# ─────────────────────────────────────────────
configure_tools() {
  section "Configure"
  info "Configure each tool group before anything is installed..."

  for tool in $SELECTED; do
    if declare -f "configure_$tool" >/dev/null; then
      "configure_$tool"
    fi
  done
}

main() {
  gum style \
    --border rounded \
    --border-foreground 212 \
    --padding "1 4" \
    --margin "1 0" \
    --bold \
    "DarkeFYI Setup"

  require_root "$@"

  run_preflight

  select_tools

  info "Starting..."
}

main "$@"
