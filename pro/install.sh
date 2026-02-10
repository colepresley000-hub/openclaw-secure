#!/bin/bash

# ShieldClaw Monitor Installation Script

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     ShieldClaw Monitor Installation                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check Python version
echo "Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
required_version="3.9"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,9) else 1)"; then
    echo "❌ Python 3.9+ required. Found: $python_version"
    exit 1
fi

echo "✓ Python $python_version OK"
echo ""

# Check if ShieldClaw (free) is installed
echo "Checking for ShieldClaw (free)..."
if [ ! -f "../openclaw.json" ] && [ ! -f "openclaw.json" ]; then
    echo "⚠️  ShieldClaw (free) not found"
    echo ""
    echo "ShieldClaw Monitor requires the free ShieldClaw toolkit."
    echo "Install it first:"
    echo "  git clone https://github.com/colepresley000-hub/openclaw-secure.git"
    echo "  cd openclaw-secure"
    echo "  ./scripts/setup.sh"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ ShieldClaw (free) found"
fi
echo ""

# Install Python dependencies
echo "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    python3 -m pip install -r requirements.txt --quiet
    echo "✓ Dependencies installed"
else
    echo "❌ requirements.txt not found"
    exit 1
fi
echo ""

# Create directories
echo "Creating directories..."
mkdir -p logs data web config
echo "✓ Directories created"
echo ""

# Setup environment
echo "Setting up environment..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✓ Created .env file"
    echo "⚠️  Edit .env with your configuration"
else
    echo "⚠️  .env already exists, skipping"
fi
echo ""

# Initialize database
echo "Initializing database..."
python3 -c "
from monitor.monitor import SecurityMonitor
monitor = SecurityMonitor()
print('✓ Database initialized')
"
echo ""

# Create sample metrics file
echo "Creating sample metrics..."
cat > web/metrics.json <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "events": {"recent": []},
  "drift": {"unacknowledged": 0},
  "api": {
    "total_requests": 0,
    "avg_response_time": 0,
    "total_tokens": 0,
    "suspicious_requests": 0
  },
  "health": {
    "status": "healthy",
    "checks": {}
  }
}
EOF
echo "✓ Sample metrics created"
echo ""

# Make scripts executable
echo "Making scripts executable..."
chmod +x monitor/*.py
echo "✓ Scripts ready"
echo ""

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Installation Complete! ✓                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure your environment:"
echo "   nano .env"
echo ""
echo "2. Start monitoring:"
echo "   python3 monitor/monitor.py"
echo ""
echo "3. View dashboard:"
echo "   cd web && python3 -m http.server 8000"
echo "   Open http://localhost:8000/dashboard.html"
echo ""
echo "4. Set up as service (optional):"
echo "   sudo cp monitor.service /etc/systemd/system/"
echo "   sudo systemctl enable monitor"
echo "   sudo systemctl start monitor"
echo ""
echo "Documentation: README.md"
echo "Support: https://github.com/colepresley000-hub/shieldclaw-monitor"
echo ""
