#!/usr/bin/env bash

set -euo pipefail

# source all modules

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/modules/config.sh"
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/utils.sh"
source "$SCRIPT_DIR/modules/init.sh"
source "$SCRIPT_DIR/modules/hosts.sh"
source "$SCRIPT_DIR/modules/modules.sh"
source "$SCRIPT_DIR/modules/ssh.sh"
source "$SCRIPT_DIR/modules/vm.sh"

main() {
  local command="$1"
  shift

  case "$command" in
    init)
      init_config "$@"
      ;;
    host)
      create_host "$@"
      ;;
    module)
      create_module "$@"
      ;;
    vm)
      case "$1" in
        create)
          shift
          create_vm_host "$@"
          ;;

        update)
          shift
          update_host "$@"
          ;;

        *)
          shift
          echo "Usage: nix help vm [create|update] hostname [config-type]"
          ;;
        esac
        ;;
    esac
}

# Run main function
main "$@"
