#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

die() {
  echo "Error: $*"
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  scripts/task.sh init
  scripts/task.sh validate
  scripts/task.sh build <qemu|virtualbox|all> [server|workstation|all]
  scripts/task.sh test <qemu|virtualbox|all> [server|workstation|all]
  scripts/task.sh clean
  scripts/task.sh status

Examples:
  scripts/task.sh build qemu server
  scripts/task.sh build all
  scripts/task.sh test qemu workstation
EOF
}

validate_variant() {
  case "$1" in
    server|workstation|all) ;;
    *) die "variant must be server, workstation, or all" ;;
  esac
}

validate_platform() {
  case "$1" in
    qemu|virtualbox|all) ;;
    *) die "platform must be qemu, virtualbox, or all" ;;
  esac
}

platform_selected() {
  local selected="$1"
  local candidate="$2"
  [[ "${selected}" == "all" || "${selected}" == "${candidate}" ]]
}

run_for_variants() {
  local selected="$1"
  shift

  case "${selected}" in
    all)
      "$@" server
      "$@" workstation
      ;;
    *)
      "$@" "${selected}"
      ;;
  esac
}

ensure_vbox() {
  local platform="$1"

  if command -v VBoxManage >/dev/null 2>&1; then
    return
  fi
  [[ "${platform}" == "virtualbox" ]] && die "VBoxManage not found. Please install VirtualBox."
  echo "Skipping VirtualBox operations (VirtualBox not installed)"
  return 1
}

run_init() {
  require_cmd packer
  echo "==> Initializing Packer plugins..."
  packer init "${PACKER_DIR}/"
}

run_validate() {
  require_cmd packer
  setup_build_context
  print_build_context

  echo "==> Validating Packer templates..."
  read -r -a packer_args <<< "$(packer_common_args)"
  packer validate "${packer_args[@]}" "${PACKER_DIR}/"
  echo "==> Validation successful!"
}

build_qemu() {
  local variant="$1"

  echo "==> Building Fedora ${FEDORA_VERSION} ${variant} for QEMU..."
  read -r -a packer_args <<< "$(packer_common_args)"
  packer build -only=qemu.fedora "${packer_args[@]}" -var "variant=${variant}" "${PACKER_DIR}/"
}

build_virtualbox() {
  local variant="$1"

  echo "==> Building Fedora ${FEDORA_VERSION} ${variant} for VirtualBox..."
  packer build \
    -only=virtualbox-iso.fedora \
    -var-file="${VAR_FILE}" \
    -var "variant=${variant}" \
    "${PACKER_DIR}/"
}

run_build() {
  local platform="${1:-qemu}"
  local variant="${2:-all}"

  validate_platform "${platform}"
  validate_variant "${variant}"
  require_cmd packer
  require_cmd ansible-playbook

  if platform_selected "${platform}" "qemu"; then
    setup_build_context
    require_cmd "$(effective_qemu_binary)"
    print_build_context
    run_for_variants "${variant}" build_qemu
  fi

  if platform_selected "${platform}" "virtualbox"; then
    ensure_vbox "${platform}" || return
    setup_build_context
    run_for_variants "${variant}" build_virtualbox
  fi
}

test_qemu() {
  local variant="$1"

  [[ -x "tests/test-qemu.sh" ]] || die "tests/test-qemu.sh not found or not executable"

  echo "==> Testing QEMU images..."
  ./tests/test-qemu.sh "${variant}"
}

test_virtualbox() {
  local variant="$1"

  [[ -x "tests/test-virtualbox.sh" ]] || die "tests/test-virtualbox.sh not found or not executable"

  echo "==> Testing VirtualBox images..."
  ./tests/test-virtualbox.sh "${variant}"
}

run_test() {
  local platform="${1:-qemu}"
  local variant="${2:-server}"

  validate_platform "${platform}"
  validate_variant "${variant}"

  if platform_selected "${platform}" "qemu"; then
    setup_build_context
    require_cmd "$(effective_qemu_binary)"
    run_for_variants "${variant}" test_qemu
  fi

  if platform_selected "${platform}" "virtualbox"; then
    ensure_vbox "${platform}" || return
    run_for_variants "${variant}" test_virtualbox
  fi
}

run_clean() {
  echo "==> Cleaning build artifacts..."
  rm -rf "${OUTPUT_DIR:?}/" .packer_cache/
  rm -f ./*.{box,qcow2,vdi}
  echo "==> Clean complete!"
}

run_status() {
  echo "==> Build Status"
  echo
  echo "Output directory: ${OUTPUT_DIR}"
  [[ -d "${OUTPUT_DIR}" ]] && { echo "Artifacts:"; ls -lh "${OUTPUT_DIR}/"; } || echo "No build artifacts found."
  echo
  echo "Packer cache:"
  [[ -d ".packer_cache" ]] && du -sh .packer_cache/ || echo "No Packer cache."
}

main() {
  local command="${1:-}"

  case "${command}" in
    init) run_init ;;
    validate) run_validate ;;
    build) run_build "${2:-}" "${3:-}" ;;
    test) run_test "${2:-}" "${3:-}" ;;
    clean) run_clean ;;
    status) run_status ;;
    ""|-h|--help|help) usage ;;
    *)
      echo "Error: unknown command: ${command}"
      echo
      usage
      exit 1
      ;;
  esac
}

main "$@"
