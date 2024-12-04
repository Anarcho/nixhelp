#!/usr/bin/env bash

create_host() {
  local host_name="$1"
  local host_type="$2"

  # check for nulls
  if [ -z "$host_name" ] || [ -z "$host_type" ]; then
    log "ERROR" "Host name and type required"
    exit 1
  fi

  # create host folder for host_name 
  mkdir -p "hosts/nixos/$hostname"

  # add nix default host template
  cat > "hosts/nixos/$host_name/default.nix" << EOF
  { nix template }

  -- Add imports here
  EOF
}
