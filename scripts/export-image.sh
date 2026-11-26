#!/usr/bin/env bash
set -euo pipefail
cd -- "${1:?Supply the KIWI target directory}"
shopt -s nullglob
images=(*.qcow2)
manifests=(*.packages)
if (( ${#images[@]} != 1 )); then
  printf 'Expected one QCOW2 deliverable, found %s\n' "${#images[@]}" >&2
  exit 1
fi
COPYFILE_DISABLE=1 tar -cf - -- "${images[@]}" "${manifests[@]}"
