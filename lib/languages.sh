#!/usr/bin/env bash

# ─────────────────────────────────────────────
# PHP + Composer
# ─────────────────────────────────────────────
PHP_EXTENSIONS=()

configure_php() {
    section "PHP + Composer"

    local selected
    selected=$(gum choose \
        --no-limit \
        --selected "bcmath,curl,gd,intl,mbstring,pdo_sqlite,sodium,zip" \
        --header "Select PHP extensions to enable" \
        --header.foreground 240 \
        --selected.foreground 212 \
        --cursor.foreground 99 \
        "bcmath" \
        "curl" \
        "gd" \
        "intl" \
        "mbstring" \
        "pdo_mysql" \
        "pdo_pgsql" \
        "pdo_sqlite" \
        "redis" \
        "sodium" \
        "xdebug" \
        "zip" \
    )

    mapfile -t PHP_EXTENSIONS <<< "$selected"
}

install_php() {
    if command -v php &>/dev/null; then
        warn "PHP is already installed ($(php -r 'echo PHP_VERSION;')), skipping"
        return
    fi

    spin "Installing PHP..." \
        pacman -S --noconfirm --needed php php-fpm php-sqlite php-intl php-gd php-sodium

    local php_ini="/etc/php/php.ini"
    for ext in "${PHP_EXTENSIONS[@]}"; do
        sed -i "s/^;extension=${ext}/extension=${ext}/" "$php_ini"
        sed -i "s/^;zend_extension=${ext}/zend_extension=${ext}/" "$php_ini"
    done

    if printf '%s\n' "${PHP_EXTENSIONS[@]}" | grep -q "^xdebug$"; then
        spin "Installing xdebug..." \
            pacman -S --noconfirm --needed xdebug
    fi

    spin "Installing Composer..." \
        bash -c "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"

    success "PHP $(php -r 'echo PHP_VERSION;') + Composer installed"
}

# ─────────────────────────────────────────────
# Node (fnm)
# ─────────────────────────────────────────────
NODE_VERSION="lts"
NODE_PM="none"

configure_node() {
    section "Node.js"

    NODE_VERSION=$(gum choose \
        --header "Node version" \
        --header.foreground 240 \
        --selected.foreground 212 \
        --cursor.foreground 99 \
        "lts" \
        "latest" \
    )
    NODE_VERSION="${NODE_VERSION:-lts}"

    NODE_PM=$(gum choose \
        --header "Additional package manager" \
        --header.foreground 240 \
        --selected.foreground 212 \
        --cursor.foreground 99 \
        "none" \
        "pnpm" \
        "yarn" \
    )
    NODE_PM="${NODE_PM:-none}"
}

install_node() {
    if command -v fnm &>/dev/null; then
        warn "fnm is already installed, skipping"
        return
    fi

    spin "Installing fnm..." \
        bash -c "curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /usr/local/bin --skip-shell"

    export PATH="/usr/local/bin:$PATH"

    if [ "$NODE_VERSION" = "lts" ]; then
        spin "Installing Node LTS..." fnm install --lts
        fnm default "$(fnm list | grep lts | tail -1 | awk '{print $2}')"
    else
        spin "Installing Node latest..." fnm install latest
        fnm default latest
    fi

    if [ "$NODE_PM" = "pnpm" ]; then
        spin "Installing pnpm..." bash -c "fnm exec --using=default npm install -g pnpm"
    elif [ "$NODE_PM" = "yarn" ]; then
        spin "Installing yarn..." bash -c "fnm exec --using=default npm install -g yarn"
    fi

    success "Node installed via fnm"
}

# ─────────────────────────────────────────────
# Rust
# ─────────────────────────────────────────────
RUST_PROFILE="default"
RUST_USER=""

configure_rust() {
    section "Rust"

    RUST_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Install for user › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    RUST_USER="${RUST_USER:-$USER}"

    RUST_PROFILE=$(gum choose \
        --header "rustup profile" \
        --header.foreground 240 \
        --selected.foreground 212 \
        --cursor.foreground 99 \
        "default" \
        "minimal" \
        "complete" \
    )
    RUST_PROFILE="${RUST_PROFILE:-default}"
}

install_rust() {
    if command -v rustc &>/dev/null; then
        warn "Rust is already installed ($(rustc --version)), skipping"
        return
    fi

    spin "Installing Rust..." \
        sudo -u "$RUST_USER" bash -c "
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
            sh -s -- -y --no-modify-path --profile $RUST_PROFILE
        "

    success "Rust installed via rustup"
}
