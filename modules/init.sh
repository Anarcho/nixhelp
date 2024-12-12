#!/usr/bin/env bash
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
CONFIG_DIR="$HOME/.config/nix-config"

init_config() {
  local target_dir=$1

  # Set up project directory
  echo "Creating config directory: $target_dir"
  setup_directory $target_dir

  # setup flake
  echo "Creating nix flake..."
  create_flake $target_dir

  # setup git
  echo "Setting up git..."
  configure_git $target_dir
}

init_registry() {
  local target_dir=$1
}

setup_directory() {
  local target_dir="${1:-.}"

  # Create the config in directory
  local structure=(
    # hosts structure
    hosts/common
    hosts/nixos
    hosts/nixos/desktop
    hosts/nixos/vm

    #home structure
    home/username
    home/username/programs

    #modules structure - nixos
    modules/nixos/desktop
    module/nixos/services

    #modules structure - home-manager
    modules/home-manager/desktop
    module/home-manager/programs

    #Modules structure - dev
    module/dev/

    #Tests structure
    tests/vm-tests
    tests/build-tests

    #Templates structure
    templates/hosts
    templates/users
    templates/modules

  )

  if [[ -d $target_dir ]]; then
    echo "Directory $target_dir already exists"
    exit 1
  else
    for dir in "${structure[@]}"; do
      mkdir -p "$target_dir/$dir"
    done
  fi
}

create_flake() {
  local target_dir="$1"
  cat <<EOF >"$target_dir/flake.nix"
{
  description = "My system configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/desktop/configuration.nix
          ./modules/nixos/desktop
          ./modules/nixos/services
        ]
      };
      vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/vm/configuration.nix
          ./modules/nixos/desktop
          ./modules/nixos/services
        ];
      };
    };
    homeConfigurations = {
      desktop = home-manager.lib.homeManagerConfiguration {
        homeDirectory = "/home/username";
        configuration = ./home/username/home.nix;
        programs = ./modules/home-manager/programs;
      };
    };
  };
}
EOF
}

configure_git() {
  local target_dir=$1

  # Set up git
  git init $target_dir

  # Add gitignore
  cat <<EOF >"$target_dir/.gitignore"

EOF

  cd $target_dir
  git add .
  git commit -a -m 'Initial commit'
}

# run prompts
init_config "$1"
