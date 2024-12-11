#!/usr/bin/env bash

#!/usr/bin/env bash

create_vm_host() {
  local hostname="$1"

  if [ -z "$hostname" ]; then
    error "Hostname is required"
  fi

  # Collect VM information
  local ip_address=$(prompt "Enter VM IP address" "192.168.1.100")
  local user=$(prompt "Enter SSH user" "nixos")
  local config_type=$(prompt "Select configuration type (nixos/home-manager/both)" "both")

  # Validate config_type
  case "$config_type" in
  nixos | home-manager | both) ;;
  *)
    error "Invalid configuration type. Must be nixos, home-manager, or both"
    ;;
  esac

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
}
EOF

  # Create home-manager configuration if needed
  if [ "$config_type" = "home-manager" ] || [ "$config_type" = "both" ]; then
    mkdir -p "home/$user/$hostname"
    cat >"home/$user/$hostname/default.nix" <<EOF
{ config, pkgs, ... }:

{
  home.username = "$user";
  home.homeDirectory = "/home/$user";

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # Add your user packages and configuration here
}
EOF
  fi

  # Set up SSH connection
  setup_ssh "$hostname" "$ip_address" "$user"

  # Register the host
  register_host "$hostname" "virtual" "$ip_address"

  if [ "$config_type" = "home-manager" ] || [ "$config_type" = "both" ]; then
    register_user "$user" "$hostname"
  fi

  # Copy configurations to remote machine
  info "Copying configurations to remote machine..."
  rsync -avz --delete \
    --exclude '.git/' \
    --exclude 'result/' \
    ./ "$hostname:/etc/nixos/"

  # Generate hardware configuration
  info "Generating hardware configuration..."
  generate_hardware_config "$hostname"

  # Deploy the configuration
  info "Deploying initial configuration..."
  deploy_config "$hostname" "$config_type"

  info "VM host $hostname setup complete"
}

generate_hardware_config() {
  local hostname="$1"
  local config_path="hosts/nixos/$hostname"

  info "Generating hardware configuration for $hostname..."

  # Remove existing hardware configuration if it exists
  if [ -f "$config_path/hardware-configuration.nix" ]; then
    info "Removing existing hardware configuration..."
    rm "$config_path/hardware-configuration.nix"
  fi

  # Generate new hardware configuration
  info "Generating new hardware configuration..."
  ssh -t "$hostname" 'sudo nixos-generate-config --show-hardware-config' >"$config_path/hardware-configuration.nix"

  if [ $? -ne 0 ]; then
    warn "Could not automatically generate hardware configuration."
    warn "Creating template hardware configuration instead."

    # Create a template hardware configuration
    cat >"$config_path/hardware-configuration.nix" <<EOF
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # TODO: Add your hardware configuration here
  # You can get this by running 'sudo nixos-generate-config --show-hardware-config'
  # on your target machine and copying the content here
}
EOF
  else
    info "Hardware configuration successfully generated"
  fi
}

create_vm_host() {
  local hostname="$1"

  if [ -z "$hostname" ]; then
    error "Hostname is required"
  fi

  # Collect VM information
  local ip_address=$(prompt "Enter VM IP address" "192.168.1.100")
  local user=$(prompt "Enter SSH user" "nixos")
  local config_type=$(prompt "Select configuration type (nixos/home-manager/both)" "both")

  # Validate config_type
  case "$config_type" in
  nixos | home-manager | both) ;;
  *)
    error "Invalid configuration type. Must be nixos, home-manager, or both"
    ;;
  esac

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
}
EOF

  # Set up SSH connection
  setup_ssh "$hostname" "$ip_address" "$user"

  # Generate hardware configuration
  generate_hardware_config "$hostname"

  # Register the host
  register_host "$hostname" "virtual" "$ip_address"

  # Create home-manager configuration if needed
  if [ "$config_type" = "home-manager" ] || [ "$config_type" = "both" ]; then
    mkdir -p "home/$user/$hostname"
    cat >"home/$user/$hostname/default.nix" <<EOF
{ config, pkgs, ... }:

{
  home.username = "$user";
  home.homeDirectory = "/home/$user";

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # Add your user packages and configuration here
}
EOF
    register_user "$user" "$hostname"
  fi

  # Deploy initial configuration
  deploy_config "$hostname" "$config_type"

  info "VM host $hostname setup complete"
}

update_hardware_config() {
  local hostname="$1"

  if [ -z "$hostname" ]; then
    error "Hostname is required"
  fi

  if [ ! -d "hosts/nixos/$hostname" ]; then
    error "Host configuration not found for $hostname"
  fi

  generate_hardware_config "$hostname"
}

cleanup_generations() {
  local hostname="$1"
  local keep_generations="${2:-3}" # Default to keeping 3 generations

  verify_ssh_connection "$hostname"

  info "Cleaning up old generations on $hostname..."
  ssh "$hostname" "sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system"
  ssh "$hostname" "sudo nixos-collect-garbage -d"

  info "Kept $keep_generations most recent generations"
}
