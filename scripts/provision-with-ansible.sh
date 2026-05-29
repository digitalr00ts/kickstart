#!/usr/bin/env bash
set -euo pipefail

IMAGE_PATH=${1:-}
ARCH=${2:-$(uname -m)}
SSH_PORT=${SSH_PORT:-2222}
SSH_USER=${SSH_USER:-admin}
SSH_PASS=${SSH_PASS:-admin}
PLAYBOOK=${ANSIBLE_PLAYBOOK:-ansible/playbook.yml}
REQS=${ANSIBLE_REQUIREMENTS:-ansible/requirements.yml}

[[ $ARCH == arm64 ]] && ARCH=aarch64
[[ $ARCH == amd64 ]] && ARCH=x86_64

QEMU=qemu-system-${ARCH}

err() { echo "Error: $*" >&2; exit 1; }

[[ -n $IMAGE_PATH ]] || err "Usage: $0 <image-path> [arch]"
[[ -f $IMAGE_PATH ]] || err "Image not found: $IMAGE_PATH"
command -v "$QEMU" &>/dev/null || err "$QEMU not found"
command -v ansible-playbook &>/dev/null || err "ansible-playbook not found"
[[ -f $PLAYBOOK ]] || err "Playbook not found: $PLAYBOOK"

WORK_IMG=$(mktemp -u).qcow2
cp "$IMAGE_PATH" "$WORK_IMG"

# Cross-arch on macOS: use Lima for KVM acceleration
use_lima() {
  [[ $(uname -s) != Darwin ]] && return 1
  local host
  host=$(uname -m)
  [[ $host == "$ARCH" || ($host == arm64 && $ARCH == aarch64) ]] && return 1
  command -v limactl &>/dev/null || { echo "Warning: cross-arch without Lima (slow TCG)" >&2; return 1; }
  return 0
}

start_native() {
  local accel="-accel tcg"
  [[ $(uname -s) == Darwin ]] && accel="-accel hvf"
  [[ -e /dev/kvm ]] && accel="-accel kvm"

  $QEMU $accel -m 2048 -smp 2 \
    -drive file="$WORK_IMG",format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic -serial mon:stdio >/tmp/qemu-provision-$$.log 2>&1 &

  QEMU_PID=$!
  USE_LIMA=false
}

start_lima() {
  limactl list | grep -q "^provision-vm" || limactl start --name=provision-vm template://default
  limactl copy "$WORK_IMG" provision-vm:/tmp/provision.qcow2

  limactl shell provision-vm qemu-system-${ARCH} -accel kvm -m 2048 -smp 2 \
    -drive file=/tmp/provision.qcow2,format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp:0.0.0.0:${SSH_PORT}-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic -daemonize -pidfile /tmp/qemu-provision.pid

  QEMU_PID=$(limactl shell provision-vm cat /tmp/qemu-provision.pid)
  USE_LIMA=true
}

wait_ssh() {
  local max=60 i=0
  while ((i++ < max)); do
    nc -z localhost "$SSH_PORT" 2>/dev/null && { sleep 5; return 0; }
    printf "\rWaiting for SSH... %d/%d" "$i" "$max"
    sleep 2
  done
  echo -e "\nTimeout" >&2
  return 1
}

provision() {
  [[ -f $REQS ]] && ansible-galaxy collection install -r "$REQS"

  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i "localhost:${SSH_PORT}," \
    -e "ansible_user=$SSH_USER" \
    -e "ansible_ssh_pass=$SSH_PASS" \
    -e "ansible_connection=ssh" \
    -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" \
    "$PLAYBOOK"
}

shutdown() {
  sshpass -p "$SSH_PASS" ssh -p "$SSH_PORT" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    ${SSH_USER}@localhost "sudo poweroff" 2>/dev/null || true

  local timeout=30 elapsed=0
  if [[ $USE_LIMA == true ]]; then
    while limactl shell provision-vm test -e /proc/$QEMU_PID 2>/dev/null && ((elapsed++ < timeout)); do sleep 1; done
    limactl shell provision-vm kill -9 "$QEMU_PID" 2>/dev/null || true
  else
    while kill -0 "$QEMU_PID" 2>/dev/null && ((elapsed++ < timeout)); do sleep 1; done
    kill -9 "$QEMU_PID" 2>/dev/null || true
  fi
}

cleanup() {
  [[ -n ${QEMU_PID:-} ]] && {
    [[ ${USE_LIMA:-false} == true ]] && {
      limactl shell provision-vm kill -9 "$QEMU_PID" 2>/dev/null || true
      limactl shell provision-vm rm -f /tmp/provision.qcow2 2>/dev/null || true
    } || kill -9 "$QEMU_PID" 2>/dev/null || true
  }
  [[ -f ${WORK_IMG:-} ]] && rm -f "$WORK_IMG"
}

trap cleanup EXIT INT TERM

use_lima && start_lima || start_native
wait_ssh || err "SSH timeout"
provision || err "Provisioning failed"
shutdown

[[ $USE_LIMA == true ]] && limactl copy provision-vm:/tmp/provision.qcow2 "$WORK_IMG"
mv "$WORK_IMG" "$IMAGE_PATH"
echo "Done: $IMAGE_PATH"
