#!/bin/bash

# ShieldClaw Emergency Kill Switch
# Immediately stops OpenClaw and enters safe mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOCKFILE="$PROJECT_ROOT/.killswitch.lock"
INCIDENT_LOG="$PROJECT_ROOT/logs/incidents.log"
ENV_FILE="$PROJECT_ROOT/.env"

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

print_banner() {
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║           ⚠️  EMERGENCY KILL SWITCH ⚠️                  ║"
    echo "║                                                        ║"
    echo "║  This will immediately shutdown OpenClaw               ║"
    echo "║  and enter safe mode                                   ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_incident() {
    local reason="$1"
    local details="$2"
    
    mkdir -p "$(dirname "$INCIDENT_LOG")"
    
    cat >> "$INCIDENT_LOG" <<EOF

═══════════════════════════════════════════════════════════
KILL SWITCH ACTIVATION
═══════════════════════════════════════════════════════════
Timestamp: $TIMESTAMP
Reason: $reason
Details: $details
Initiated by: $(whoami)
Host: $(hostname)
═══════════════════════════════════════════════════════════

EOF
}

stop_processes() {
    echo -e "${YELLOW}Stopping OpenClaw processes...${NC}"
    
    # Try to stop via process name
    if pgrep -f "openclaw" > /dev/null; then
        pkill -TERM -f "openclaw" 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        if pgrep -f "openclaw" > /dev/null; then
            echo -e "${RED}Forcing process termination...${NC}"
            pkill -KILL -f "openclaw" 2>/dev/null || true
        fi
    fi
    
    # Stop common Node.js processes that might be OpenClaw
    if pgrep -f "node.*openclaw" > /dev/null; then
        pkill -TERM -f "node.*openclaw" 2>/dev/null || true
        sleep 2
        pkill -KILL -f "node.*openclaw" 2>/dev/null || true
    fi
    
    # Check if using pm2
    if command -v pm2 &> /dev/null; then
        pm2 delete openclaw 2>/dev/null || true
        pm2 kill 2>/dev/null || true
    fi
    
    # Check if using systemd
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet openclaw 2>/dev/null; then
            sudo systemctl stop openclaw 2>/dev/null || true
        fi
    fi
    
    echo -e "${GREEN}✓ Processes stopped${NC}"
}

block_network() {
    echo -e "${YELLOW}Blocking network access...${NC}"
    
    # Create or update firewall rules (requires sudo)
    if command -v ufw &> /dev/null; then
        echo "UFW detected. To block network access, run:"
        echo "  sudo ufw deny from any to any port 3000"
    elif command -v iptables &> /dev/null; then
        echo "iptables detected. To block network access, run:"
        echo "  sudo iptables -A INPUT -p tcp --dport 3000 -j DROP"
    else
        echo -e "${YELLOW}⚠ No firewall tool detected. Manually block port access.${NC}"
    fi
    
    echo -e "${GREEN}✓ Network blocking instructions provided${NC}"
}

disable_api_key() {
    echo -e "${YELLOW}Disabling API access...${NC}"
    
    if [ -f "$ENV_FILE" ]; then
        # Backup original .env
        cp "$ENV_FILE" "$ENV_FILE.killswitch.bak"
        
        # Comment out API key
        sed -i.tmp 's/^ANTHROPIC_API_KEY=/#ANTHROPIC_API_KEY=/' "$ENV_FILE"
        rm -f "$ENV_FILE.tmp"
        
        echo -e "${GREEN}✓ API key disabled (backed up to .env.killswitch.bak)${NC}"
    else
        echo -e "${YELLOW}⚠ .env file not found${NC}"
    fi
}

create_lockfile() {
    echo -e "${YELLOW}Creating kill switch lock...${NC}"
    
    cat > "$LOCKFILE" <<EOF
KILL SWITCH ACTIVATED
═══════════════════════════════════════
Activated: $TIMESTAMP
Status: LOCKED
═══════════════════════════════════════

OpenClaw is in emergency shutdown mode.

To restore service:
1. Investigate the incident
2. Fix the security issue
3. Run: ./scripts/kill-switch.sh --unlock
4. Restart OpenClaw

DO NOT bypass this lock without proper investigation.
EOF
    
    chmod 444 "$LOCKFILE"
    echo -e "${GREEN}✓ Lock file created${NC}"
}

