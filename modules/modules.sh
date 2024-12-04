#!/usr/bin/env bash

create_module(){
  local module_name="$1"
  local module_type="$2"

  if [ -z "$module_name" ]; then
    log "ERROR" "Module name required"
    exit 1
  fi

  mkdir -p "modules/$module_type/$module_name"

  cat >> "modules/$module_type/$module_name/default.nix" << EOF

  { -- standard module }

  EOF

  log "INFO" "Created new module: $module_name in $module_type"
}
