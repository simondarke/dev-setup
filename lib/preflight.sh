#!/usr/bin/env bash

# Preflight state — these get populated during run_preflight
PREFLIGHT_USERNAME=""
PREFLIGHT_TIMEZONE=""
PREFLIGHT_HOSTNAME=""
PREFLIGHT_GIT_NAME=""
PREFLIGHT_GIT_EMAIL=""
PREFLIGHT_CREATE_USER=false

run_preflight() {
  section "Preflight"
  info "Let's get some basic settings sorted before installing anything..."

  _preflight_timezone
  _preflight_hostname
  _preflight_user
  _preflight_git
  _preflight_ssh
  _preflight_wsl_conf

  success "Preflight complete"
}

# ─────────────────────────────────────────────
# Timezone
# ─────────────────────────────────────────────
_preflight_timezone() {
  PREFLIGHT_TIMEZONE=$(
    gum input \
      --placeholder "Europe/London" \
      --value "Europe/London" \
      --prompt "Timezone › " \
      --prompt.foreground 99 \
      --width 40
  )
  PREFLIGHT_TIMEZONE="${PREFLIGHT_TIMEZONE:-Europe/London}"

  if [ ! -f "/usr/share/zoneinfo/$PREFLIGHT_TIMEZONE" ]; then
    warn "Timezone '$PREFLIGHT_TIMEZONE' not found, defaulting to Europe/London"
    PREFLIGHT_TIMEZONE="Europe/London"
  fi

  ln -sf "/usr/share/zoneinfo/$PREFLIGHT_TIMEZONE" /etc/localtime
  success "Timezone set to $PREFLIGHT_TIMEZONE"
}

# ─────────────────────────────────────────────
# Hostname
# ─────────────────────────────────────────────
_preflight_hostname() {
  PREFLIGHT_HOSTNAME=$(
    gum input \
      --placeholder "arch-wsl" \
      --value "arch-wsl" \
      --prompt "Hostname  › " \
      --prompt.foreground 99 \
      --width 40
  )
  PREFLIGHT_HOSTNAME="${PREFLIGHT_HOSTNAME:-arch-wsl}"

  echo "$PREFLIGHT_HOSTNAME" >/etc/hostname
  success "Hostname set to $PREFLIGHT_HOSTNAME"
}

# ─────────────────────────────────────────────
# User creation
# ─────────────────────────────────────────────
_preflight_user() {
  PREFLIGHT_USERNAME=$(
    gum input \
      --placeholder "simon" \
      --prompt "Username  › " \
      --prompt.foreground 99 \
      --width 40
  )
  PREFLIGHT_USERNAME="${PREFLIGHT_USERNAME:-simon}"

  if id "$PREFLIGHT_USERNAME" &>/dev/null; then
    info "User '$PREFLIGHT_USERNAME' already exists, skipping creation"
    PREFLIGHT_CREATE_USER=false
    return
  fi

  PREFLIGHT_CREATE_USER=true

  local password password_confirm
  password=$(
    gum input \
      --password \
      --placeholder "password" \
      --prompt "Password  › " \
      --prompt.foreground 99 \
      --width 40
  )
  password_confirm=$(
    gum input \
      --password \
      --placeholder "confirm password" \
      --prompt "Confirm   › " \
      --prompt.foreground 99 \
      --width 40
  )

  if [ "$password" != "$password_confirm" ]; then
    error "Passwords do not match"
  fi

  useradd -m -G wheel -s /bin/bash "$PREFLIGHT_USERNAME"
  echo "$PREFLIGHT_USERNAME:$password" | chpasswd
  unset password password_confirm

  # Enable wheel group in sudoers
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  success "User '$PREFLIGHT_USERNAME' created"
}

# ─────────────────────────────────────────────
# Git config
# ─────────────────────────────────────────────
_preflight_git() {
  gum style --foreground 240 "Git config:"

  PREFLIGHT_GIT_NAME=$(
    gum input \
      --placeholder "Simon Hamp" \
      --prompt "Git name  › " \
      --prompt.foreground 99 \
      --width 40
  )

  PREFLIGHT_GIT_EMAIL=$(
    gum input \
      --placeholder "simon@example.com" \
      --prompt "Git email › " \
      --prompt.foreground 99 \
      --width 40
  )

  local git_config
  if [ "$PREFLIGHT_CREATE_USER" = true ]; then
    git_config="/home/$PREFLIGHT_USERNAME/.gitconfig"
  else
    git_config="$HOME/.gitconfig"
  fi

  cat >"$git_config" <<EOF
[user]
    name = ${PREFLIGHT_GIT_NAME}
    email = ${PREFLIGHT_GIT_EMAIL}

[core]
    editor = nvim
    autocrlf = input
    pager = less -FRX

[init]
    defaultBranch = main

[pull]
    rebase = true

[push]
    autoSetupRemote = true

[fetch]
    prune = true

[alias]
    lg = log --oneline --graph --decorate --all
    undo = reset HEAD~1 --mixed
    stash-all = stash save --include-untracked

[color]
    ui = auto

[url "git@github.com:"]
    insteadOf = https://github.com/
EOF

  [ "$PREFLIGHT_CREATE_USER" = true ] && chown "$PREFLIGHT_USERNAME:$PREFLIGHT_USERNAME" "$git_config"
  success "Git config written"
}

# ─────────────────────────────────────────────
# SSH key
# ─────────────────────────────────────────────
_preflight_ssh() {
  local ssh_dir
  if [ "$PREFLIGHT_CREATE_USER" = true ]; then
    ssh_dir="/home/$PREFLIGHT_USERNAME/.ssh"
  else
    ssh_dir="$HOME/.ssh"
  fi

  local key_path="$ssh_dir/id_ed25519"

  if [ -f "$key_path" ]; then
    info "SSH key already exists at $key_path, skipping"
    return
  fi

  if ! gum confirm "Generate an SSH key for GitHub?"; then
    info "Skipping SSH key generation"
    return
  fi

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  ssh-keygen -t ed25519 -C "$PREFLIGHT_GIT_EMAIL" -f "$key_path" -N ""

  if [ "$PREFLIGHT_CREATE_USER" = true ]; then
    chown -R "$PREFLIGHT_USERNAME:$PREFLIGHT_USERNAME" "$ssh_dir"
  fi

  success "SSH key generated"
  echo ""
  gum style --foreground 212 --bold "Your public key:"
  gum style --foreground 255 --border rounded --padding "0 2" "$(cat "${key_path}.pub")"
  echo ""
  gum style --foreground 240 "Add this key to GitHub at: https://github.com/settings/ssh/new"
  echo ""

  gum confirm "Done adding the key to GitHub? Press Enter to continue..." \
    --affirmative "Yes, continue" \
    --negative "Skip for now"

  # Add github to known hosts so first clone doesn't prompt
  mkdir -p "$ssh_dir"
  ssh-keyscan github.com >>"$ssh_dir/known_hosts" 2>/dev/null
  [ "$PREFLIGHT_CREATE_USER" = true ] && chown "$PREFLIGHT_USERNAME:$PREFLIGHT_USERNAME" "$ssh_dir/known_hosts"
  success "github.com added to known_hosts"
}

# ─────────────────────────────────────────────
# WSL config
# ─────────────────────────────────────────────
_preflight_wsl_conf() {
  cat >/etc/wsl.conf <<EOF
[boot]
systemd=true

[user]
default=${PREFLIGHT_USERNAME}

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
  success "WSL config written to /etc/wsl.conf"
}
