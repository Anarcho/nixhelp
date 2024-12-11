#!/usr/bin/env bash

# Initialize registry files if they don't exist
init_registry() {
  # Create registry directory if it doesn't exist
  mkdir -p "$REGISTRY_DIR"

  # Initialize hosts registry
  if [ ! -f "$HOSTS_REGISTRY" ]; then
    echo '{
            "hosts": {
                "physical": [],
                "virtual": []
            }
        }' >"$HOSTS_REGISTRY"
  fi

  # Initialize users registry
  if [ ! -f "$USERS_REGISTRY" ]; then
    echo '{
            "users": []
        }' >"$USERS_REGISTRY"
  fi

  # Initialize modules registry
  if [ ! -f "$MODULES_REGISTRY" ]; then
    echo '{
            "modules": {
                "nixos": [],
                "home-manager": [],
                "development": []
            }
        }' >"$MODULES_REGISTRY"
  fi
}

# Register a new host
register_host() {
  local hostname="$1"
  local host_type="$2"  # physical or virtual
  local ip_address="$3" # optional, mainly for VMs
  local temp_file

  if [ ! -f "$HOSTS_REGISTRY" ]; then
    error "Hosts registry not found. Run init_registry first."
  fi

  temp_file=$(mktemp)

  # Check if host already exists
  if jq -e --arg hostname "$hostname" '.hosts[] | select(.name == $hostname)' "$HOSTS_REGISTRY" >/dev/null; then
    error "Host $hostname already registered"
  fi

  # Add host to registry based on type
  if [ "$host_type" = "virtual" ] && [ -n "$ip_address" ]; then
    jq --arg hostname "$hostname" \
      --arg ip "$ip_address" \
      '.hosts.virtual += [{"name": $hostname, "ip": $ip}]' \
      "$HOSTS_REGISTRY" >"$temp_file"
  else
    jq --arg hostname "$hostname" \
      ".hosts.$host_type += [{\"name\": \$hostname}]" \
      "$HOSTS_REGISTRY" >"$temp_file"
  fi

  mv "$temp_file" "$HOSTS_REGISTRY"
  info "Registered host: $hostname (Type: $host_type)"
}

# Register a new user
register_user() {
  local username="$1"
  local hostname="$2" # optional, for user-host association
  local temp_file

  if [ ! -f "$USERS_REGISTRY" ]; then
    error "Users registry not found. Run init_registry first."
    return 1
  fi

  temp_file=$(mktemp)

  # Check if user already exists
  if jq -e --arg username "$username" '.users[] | select(.name == $username)' "$USERS_REGISTRY" >/dev/null; then
    if [ -n "$hostname" ]; then
      # Update existing user with new host
      jq --arg username "$username" \
        --arg hostname "$hostname" \
        '.users |= map(if .name == $username then . + {"host": $hostname} else . end)' \
        "$USERS_REGISTRY" >"$temp_file"
    else
      error "User $username already registered"
      return 1
    fi
  else
    # Add new user
    if [ -n "$hostname" ]; then
      jq --arg username "$username" \
        --arg hostname "$hostname" \
        '.users += [{"name": $username, "host": $hostname}]' \
        "$USERS_REGISTRY" >"$temp_file"
    else
      jq --arg username "$username" \
        '.users += [{"name": $username}]' \
        "$USERS_REGISTRY" >"$temp_file"
    fi
  fi

  mv "$temp_file" "$USERS_REGISTRY"
  info "Registered user: $username${hostname:+ on host: $hostname}"
}

# Register a new module
register_module() {
  local module_name="$1"
  local module_type="$2" # nixos, home-manager, or development
  local module_path="$3"
  local temp_file

  if [ ! -f "$MODULES_REGISTRY" ]; then
    error "Modules registry not found. Run init_registry first."
    return 1
  fi

  temp_file=$(mktemp)

  # Check if module already exists
  if jq -e --arg name "$module_name" --arg type "$module_type" \
    '.modules[$type][] | select(.name == $name)' "$MODULES_REGISTRY" >/dev/null; then
    error "Module $module_name already registered for type $module_type"
    return 1
  fi

  jq --arg name "$module_name" \
    --arg path "$module_path" \
    --arg type "$module_type" \
    '.modules[$type] += [{"name": $name, "path": $path}]' \
    "$MODULES_REGISTRY" >"$temp_file"

  mv "$temp_file" "$MODULES_REGISTRY"
  info "Registered module: $module_name (Type: $module_type)"
}

# List functions
list_hosts() {
  echo "Registered Hosts:"
  echo "----------------"
  echo "Physical Hosts:"
  jq -r '.hosts.physical[] | "  - \(.name)"' "$HOSTS_REGISTRY"
  echo "Virtual Hosts:"
  jq -r '.hosts.virtual[] | "  - \(.name) [\(.ip)]"' "$HOSTS_REGISTRY"
}

list_users() {
  echo "Registered Users:"
  echo "----------------"
  jq -r '.users[] | "  - \(.name)\(.host | if . then " on \(.)" else "" end)"' "$USERS_REGISTRY"
}

list_modules() {
  echo "Registered Modules:"
  echo "------------------"
  echo "NixOS Modules:"
  jq -r '.modules.nixos[] | "  - \(.name) [\(.path)]"' "$MODULES_REGISTRY"
  echo "Home Manager Modules:"
  jq -r '.modules.home-manager[] | "  - \(.name) [\(.path)]"' "$MODULES_REGISTRY"
  echo "Development Modules:"
  jq -r '.modules.development[] | "  - \(.name) [\(.path)]"' "$MODULES_REGISTRY"
}
