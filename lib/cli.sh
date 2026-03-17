#!/usr/bin/env bash

# ─────────────────────────────────────────────
# Oh My Posh
# ─────────────────────────────────────────────
OMP_INSTALL_FONT=true

configure_oh_my_posh() {
    section "Oh My Posh"

    if gum confirm "Install Meslo LGM Nerd Font to Windows fonts?"; then
        OMP_INSTALL_FONT=true
    else
        OMP_INSTALL_FONT=false
        warn "You'll need to install a Nerd Font manually"
    fi
}

install_oh_my_posh() {
    if command -v oh-my-posh &>/dev/null; then
        warn "Oh My Posh is already installed, skipping"
        return
    fi

    spin "Installing Oh My Posh..." \
        bash -c "curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin"

    if [ "$OMP_INSTALL_FONT" = true ]; then
        local win_user
        win_user=$(powershell.exe -Command 'Write-Host $env:USERNAME' 2>/dev/null | tr -d '\r')
        local font_dir="/mnt/c/Users/${win_user}/AppData/Local/Microsoft/Windows/Fonts"
        mkdir -p "$font_dir" 2>/dev/null || true

        local tmp_dir
        tmp_dir=$(mktemp -d)

        spin "Downloading Meslo LGM Nerd Font..." \
            curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" \
            -o "$tmp_dir/Meslo.zip"

        unzip -q "$tmp_dir/Meslo.zip" -d "$tmp_dir/Meslo"
        cp "$tmp_dir"/Meslo/*.ttf "$font_dir/" 2>/dev/null \
            || warn "Could not copy fonts — install manually from $tmp_dir/Meslo"

        rm -rf "$tmp_dir"
        success "Meslo LGM Nerd Font installed"
        warn "Set your Windows Terminal font to 'MesloLGM Nerd Font' in its settings"
    fi

    success "Oh My Posh installed"
}

# ─────────────────────────────────────────────
# Neovim
# ─────────────────────────────────────────────
NEOVIM_USER=""

configure_neovim() {
    section "Neovim"

    NEOVIM_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Install for user › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    NEOVIM_USER="${NEOVIM_USER:-$USER}"
}

install_neovim() {
    if command -v nvim &>/dev/null; then
        warn "Neovim is already installed ($(nvim --version | head -1)), skipping"
        return
    fi

    spin "Installing Neovim..." \
        pacman -S --noconfirm --needed neovim

    success "Neovim installed — config will be pulled via dotfiles"
}

# ─────────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────────
DOTFILES_REPO=""
DOTFILES_USER=""

configure_dotfiles() {
    section "Dotfiles"

    DOTFILES_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Username          › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    DOTFILES_USER="${DOTFILES_USER:-$USER}"

    DOTFILES_REPO=$(gum input \
        --placeholder "git@github.com:yourusername/dotfiles.git" \
        --prompt "Dotfiles repo     › " \
        --prompt.foreground 99 \
        --width 60 \
    )
}

install_dotfiles() {
    if [ -z "$DOTFILES_REPO" ]; then
        error "No dotfiles repo specified"
    fi

    local dotfiles_dir="/home/${DOTFILES_USER}/dotfiles"

    if [ -d "$dotfiles_dir" ]; then
        warn "Dotfiles directory already exists, pulling latest..."
        spin "Pulling dotfiles..." \
            sudo -u "$DOTFILES_USER" git -C "$dotfiles_dir" pull
    else
        spin "Cloning dotfiles..." \
            sudo -u "$DOTFILES_USER" git clone "$DOTFILES_REPO" "$dotfiles_dir"
    fi

    spin "Stowing dotfiles..." \
        sudo -u "$DOTFILES_USER" stow \
            --dir="$dotfiles_dir" \
            --target="/home/${DOTFILES_USER}" \
            --restow .

    success "Dotfiles linked"

    # Run headless Lazy sync if nvim config exists
    if [ -d "/home/${DOTFILES_USER}/.config/nvim" ] && command -v nvim &>/dev/null; then
        spin "Syncing Neovim plugins..." \
            sudo -u "$DOTFILES_USER" nvim --headless "+Lazy! sync" +qa
        success "Neovim plugins synced"
    fi
}
