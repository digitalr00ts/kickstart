#!/usr/bin/env bash

type packer > /dev/null
if [ "$?" -gt 0 ]; then
    printf "Packer not found in path."
    exit 1
fi

for FILE in ${@:2}; do
    packer "${1}" "${FILE}"
done
