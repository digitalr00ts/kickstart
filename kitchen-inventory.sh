#!/usr/bin/env sh

# Shim to run inventory script with bundler.
# Ansible config does not seem to support running command, only scripts.

bundle exec kitchen-ansible-inventory
