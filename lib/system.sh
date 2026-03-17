#!/usr/bin/env bash

# ─────────────────────────────────────────────
# Locale & Timezone
# ─────────────────────────────────────────────
configure_locale() {
    section "Locale & Timezone"

    LOCALE_TZ=$(gum input \
        --placeholder "Europe/London" \
        --value "Europe/London" \
        --prompt "Timezone › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    LOCALE_TZ="${LOCALE_TZ:-Europe/London}"
}

install_locale() {
    if [ ! -f "/usr/share/zoneinfo/${LOCALE_TZ}" ]; then
        warn "Timezone '${LOCALE_TZ}' not found, defaulting to Europe/London"
        LOCALE_TZ="Europe/London"
    fi

    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    spin "Generating locale..." locale-gen
    localectl set-locale LANG=en_US.UTF-8

    ln -sf "/usr/share/zoneinfo/${LOCALE_TZ}" /etc/localtime
    success "Locale set to en_US.UTF-8, timezone set to ${LOCALE_TZ}"
}

# ─────────────────────────────────────────────
# Hostname
# ─────────────────────────────────────────────
configure_hostname() {
    section "Hostname"

    SYSTEM_HOSTNAME=$(gum input \
        --placeholder "arch-wsl" \
        --value "arch-wsl" \
        --prompt "Hostname › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    SYSTEM_HOSTNAME="${SYSTEM_HOSTNAME:-arch-wsl}"
}

install_hostname() {
    echo "$SYSTEM_HOSTNAME" > /etc/hostname
    success "Hostname set to $SYSTEM_HOSTNAME"
}

# ─────────────────────────────────────────────
# User setup
# ─────────────────────────────────────────────
configure_user() {
    section "User Setup"

    USER_NAME=$(gum input \
        --placeholder "simon" \
        --prompt "Username › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    USER_NAME="${USER_NAME:-simon}"
}

install_user() {
    if id "$USER_NAME" &>/dev/null; then
        warn "User '$USER_NAME' already exists, skipping"
        return
    fi

    local password password_confirm
    password=$(gum input \
        --password \
        --placeholder "password" \
        --prompt "Password  › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    password_confirm=$(gum input \
        --password \
        --placeholder "confirm password" \
        --prompt "Confirm   › " \
        --prompt.foreground 99 \
        --width 40 \
    )

    if [ "$password" != "$password_confirm" ]; then
        error "Passwords do not match"
    fi

    useradd -m -G wheel -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$password" | chpasswd
    unset password password_confirm

    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    success "User '$USER_NAME' created"
}

# ─────────────────────────────────────────────
# WSL config
# ─────────────────────────────────────────────
configure_wsl_conf() {
    section "WSL Config"

    WSL_DEFAULT_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Default user › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    WSL_DEFAULT_USER="${WSL_DEFAULT_USER:-simon}"
}

install_wsl_conf() {
    cat > /etc/wsl.conf <<EOF
[boot]
systemd=true

[user]
default=${WSL_DEFAULT_USER}

[automount]
enabled=true
options="metadata,uid=1000,gid=1000,umask=022"
mountFsTab=true

[network]
generateHosts=true
generateResolvConf=true

[interop]
enabled=true
appendWindowsPath=true
EOF
    success "WSL config written — restart WSL to apply"
}
