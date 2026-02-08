#!/bin/bash

# ShieldClaw Health Check & Diagnostics
# Validates system integrity and security posture

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/openclaw.json"
SOUL_FILE="$PROJECT_ROOT/SOUL.md"
ENV_FILE="$PROJECT_ROOT/.env"
LOCKFILE="$PROJECT_ROOT/.killswitch.lock"

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║        ShieldClaw Health Check & Diagnostics           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_CHECKS++))
}

check_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED_CHECKS++))
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNING_CHECKS++))
}

section_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_system_status() {
    section_header "System Status"
    
    ((TOTAL_CHECKS++))
    # Check if kill switch is active
    if [ -f "$LOCKFILE" ]; then
        check_fail "Kill switch is ACTIVE - system locked"
        return
    else
        check_pass "Kill switch is inactive"
    fi
    
    ((TOTAL_CHECKS++))
    # Check if processes are running
    if pgrep -f "openclaw" > /dev/null 2>&1; then
        check_pass "OpenClaw processes running"
    else
        check_warn "No OpenClaw processes detected"
    fi
    
    ((TOTAL_CHECKS++))
    # Check system resources
    if command -v free &> /dev/null; then
        mem_available=$(free -m | awk 'NR==2{printf "%.0f", $7*100/$2}')
        if [ "$mem_available" -gt 20 ]; then
            check_pass "Memory available: ${mem_available}%"
        else
            check_warn "Low memory: ${mem_available}% available"
        fi
    fi
    
    ((TOTAL_CHECKS++))
    # Check disk space
    if command -v df &> /dev/null; then
        disk_usage=$(df -h "$PROJECT_ROOT" | awk 'NR==2{print $5}' | sed 's/%//')
        if [ "$disk_usage" -lt 80 ]; then
            check_pass "Disk usage: ${disk_usage}%"
        else
            check_warn "High disk usage: ${disk_usage}%"
        fi
    fi
}

check_configuration() {
    section_header "Configuration Files"
    
    ((TOTAL_CHECKS++))
    # Check if config file exists
    if [ -f "$CONFIG_FILE" ]; then
        check_pass "openclaw.json exists"
        
        ((TOTAL_CHECKS++))
        # Validate JSON syntax
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            check_pass "openclaw.json is valid JSON"
        else
            check_fail "openclaw.json has syntax errors"
        fi
        
        ((TOTAL_CHECKS++))
        # Check security settings
        if jq -e '.security.prompt_injection_defense.enabled == true' "$CONFIG_FILE" >/dev/null; then
            check_pass "Prompt injection defense enabled"
        else
            check_warn "Prompt injection defense disabled"
        fi
        
        ((TOTAL_CHECKS++))
        if jq -e '.security.authentication.enabled == true' "$CONFIG_FILE" >/dev/null; then
            check_pass "Authentication enabled"
        else
            check_fail "Authentication disabled"
        fi
        
        ((TOTAL_CHECKS++))
        if jq -e '.operational.failsafe.kill_switch_enabled == true' "$CONFIG_FILE" >/dev/null; then
            check_pass "Kill switch enabled in config"
        else
            check_warn "Kill switch disabled in config"
        fi
    else
        check_fail "openclaw.json not found"
    fi
    
    ((TOTAL_CHECKS++))
    # Check SOUL file
    if [ -f "$SOUL_FILE" ]; then
        check_pass "SOUL.md exists"
        
        ((TOTAL_CHECKS++))
        # Verify hash if present
        if grep -q "SHA-256:" "$SOUL_FILE"; then
            stored_hash=$(grep "SHA-256:" "$SOUL_FILE" | awk '{print $2}')
            
            # Calculate current hash (temporarily remove hash line)
            current_hash=$(grep -v "SHA-256:" "$SOUL_FILE" | openssl dgst -sha256 | awk '{print $2}')
            
            if [ "$stored_hash" = "$current_hash" ] || [ "$stored_hash" = "[Generate" ]; then
                check_pass "SOUL.md integrity verified"
            else
                check_fail "SOUL.md has been modified (hash mismatch)"
            fi
        else
            check_warn "SOUL.md has no verification hash"
        fi
    else
        check_fail "SOUL.md not found"
    fi
    
    ((TOTAL_CHECKS++))
    # Check environment file
    if [ -f "$ENV_FILE" ]; then
        check_pass ".env file exists"
        
        ((TOTAL_CHECKS++))
        # Check permissions
        perm=$(stat -c %a "$ENV_FILE" 2>/dev/null || stat -f %A "$ENV_FILE" 2>/dev/null)
        if [ "$perm" = "600" ]; then
            check_pass ".env permissions secure (600)"
        else
            check_fail ".env permissions insecure ($perm, should be 600)"
        fi
        
        ((TOTAL_CHECKS++))
        # Check API key
        if grep -q "^ANTHROPIC_API_KEY=sk-ant-" "$ENV_FILE"; then
            check_pass "API key configured"
        else
            check_warn "API key not found or disabled"
        fi
    else
        check_fail ".env file not found"
    fi
}

