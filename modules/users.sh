#!/usr/bin/env bash

create_module() {
  local module_name="$1"
  local module_type="$2" # nixos, home-manager, or dev

  if [ -z "$module_name" ] || [ -z "$module_type" ]; then
    error "Module name and type are required"
  fi

  # Validate module type
  case "$module_type" in
  nixos | home-manager | dev) ;;
  *)
    error "Invalid module type. Must be nixos, home-manager, or dev"
    ;;
  esac

  local module_path="modules/$module_type/$module_name"

  # Check if module already exists
  if [ -d "$module_path" ]; then
    error "Module $module_name already exists for type $module_type"
  fi

  # Create module directory
  mkdir -p "$module_path"

  # Create appropriate module configuration based on type
  case "$module_type" in
  "nixos")
    create_nixos_module "$module_name" "$module_path"
    ;;
  "home-manager")
    create_home_manager_module "$module_name" "$module_path"
    ;;
  "dev")
    create_dev_module "$module_name" "$module_path"
    ;;
  esac

  # Register module
  register_module "$module_name" "$module_type" "$module_path"

  info "Created new $module_type module: $module_name"
}

create_nixos_module() {
  local module_name="$1"
  local module_path="$2"

  cat >"$module_path/default.nix" <<EOF
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.$module_name;
in {
  options.modules.$module_name = {
    enable = mkEnableOption "Enable $module_name module";
  };

  config = mkIf cfg.enable {
    # Add your module configuration here

    environment.systemPackages = with pkgs; [
      # Add required packages
    ];

    # Add services, configuration, etc.
  };
}
EOF
}

create_home_manager_module() {
  local module_name="$1"
  local module_path="$2"

  cat >"$module_path/default.nix" <<EOF
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.$module_name;
in {
  options.modules.$module_name = {
    enable = mkEnableOption "Enable $module_name module";
  };

  config = mkIf cfg.enable {
    # Add your module configuration here

    home.packages = with pkgs; [
      # Add required packages
    ];

    # Add program configurations, files, etc.
  };
}
EOF
}

create_dev_module() {
  local module_name="$1"
  local module_path="$2"

  cat >"$module_path/default.nix" <<EOF
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.dev.$module_name;
in {
  options.modules.dev.$module_name = {
    enable = mkEnableOption "$module_name development environment";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Add development tools and dependencies
    ];

    programs = {
      # Add development tool configurations
    };

    # Add language-specific settings, environment variables, etc.
  };
}
EOF

  # Create specific configurations based on development environment
  case "$module_name" in
  "rust")
    configure_rust_module "$module_path"
    ;;
  "python")
    configure_python_module "$module_path"
    ;;
  "cpp")
    configure_cpp_module "$module_path"
    ;;
  "zig")
    configure_zig_module "$module_path"
    ;;
  "bash")
    configure_bash_module "$module_path"
    ;;
  esac
}

configure_rust_module() {
  local module_path="$1"
  cat >"$module_path/default.nix" <<EOF
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.dev.rust;
in {
  options.modules.dev.rust = {
    enable = mkEnableOption "Rust development environment";

    withLsp = mkOption {
      type = types.bool;
      default = true;
      description = "Enable rust-analyzer LSP support";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
    ] ++ (if cfg.withLsp then [ rust-analyzer ] else [ ]);

    home.sessionVariables = {
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
    };
  };
}
EOF
}

# Add similar configure_*_module functions for other development environments

enable_module() {
  local module_name="$1"
  local module_type="$2"
  local target="$3" # hostname or username

  # Verify module exists
  if [ ! -d "modules/$module_type/$module_name" ]; then
    error "Module $module_name not found for type $module_type"
  fi

  # Add module to appropriate configuration
  case "$module_type" in
  "nixos")
    add_module_to_host "$module_name" "$target"
    ;;
  "home-manager")
    add_module_to_user "$module_name" "$target"
    ;;
  "dev")
    add_dev_module_to_user "$module_name" "$target"
    ;;
  esac

  info "Enabled $module_type module $module_name for $target"
}

add_module_to_host() {
  local module_name="$1"
  local hostname="$2"
  local config_file="hosts/nixos/$hostname/default.nix"

  # Add module to host configuration
  sed -i "/imports = \[/a \    ../../modules/nixos/$module_name" "$config_file"
  echo "  modules.$module_name.enable = true;" >>"$config_file"
}

add_module_to_user() {
  local module_name="$1"
  local username="$2"
  local config_file="home/$username/default.nix"

  # Add module to user configuration
  sed -i "/imports = \[/a \    ../modules/home-manager/$module_name" "$config_file"
  echo "  modules.$module_name.enable = true;" >>"$config_file"
}

add_dev_module_to_user() {
  local module_name="$1"
  local username="$2"
  local config_file="home/$username/default.nix"

  # Add development module to user configuration
  sed -i "/imports = \[/a \    ../modules/dev/$module_name" "$config_file"
  echo "  modules.dev.$module_name.enable = true;" >>"$config_file"
}
