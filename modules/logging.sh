#!/usr/bin/env bash

log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/nixhelp.log"
}

error() {
  log "ERROR" "$1"
  exit 1
}

warn() {
  log "WARN" "$1"
}

info() {
  log "INFO" "$1"
}
