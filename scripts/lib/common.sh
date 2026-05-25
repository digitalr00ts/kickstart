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

detect_host_uname_m() {
  uname -m
}

detect_host_uname_s() {
  uname -s
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
  HOST_UNAME_M="$(detect_host_uname_m)"
  HOST_UNAME_S="$(detect_host_uname_s)"
  HOST_ARCH="$(detect_host_arch)"
  DETECTED_HOST_OS_HINT="$(detect_host_os_hint)"
  USER_GUEST_ARCH_OVERRIDE="${GUEST_ARCH:-}"
  USER_HOST_OS_HINT_OVERRIDE="${HOST_OS_HINT:-}"
  GUEST_ARCH="${USER_GUEST_ARCH_OVERRIDE:-${HOST_ARCH}}"
  HOST_OS_HINT="${USER_HOST_OS_HINT_OVERRIDE:-}"
  QEMU_BINARY="${QEMU_BINARY:-}"
  QEMU_ACCELERATOR="${QEMU_ACCELERATOR:-}"
  VAR_FILE="$(resolve_var_file)"

  if [[ "${GUEST_ARCH}" != "x86_64" && "${GUEST_ARCH}" != "aarch64" ]]; then
    echo "Error: GUEST_ARCH must be x86_64 or aarch64."
    exit 1
  fi

  if [[ -n "${HOST_OS_HINT}" && "${HOST_OS_HINT}" != "auto" && "${HOST_OS_HINT}" != "linux" && "${HOST_OS_HINT}" != "macos" ]]; then
    echo "Error: HOST_OS_HINT must be auto, linux, or macos when set."
    exit 1
  fi
}

effective_qemu_binary() {
  if [[ -n "${QEMU_BINARY:-}" ]]; then
    echo "${QEMU_BINARY}"
    return
  fi
  echo "qemu-system-${GUEST_ARCH}"
}

print_build_context() {
  echo "==> Host uname -m: ${HOST_UNAME_M}"
  echo "==> Host uname -s: ${HOST_UNAME_S}"
  echo "==> Guest architecture (shell check): ${GUEST_ARCH}"
  if [[ -n "${HOST_OS_HINT:-}" ]]; then
    echo "==> Host OS hint override: ${HOST_OS_HINT}"
  else
    echo "==> Host OS hint: auto (HCL derives from uname -s, detected shell hint: ${DETECTED_HOST_OS_HINT})"
  fi
  if [[ -n "${QEMU_BINARY:-}" ]]; then
    echo "==> QEMU binary override: ${QEMU_BINARY}"
  else
    echo "==> QEMU binary: auto (HCL default from guest_arch)"
  fi
  if [[ -n "${QEMU_ACCELERATOR:-}" ]]; then
    echo "==> QEMU accelerator override: ${QEMU_ACCELERATOR}"
  else
    echo "==> QEMU accelerator: auto (HCL default from host_os_hint)"
  fi
  echo "==> Vars file: ${VAR_FILE}"
}

packer_common_args() {
  local args
  args=(
    "-var-file=${VAR_FILE}"
    "-var" "host_uname_m=${HOST_UNAME_M}"
    "-var" "host_uname_s=${HOST_UNAME_S}"
  )

  if [[ -n "${USER_GUEST_ARCH_OVERRIDE:-}" ]]; then
    args+=("-var" "guest_arch=${USER_GUEST_ARCH_OVERRIDE}")
  fi
  if [[ -n "${USER_HOST_OS_HINT_OVERRIDE:-}" ]]; then
    args+=("-var" "host_os_hint=${USER_HOST_OS_HINT_OVERRIDE}")
  fi

  if [[ -n "${QEMU_BINARY:-}" ]]; then
    args+=("-var" "qemu_binary=${QEMU_BINARY}")
  fi
  if [[ -n "${QEMU_ACCELERATOR:-}" ]]; then
    args+=("-var" "qemu_accelerator=${QEMU_ACCELERATOR}")
  fi

  printf '%s ' "${args[@]}"
}
