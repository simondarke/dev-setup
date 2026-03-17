#!/usr/bin/env bash

section() {
    echo ""
    gum style \
        --foreground 99 \
        --bold \
        "── $1 ──────────────────────────"
    echo ""
}

spin() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}
