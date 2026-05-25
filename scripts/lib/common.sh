#!/usr/bin/env bash

set -euo pipefail

FEDORA_VERSION="${FEDORA_VERSION:-44}"
PACKER_DIR="${PACKER_DIR:-packer}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: $1 not found."
    exit 1
  }
}

resolve_var_file() {
  local candidate

  if [[ -n "${VAR_FILE:-}" ]]; then
    [[ -f "${VAR_FILE}" ]] && { echo "${VAR_FILE}"; return; }
    echo "Error: VAR_FILE does not exist: ${VAR_FILE}"
    exit 1
  fi

  for candidate in \
    "${PACKER_DIR}/fedora-${FEDORA_VERSION}.pkrvars.hcl" \
    "${PACKER_DIR}/fedora-${FEDORA_VERSION}.auto.pkrvars.hcl"; do
    [[ -f "${candidate}" ]] && { echo "${candidate}"; return; }
  done

  echo "Error: No vars file found for Fedora ${FEDORA_VERSION} in ${PACKER_DIR}/"
  exit 1
}

setup_build_context() {
  GUEST_ARCH_OVERRIDE="${GUEST_ARCH:-}"
  VAR_FILE="$(resolve_var_file)"
  [[ -z "${GUEST_ARCH_OVERRIDE}" || "${GUEST_ARCH_OVERRIDE}" == "x86_64" || "${GUEST_ARCH_OVERRIDE}" == "aarch64" ]] || {
    echo "Error: GUEST_ARCH must be x86_64 or aarch64."
    exit 1
  }
}

print_build_context() {
  echo "==> Guest architecture${GUEST_ARCH_OVERRIDE:+ override}: ${GUEST_ARCH_OVERRIDE:-auto (HCL resolves from host hints/defaults)}"
  echo "==> Host hints: auto (HCL resolves from HOSTTYPE/OSTYPE or safe defaults)"
  echo "==> Vars file: ${VAR_FILE}"
}

packer_common_args() {
  printf '%s ' \
    "-var-file=${VAR_FILE}" \
    "-var=host_arch=$(uname -m)" \
    "-var=host_os=$(uname -s)"
  [[ -n "${GUEST_ARCH_OVERRIDE}" ]] && printf '%s ' "-var=guest_arch=${GUEST_ARCH_OVERRIDE}"
}
