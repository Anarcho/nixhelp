#!/usr/bin/env bash

create_host() {
  local hostname="$1"
  local host_type="${2:-physical}" # Default to physical host if not specified

  if [ -z "$hostname" ]; then
    error "Hostname is required"
  fi

  # Validate host type
  case "$host_type" in
  physical | virtual) ;;
  *)
    error "Invalid host type. Must be physical or virtual"
    ;;
  esac

  # Check if host already exists
  if [ -d "hosts/nixos/$hostname" ]; then
    error "Host configuration already exists for $hostname"
  fi

  # Create host directory structure
  mkdir -p "hosts/nixos/$hostname"

  # Create default NixOS configuration
  cat >"hosts/nixos/$hostname/default.nix" <<EOF
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
  ];

  networking.hostName = "$hostname";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic system configuration
  system.stateVersion = "23.11"; # Update this to match your NixOS version

  # Import optional features
  # imports = [
  #   ../../modules/nixos/desktop
  #   ../../modules/nixos/development
  # ];
}
EOF

  # Create common directory if it doesn't exist
  if [ ! -d "hosts/common" ]; then
    mkdir -p "hosts/common"
    cat >"hosts/common/default.nix" <<EOF
{ config, pkgs, ... }:

{
  # Common configuration shared between all hosts

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Enable system features
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };
}
EOF
  fi

  # If this is a physical host, attempt to generate hardware config
  if [ "$host_type" = "physical" ] && [ -f "/etc/nixos/hardware-configuration.nix" ]; then
    cp "/etc/nixos/hardware-configuration.nix" "hosts/nixos/$hostname/hardware-configuration.nix"
    info "Copied local hardware configuration"
  else
    # Create placeholder hardware configuration
    cat >"hosts/nixos/$hostname/hardware-configuration.nix" <<EOF
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Add your hardware configuration here
  # This is a placeholder and should be replaced with your actual hardware configuration
}
EOF
    warn "Created placeholder hardware configuration. Remember to update it with actual hardware details."
  fi

  # Register the host
  register_host "$hostname" "$host_type"

  info "Created new host: $hostname (Type: $host_type)"
  info "Remember to:"
  info "1. Update hardware-configuration.nix with your actual hardware details"
  info "2. Add desired modules in hosts/nixos/$hostname/default.nix"
  info "3. Update the system.stateVersion if needed"
}

update_host() {
  local hostname="$1"
  local config_path="hosts/nixos/$hostname"

  if [ ! -d "$config_path" ]; then
    error "Host configuration not found for $hostname"
  fi

  # For physical hosts, update hardware configuration
  if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
    cp "/etc/nixos/hardware-configuration.nix" "$config_path/hardware-configuration.nix"
    info "Updated hardware configuration for $hostname"
  fi

  info "Host $hostname configuration updated"
}

delete_host() {
  local hostname="$1"
  local config_path="hosts/nixos/$hostname"

  if [ ! -d "$config_path" ]; then
    error "Host configuration not found for $hostname"
  fi

  # Create backup before deletion
  local backup_dir="$CONFIG_DIR/backups/hosts/$hostname-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  cp -r "$config_path" "$backup_dir"

  # Remove configuration directory
  rm -rf "$config_path"

  # Remove from registry
  # Note: This assumes you have a function to remove from registry
  cleanup_ssh_config "$hostname"

  info "Deleted host: $hostname (Backup created at $backup_dir)"
}
