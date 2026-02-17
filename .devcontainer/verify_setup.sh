#!/bin/bash
# DevContainer Setup Verification Script
# Run this inside your devcontainer to verify GitHub and Docker access

set -e

echo "════════════════════════════════════════════════════════════════"
echo "  DevContainer Setup Verification"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0
TOTAL=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL=$((TOTAL + 1))
    echo -n "[$TOTAL] Testing: $test_name ... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "─────────────────────────────────────────────────────────────────"
echo "1. GIT CONFIGURATION TESTS"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# Git configuration
run_test "Git is installed" "git --version"
run_test "Git user.name is configured" "git config --get user.name"
run_test "Git user.email is configured" "git config --get user.email"

echo ""
echo "Git Configuration:"
echo "  Name:  $(git config --get user.name 2>/dev/null || echo 'Not set')"
echo "  Email: $(git config --get user.email 2>/dev/null || echo 'Not set')"
echo ""

echo "─────────────────────────────────────────────────────────────────"
echo "2. SSH & GITHUB AUTHENTICATION TESTS"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# SSH configuration
run_test "SSH keys directory exists" "test -d ~/.ssh"
run_test "SSH keys have correct permissions" "test \$(stat -c %a ~/.ssh 2>/dev/null || stat -f %A ~/.ssh) = '700'"
run_test "SSH_AUTH_SOCK is set" "test -n \"$SSH_AUTH_SOCK\""

# GitHub SSH
echo ""
echo -n "[$((TOTAL + 1))] Testing: GitHub SSH connection ... "
TOTAL=$((TOTAL + 1))
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED + 1))
    GITHUB_USER=$(ssh -T git@github.com 2>&1 | grep -oP "Hi \K[^!]+")
    echo "  → Connected as: $GITHUB_USER"
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED + 1))
    echo "  → Cannot authenticate with GitHub via SSH"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────"
echo "3. GITHUB CLI TESTS"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# GitHub CLI
run_test "GitHub CLI (gh) is installed" "gh --version"
run_test "GitHub CLI is authenticated" "gh auth status"

if gh auth status > /dev/null 2>&1; then
    echo ""
    echo "GitHub CLI Status:"
    gh auth status 2>&1 | head -3
fi

echo ""
echo "─────────────────────────────────────────────────────────────────"
echo "4. DOCKER ACCESS TESTS"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# Docker
run_test "Docker is installed" "docker --version"
run_test "Docker Compose is installed" "docker-compose --version"
run_test "Docker socket exists" "test -S /var/run/docker.sock"
run_test "Can communicate with Docker daemon" "docker info"
run_test "Can list Docker containers" "docker ps"

echo ""
echo "Docker Information:"
docker --version 2>/dev/null || echo "  Docker: Not available"
docker-compose --version 2>/dev/null || echo "  Docker Compose: Not available"

echo ""
echo -n "[$((TOTAL + 1))] Testing: Can pull Docker images ... "
TOTAL=$((TOTAL + 1))
if docker pull alpine:latest > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""
echo -n "[$((TOTAL + 1))] Testing: Can run Docker containers ... "
TOTAL=$((TOTAL + 1))
if docker run --rm alpine:latest echo "test" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    FAILED=$((FAILED + 1))
fi

# Count running containers
CONTAINER_COUNT=$(docker ps -q | wc -l)
echo ""
echo "Running containers on Docker Desktop: $CONTAINER_COUNT"

echo ""
echo "─────────────────────────────────────────────────────────────────"
echo "5. FRAPPE ENVIRONMENT TESTS"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# Frappe bench
run_test "Frappe bench directory exists" "test -d /workspace/development/frappe-bench"
run_test "Prevance Health app exists" "test -d /workspace/development/frappe-bench/apps/prevance_health"

if [ -d /workspace/development/frappe-bench ]; then
    echo ""
    echo "Frappe Bench Apps:"
    ls -1 /workspace/development/frappe-bench/apps/ 2>/dev/null | sed 's/^/  - /' || echo "  (none)"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VERIFICATION SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Total Tests: $TOTAL"
echo -e "Passed:      ${GREEN}$PASSED${NC}"
echo -e "Failed:      ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo ""
    echo "Your devcontainer is fully configured for:"
    echo "  ✓ Git and GitHub CLI"
    echo "  ✓ Docker Desktop access"
    echo "  ✓ Frappe development"
    echo ""
    echo "You can now:"
    echo "  • Run: git status, gh pr list"
    echo "  • Run: docker ps, docker-compose up"
    echo "  • Deploy full stacks for integration testing"
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check Docker Desktop is running on your Mac"
    echo "  2. Verify Docker Desktop settings (see SETUP_GUIDE.md)"
    echo "  3. Rebuild container: Cmd+Shift+P → 'Rebuild Container'"
    echo "  4. Check SSH agent: ssh-add -l (on Mac)"
    echo "  5. Check GitHub auth: gh auth login (on Mac or in container)"
    echo ""
    echo "For detailed help, see: .devcontainer/SETUP_GUIDE.md"
    echo ""
    exit 1
fi
