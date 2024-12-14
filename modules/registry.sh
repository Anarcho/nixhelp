#!/usr/bin/env bash

register_host() {
  local hostname=$1
  local host_type=$2
  local ip_address=$3
  local targer_dir=$4
  local username=$5

  # Validates input
  if [[ -z $hostname || -z $host_type || -z $ip_address ]]; then
    echo "Error: hostname and host_type are required"
    return 1
  fi

  # update registry json
  local registry_file="$targer_dir/repos/nixcfg/registry.json"
  echo $registry_file

  # Check if registry file exists
  if [[ ! -f $registry_file ]]; then
    echo "Error: Registry file not found"
    return 1
  fi

  # Check if host already exists
  if grep -q "\"name\": \"$hostname\"" $registry_file; then
    echo "Error: Host already exists"
    return 1
  fi

  # Add host to registry
  jq --arg hostname "$hostname" --arg host_type "$host_type" --arg ip_address "$ip_address" '.hosts.physical += [{"name": $hostname, "config_path": "hosts/nixos/$hostname", "ip_address": $ip_address}]' $registry_file >$registry_file.tmp && mv $registry_file.tmp $registry_file
}

register_host "nixvm" "desktop" "192.168.1.1" "" ""