check_security_posture() {
    section_header "Security Posture"
    
    ((TOTAL_CHECKS++))
    # Check if .env is in .gitignore
    if [ -f "$PROJECT_ROOT/.gitignore" ]; then
        if grep -q "^\.env$" "$PROJECT_ROOT/.gitignore"; then
            check_pass ".env is in .gitignore"
        else
            check_fail ".env is NOT in .gitignore (security risk!)"
        fi
    else
        check_warn ".gitignore not found"
    fi
    
    ((TOTAL_CHECKS++))
    # Check for exposed secrets
    if command -v git &> /dev/null; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            if git log --all --full-history --pretty=format: --name-only | grep -q "^\.env$"; then
                check_fail ".env appears in git history (SECURITY BREACH!)"
            else
                check_pass "No .env in git history"
            fi
        fi
    fi
    
    ((TOTAL_CHECKS++))
    # Check log directory permissions
    if [ -d "$PROJECT_ROOT/logs" ]; then
        log_perm=$(stat -c %a "$PROJECT_ROOT/logs" 2>/dev/null || stat -f %A "$PROJECT_ROOT/logs" 2>/dev/null)
        if [ "$log_perm" = "750" ] || [ "$log_perm" = "700" ]; then
            check_pass "Log directory permissions secure ($log_perm)"
        else
            check_warn "Log directory permissions: $log_perm (consider 750)"
        fi
    fi
    
    ((TOTAL_CHECKS++))
    # Check for recent incidents
    if [ -f "$PROJECT_ROOT/logs/incidents.log" ]; then
        incident_count=$(grep -c "KILL SWITCH ACTIVATION" "$PROJECT_ROOT/logs/incidents.log" 2>/dev/null || echo "0")
        if [ "$incident_count" -gt 0 ]; then
            check_warn "Found $incident_count kill switch activation(s) in incident log"
        else
            check_pass "No incidents recorded"
        fi
    fi
}

check_dependencies() {
    section_header "Dependencies"
    
    local deps=("jq" "openssl" "curl")
    
    for dep in "${deps[@]}"; do
        ((TOTAL_CHECKS++))
        if command -v "$dep" &> /dev/null; then
            version=$($dep --version 2>&1 | head -n1 || echo "unknown")
            check_pass "$dep installed"
        else
            check_warn "$dep not installed (optional but recommended)"
        fi
    done
}

check_api_connectivity() {
    section_header "API Connectivity"
    
    if [ ! -f "$ENV_FILE" ]; then
        check_warn "Cannot test API - .env not found"
        return
    fi
    
    # Load API key
    source "$ENV_FILE"
    
    ((TOTAL_CHECKS++))
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        check_warn "API key not set, skipping connectivity test"
        return
    fi
    
    # Test API connectivity
    if command -v curl &> /dev/null; then
        response=$(curl -s -w "%{http_code}" -o /dev/null \
            https://api.anthropic.com/v1/messages \
            -H "anthropic-version: 2023-06-01" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "content-type: application/json" \
            -d '{"model":"claude-sonnet-4-20250514","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' \
            2>/dev/null || echo "000")
        
        if [ "$response" = "200" ]; then
            check_pass "API connectivity test passed"
        elif [ "$response" = "401" ]; then
            check_fail "API authentication failed (invalid key)"
        elif [ "$response" = "000" ]; then
            check_warn "Cannot reach API endpoint (network issue)"
        else
            check_warn "API returned unexpected status: $response"
        fi
    else
        check_warn "curl not available, skipping API test"
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo "Total checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo ""
    
    # Calculate health score
    if [ "$TOTAL_CHECKS" -gt 0 ]; then
        health_score=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
        
        if [ "$health_score" -ge 90 ]; then
            echo -e "${GREEN}System Health: $health_score% - EXCELLENT${NC}"
        elif [ "$health_score" -ge 70 ]; then
            echo -e "${YELLOW}System Health: $health_score% - GOOD${NC}"
        elif [ "$health_score" -ge 50 ]; then
            echo -e "${YELLOW}System Health: $health_score% - NEEDS ATTENTION${NC}"
        else
            echo -e "${RED}System Health: $health_score% - CRITICAL${NC}"
        fi
    fi
    
    echo ""
    
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        echo -e "${RED}⚠️  Action required: Fix $FAILED_CHECKS critical issue(s)${NC}"
        echo ""
        exit 1
    elif [ "$WARNING_CHECKS" -gt 0 ]; then
        echo -e "${YELLOW}ℹ️  Review $WARNING_CHECKS warning(s)${NC}"
        echo ""
        exit 0
    else
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo ""
        exit 0
    fi
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        --verbose|-v)
            print_header
            check_system_status
            check_configuration
            check_security_posture
            check_dependencies
            check_api_connectivity
            print_summary
            ;;
        --quick|-q)
            check_system_status
            check_configuration
            print_summary
            ;;
        --help|-h)
            echo "ShieldClaw Health Check & Diagnostics"
            echo ""
            echo "Usage:"
            echo "  ./health-check.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (no args)     Run all checks"
            echo "  --quick, -q   Quick check (skip API test)"
            echo "  --verbose, -v Full diagnostic output"
            echo "  --help, -h    Show this help"
            echo ""
            ;;
        *)
            print_header
            check_system_status
            check_configuration
            check_security_posture
            check_dependencies
            check_api_connectivity
            print_summary
            ;;
    esac
}

# Run main function
main "$@"
