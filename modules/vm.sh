#!/usr/bin/env bash
deploy_config() {
  local hostname="$1"
  local config_type="$2"

  #update this later
  local remote_path="/etc/nixos"

  if [[ "$config_type" == "home-manager" ]]; then
    remote_path="$HOME/.config/home-manager"
  fi

  log "INFO" "syncing configuration to $hostname..."
  rsync -avz --delete \
    --exclude '.git/' \
    --exclude 'result/' \
    ./ "{$hostname}:${remote_path}/"

  log "INFO" "Buiding configuration on $hostname"

  case "$config_type" in
  "nixos")
    ssh "$hostname" "sudo nixos-rebuild switch --flake ${remote_path}#${hostname}"
    ;;
  "home-manager")
    ssh "$hostname" "sudo home-manager switch --flake ${remote_path}#${hostname}"
    ;;
  "both")
    ssh "$hostname" "sudo nixos-rebuild switch --flake ${remote_path}#${hostname} && home-manager switch --flake ${remote_path}#${hostname}"
    ;;
  esac
}

create_vm_host() {
  local hostname="$1"

  local ip_address=$(prompt_input "Enter VM IP address" "192.168.1.100")
  local user=$(prompt_input "Enter SSH user" "nixos")
  local config_type=$(prompt_input "Configuration type (nixos/home-manager/both)" "both")h

  mkdir -p "hosts/nixos/$hostname"
  cat >"hosts/nixos/$hostname/default.nix" <<EOF
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
  ];


  networking.hostName = "$hostname";
}
EOF

  setup_ssh "$hostname" "$ip_address" "$user"

  log "INFO" "Generating hardware configuration for $hostname..."
  ssh "$hostname" "sudo nixos-generate-config --show-hardware-config" >"hosts/nixos/$hostname/hardware-configuration.nix"

  deploy_config "$hostname" "$config_type"
  log "INFO" "VM host $hostname setup complete"
}

update_host() {
  local hostname="$1"
  local config_type="$2"

  if [ -z $config_type ]; then
    config_type$(prompt_input "Configuration type (nixos/home-manager/both)" "both")
  fi

  deploy_config "$hostname" "$config_type"
  log "INFO" "Updated $hostname configuration"
}
