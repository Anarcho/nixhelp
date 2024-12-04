#!/usr/bin/env bash

init_config() {
  local target_dir="$1"

  if [ -z "$target_dir" ]; then
    target_dir="."
  fi

  #create base structure
  mkdir -p "$target_dir"/{hosts,modules}

  # Write nix flake to file
  cat >"$target_dir"/flake.nix <<EOF
  testing
EOF
}
