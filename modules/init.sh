#!/usr/bin/env bash

init_config() {
  local target_dir="$1"

  if [ -z "$target_dir" ]; then
    target_dir=$(prompt "Enter directory for NixOS configuration" ".")
  fi

  # Convert to absolute path
  target_dir=$(realpath "$target_dir")

  if [ -d "$target_dir" ] && [ "$(ls -A "$target_dir")" ]; then
    error "Directory $target_dir is not empty"
  fi

  info "Initializing NixOS configuration in $target_dir"

  # Create base directory structure
  mkdir -p "$target_dir"/{hosts/{nixos,common},modules/{nixos,home-manager,dev},home}

  # Initialize registry
  init_registry

  # Create flake.nix
  cat >"$target_dir/flake.nix" <<'EOF'
{
  description = "NixOS System Configuration";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: Add more inputs here
    # hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";  # Update if needed
      pkgs = nixpkgs.legacyPackages.${system};

      # Helper to create host configurations
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixos/${hostname}
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
        specialArgs = { inherit inputs; };
      };

      # Helper to create home-manager configurations
      mkHome = username: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home/${username} ];
        extraSpecialArgs = { inherit inputs; };
      };
    in {
      nixosConfigurations = {
        # Hosts will be added here
        # example = mkHost "example";
      };

      homeConfigurations = {
        # Users will be added here
        # username = mkHome "username";
      };
    };
}
EOF

  # Create common configuration
  mkdir -p "$target_dir/hosts/common"
  cat >"$target_dir/hosts/common/default.nix" <<'EOF'
{ config, pkgs, ... }:

{
  # Common configuration shared between all hosts

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
  ];

  # System-wide settings
  time.timeZone = "UTC";  # Update this
  i18n.defaultLocale = "en_US.UTF-8";

  # Basic security settings
  security.sudo.wheelNeedsPassword = true;
}
EOF

  # Create gitignore
  cat >"$target_dir/.gitignore" <<'EOF'
result
result-*
.direnv
.envrc
EOF

  # Initialize git repository
  if command -v git >/dev/null 2>&1; then
    cd "$target_dir"
    git init
    git add .
    git commit -m "Initial NixOS configuration"
  fi

  # Start interactive configuration
  configure_initial_setup "$target_dir"
}
#!/usr/bin/env bash

configure_initial_setup() {
  local target_dir="$1"
  local hostname=""
  local username=""

  info "Starting initial configuration..."

  # Configure first host
  local create_host=$(prompt "Would you like to create your first host? (yes/no)" "yes")
  if [[ "${create_host,,}" =~ ^(yes|y)$ ]]; then
    hostname=$(prompt "Enter hostname" "")
    local host_type=$(prompt "Is this a virtual machine? (yes/no)" "no")

    if [[ "${host_type,,}" =~ ^(yes|y)$ ]]; then
      create_vm_host "$hostname"
    else
      create_host "$hostname" "physical"
    fi
  fi

  # Configure first user
  local create_user=$(prompt "Would you like to create your first user? (yes/no)" "yes")
  if [[ "${create_user,,}" =~ ^(yes|y)$ ]]; then
    username=$(prompt "Enter username" "")
    if [ -n "$username" ]; then
      if [ -n "$hostname" ]; then
        create_user "$username" "$hostname"
      else
        create_user "$username"
      fi
    fi
  fi

  # Configure development environments
  local setup_dev=$(prompt "Would you like to set up development environments? (yes/no)" "no")
  if [[ "${setup_dev,,}" =~ ^(yes|y)$ ]]; then
    for env in "rust" "python" "cpp" "zig" "bash"; do
      local enable_env=$(prompt "Enable $env development environment? (yes/no)" "no")
      if [[ "${enable_env,,}" =~ ^(yes|y)$ ]]; then
        create_module "$env" "dev"
        if [ -n "$username" ]; then
          enable_module "$env" "dev" "$username"
        fi
      fi
    done
  fi

  print_next_steps "$target_dir"
}

# Rest of your init.sh functions remain the same

print_next_steps() {
  local target_dir="$1"

  echo -e "\nConfiguration Initialized Successfully!"
  echo "----------------------------------------"
  echo "Your NixOS configuration has been created in: $target_dir"
  echo
  echo "Next steps:"
  echo "1. Review the generated configurations"
  echo "2. Update the time.timeZone in hosts/common/default.nix"
  echo "3. Customize your host configurations in hosts/nixos/"
  echo "4. Customize your user configurations in home/"
  echo "5. Add additional modules as needed using 'nixhelp module add'"
  echo
  echo "To deploy your configuration:"
  echo "  nixhelp deploy <hostname> [nixos|home-manager|both]"
  echo
  echo "For more information:"
  echo "  nixhelp --help"
}
