#!/usr/bin/env bash

init_config() {
  local target_dir="${1:-.}"
  echo "$target_dir"
}

init_config "$1"
