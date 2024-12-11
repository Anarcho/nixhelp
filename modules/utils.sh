#!/usr/bin/env bash

# Prompt user for input with default value
prompt() {
  local prompt_msg="$1"
  local default_val="$2"
  local response=""

  if [ -n "$default_val" ]; then
    read -r -p "$prompt_msg [$default_val]: " response
    echo "${response:-$default_val}"
  else
    while [ -z "$response" ]; do
      read -r -p "$prompt_msg: " response
    done
    echo "$response"
  fi
}
# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if we're running on NixOS
is_nixos() {
  [ -f "/etc/NIXOS" ]
}

# Validate hostname format
validate_hostname() {
  local hostname="$1"
  if [[ ! "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
    error "Invalid hostname format. Use only letters, numbers, and hyphens, starting with a letter or number."
  fi
}

# Validate username format
validate_username() {
  local username="$1"
  if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    error "Invalid username format. Use only lowercase letters, numbers, underscores, and hyphens, starting with a letter or underscore."
  fi
}

# Check if running with appropriate permissions
check_permissions() {
  local required_perm="$1"

  case "$required_perm" in
  "root")
    if [ "$EUID" -ne 0 ]; then
      error "This operation requires root privileges"
    fi
    ;;
  "user")
    if [ "$EUID" -eq 0 ]; then
      error "This operation should not be run as root"
    fi
    ;;
  esac
}

# Create backup of a file or directory
create_backup() {
  local target="$1"
  local backup_dir="$CONFIG_DIR/backups"
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_path="$backup_dir/$(basename "$target")-$timestamp"

  mkdir -p "$backup_dir"

  if [ -e "$target" ]; then
    cp -r "$target" "$backup_path"
    info "Created backup at $backup_path"
  fi
}

# Find the project root directory (where flake.nix is located)
find_project_root() {
  local current_dir="$PWD"
  while [ "$current_dir" != "/" ]; do
    if [ -f "$current_dir/flake.nix" ]; then
      echo "$current_dir"
      return 0
    fi
    current_dir="$(dirname "$current_dir")"
  done
  error "Not in a NixOS configuration project (no flake.nix found)"
}

# Add a new attribute to a Nix file
add_nix_attr() {
  local file="$1"
  local attr_path="$2"
  local value="$3"

  # Ensure the file exists
  if [ ! -f "$file" ]; then
    error "File $file does not exist"
  fi

  # Create temporary file
  local temp_file=$(mktemp)

  # Add attribute while preserving formatting
  awk -v path="$attr_path" -v val="$value" '
        /}[[:space:]]*$/ && !found {
            print "  " path " = " val ";"
            found=1
        }
        {print}
    ' "$file" >"$temp_file"

  mv "$temp_file" "$file"
}

# Check if nix flake is properly initialized
check_flake() {
  local dir="${1:-.}"

  if [ ! -f "$dir/flake.nix" ]; then
    error "No flake.nix found in $dir"
  fi

  if [ ! -f "$dir/flake.lock" ] && command_exists "nix"; then
    info "Initializing flake.lock..."
    (cd "$dir" && nix flake update)
  fi
}
