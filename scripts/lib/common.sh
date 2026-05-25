#!/usr/bin/env bash

set -euo pipefail

FEDORA_VERSION="${FEDORA_VERSION:-44}"
PACKER_DIR="${PACKER_DIR:-packer}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

detect_host_arch() {
  local arch
  arch="$(uname -m)"
  case "${arch}" in
    aarch64|arm64) echo "aarch64" ;;
    *) echo "x86_64" ;;
  esac
}

detect_host_os_hint() {
  local os
  os="$(uname -s)"
  case "${os}" in
    Linux) echo "linux" ;;
    Darwin) echo "macos" ;;
    *) echo "auto" ;;
  esac
}

default_qemu_accelerator() {
  local hint
  hint="$(detect_host_os_hint)"
  case "${hint}" in
    linux) echo "kvm" ;;
    macos) echo "hvf" ;;
    *) echo "tcg" ;;
  esac
}

require_cmd() {
  local cmd
  cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "Error: ${cmd} not found."
    exit 1
  }
}

resolve_var_file() {
  if [[ -n "${VAR_FILE:-}" ]]; then
    if [[ -f "${VAR_FILE}" ]]; then
      echo "${VAR_FILE}"
      return
    fi
    echo "Error: VAR_FILE does not exist: ${VAR_FILE}"
    exit 1
  fi

  local candidate1 candidate2
  candidate1="${PACKER_DIR}/fedora-${FEDORA_VERSION}.pkrvars.hcl"
  candidate2="${PACKER_DIR}/fedora-${FEDORA_VERSION}.auto.pkrvars.hcl"

  if [[ -f "${candidate1}" ]]; then
    echo "${candidate1}"
    return
  fi
  if [[ -f "${candidate2}" ]]; then
    echo "${candidate2}"
    return
  fi

  echo "Error: No vars file found for Fedora ${FEDORA_VERSION} in ${PACKER_DIR}/"
  exit 1
}

setup_build_context() {
  HOST_ARCH="$(detect_host_arch)"
  HOST_OS_HINT="$(detect_host_os_hint)"
  GUEST_ARCH="${GUEST_ARCH:-${HOST_ARCH}}"
  QEMU_BINARY="${QEMU_BINARY:-qemu-system-${GUEST_ARCH}}"
  QEMU_ACCELERATOR="${QEMU_ACCELERATOR:-$(default_qemu_accelerator)}"
  VAR_FILE="$(resolve_var_file)"

  if [[ "${GUEST_ARCH}" != "x86_64" && "${GUEST_ARCH}" != "aarch64" ]]; then
    echo "Error: GUEST_ARCH must be x86_64 or aarch64."
    exit 1
  fi
}

print_build_context() {
  echo "==> Host architecture: ${HOST_ARCH}"
  echo "==> Guest architecture: ${GUEST_ARCH}"
  echo "==> QEMU binary: ${QEMU_BINARY}"
  echo "==> Using QEMU accelerator: ${QEMU_ACCELERATOR}"
  echo "==> Vars file: ${VAR_FILE}"
}

packer_common_args() {
  echo "-var-file=${VAR_FILE}" \
       "-var" "guest_arch=${GUEST_ARCH}" \
       "-var" "qemu_binary=${QEMU_BINARY}" \
       "-var" "qemu_accelerator=${QEMU_ACCELERATOR}" \
       "-var" "host_os_hint=${HOST_OS_HINT}"
}
