#!/usr/bin/env bash
set -euo pipefail

run_dotfiles() {
DOTFILES_REPO="git@github.com:simondarke/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

if ! command -v gum &>/dev/null; then
    echo "gum is not installed. Run: pacman -S gum"
    exit 1
fi

gum style \
    --border rounded \
    --border-foreground 99 \
    --padding "1 4" \
    --margin "1 0" \
    --bold \
    --foreground 212 \
    "dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    gum log --level warn "Dotfiles already exist, pulling latest..."
    gum spin --spinner dot --title "Pulling latest..." -- \
        git -C "$DOTFILES_DIR" pull
else
    gum spin --spinner dot --title "Cloning dotfiles..." -- \
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

gum spin --spinner dot --title "Stowing..." -- \
    stow --dir="$DOTFILES_DIR" --target="$HOME" --restow .

gum log --level info "✓ Done! Restart your shell for changes to take effect."
}