#!/usr/bin/env bash

check_existing_ssh_config() {
  local hostname="$1"
  local existing_config=""

  if grep -q "^Host ${hostname}$" "$SSH_DIR/config" 2>/dev/null; then
    # Extract existing config details
    local start_line=$(grep -n "^Host ${hostname}$" "$SSH_DIR/config" | cut -d: -f1)
    local config_block=$(sed -n "${start_line},/^$/p" "$SSH_DIR/config")

    local existing_ip=$(echo "$config_block" | grep "HostName" | awk '{print $2}')
    local existing_user=$(echo "$config_block" | grep "User" | awk '{print $2}')

    info "Found existing SSH configuration for $hostname:"
    echo "Current IP: $existing_ip"
    echo "Current User: $existing_user"

    local use_existing=$(prompt "Would you like to use this existing configuration? (yes/no)" "yes")

    if [[ "${use_existing,,}" =~ ^(yes|y)$ ]]; then
      echo "$existing_ip:$existing_user"
      return 0
    fi
  fi
  return 1
}
setup_ssh() {
  local hostname="$1"
  local ip_address="$2"
  local user="$3"
  local key_path="$SSH_DIR/$hostname"
  local existing_config

  # Create SSH directory if it doesn't exist
  mkdir -p "$SSH_DIR"
  touch "$SSH_DIR/config"

  # Check for existing configuration
  if existing_config=$(check_existing_ssh_config "$hostname"); then
    IFS=':' read -r ip_address user <<<"$existing_config"
    info "Using existing SSH configuration"
  fi

  # Check if we already have SSH access
  if ssh -q "$hostname" exit >/dev/null 2>&1; then
    info "SSH connection to $hostname already working"
    return 0
  fi

  # Generate SSH key if it doesn't exist
  if [ ! -f "${key_path}" ]; then
    info "Generating SSH key for $hostname"
    ssh-keygen -t ed25519 -C "$hostname" -f "$key_path" -N "" || error "Failed to generate SSH key"
  else
    info "Using existing SSH key at ${key_path}"
  fi

  # Update SSH config
  if ! grep -q "^Host $hostname$" "$SSH_DIR/config" 2>/dev/null; then
    info "Adding SSH config entry for $hostname"
    {
      echo -e "\nHost $hostname"
      echo -e "    HostName $ip_address"
      echo -e "    User $user"
      echo -e "    IdentityFile $key_path"
    } >>"$SSH_DIR/config"
  else
    info "Updating SSH config entry for $hostname"
    sed -i.bak "/^Host $hostname$/,/^$/ c\
Host $hostname\n\
    HostName $ip_address\n\
    User $user\n\
    IdentityFile $key_path" "$SSH_DIR/config"
  fi

  # Wait for SSH to be available
  info "Waiting for SSH availability..."
  for i in {1..30}; do
    if nc -z "$ip_address" 22 2>/dev/null; then
      break
    fi
    echo -n "."
    sleep 1
  done
  echo ""

  # Test SSH connection before copying key
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$hostname" exit >/dev/null 2>&1; then
    info "Testing SSH connection with password authentication..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${user}@${ip_address}" exit >/dev/null 2>&1; then
      info "SSH connection working with password authentication"
    else
      warn "Cannot establish SSH connection. You may need to manually set up SSH access"
      return 0
    fi
  else
    info "SSH connection already working"
    return 0
  fi

  # Copy SSH key to remote host
  info "Copying SSH key to remote host..."
  if ssh-copy-id -i "${key_path}.pub" "${user}@${ip_address}"; then
    info "SSH key successfully copied to remote host"
  else
    warn "Failed to copy SSH key. You may need to manually copy the key or the key might already exist"
  fi

  # Final connection test
  if ssh -q "$hostname" exit >/dev/null 2>&1; then
    info "SSH connection to $hostname successfully configured"
  else
    warn "SSH connection could not be established. You may need to:"
    echo "1. Manually copy the SSH key: ssh-copy-id -i ${key_path}.pub ${user}@${ip_address}"
    echo "2. Check the SSH service on the remote host"
    echo "3. Verify the IP address and username"
  fi
}
verify_ssh_connection() {
  local hostname="$1"

  if ! ssh -q "$hostname" exit >/dev/null 2>&1; then
    error "Unable to connect to $hostname via SSH"
  fi

  info "SSH connection to $hostname verified"
}

cleanup_ssh_config() {
  local hostname="$1"

  if [ -f "$SSH_DIR/config" ]; then
    sed -i.bak "/^Host $hostname$/,/^$/ d" "$SSH_DIR/config"
    info "Removed SSH configuration for $hostname"
  fi
}
