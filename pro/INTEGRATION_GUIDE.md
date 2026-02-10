# Integrating ShieldClaw Monitor with Your Repository

This guide shows how to add the ShieldClaw Monitor package to your existing `openclaw-secure` repository.

## Option 1: Add as `/pro` Directory (Recommended)

This keeps everything in one repository with a clear free/paid separation.

### Steps:

1. **Copy the monitor files into your existing repo:**

```bash
cd /path/to/openclaw-secure
mkdir -p pro
cp -r /path/to/shieldclaw-monitor/* pro/
```

2. **Update your repository structure:**

```
openclaw-secure/
├── openclaw.json          (Free tier)
├── SOUL.md               (Free tier)
├── scripts/              (Free tier)
├── README.md             (Free tier)
├── pro/                  (NEW - Monitor tier)
│   ├── monitor/
│   │   ├── monitor.py
│   │   ├── drift_detector.py
│   │   ├── alerts.py
│   │   └── payments.py
│   ├── web/
│   │   ├── dashboard.html
│   │   └── pricing.html
│   ├── docs/
│   │   └── BUSINESS_PLAN.md
│   ├── README.md
│   ├── requirements.txt
│   ├── install.sh
│   └── .env.example
└── .gitignore
```

3. **Update main README.md:**

Add this section after the Quick Start:

```markdown
## 🔒 ShieldClaw Monitor (Premium)

Need 24/7 runtime monitoring? Check out [ShieldClaw Monitor](pro/README.md):

- 24/7 runtime monitoring daemon
- Automated drift detection
- Real-time security alerts
- Web monitoring dashboard
- Multi-channel notifications (Email, Slack, Discord, SMS)

**[Learn more →](pro/README.md)** | **[View pricing →](https://shieldclaw.xyz/pricing)**
```

4. **Update .gitignore:**

Add to your existing .gitignore:

```gitignore
# ShieldClaw Monitor
pro/.env
pro/monitor.db
pro/logs/
pro/data/
pro/__pycache__/
pro/monitor/__pycache__/
```

5. **Commit and push:**

```bash
git add pro/
git commit -m "Add ShieldClaw Monitor (premium tier)"
git push
```

## Option 2: Separate Repository

Keep Monitor as a separate repository that depends on the free version.

### Steps:

1. **Create new GitHub repository:**
   - Name: `shieldclaw-monitor`
   - Description: "Premium runtime monitoring for ShieldClaw"

2. **Push Monitor code:**

```bash
cd /path/to/shieldclaw-monitor
git init
git add .
git commit -m "Initial commit: ShieldClaw Monitor v1.0.0"
git remote add origin https://github.com/colepresley000-hub/shieldclaw-monitor.git
git push -u origin main
```

3. **Link from main repo:**

Update `openclaw-secure/README.md`:

```markdown
## Related Projects

**[ShieldClaw Monitor](https://github.com/colepresley000-hub/shieldclaw-monitor)** - Premium runtime monitoring and alerting
```

## Pricing Page Setup

### Option A: Host on Vercel (Recommended)

1. **Deploy pricing page:**

```bash
cd pro/web
git init
git add pricing.html
git commit -m "Add pricing page"

# Push to GitHub
git remote add origin https://github.com/colepresley000-hub/shieldclaw-website.git
git push -u origin main
```

2. **Deploy to Vercel:**
   - Go to vercel.com/new
   - Import `shieldclaw-website`
   - Deploy
   - Add custom domain: `shieldclaw.xyz`

### Option B: Add to Existing Landing Page

Add pricing section to your existing `shieldclaw-landing-page.html`:

```html
<!-- Add after existing content -->
<section id="pricing">
  <!-- Copy content from pro/web/pricing.html -->
</section>
```

## Stripe Integration

### Setup Stripe Products:

1. **Create Stripe account** at stripe.com

2. **Run product setup:**

```bash
cd pro
export STRIPE_SECRET_KEY=sk_test_your_key
python3 monitor/payments.py --setup-products
```

3. **Add keys to .env:**

```bash
STRIPE_SECRET_KEY=sk_live_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_secret
STRIPE_MONITOR_PRICE_ID=price_xxxxx
```

4. **Test checkout:**

```bash
python3 monitor/payments.py --test-checkout your@email.com
```

## Marketing Strategy

### 1. Update GitHub Repository

**In main README.md**, add badges:

```markdown
[![GitHub stars](https://img.shields.io/github/stars/colepresley000-hub/openclaw-secure.svg)](https://github.com/colepresley000-hub/openclaw-secure/stargazers)
[![Pro Version](https://img.shields.io/badge/Pro-Available-success)](pro/README.md)
```

### 2. Create Comparison Table

Add to README.md:

```markdown
## Free vs Monitor

| Feature | Free | Monitor |
|---------|------|---------|
| Configuration hardening | ✓ | ✓ |
| Prompt injection defense | ✓ | ✓ |
| Kill switch | ✓ | ✓ |
| 24/7 monitoring | – | ✓ |
| Drift detection | Manual | Automated |
| Alerts | – | Email/Slack/Discord |
| Dashboard | – | Web UI |
| Support | Community | Priority |
| Price | Free | $79/mo |

[View full comparison →](pro/README.md)
```

### 3. Add CTA Buttons

In README.md:

```markdown
## Get Started

**Free (Open Source)**
```bash
git clone https://github.com/colepresley000-hub/openclaw-secure.git
./scripts/setup.sh
```

**Monitor (Premium) - [14-day free trial](https://shieldclaw.xyz/pricing)**
```

### 4. Update Landing Page

Add to `shieldclaw-landing-page.html`:

```html
<div class="cta-section">
  <h2>Ready to Upgrade?</h2>
  <p>Get 24/7 protection with ShieldClaw Monitor</p>
  <a href="https://shieldclaw.xyz/pricing" class="cta-button">
    Start Free Trial →
  </a>
</div>
```

## Launch Checklist

- [ ] Add Monitor to repository (as `/pro` or separate repo)
- [ ] Update main README with Monitor info
- [ ] Deploy pricing page to shieldclaw.xyz
- [ ] Set up Stripe products and webhooks
- [ ] Test checkout flow
- [ ] Update landing page with CTA
- [ ] Write launch blog post
- [ ] Prepare Product Hunt launch
- [ ] Create demo video
- [ ] Set up analytics (PostHog/Plausible)

## Support Setup

### Community (Free Users)

- GitHub Discussions
- Discord server (optional)
- Stack Overflow tag

### Paid Support (Monitor Users)

- Email: support@shieldclaw.xyz
- Slack channel (business tier)
- Priority GitHub issues

## Revenue Tracking

Track these metrics:

1. **Acquisition:**
   - GitHub stars
   - Website visits
   - Free signups

2. **Activation:**
   - Setup completions
   - Trial starts

3. **Revenue:**
   - Free-to-paid conversion
   - MRR growth
   - Churn rate

4. **Retention:**
   - Active users
   - Feature adoption
   - NPS score

Use tools:
- Stripe Dashboard (revenue)
- PostHog (product analytics)
- GitHub Insights (community growth)

---

**Questions?** Open an issue or email support@shieldclaw.xyz
