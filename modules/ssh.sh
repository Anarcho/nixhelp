#!/usr/bin/env bash

setup_ssh() {
  local hostname="$1"
  local ip_address="$2"
  local user="$"
  local key_path="$SSH_DIR/$hostname"

  # generate SSH key if it doesn't exist

  if [ ! -f "${key_path}" ]; then
    log "INFO" "Generating SSH key for $hostname"
    ssh-keygen -t ed25519 -C "$hostname" -f "$key_path" -N ""
  fi

  # Grep ssh config entry
  
  if ! grep -q "Host $hostname" "$SSH_DIR/config" 2>/dev/null; then
    {
      echo -e "\nHost $hostname"
      echo -e "   HostName $ip_address"
      echo -e "   User $user"
      echo -e "   IdentityFile $key_path"
    } >> "$SSH_DIR/config"
  if

  # copy ssh key to remote host
  
  log "INFO" "Copying SSH key to remote host..."
  ssh-copy-id -i "${key_path}.pub" "{$user}@{$ip_address}"
}
