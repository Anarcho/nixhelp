#!/usr/bin/env bash

prompt() {
  local prompt="$1"
  local default="$2"
  local response

  read -p "$prompt [$default]: " response
  echo "${response:-$default}"
}
