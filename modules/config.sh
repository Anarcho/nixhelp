#!/usr/bin/env bash

# Base directories
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nixhelp"
TEMPLATE_DIR="$CONFIG_DIR/templates"
LOG_DIR="$CONFIG_DIR/logs"
REGISTRY_DIR="$CONFIG_DIR/registry"
SSH_DIR="$HOME/.ssh"

# Registry files
HOSTS_REGISTRY="$REGISTRY_DIR/hosts.json"
USERS_REGISTRY="$REGISTRY_DIR/users.json"
MODULES_REGISTRY="$REGISTRY_DIR/modules.json"

# Create required directories
mkdir -p "$CONFIG_DIR" "$TEMPLATE_DIR" "$LOG_DIR" "$REGISTRY_DIR"
