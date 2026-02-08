#!/bin/bash

# ShieldClaw Verification Script
# Tests the security configuration with simulated attacks

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║      ShieldClaw Security Verification Tests           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_test() {
    echo -e "${BLUE}Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}  ✓ PASS: $1${NC}"
}

print_fail() {
    echo -e "${RED}  ✗ FAIL: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}  ℹ INFO: $1${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

test_files_exist() {
    section "File Existence Tests"
    
    local files=("openclaw.json" "SOUL.md" ".env.example" ".gitignore" "README.md")
    local failed=0
    
    for file in "${files[@]}"; do
        print_test "Checking $file"
        if [ -f "$PROJECT_ROOT/$file" ]; then
            print_pass "File exists"
        else
            print_fail "File missing"
            ((failed++))
        fi
    done
    
    return $failed
}

test_scripts_executable() {
    section "Script Permissions Tests"
    
    local scripts=("setup.sh" "kill-switch.sh" "health-check.sh")
    local failed=0
    
    for script in "${scripts[@]}"; do
        print_test "Checking scripts/$script"
        if [ -x "$PROJECT_ROOT/scripts/$script" ]; then
            print_pass "Executable"
        else
            print_fail "Not executable"
            ((failed++))
        fi
    done
    
    return $failed
}

test_json_valid() {
    section "Configuration Validation Tests"
    
    print_test "Validating openclaw.json syntax"
    if jq empty "$PROJECT_ROOT/openclaw.json" 2>/dev/null; then
        print_pass "Valid JSON"
    else
        print_fail "Invalid JSON"
        return 1
    fi
    
    print_test "Checking required security fields"
    local required_fields=(
        ".security"
        ".security.authentication"
        ".security.prompt_injection_defense"
        ".operational.failsafe.kill_switch_enabled"
    )
    
    local failed=0
    for field in "${required_fields[@]}"; do
        if jq -e "$field" "$PROJECT_ROOT/openclaw.json" >/dev/null 2>&1; then
            print_pass "Field $field exists"
        else
            print_fail "Field $field missing"
            ((failed++))
        fi
    done
    
    return $failed
}

test_soul_content() {
    section "SOUL.md Content Tests"
    
    local required_sections=(
        "Core Identity"
        "Input Validation"
        "Context Isolation"
        "Injection Patterns"
        "Response Protocols"
        "Emergency Protocols"
    )
    
    local failed=0
    for section in "${required_sections[@]}"; do
        print_test "Checking for '$section' section"
        if grep -q "$section" "$PROJECT_ROOT/SOUL.md"; then
            print_pass "Section found"
        else
            print_fail "Section missing"
            ((failed++))
        fi
    done
    
    return $failed
}

test_gitignore() {
    section "Git Security Tests"
    
    local sensitive_patterns=(".env" "*.key" "*.pem" "secrets/" "logs/")
    local failed=0
    
    for pattern in "${sensitive_patterns[@]}"; do
        print_test "Checking .gitignore for $pattern"
        if grep -q "$pattern" "$PROJECT_ROOT/.gitignore"; then
            print_pass "Pattern found"
        else
            print_fail "Pattern missing"
            ((failed++))
        fi
    done
    
    # Check if .env would be ignored
    if command -v git &> /dev/null; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            cd "$PROJECT_ROOT"
            print_test "Verifying .env is ignored by git"
            if git check-ignore .env >/dev/null 2>&1; then
                print_pass ".env would be ignored"
            else
                print_fail ".env would NOT be ignored"
                ((failed++))
            fi
        fi
    fi
    
    return $failed
}

test_env_example() {
    section "Environment Template Tests"
    
    local required_vars=(
        "ANTHROPIC_API_KEY"
        "SESSION_SECRET"
        "ENCRYPTION_KEY"
        "ENABLE_PROMPT_INJECTION_DEFENSE"
        "KILL_SWITCH_ENABLED"
    )
    
    local failed=0
    for var in "${required_vars[@]}"; do
        print_test "Checking for $var in .env.example"
        if grep -q "^$var=" "$PROJECT_ROOT/.env.example" || grep -q "^# $var=" "$PROJECT_ROOT/.env.example"; then
            print_pass "Variable defined"
        else
            print_fail "Variable missing"
            ((failed++))
        fi
    done
    
    return $failed
}

test_injection_patterns() {
    section "Prompt Injection Pattern Tests"
    
    local patterns=(
        "ignore previous instructions"
        "disregard all previous"
        "you are now"
        "new instructions"
    )
    
    print_info "Checking if common injection patterns are blocked"
    
    local failed=0
    for pattern in "${patterns[@]}"; do
        print_test "Pattern: '$pattern'"
        if jq -e ".security.prompt_injection_defense.blocked_patterns | map(. | ascii_downcase) | contains([\"$pattern\"])" "$PROJECT_ROOT/openclaw.json" >/dev/null 2>&1; then
            print_pass "Pattern is blocked"
        else
            print_fail "Pattern not blocked"
            ((failed++))
        fi
    done
    
    return $failed
}

test_security_defaults() {
    section "Security Defaults Tests"
    
    print_test "Authentication enabled by default"
    if jq -e '.security.authentication.enabled == true' "$PROJECT_ROOT/openclaw.json" >/dev/null; then
        print_pass "Enabled"
    else
        print_fail "Disabled"
        return 1
    fi
    
    print_test "Prompt injection defense enabled"
    if jq -e '.security.prompt_injection_defense.enabled == true' "$PROJECT_ROOT/openclaw.json" >/dev/null; then
        print_pass "Enabled"
    else
        print_fail "Disabled"
        return 1
    fi
    
    print_test "Kill switch enabled"
    if jq -e '.operational.failsafe.kill_switch_enabled == true' "$PROJECT_ROOT/openclaw.json" >/dev/null; then
        print_pass "Enabled"
    else
        print_fail "Disabled"
        return 1
    fi
    
    print_test "Rate limiting configured"
    if jq -e '.security.authentication.rate_limiting.enabled == true' "$PROJECT_ROOT/openclaw.json" >/dev/null; then
        print_pass "Configured"
    else
        print_fail "Not configured"
        return 1
    fi
    
    return 0
}

test_script_safety() {
    section "Script Safety Tests"
    
    local scripts=("setup.sh" "kill-switch.sh" "health-check.sh")
    local failed=0
    
    for script in "${scripts[@]}"; do
        print_test "Checking $script for 'set -e'"
        if grep -q "^set -e" "$PROJECT_ROOT/scripts/$script"; then
            print_pass "Safe mode enabled"
        else
            print_fail "No 'set -e' found"
            ((failed++))
        fi
    done
    
    return $failed
}

run_all_tests() {
    print_header
    
    local total_failed=0
    
    test_files_exist || ((total_failed+=$?))
    test_scripts_executable || ((total_failed+=$?))
    test_json_valid || ((total_failed+=$?))
    test_soul_content || ((total_failed+=$?))
    test_gitignore || ((total_failed+=$?))
    test_env_example || ((total_failed+=$?))
    test_injection_patterns || ((total_failed+=$?))
    test_security_defaults || ((total_failed+=$?))
    test_script_safety || ((total_failed+=$?))
    
    echo ""
    section "Test Summary"
    echo ""
    
    if [ $total_failed -eq 0 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ALL TESTS PASSED! ✓                           ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "ShieldClaw is properly configured and ready to use!"
        echo ""
        echo "Next steps:"
        echo "  1. Run: ./scripts/setup.sh"
        echo "  2. Customize: openclaw.json and SOUL.md"
        echo "  3. Verify: ./scripts/health-check.sh"
        echo ""
        return 0
    else
        echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║          TESTS FAILED! ✗                               ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${RED}$total_failed test(s) failed.${NC}"
        echo ""
        echo "Please review the errors above and fix them before proceeding."
        echo ""
        return 1
    fi
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        --help|-h)
            echo "ShieldClaw Verification Script"
            echo ""
            echo "Usage:"
            echo "  ./verify.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (no args)  Run all verification tests"
            echo "  --help, -h Show this help"
            ;;
        *)
            run_all_tests
            ;;
    esac
}

main "$@"
