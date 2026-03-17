#!/usr/bin/env bash

# ─────────────────────────────────────────────
# Docker
# ─────────────────────────────────────────────
DOCKER_USER=""
DOCKER_COMPOSE=true
DOCKER_BUILDX=true

configure_docker() {
    section "Docker"

    DOCKER_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Add user to docker group › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    DOCKER_USER="${DOCKER_USER:-$USER}"

    local selected
    selected=$(gum choose \
        --no-limit \
        --selected "docker-compose,docker-buildx" \
        --header "Additional components" \
        --header.foreground 240 \
        --selected.foreground 212 \
        --cursor.foreground 99 \
        "docker-compose" \
        "docker-buildx" \
    )

    echo "$selected" | grep -q "docker-compose" && DOCKER_COMPOSE=true || DOCKER_COMPOSE=false
    echo "$selected" | grep -q "docker-buildx"  && DOCKER_BUILDX=true  || DOCKER_BUILDX=false
}

install_docker() {
    if command -v docker &>/dev/null; then
        warn "Docker is already installed ($(docker --version)), skipping"
        return
    fi

    local packages=(docker)
    [ "$DOCKER_COMPOSE" = true ] && packages+=(docker-compose)
    [ "$DOCKER_BUILDX" = true ]  && packages+=(docker-buildx)

    spin "Installing Docker..." \
        pacman -S --noconfirm --needed "${packages[@]}"

    systemctl enable docker

    if [ -n "$DOCKER_USER" ] && id "$DOCKER_USER" &>/dev/null; then
        usermod -aG docker "$DOCKER_USER"
        success "Added $DOCKER_USER to docker group"
    fi

    success "Docker installed"
}

# ─────────────────────────────────────────────
# Kubernetes tools
# ─────────────────────────────────────────────
K8S_TOOLS=()
K8S_USER=""

configure_kubernetes() {
    section "Kubernetes Tools"

    K8S_USER=$(gum input \
        --placeholder "simon" \
        --prompt "Install for user › " \
        --prompt.foreground 99 \
        --width 40 \
    )
    K8S_USER="${K8S_USER:-$USER}"

    local selected
    selected=$(gum choose \
        --no-limit \
        --selected "kubectl,helm,k9s,kubectx" \
        --header "Select tools to install" \
        --header.foreground 240 \
        --selected.foreground 212 \
        --cursor.foreground 99 \
        "kubectl" \
        "helm" \
        "k9s" \
        "kubectx" \
    )

    mapfile -t K8S_TOOLS <<< "$selected"
}

install_kubernetes() {
    local pacman_tools=()
    local aur_tools=()

    for tool in "${K8S_TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            warn "$tool is already installed, skipping"
            continue
        fi
        case "$tool" in
            kubectl|helm) pacman_tools+=("$tool") ;;
            k9s|kubectx)  aur_tools+=("$tool") ;;
        esac
    done

    if [ "${#pacman_tools[@]}" -gt 0 ]; then
        spin "Installing ${pacman_tools[*]}..." \
            pacman -S --noconfirm --needed "${pacman_tools[@]}"
    fi

    if [ "${#aur_tools[@]}" -gt 0 ]; then
        _ensure_yay
        spin "Installing ${aur_tools[*]} from AUR..." \
            sudo -u "$K8S_USER" yay -S --noconfirm "${aur_tools[@]}"
    fi

    success "Kubernetes tools installed"
}

_ensure_yay() {
    if command -v yay &>/dev/null; then
        return
    fi

    info "Installing yay (AUR helper)..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    chown "$K8S_USER:$K8S_USER" "$tmp_dir"

    sudo -u "$K8S_USER" bash -c "
        git clone https://aur.archlinux.org/yay.git '$tmp_dir/yay'
        cd '$tmp_dir/yay'
        makepkg -si --noconfirm
    "
    rm -rf "$tmp_dir"
    success "yay installed"
}
