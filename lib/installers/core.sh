#!/usr/bin/env bash

CORE_PACKAGES=()

configure_core() {
  gum style --foreground 99 --bold "Core packages:"

  local selected
  selected=$(
    gum choose \
      --no-limit \
      --selected "base-devel,git,curl,wget,unzip,zip,jq,nano,ripgrep,fd,fzf,stow,openssh,bash-completion,xdg-utils" \
      --header "Select core packages to install" \
      --header.foreground 240 \
      --selected.foreground 212 \
      --cursor.foreground 99 \
      "base-devel" \
      "git" \
      "curl" \
      "wget" \
      "unzip" \
      "zip" \
      "jq" \
      "nano" \
      "ripgrep" \
      "fd" \
      "fzf" \
      "stow" \
      "openssh" \
      "bash-completion" \
      "xdg-utils"
 )

  mapfile -t CORE_PACKAGES <<<"$selected"
}

install_core() {
  gum log "Installing: ${CORE_PACKAGES[@]}" 
  gum spin "pacman -S --noconfirm --needed ${CORE_PACKAGES[*]} " --spinner dot --title "Installing core packages..."
  gum log --levelerror "Installing: ${CORE_PACKAGES[*]}"
  pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"
  success "Core packages installed"
}

summary_core() {
  echo "  ◆ core: ${CORE_PACKAGES[*]}"
}

run_core() {
  configure_core
  install_core
  summary_core
}