# ShieldClaw Monitor

**24/7 Runtime Security Monitoring for OpenClaw Deployments**

ShieldClaw Monitor extends the free [ShieldClaw toolkit](https://github.com/colepresley000-hub/openclaw-secure) with continuous monitoring, automated drift detection, and real-time security alerts.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)

## 🎯 What is ShieldClaw Monitor?

**ShieldClaw (Free)** secures your OpenClaw deployment → **ShieldClaw Monitor** keeps it secure 24/7

```
┌─────────────────────────────────────┐
│  ShieldClaw Monitor (This Repo)     │
│  Runtime monitoring & alerts         │
├─────────────────────────────────────┤
│  Your OpenClaw Application           │
├─────────────────────────────────────┤
│  ShieldClaw (Free)                   │
│  Deployment security foundation      │
└─────────────────────────────────────┘
```

## ✨ Features

### Core Monitoring
- **24/7 Daemon** - Continuous runtime monitoring
- **Drift Detection** - Automatic configuration change detection
- **Injection Scanning** - Real-time prompt injection attempt detection
- **Health Monitoring** - System status and resource tracking
- **Audit Scheduler** - Automated security audits

### Alerts & Notifications
- **Email** - SMTP-based alerts
- **Slack** - Webhook integration
- **Discord** - Bot notifications
- **SMS** - Twilio integration for critical alerts

### Dashboard
- **Web UI** - Real-time monitoring dashboard
- **Metrics** - API usage, response times, tokens
- **Event History** - Complete security event log
- **Health Status** - System health at a glance

## 🚀 Quick Start

### Prerequisites

- ShieldClaw (free) already installed
- Python 3.9 or higher
- SQLite or PostgreSQL

### Installation

1. **Clone this repository**

```bash
git clone https://github.com/colepresley000-hub/shieldclaw-monitor.git
cd shieldclaw-monitor
```

2. **Install dependencies**

```bash
pip install -r requirements.txt
```

3. **Configure environment**

```bash
cp .env.example .env
# Edit .env with your settings
```

4. **Initialize database**

```bash
python monitor/monitor.py --init-db
```

5. **Start monitoring**

```bash
python monitor/monitor.py
```

6. **Open dashboard**

Navigate to `http://localhost:8000/dashboard.html`

## 📋 Configuration

### Environment Variables

```bash
# Monitoring
MONITOR_INTERVAL=60                    # Check interval in seconds
SHIELDCLAW_CONFIG_DIR=./config         # Config directory
SHIELDCLAW_LOG_DIR=./logs              # Logs directory

# Database
SHIELDCLAW_DB=./monitor.db             # SQLite path (or PostgreSQL URL)

# Email Alerts
ALERT_EMAIL_ENABLED=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
ALERT_FROM_EMAIL=alerts@yourcompany.com
ALERT_TO_EMAILS=admin@yourcompany.com,security@yourcompany.com

# Slack Alerts
ALERT_SLACK_ENABLED=true
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Discord Alerts
ALERT_DISCORD_ENABLED=true
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/WEBHOOK/URL

# SMS Alerts (Twilio)
ALERT_SMS_ENABLED=false
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_FROM_NUMBER=+1234567890
ALERT_TO_NUMBERS=+1234567890,+0987654321
```

### Monitored Files

By default, Monitor watches:
- `openclaw.json` - Configuration
- `SOUL.md` - Security prompts
- `.env` - Environment variables

Add more files in `monitor/monitor.py`:

```python
monitored_files = [
    'openclaw.json',
    'SOUL.md',
    '.env',
    'custom-config.json'  # Add your files
]
```

## 🔧 Usage

### Running as Daemon

**Linux/macOS:**

```bash
# Using systemd
sudo cp monitor.service /etc/systemd/system/
sudo systemctl enable monitor
sudo systemctl start monitor

# Check status
sudo systemctl status monitor
```

**Using nohup:**

```bash
nohup python monitor/monitor.py > monitor.log 2>&1 &
```

### Manual Drift Detection

```bash
python monitor/drift_detector.py --scan openclaw.json SOUL.md .env
```

### Viewing Dashboard

1. Start a simple web server:

```bash
cd web
python -m http.server 8000
```

2. Open http://localhost:8000/dashboard.html

### Testing Alerts

```bash
python monitor/alerts.py
```

## 📊 Dashboard

The web dashboard provides:

- **System Health** - Real-time status indicators
- **API Metrics** - Request counts, response times, token usage
- **Drift Alerts** - Configuration changes requiring attention
- **Security Events** - Complete event log with filtering

Dashboard auto-refreshes every 30 seconds.

## 🔔 Alert Types

### Critical (All Channels)
- Prompt injection attempts detected
- Unauthorized configuration changes
- Security audit failures (score < 50)
- System health critical

### Warning (Email + Chat)
- Configuration drift detected
- Security audit warnings
- High resource usage
- Unacknowledged alerts > 10

### Info (Chat Only)
- Routine security audits passed
- System health checks passed
- Configuration approved

## 💳 Subscription Plans

ShieldClaw Monitor is available under these plans:

### Free (This Code)
- Open source, self-hosted
- All monitoring features
- Community support
- DIY setup required

### Monitor ($79/month)
- Hosted dashboard
- Managed monitoring
- Priority support
- 5 deployments
- [Learn more](https://shieldclaw.xyz/pricing)

### Enterprise (Custom)
- Unlimited deployments
- White-label dashboard
- SOC2 compliance
- 24/7 support
- [Contact sales](mailto:enterprise@shieldclaw.xyz)

## 🛠️ Advanced Features

### Custom Alert Conditions

Edit `monitor/monitor.py` to add custom alerts:

```python
def check_custom_condition(self):
    # Your custom logic
    if suspicious_activity_detected:
        alert_system.send_alert(
            alert_type='custom_alert',
            severity='warning',
            message='Custom condition triggered'
        )
```

### Database Backends

**SQLite (default)**:
```bash
SHIELDCLAW_DB=./monitor.db
```

**PostgreSQL**:
```bash
SHIELDCLAW_DB=postgresql://user:pass@localhost/shieldclaw
```

### Webhook Integration

Set up custom webhooks:

```python
import requests

def send_custom_webhook(event):
    requests.post(
        'https://your-webhook.com/alerts',
        json=event
    )
```

## 📈 Metrics

Monitor tracks:

- **Configuration Events**: Changes, drifts, approvals
- **Security Events**: Injections, attacks, violations
- **API Metrics**: Calls, tokens, response times
- **Health Metrics**: Status, resources, availability

All metrics stored in SQLite/PostgreSQL for analysis.

## 🤝 Integration

### With ShieldClaw Free

Monitor works alongside the free toolkit:

1. Deploy with ShieldClaw free
2. Run setup scripts
3. Start Monitor daemon
4. View dashboard

### With CI/CD

Add to your pipeline:

```yaml
# .github/workflows/security.yml
- name: Run Security Audit
  run: python monitor/monitor.py --audit

- name: Check for Drift
  run: python monitor/drift_detector.py --report
```

## 🐛 Troubleshooting

**Monitor not detecting drift:**
- Check file paths in configuration
- Ensure baseline was established
- Verify file permissions

**Alerts not sending:**
- Check SMTP credentials
- Verify webhook URLs
- Test alert system manually

**Dashboard not loading:**
- Ensure web server is running
- Check metrics.json is being generated
- Verify file permissions

## 📚 Documentation

- [Business Plan](docs/BUSINESS_PLAN.md)
- [API Reference](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [FAQ](docs/FAQ.md)

## 🔒 Security

To report security vulnerabilities, email: security@shieldclaw.xyz

Do not open public issues for security concerns.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

- Built on [ShieldClaw](https://github.com/colepresley000-hub/openclaw-secure)
- Inspired by [ClawSec](https://github.com/prompt-security/clawsec)
- OpenClaw community

## 📞 Support

- **Community**: [GitHub Discussions](https://github.com/colepresley000-hub/shieldclaw-monitor/discussions)
- **Email**: support@shieldclaw.xyz
- **Enterprise**: enterprise@shieldclaw.xyz

---

**Made with 🛡️ by the ShieldClaw team**
