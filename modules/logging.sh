#!/usr/bin/env bash

log() {
  local level="$1"
  local message="$2"
  echo "[$(date '+%y-%m-%-d %H:%M:%S')] [$level] $message" | tee -a "$LOG_DIR/nixhelp.log"
}
