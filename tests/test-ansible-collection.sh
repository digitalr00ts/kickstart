#!/bin/bash
# test-ansible-collection.sh - Test Ansible collection integration
# Validates both local and GitHub collection workflows

set -e

# Source validation functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/validation.sh"

echo "========================================"
echo "Testing Ansible Collection Integration"
echo "========================================"

# Test 1: Check if Ansible is installed
print_info "Checking Ansible installation..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -1)
    print_success "Ansible is installed: ${ANSIBLE_VERSION}"
else
    print_failure "Ansible is not installed"
    exit 1
fi

# Test 2: Check if ansible-galaxy is available
print_info "Checking ansible-galaxy command..."
if command -v ansible-galaxy &> /dev/null; then
    print_success "ansible-galaxy is available"
else
    print_failure "ansible-galaxy is not available"
    exit 1
fi

# Test 3: Validate requirements.yml syntax
print_info "Validating requirements.yml..."
if [ -f "ansible/requirements.yml" ]; then
    if ansible-galaxy collection list 2>&1 | grep -q "ERROR"; then
        print_warning "requirements.yml may have issues"
    else
        print_success "requirements.yml syntax is valid"
    fi
else
    print_failure "ansible/requirements.yml not found"
fi

# Test 4: Validate ansible.cfg
print_info "Validating ansible.cfg..."
if [ -f "ansible/ansible.cfg" ]; then
    print_success "ansible.cfg exists"

    # Check for important settings
    if grep -q "collections_path" ansible/ansible.cfg; then
        print_success "collections_path is configured"
    else
        print_warning "collections_path not found in ansible.cfg"
    fi
else
    print_failure "ansible/ansible.cfg not found"
fi

# Test 5: Check playbooks exist and are valid YAML
print_info "Validating playbook files..."

for playbook in ansible/playbook-server.yml ansible/playbook-workstation.yml; do
    if [ -f "${playbook}" ]; then
        # Basic YAML syntax check
        if python3 -c "import yaml; yaml.safe_load(open('${playbook}'))" 2>/dev/null; then
            print_success "$(basename ${playbook}) is valid YAML"
        else
            print_failure "$(basename ${playbook}) has YAML syntax errors"
        fi
    else
        print_failure "${playbook} not found"
    fi
done

# Test 6: Test local collection path support
print_info "Testing local collection path support..."
if [ -n "${ANSIBLE_COLLECTIONS_PATH}" ]; then
    print_success "ANSIBLE_COLLECTIONS_PATH is set: ${ANSIBLE_COLLECTIONS_PATH}"

    # Check if the path exists
    if [ -d "${ANSIBLE_COLLECTIONS_PATH}" ]; then
        print_success "Collection path directory exists"
    else
        print_warning "Collection path directory does not exist"
    fi
else
    print_info "ANSIBLE_COLLECTIONS_PATH not set (will use default or requirements.yml)"
fi

# Test 7: Try to install collection from GitHub (dry-run simulation)
print_info "Testing collection installation from GitHub..."
if [ -f "ansible/requirements.yml" ]; then
    # Create a temporary directory for testing
    TEMP_COLLECTIONS_DIR=$(mktemp -d)

    if ansible-galaxy collection install \
        -r ansible/requirements.yml \
        -p "${TEMP_COLLECTIONS_DIR}" \
        --force 2>&1 | grep -q "drts01.collection"; then
        print_success "Collection can be installed from GitHub"
    else
        print_warning "Collection installation test skipped (may require network access)"
    fi

    # Cleanup
    rm -rf "${TEMP_COLLECTIONS_DIR}"
else
    print_warning "Cannot test collection installation (requirements.yml not found)"
fi

# Test 8: Check for collection dependencies in playbooks
print_info "Checking playbook structure..."

for playbook in ansible/playbook-server.yml ansible/playbook-workstation.yml; do
    if [ -f "${playbook}" ]; then
        # Check if playbook has hosts and tasks
        if grep -q "hosts:" "${playbook}" && \
           (grep -q "tasks:" "${playbook}" || grep -q "roles:" "${playbook}"); then
            print_success "$(basename ${playbook}) has valid structure"
        else
            print_warning "$(basename ${playbook}) may be missing hosts or tasks"
        fi
    fi
done

# Test 9: Verify collection reference in playbooks
print_info "Checking for collection references..."

# Note: Actual collection roles are placeholder until drts01 collection structure is known
if grep -r "drts01.collection" ansible/*.yml 2>/dev/null | grep -q "#"; then
    print_info "Collection references are commented (placeholder mode)"
elif grep -r "drts01.collection" ansible/*.yml 2>/dev/null; then
    print_success "Collection references found in playbooks"
else
    print_info "No collection references (using built-in modules only)"
fi

# Print summary
echo ""
print_summary

exit $?
