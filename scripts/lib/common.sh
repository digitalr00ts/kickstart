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
  QEMU_DISPLAY_MODE_OVERRIDE="${QEMU_DISPLAY_MODE:-}"
  VAR_FILE="$(resolve_var_file)"
  [[ -z "${GUEST_ARCH_OVERRIDE}" || "${GUEST_ARCH_OVERRIDE}" == "x86_64" || "${GUEST_ARCH_OVERRIDE}" == "aarch64" ]] || {
    echo "Error: GUEST_ARCH must be x86_64 or aarch64."
    exit 1
  }
  [[ -z "${QEMU_DISPLAY_MODE_OVERRIDE}" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "spice" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "auto" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "none" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "gtk" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "cocoa" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "sdl" || "${QEMU_DISPLAY_MODE_OVERRIDE}" == "vnc" ]] || {
    echo "Error: QEMU_DISPLAY_MODE must be spice, auto, none, gtk, cocoa, sdl, or vnc."
    exit 1
  }
}

print_build_context() {
  local host_os default_display
  host_os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  default_display="auto"
  if [[ "${host_os}" == linux* ]]; then
    default_display="spice"
  elif [[ "${host_os}" == darwin* ]]; then
    default_display="cocoa"
  fi

  echo "==> Guest architecture${GUEST_ARCH_OVERRIDE:+ override}: ${GUEST_ARCH_OVERRIDE:-auto (HCL resolves from host hints/defaults)}"
  echo "==> Host hints: auto (HCL resolves from HOSTTYPE/OSTYPE or safe defaults)"
  echo "==> QEMU display mode${QEMU_DISPLAY_MODE_OVERRIDE:+ override}: ${QEMU_DISPLAY_MODE_OVERRIDE:-${default_display}}"
  echo "==> Vars file: ${VAR_FILE}"
}

packer_common_args() {
  printf '%s ' \
    "-var-file=${VAR_FILE}" \
    "-var=host_arch=$(uname -m)" \
    "-var=host_os=$(uname -s)"
  [[ -n "${GUEST_ARCH_OVERRIDE}" ]] && printf '%s ' "-var=guest_arch=${GUEST_ARCH_OVERRIDE}"
  [[ -n "${QEMU_DISPLAY_MODE_OVERRIDE}" ]] && printf '%s ' "-var=qemu_display_mode=${QEMU_DISPLAY_MODE_OVERRIDE}"
}
