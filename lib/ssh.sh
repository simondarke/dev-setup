#!/usr/bin/env bash

# ─────────────────────────────────────────────
# SSH Key for GitHub
# ─────────────────────────────────────────────
SSH_GITHUB_USER=""
SSH_GITHUB_EMAIL=""

configure_ssh_github() {
    section "SSH Key for GitHub"

    SSH_GITHUB_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Username (for path) › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    SSH_GITHUB_USER="${SSH_GITHUB_USER:-$USER}"

    SSH_GITHUB_EMAIL=$(gum input \
        --placeholder "simon@example.com" \
        --prompt "Email (for key)     › " \
        --prompt.foreground 99 \
        --width 40 \
    )
}

install_ssh_github() {
    local ssh_dir="/home/${SSH_GITHUB_USER}/.ssh"
    local key_path="${ssh_dir}/id_ed25519"

    if [ -f "$key_path" ]; then
        warn "SSH key already exists at $key_path, skipping"
        return
    fi

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    spin "Generating SSH key..." \
        ssh-keygen -t ed25519 -C "$SSH_GITHUB_EMAIL" -f "$key_path" -N ""

    chown -R "${SSH_GITHUB_USER}:${SSH_GITHUB_USER}" "$ssh_dir"

    # Add github to known hosts
    ssh-keyscan github.com >> "$ssh_dir/known_hosts" 2>/dev/null
    success "SSH key generated"

    echo ""
    gum style --foreground 212 --bold "Your public key:"
    gum style --foreground 255 --border rounded --padding "0 2" "$(cat "${key_path}.pub")"
    echo ""
    gum style --foreground 240 "Add this to GitHub at: https://github.com/settings/ssh/new"
    echo ""

    gum confirm "Done adding the key to GitHub?" \
        --affirmative "Yes, continue" \
        --negative "Skip for now"
}

# ─────────────────────────────────────────────
# SSH Key (custom)
# ─────────────────────────────────────────────
SSH_CUSTOM_USER=""
SSH_CUSTOM_EMAIL=""
SSH_CUSTOM_HOST=""
SSH_CUSTOM_NAME=""

configure_ssh_custom() {
    section "SSH Key (custom)"

    SSH_CUSTOM_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Username (for path) › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    SSH_CUSTOM_USER="${SSH_CUSTOM_USER:-$USER}"

    SSH_CUSTOM_EMAIL=$(gum input \
        --placeholder "simon@example.com" \
        --prompt "Email (for key)     › " \
        --prompt.foreground 99 \
        --width 40 \
    )

    SSH_CUSTOM_HOST=$(gum input \
        --placeholder "gitlab.com" \
        --prompt "Host                › " \
        --prompt.foreground 99 \
        --width 40 \
    )

    SSH_CUSTOM_NAME=$(gum input \
        --placeholder "gitlab" \
        --prompt "Key name            › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    SSH_CUSTOM_NAME="${SSH_CUSTOM_NAME:-custom}"
}

install_ssh_custom() {
    local ssh_dir="/home/${SSH_CUSTOM_USER}/.ssh"
    local key_path="${ssh_dir}/id_ed25519_${SSH_CUSTOM_NAME}"

    if [ -f "$key_path" ]; then
        warn "SSH key already exists at $key_path, skipping"
        return
    fi

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    spin "Generating SSH key..." \
        ssh-keygen -t ed25519 -C "$SSH_CUSTOM_EMAIL" -f "$key_path" -N ""

    # Append to ssh config so it's used automatically for that host
    cat >> "$ssh_dir/config" <<EOF

Host ${SSH_CUSTOM_HOST}
    IdentityFile ${key_path}
    AddKeysToAgent yes
EOF

    if [ -n "$SSH_CUSTOM_HOST" ]; then
        ssh-keyscan "$SSH_CUSTOM_HOST" >> "$ssh_dir/known_hosts" 2>/dev/null
    fi

    chown -R "${SSH_CUSTOM_USER}:${SSH_CUSTOM_USER}" "$ssh_dir"
    success "SSH key generated: $key_path"

    echo ""
    gum style --foreground 212 --bold "Your public key:"
    gum style --foreground 255 --border rounded --padding "0 2" "$(cat "${key_path}.pub")"
    echo ""
}
