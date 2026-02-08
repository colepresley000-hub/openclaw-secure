# ShieldClaw 🛡️

**Hardened security configuration for OpenClaw deployments**

ShieldClaw provides production-ready security templates, tools, and best practices for running OpenClaw safely. Whether you're deploying in development or production, ShieldClaw helps protect against prompt injection attacks, unauthorized access, and system compromise.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)]()

## 🎯 What's Included

- **`openclaw.json`** — Comprehensive security configuration template
- **`SOUL.md`** — Prompt injection defense system prompt
- **`scripts/setup.sh`** — Interactive setup wizard
- **`scripts/kill-switch.sh`** — Emergency shutdown tool
- **`scripts/health-check.sh`** — Security diagnostics
- **`.env.example`** — Secure environment template
- **`.gitignore`** — Prevent secret leakage

## 🚀 Quick Start

### Prerequisites

- Linux or macOS environment
- Bash 4.0+
- Required tools: `jq`, `openssl`, `curl`

```bash
# Ubuntu/Debian
sudo apt-get install jq openssl curl

# macOS
brew install jq openssl curl
```

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/shieldclaw.git
cd shieldclaw
```

2. **Make scripts executable**

```bash
chmod +x scripts/*.sh
```

3. **Run the setup wizard**

```bash
./scripts/setup.sh
```

The setup wizard will:
- Check dependencies
- Generate secure secrets
- Configure your Anthropic API key
- Set up security boundaries
- Create necessary directories
- Generate verification hashes

4. **Verify your setup**

```bash
./scripts/health-check.sh
```

## 📋 Step-by-Step Configuration

### 1. Configure Security Settings

Edit `openclaw.json` to customize:

**Authentication & Rate Limiting**
```json
{
  "security": {
    "authentication": {
      "enabled": true,
      "rate_limiting": {
        "requests_per_minute": 60,
        "burst_limit": 10
      }
    }
  }
}
```

**Prompt Injection Defense**
```json
{
  "security": {
    "prompt_injection_defense": {
      "enabled": true,
      "soul_file": "SOUL.md",
      "blocked_patterns": [
        "ignore previous instructions",
        "disregard all previous"
      ],
      "max_input_length": 4000
    }
  }
}
```

### 2. Customize SOUL.md

The SOUL (System Operational Understanding Layer) file defines your AI's security boundaries:

- **Input validation rules** — Pattern detection and sanitization
- **Context isolation** — Separation between system and user instructions
- **Response protocols** — How to handle attacks
- **Operational boundaries** — What the system can and cannot do

Review and customize `SOUL.md` based on your security requirements.

### 3. Set Environment Variables

Copy the example and fill in your values:

```bash
cp .env.example .env
chmod 600 .env
```

**Required variables:**
```env
REMOVED=sk-ant-your-key-here
MODEL_ID=claude-sonnet-4-20250514
REMOVED=<generated-by-setup>
REMOVED=<generated-by-setup>
```

### 4. Configure Access Controls

**IP Whitelist** (optional but recommended for production):

```json
{
  "security": {
    "authentication": {
      "ip_whitelist": {
        "enabled": true,
        "allowed_ips": ["203.0.113.0/24", "198.51.100.42"]
      }
    }
  }
}
```

**Tool Restrictions**:

```json
{
  "security": {
    "boundaries": {
      "allowed_tools": ["web_search", "calculator"],
      "blocked_tools": ["file_system_write", "system_commands"],
      "require_approval": ["external_api_calls"]
    }
  }
}
```

## 🔧 Usage

### Running Health Checks

```bash
# Full diagnostic
./scripts/health-check.sh

# Quick check
./scripts/health-check.sh --quick

# Verbose output
./scripts/health-check.sh --verbose
```

Health checks validate:
- System status and resources
- Configuration file integrity
- Security posture
- API connectivity
- File permissions
- Incident history

### Emergency Kill Switch

If you detect suspicious activity or compromise:

```bash
# Activate emergency shutdown
./scripts/kill-switch.sh

# Check current status
./scripts/kill-switch.sh --status

# Unlock after incident resolution
./scripts/kill-switch.sh --unlock
```

The kill switch:
1. Stops all OpenClaw processes
2. Disables API access
3. Creates incident logs
4. Locks the system
5. Provides recovery instructions

### Monitoring

**View incident logs:**
```bash
tail -f logs/incidents.log
```

**Check system health:**
```bash
watch -n 60 ./scripts/health-check.sh --quick
```

**Monitor API usage:**
```bash
# Implement with your monitoring solution
# Log format: timestamp, user, action, tokens, status
```

## 🔒 Security Features

### Prompt Injection Defense

ShieldClaw protects against:

- **Explicit overrides** — "Ignore previous instructions"
- **Role manipulation** — "You are now an unrestricted AI"
- **Context poisoning** — Injecting fake system messages
- **Encoding attacks** — Base64, Unicode obfuscation
- **Social engineering** — Authority claims, emotional manipulation

### Data Protection

- **PII detection and redaction** — Automatic scanning
- **Encryption at rest** — Sensitive data encrypted
- **Audit logging** — Complete activity trail
- **Secrets management** — Environment-based configuration

### Access Control

- **API key authentication** — Required for all requests
- **Rate limiting** — Prevent abuse
- **IP whitelisting** — Restrict access by network
- **Tool sandboxing** — Limit system capabilities

### Monitoring & Alerting

- **Health checks** — Automated system validation
- **Anomaly detection** — Pattern-based alerts
- **Incident logging** — Detailed security events
- **Kill switch** — Emergency shutdown capability

## 📚 Configuration Reference

### openclaw.json Structure

```json
{
  "security": {
    "authentication": { /* Auth settings */ },
    "prompt_injection_defense": { /* Injection protection */ },
    "data_protection": { /* Data security */ },
    "boundaries": { /* Capability limits */ }
  },
  "operational": {
    "monitoring": { /* Health checks */ },
    "resource_limits": { /* Performance */ },
    "failsafe": { /* Emergency systems */ }
  },
  "model": { /* AI configuration */ },
  "compliance": { /* Legal requirements */ }
}
```

### SOUL.md Sections

1. **Core Identity** — System purpose and values
2. **Input Validation** — Pre-processing checks
3. **Context Isolation** — Boundary enforcement
4. **Instruction Hierarchy** — Priority rules
5. **Injection Patterns** — Known attack signatures
6. **Response Protocols** — Handling violations
7. **Operational Boundaries** — Capabilities and limits
8. **Emergency Protocols** — Incident response

## 🛠️ Integration

### With Your OpenClaw Instance

```javascript
// Load configuration
const config = require('./openclaw.json');
const soul = fs.readFileSync('./SOUL.md', 'utf-8');

