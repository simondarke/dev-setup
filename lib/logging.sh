#!/usr/bin/env bash

info()    { gum log --level info  "$*"; }
success() { gum log --level info  "✓ $*"; }
warn()    { gum log --level warn  "$*"; }
error()   { gum log --level error "$*"; exit 1; }
