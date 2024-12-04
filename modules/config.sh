#!/usr/bin/env bash

CONFIG_DIR=${XDG_CONFG_HOME:-$HOME/.config}/nixhelp
TEMPLATE_DIR="$CONFIG_DIR/templates"
LOG_DIR="$CONFIG_DIR/logs"
SSH_DIR="$HOME/.ssh"

# Generate the directories

mkdir -p "$CONFIG_DIR" "$TEMPLATE_DIR" "$LOG_DIR"
