#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

die() {
  echo "Error: $*"
  exit 1
}

validate_in() {
  local value="$1" allowed="$2" message="$3"
  case "|${allowed}|" in
    *"|${value}|"*) ;;
    *) die "${message}" ;;
  esac
}

usage() {
  cat <<'EOF'
Usage:
  scripts/task.sh init
  scripts/task.sh validate
  scripts/task.sh build <qemu|virtualbox|all> [server|workstation|all]
  scripts/task.sh test <qemu|virtualbox|all|ansible-collection> [server|workstation|all]
  scripts/task.sh clean
  scripts/task.sh status

Examples:
  scripts/task.sh build qemu server
  scripts/task.sh build all
  scripts/task.sh test qemu workstation
  scripts/task.sh test ansible-collection
EOF
}

is_selected() {
  local selected="$1"
  local candidate="$2"
  [[ "${selected}" == "all" || "${selected}" == "${candidate}" ]]
}

run_for_variants() {
  local selected="$1"
  shift
  local variants

  variants=("${selected}")
  [[ "${selected}" == "all" ]] && variants=(server workstation)

  local variant
  for variant in "${variants[@]}"; do
    "$@" "${variant}"
  done
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

  validate_in "${platform}" "qemu|virtualbox|all" "platform must be qemu, virtualbox, or all"
  validate_in "${variant}" "server|workstation|all" "variant must be server, workstation, or all"
  require_cmd packer
  require_cmd ansible-playbook

  is_selected "${platform}" qemu && {
    setup_build_context
    print_build_context
    run_for_variants "${variant}" build_qemu
  }

  is_selected "${platform}" virtualbox && {
    ensure_vbox "${platform}" || return
    setup_build_context
    run_for_variants "${variant}" build_virtualbox
  }
}

test_qemu() {
  local variant="$1"
  local policy_mode="${MOLECULE_POLICY_MODE:-strict}"

  require_cmd molecule
  echo "==> Testing QEMU image with Molecule scenario: qemu-${variant} (policy=${policy_mode})"
  MOLECULE_POLICY_MODE="${policy_mode}" molecule test -s "qemu-${variant}"
}

test_virtualbox() {
  local variant="$1"
  local policy_mode="${MOLECULE_POLICY_MODE:-strict}"

  require_cmd molecule
  ensure_vbox "virtualbox"
  echo "==> Testing VirtualBox image with Molecule scenario: virtualbox-${variant} (policy=${policy_mode})"
  MOLECULE_POLICY_MODE="${policy_mode}" molecule test -s "virtualbox-${variant}"
}

test_ansible_collection() {
  require_cmd ansible
  require_cmd ansible-galaxy
  require_cmd python3

  [[ -f "ansible/requirements.yml" ]] || die "ansible/requirements.yml not found"
  [[ -f "ansible/ansible.cfg" ]] || die "ansible/ansible.cfg not found"

  grep -q collections_path ansible/ansible.cfg || echo "warn: collections_path not set in ansible/ansible.cfg"

  local playbook
  for playbook in ansible/playbook-server.yml ansible/playbook-workstation.yml; do
    [[ -f "${playbook}" ]] || die "${playbook} not found"
    python3 - <<'PY' "${playbook}"
import sys, yaml
yaml.safe_load(open(sys.argv[1]))
PY
    echo "ok: yaml ${playbook}"
  done

  if [[ -n "${ANSIBLE_COLLECTIONS_PATH:-}" ]]; then
    [[ -d "${ANSIBLE_COLLECTIONS_PATH}" ]] || echo "warn: ANSIBLE_COLLECTIONS_PATH does not exist: ${ANSIBLE_COLLECTIONS_PATH}"
  fi

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  ansible-galaxy collection install -r ansible/requirements.yml -p "${tmp}" --force >/dev/null 2>&1 \
    && echo "ok: galaxy install" \
    || echo "warn: galaxy install skipped/failed"

  for playbook in ansible/playbook-server.yml ansible/playbook-workstation.yml; do
    grep -Eq 'hosts:' "${playbook}" || echo "warn: hosts missing: ${playbook}"
    grep -Eq 'tasks:|roles:' "${playbook}" || echo "warn: tasks/roles missing: ${playbook}"
  done

  grep -r "drts01.collection" ansible/*.yml >/dev/null 2>&1 \
    && echo "ok: collection refs present" \
    || echo "warn: no drts01.collection refs"
}

run_test() {
  local platform="${1:-qemu}"
  local variant="${2:-server}"

  validate_in "${platform}" "qemu|virtualbox|all|ansible-collection" "platform must be qemu, virtualbox, all, or ansible-collection"

  if [[ "${platform}" == "ansible-collection" ]]; then
    test_ansible_collection
    return
  fi

  validate_in "${variant}" "server|workstation|all" "variant must be server, workstation, or all"

  is_selected "${platform}" qemu && {
    setup_build_context
    run_for_variants "${variant}" test_qemu
  }

  is_selected "${platform}" virtualbox && {
    ensure_vbox "${platform}" || return
    run_for_variants "${variant}" test_virtualbox
  }
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