check_status() {
    echo ""
    echo "════════════════════════════════════════"
    echo "  System Status Check"
    echo "════════════════════════════════════════"
    echo ""
    
    # Check if locked
    if [ -f "$LOCKFILE" ]; then
        echo -e "${RED}Status: LOCKED${NC}"
        echo ""
        cat "$LOCKFILE"
        return
    else
        echo -e "${GREEN}Status: OPERATIONAL${NC}"
    fi
    
    # Check for running processes
    if pgrep -f "openclaw" > /dev/null; then
        echo -e "${GREEN}Processes: RUNNING${NC}"
    else
        echo -e "${YELLOW}Processes: STOPPED${NC}"
    fi
    
    # Check API key
    if [ -f "$ENV_FILE" ]; then
        if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE"; then
            echo -e "${GREEN}API Key: ENABLED${NC}"
        else
            echo -e "${RED}API Key: DISABLED${NC}"
        fi
    fi
    
    echo ""
}

unlock() {
    echo -e "${YELLOW}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Unlocking Kill Switch"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo ""
    echo "Before unlocking, ensure:"
    echo "  1. Security incident has been investigated"
    echo "  2. Vulnerabilities have been patched"
    echo "  3. Logs have been reviewed"
    echo "  4. System integrity verified"
    echo ""
    read -p "Have you completed all checks? (yes/NO): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${RED}Unlock cancelled.${NC}"
        exit 1
    fi
    
    # Restore API key
    if [ -f "$ENV_FILE.killswitch.bak" ]; then
        echo -e "${YELLOW}Restoring API configuration...${NC}"
        mv "$ENV_FILE.killswitch.bak" "$ENV_FILE"
        chmod 600 "$ENV_FILE"
        echo -e "${GREEN}✓ API key restored${NC}"
    fi
    
    # Remove lock file
    if [ -f "$LOCKFILE" ]; then
        rm -f "$LOCKFILE"
        echo -e "${GREEN}✓ Lock file removed${NC}"
    fi
    
    # Log unlock
    log_incident "UNLOCKED" "Kill switch manually unlocked after incident resolution"
    
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║            Kill Switch Unlocked                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "You can now restart OpenClaw."
    echo "Review logs before starting: tail -f logs/incidents.log"
    echo ""
}

activate_killswitch() {
    local reason="${1:-Manual activation}"
    local details="${2:-No details provided}"
    
    print_banner
    echo ""
    echo -e "${RED}Reason: $reason${NC}"
    echo ""
    
    read -p "Activate kill switch? (yes/NO): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Kill switch activation cancelled."
        exit 0
    fi
    
    echo ""
    echo "Initiating emergency shutdown..."
    echo ""
    
    # Log the incident
    log_incident "$reason" "$details"
    
    # Execute shutdown sequence
    stop_processes
    disable_api_key
    block_network
    create_lockfile
    
    # Final status
    echo ""
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         KILL SWITCH ACTIVATED                          ║"
    echo "║         System is now in safe mode                     ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review incident log: less logs/incidents.log"
    echo "  2. Investigate the security issue"
    echo "  3. Check system logs: journalctl -u openclaw"
    echo "  4. After fixing, unlock: ./scripts/kill-switch.sh --unlock"
    echo ""
    echo -e "${YELLOW}Alert your security team immediately.${NC}"
    echo ""
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        --status)
            check_status
            ;;
        --unlock)
            unlock
            ;;
        --help)
            echo "ShieldClaw Emergency Kill Switch"
            echo ""
            echo "Usage:"
            echo "  ./kill-switch.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (no args)     Activate kill switch"
            echo "  --status      Check current status"
            echo "  --unlock      Unlock after incident resolution"
            echo "  --help        Show this help"
            echo ""
            echo "Examples:"
            echo "  ./kill-switch.sh"
            echo "  ./kill-switch.sh --status"
            echo "  ./kill-switch.sh --unlock"
            ;;
        *)
            activate_killswitch "${1:-Manual activation}" "${2:-Emergency stop initiated}"
            ;;
    esac
}

# Run main function
main "$@"
