#!/bin/bash
# validation.sh - Common validation functions for testing built images
# Source this file in other test scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Print functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

print_failure() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "ℹ $1"
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo -e "${GREEN}Passed:${NC} ${TESTS_PASSED}"
    echo -e "${RED}Failed:${NC} ${TESTS_FAILED}"
    echo "========================================"

    if [ ${TESTS_FAILED} -gt 0 ]; then
        return 1
    fi
    return 0
}

# Wait for SSH to be available
wait_for_ssh() {
    local host=$1
    local port=$2
    local user=$3
    local max_attempts=${4:-30}
    local attempt=0

    print_info "Waiting for SSH on ${host}:${port}..."

    while [ $attempt -lt $max_attempts ]; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
               -p ${port} ${user}@${host} "exit" 2>/dev/null; then
            print_success "SSH is available"
            return 0
        fi
        ((attempt++))
        sleep 2
    done

    print_failure "SSH timeout after ${max_attempts} attempts"
    return 1
}

# Check if VM booted successfully
check_boot() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Checking if system booted successfully..."

    if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
           "uptime" 2>/dev/null; then
        print_success "System is running"
        return 0
    else
        print_failure "Failed to verify system boot"
        return 1
    fi
}

# Check SSH access
check_ssh() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Testing SSH access..."

    if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
           "whoami" 2>/dev/null | grep -q "${user}"; then
        print_success "SSH access working"
        return 0
    else
        print_failure "SSH access failed"
        return 1
    fi
}

# Check required packages are installed
check_packages() {
    local host=$1
    local port=$2
    local user=$3
    shift 3
    local packages=("$@")

    print_info "Checking required packages..."

    for package in "${packages[@]}"; do
        if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
               "rpm -q ${package}" 2>/dev/null | grep -q "^${package}"; then
            print_success "Package ${package} is installed"
        else
            print_failure "Package ${package} is not installed"
        fi
    done
}

# Check disk partitions
check_partitions() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Checking disk partitions..."

    local output
    output=$(ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
                      "df -h /" 2>/dev/null)

    if echo "${output}" | grep -q "/"; then
        print_success "Root partition is mounted"
        echo "${output}" | tail -1
        return 0
    else
        print_failure "Failed to check partitions"
        return 1
    fi
}

# Check for LVM
check_lvm() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Checking LVM configuration..."

    if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
           "sudo lvs" 2>/dev/null | grep -q "root"; then
        print_success "LVM is configured"
        return 0
    else
        print_warning "LVM check skipped or not configured"
        return 0
    fi
}

# Check Python installation
check_python() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Checking Python installation..."

    local version
    version=$(ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
                       "python3 --version" 2>&1)

    if echo "${version}" | grep -q "Python 3"; then
        print_success "Python is installed: ${version}"
        return 0
    else
        print_failure "Python check failed"
        return 1
    fi
}

# Check system services
check_services() {
    local host=$1
    local port=$2
    local user=$3
    shift 3
    local services=("$@")

    print_info "Checking system services..."

    for service in "${services[@]}"; do
        if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
               "sudo systemctl is-active ${service}" 2>/dev/null | grep -q "active"; then
            print_success "Service ${service} is active"
        else
            print_warning "Service ${service} is not active (may be expected)"
        fi
    done
}

# Check network configuration
check_network() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Checking network configuration..."

    # Check if we can ping a public DNS
    if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
           "ping -c 1 8.8.8.8" 2>/dev/null | grep -q "1 received"; then
        print_success "Network connectivity is working"
        return 0
    else
        print_warning "Network connectivity test failed (may be firewall related)"
        return 0
    fi
}

# Check DNF/package manager
check_dnf() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Checking DNF package manager..."

    if ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
           "sudo dnf --version" 2>/dev/null | grep -q "dnf"; then
        print_success "DNF is working"
        return 0
    else
        print_failure "DNF check failed"
        return 1
    fi
}

# Get system information
get_system_info() {
    local host=$1
    local port=$2
    local user=$3

    print_info "Gathering system information..."

    echo ""
    echo "System Information:"
    echo "----------------------------------------"
    ssh -o StrictHostKeyChecking=no -p ${port} ${user}@${host} \
        "echo 'OS Release:'; cat /etc/os-release | grep PRETTY_NAME; \
         echo ''; \
         echo 'Kernel:'; uname -r; \
         echo ''; \
         echo 'Memory:'; free -h | grep Mem; \
         echo ''; \
         echo 'Disk:'; df -h /" 2>/dev/null
    echo "----------------------------------------"
    echo ""
}
