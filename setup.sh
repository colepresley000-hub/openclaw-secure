#!/bin/bash

# ShieldClaw Interactive Setup Script
# Configures OpenClaw with hardened security settings

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
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║           ShieldClaw Security Setup v1.0.0             ║"
    echo "║        Hardened Configuration for OpenClaw             ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local deps=("jq" "openssl" "curl")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Install them with:"
        echo "  Ubuntu/Debian: sudo apt-get install ${missing[*]}"
        echo "  macOS: brew install ${missing[*]}"
        exit 1
    fi
    
    print_success "All dependencies found"
}

validate_api_key() {
    local key="$1"
    
    # Basic validation - should start with sk- and be reasonable length
    if [[ ! "$key" =~ ^sk-ant-[a-zA-Z0-9_-]{32,}$ ]]; then
        return 1
    fi
    
    return 0
}

setup_environment() {
    print_info "Setting up environment configuration..."
    
    if [ -f "$ENV_FILE" ]; then
        echo ""
        read -p "$(echo -e ${YELLOW})⚠ .env file exists. Overwrite? (y/N): $(echo -e ${NC})" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Keeping existing .env file"
            return
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  API Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # API Key
    while true; do
        read -sp "Enter Anthropic API Key (sk-ant-...): " api_key
        echo ""
        
        if validate_api_key "$api_key"; then
            break
        else
            print_error "Invalid API key format. Should start with 'sk-ant-'"
        fi
    done
    
    # Generate session secret
    print_info "Generating secure session secret..."
    session_secret=$(openssl rand -hex 32)
    
    # Encryption key
    print_info "Generating encryption key..."
    encryption_key=$(openssl rand -base64 32)
    
    # Environment selection
    echo ""
    echo "Select environment:"
    echo "  1) Development"
    echo "  2) Production"
    read -p "Choice [1]: " env_choice
    env_choice=${env_choice:-1}
    
    if [ "$env_choice" = "2" ]; then
        environment="production"
    else
        environment="development"
    fi
    
    # Write .env file
    cat > "$ENV_FILE" <<EOF
# ShieldClaw Environment Configuration
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Environment
NODE_ENV=$environment

# API Configuration
ANTHROPIC_API_KEY=$api_key
MODEL_ID=claude-sonnet-4-20250514

# Security
SESSION_SECRET=$session_secret
ENCRYPTION_KEY=$encryption_key

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE=60
RATE_LIMIT_BURST=10

# Operational
PORT=3000
LOG_LEVEL=info
HEALTH_CHECK_INTERVAL=300

# Features
ENABLE_PROMPT_INJECTION_DEFENSE=true
ENABLE_PII_DETECTION=true
ENABLE_AUDIT_LOGGING=true
KILL_SWITCH_ENABLED=true

# Paths
CONFIG_FILE=openclaw.json
SOUL_FILE=SOUL.md
LOG_DIR=./logs
EOF

    chmod 600 "$ENV_FILE"
    print_success "Environment file created and secured"
}

configure_security() {
    print_info "Configuring security settings..."
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Security Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # IP whitelist
    read -p "Enable IP whitelist? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        jq '.security.authentication.ip_whitelist.enabled = true' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        echo "Enter allowed IP addresses (one per line, empty line to finish):"
        ips=()
        while read -r ip; do
            [ -z "$ip" ] && break
            ips+=("\"$ip\"")
        done
        
        if [ ${#ips[@]} -gt 0 ]; then
            ip_json=$(printf '%s\n' "${ips[@]}" | jq -s .)
            jq ".security.authentication.ip_whitelist.allowed_ips = $ip_json" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
            mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi
    
    # Custom blocked patterns
    read -p "Add custom blocked patterns for prompt injection? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Enter patterns to block (one per line, empty line to finish):"
        patterns=()
        while read -r pattern; do
            [ -z "$pattern" ] && break
            patterns+=("\"$pattern\"")
        done
        
        if [ ${#patterns[@]} -gt 0 ]; then
            current_patterns=$(jq '.security.prompt_injection_defense.blocked_patterns' "$CONFIG_FILE")
            new_patterns=$(printf '%s\n' "${patterns[@]}" | jq -s .)
            merged=$(jq -n --argjson a "$current_patterns" --argjson b "$new_patterns" '$a + $b | unique')
            jq ".security.prompt_injection_defense.blocked_patterns = $merged" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
            mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi
    
    print_success "Security configuration updated"
}

setup_directories() {
    print_info "Creating necessary directories..."
    
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/data"
    mkdir -p "$PROJECT_ROOT/backups"
    
    chmod 750 "$PROJECT_ROOT/logs"
    chmod 750 "$PROJECT_ROOT/data"
    chmod 750 "$PROJECT_ROOT/backups"
    
    print_success "Directories created"
}

verify_setup() {
    print_info "Verifying setup..."
    
    local errors=0
    
    # Check files exist
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "openclaw.json not found"
        ((errors++))
    fi
    
    if [ ! -f "$SOUL_FILE" ]; then
        print_error "SOUL.md not found"
        ((errors++))
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        print_error ".env not found"
        ((errors++))
    fi
    
    # Validate JSON
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        print_error "openclaw.json is invalid JSON"
        ((errors++))
    fi
    
    # Check permissions
    if [ "$(stat -c %a "$ENV_FILE" 2>/dev/null || stat -f %A "$ENV_FILE" 2>/dev/null)" != "600" ]; then
        print_warning ".env file permissions should be 600"
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "Setup verification passed"
        return 0
    else
        print_error "Setup verification failed with $errors error(s)"
        return 1
    fi
}

generate_soul_hash() {
    print_info "Generating SOUL.md verification hash..."
    
    hash=$(openssl dgst -sha256 "$SOUL_FILE" | awk '{print $2}')
    
    # Update SOUL.md with hash
    sed -i.bak "s/SHA-256: \[Generate after deployment\]/SHA-256: $hash/" "$SOUL_FILE"
    rm -f "$SOUL_FILE.bak"
    
    print_success "Verification hash: $hash"
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║              Setup Complete! 🎉                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Review configuration:"
    echo "     less openclaw.json"
    echo ""
    echo "  2. Test your setup:"
    echo "     ./scripts/health-check.sh"
    echo ""
    echo "  3. Start your OpenClaw instance"
    echo ""
    echo "  4. In case of emergency:"
    echo "     ./scripts/kill-switch.sh"
    echo ""
    echo "Security reminders:"
    echo "  • Never commit .env to version control"
    echo "  • Review SOUL.md regularly"
    echo "  • Monitor logs for injection attempts"
    echo "  • Keep API keys secure"
    echo ""
}

# Main execution
main() {
    print_header
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    echo "This script will configure ShieldClaw with hardened security settings."
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    echo ""
    
    check_dependencies
    setup_directories
    setup_environment
    configure_security
    generate_soul_hash
    
    echo ""
    
    if verify_setup; then
        print_next_steps
        exit 0
    else
        print_error "Setup completed with errors. Please review and fix."
        exit 1
    fi
}

# Run main function
main "$@"