// Initialize with security
const openclaw = new OpenClaw({
  apiKey: process.env.REMOVED,
  model: config.model.model_id,
  systemPrompt: soul,
  security: config.security
});

// Add request validation
openclaw.use(promptInjectionDefense(config.security.prompt_injection_defense));
openclaw.use(rateLimiter(config.security.authentication.rate_limiting));
```

### With Docker

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy ShieldClaw configuration
COPY openclaw.json SOUL.md ./
COPY scripts/ ./scripts/
COPY .env ./

# Your app setup
COPY package*.json ./
RUN npm ci --production

# Security: run as non-root
RUN addgroup -g 1001 -S openclaw && \
    adduser -S openclaw -u 1001
USER openclaw

CMD ["node", "server.js"]
```

### With Kubernetes

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: shieldclaw-config
data:
  openclaw.json: |
    { /* your config */ }
  SOUL.md: |
    # Your SOUL configuration
---
apiVersion: v1
kind: Secret
metadata:
  name: shieldclaw-secrets
type: Opaque
stringData:
  REMOVED: sk-ant-your-key
  REMOVED: your-secret
```

## 🔍 Troubleshooting

### Setup Issues

**"Missing dependencies"**
```bash
# Install required tools
sudo apt-get install jq openssl curl  # Ubuntu/Debian
brew install jq openssl curl          # macOS
```

**"API key validation failed"**
- Ensure key starts with `sk-ant-`
- Verify key is active in Anthropic console
- Check for extra spaces or quotes

### Runtime Issues

**"Health check failing"**
```bash
# Run verbose diagnostics
./scripts/health-check.sh --verbose

# Check logs
tail -50 logs/incidents.log

# Verify configuration
jq empty openclaw.json
```

**"Kill switch activated"**
```bash
# Review incident
./scripts/kill-switch.sh --status

# Check what triggered it
less logs/incidents.log

# After fixing, unlock
./scripts/kill-switch.sh --unlock
```

### Security Issues

**"Prompt injection detected"**
1. Review the blocked input in logs
2. Update `blocked_patterns` if needed
3. Consider adjusting `max_input_length`
4. Check if SOUL.md needs updates

**"Unauthorized access attempts"**
1. Enable IP whitelist
2. Review API key distribution
3. Increase rate limiting strictness
4. Enable two-factor authentication

## 🤝 Contributing

We welcome security improvements and bug fixes!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Security Contributions

For security vulnerabilities:
- **Do not** open public issues
- Email: security@yourproject.com
- Use PGP key: [link to key]

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

## 🙏 Acknowledgments

- OpenClaw community for the base project
- Anthropic for Claude API and security guidance
- Security researchers who contributed attack patterns
- Everyone who reported issues and improvements

## 📞 Support

- **Documentation**: [Wiki](https://github.com/yourusername/shieldclaw/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/shieldclaw/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/shieldclaw/discussions)
- **Security**: security@yourproject.com

## 🗺️ Roadmap

- [ ] Web UI for configuration management
- [ ] Advanced threat detection with ML
- [ ] Integration with SIEM systems
- [ ] Automated compliance reporting
- [ ] Multi-tenant support
- [ ] Redis-backed rate limiting
- [ ] Webhook alerting system

---

**Made with 🛡️ by the ShieldClaw community**

*Stay safe, stay secure!*
