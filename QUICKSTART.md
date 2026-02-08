# Quick Start Guide

Get ShieldClaw up and running in 5 minutes!

## Prerequisites

- Linux or macOS
- Bash 4.0+
- Internet connection

## Step 1: Install Dependencies (2 minutes)

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y jq openssl curl
```

### macOS
```bash
brew install jq openssl curl
```

### Verify Installation
```bash
jq --version && openssl version && curl --version
```

## Step 2: Get an API Key (1 minute)

1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Navigate to API Keys
4. Create a new key
5. Copy it (starts with `sk-ant-`)

## Step 3: Run Setup (2 minutes)

```bash
cd shieldclaw
chmod +x scripts/*.sh
./scripts/setup.sh
```

The setup wizard will ask you:
1. Your Anthropic API key
2. Environment (dev/prod)
3. Security preferences

It will automatically:
- Generate secure secrets
- Create configuration files
- Set proper permissions
- Verify the setup

## Step 4: Verify (30 seconds)

```bash
./scripts/health-check.sh
```

You should see all checks passing! ✓

## What's Next?

### Integrate with Your OpenClaw Instance

```javascript
// Load configuration
const config = require('./openclaw.json');
const soul = fs.readFileSync('./SOUL.md', 'utf-8');

// Initialize
const openclaw = new OpenClaw({
  apiKey: process.env.ANTHROPIC_API_KEY,
  systemPrompt: soul,
  security: config.security
});
```

### Customize Your Security

1. **Edit `openclaw.json`** - Adjust security settings
2. **Customize `SOUL.md`** - Add your specific rules
3. **Review `.env`** - Configure operational parameters

### Monitor Your System

```bash
# Check health
./scripts/health-check.sh

# View logs
tail -f logs/incidents.log

# Check status
./scripts/kill-switch.sh --status
```

## Emergency Procedures

### If You Detect a Security Issue

```bash
# Immediate shutdown
./scripts/kill-switch.sh

# Review logs
less logs/incidents.log

# After fixing
./scripts/kill-switch.sh --unlock
```

## Common Issues

### "Missing dependencies"
```bash
# Install missing tools
sudo apt-get install jq openssl curl  # Ubuntu
brew install jq openssl curl          # macOS
```

### "API key invalid"
- Ensure it starts with `sk-ant-`
- Check for typos or extra spaces
- Verify it's active in console.anthropic.com

### "Permission denied"
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### "Health check failing"
```bash
# Run verbose diagnostics
./scripts/health-check.sh --verbose

# Check configuration
jq empty openclaw.json
```

## Configuration Examples

### Development Setup
```json
{
  "security": {
    "authentication": {
      "enabled": true,
      "rate_limiting": {
        "requests_per_minute": 100
      }
    },
    "prompt_injection_defense": {
      "enabled": true
    }
  }
}
```

### Production Setup
```json
{
  "security": {
    "authentication": {
      "enabled": true,
      "rate_limiting": {
        "requests_per_minute": 60,
        "burst_limit": 10
      },
      "ip_whitelist": {
        "enabled": true,
        "allowed_ips": ["203.0.113.0/24"]
      }
    },
    "prompt_injection_defense": {
      "enabled": true,
      "max_input_length": 4000
    },
    "data_protection": {
      "pii_detection": true,
      "audit_logging": true
    }
  }
}
```

## Resources

- **Full Documentation**: See README.md
- **Security Policy**: See SECURITY.md
- **Contributing**: See CONTRIBUTING.md
- **API Reference**: https://docs.anthropic.com/

## Need Help?

- GitHub Issues: Report bugs
- GitHub Discussions: Ask questions
- Email: security@yourproject.com (security only)

---

**You're all set! 🛡️**

Start building with confidence knowing your OpenClaw instance is secured by ShieldClaw.
