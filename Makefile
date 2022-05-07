.PHONY: install build vagrant-clean lint help
.NOTPARALLEL:
.POSIX:
.ONESHELL:
.DEFAULT_GOAL := help
SHELL := /bin/sh

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print(f"{target:20s} {help}")
endef
export PRINT_HELP_PYSCRIPT

install:  ## Install or update tools
	scripts/install.sh

build:  ## Packer build
	rm -rf -- output-*
	bin/packer build -force packer/template.pkr.hcl

lint:  ## Lint Kickstart, Packer, and Ansible files
	bin/packer validate packer/template.pkr.hcl
	ksvalidator --followincludes --version F32 kickstart/ks.cfg
	ansible-playbook playbooks/*.yml --syntax-check
	# ansible-lint

vagrant-clean:  ## Remove Vagrant images from KVM
	bin/vagrant destroy -f
	bin/vagrant provision

help:  ## Print this help message
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)
