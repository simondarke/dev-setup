#!/usr/bin/env bash
set -euo pipefail

if ! command -v gum &>/dev/null; then
    echo "gum is not installed. Run: pacman -S gum"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/ui.sh"

for installer in "$SCRIPT_DIR"/lib/installers/*.sh; do
    source "$installer"
done

# ─────────────────────────────────────────────
# Root check
# ─────────────────────────────────────────────
require_root() {
    if [ "$EUID" -ne 0 ]; then
        warn "This script needs to run as root."
        gum confirm "Re-run with sudo?" && exec sudo bash "$(realpath "$0")" "$@" || error "Aborted."
    fi
}

# ─────────────────────────────────────────────
# Category menus
# ─────────────────────────────────────────────
menu_system() {
    while true; do
        local choice
        choice=$(gum choose \
            --header "System" \
            --header.foreground 240 \
            --selected.foreground 212 \
            --cursor.foreground 99 \
            "Locale & Timezone" \
            "Hostname" \
            "User Setup" \
            "WSL Config" \
            "← Back"
        )

        case "$choice" in
            "Locale & Timezone") run_installer "locale" ;;
            "Hostname")          run_installer "hostname" ;;
            "User Setup")        run_installer "user" ;;
            "WSL Config")        run_installer "wsl_conf" ;;
            "← Back")            return ;;
        esac
    done
}

menu_security() {
    while true; do
        local choice
        choice=$(gum choose \
            --header "Security & Auth" \
            --header.foreground 240 \
            --selected.foreground 212 \
            --cursor.foreground 99 \
            "SSH Key for GitHub" \
            "SSH Key (custom)" \
            "← Back"
        )

        case "$choice" in
            "SSH Key for GitHub") run_installer "ssh_github" ;;
            "SSH Key (custom)")   run_installer "ssh_custom" ;;
            "← Back")             return ;;
        esac
    done
}

menu_cli() {
    while true; do
        local choice
        choice=$(gum choose \
            --header "CLI & Editor" \
            --header.foreground 240 \
            --selected.foreground 212 \
            --cursor.foreground 99 \
            "Oh My Posh" \
            "Neovim" \
            "Dotfiles" \
            "← Back"
        )

        case "$choice" in
            "Oh My Posh") run_installer "oh_my_posh" ;;
            "Neovim")     run_installer "neovim" ;;
            "Dotfiles")   run_installer "dotfiles" ;;
            "← Back")     return ;;
        esac
    done
}

menu_languages() {
    while true; do
        local choice
        choice=$(gum choose \
            --header "Languages" \
            --header.foreground 240 \
            --selected.foreground 212 \
            --cursor.foreground 99 \
            "PHP + Composer" \
            "Node (fnm)" \
            "Rust (rustup)" \
            "← Back"
        )

        case "$choice" in
            "PHP + Composer") run_installer "php" ;;
            "Node (fnm)")     run_installer "node" ;;
            "Rust (rustup)")  run_installer "rust" ;;
            "← Back")         return ;;
        esac
    done
}

menu_devops() {
    while true; do
        local choice
        choice=$(gum choose \
            --header "DevOps" \
            --header.foreground 240 \
            --selected.foreground 212 \
            --cursor.foreground 99 \
            "Docker" \
            "Kubernetes Tools" \
            "← Back"
        )

        case "$choice" in
            "Docker")            run_installer "docker" ;;
            "Kubernetes Tools")  run_installer "kubernetes" ;;
            "← Back")            return ;;
        esac
    done
}

# ─────────────────────────────────────────────
# Run an installer — configure → confirm → install
# ─────────────────────────────────────────────
run_installer() {
    local name="$1"

    # Run configure if it exists
    if declare -f "configure_${name}" > /dev/null; then
        "configure_${name}"
    fi

    gum confirm "Install ${name//_/ }?" || return

    "install_${name}"
}

# ─────────────────────────────────────────────
# Main menu loop
# ─────────────────────────────────────────────
main_menu() {
    while true; do
        echo ""
        local choice
        choice=$(gum choose \
            --header "What do you want to set up?" \
            --header.foreground 240 \
            --selected.foreground 212 \
            --cursor.foreground 99 \
            "System" \
            "Security & Auth" \
            "CLI & Editor" \
            "Languages" \
            "DevOps" \
            "Quit"
        )

        case "$choice" in
            "System")         menu_system ;;
            "Security & Auth") menu_security ;;
            "CLI & Editor")   menu_cli ;;
            "Languages")      menu_languages ;;
            "DevOps")         menu_devops ;;
            "Quit")           quit ;;
        esac
    done
}

quit() {
    gum style \
        --foreground 240 \
        --margin "1 0" \
        "Bye 👋"
    exit 0
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
    gum style \
        --border rounded \
        --border-foreground 99 \
        --padding "1 4" \
        --margin "1 0" \
        --bold \
        --foreground 212 \
        "dotfiles"

    require_root "$@"

    main_menu
}

main "$@"
