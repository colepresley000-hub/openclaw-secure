#!/usr/bin/env python3
"""
ShieldClaw Alert System

Sends notifications via multiple channels:
- Email (SMTP)
- Slack
- Discord
- SMS (Twilio)
- Webhook
"""

import os
import json
import smtplib
import requests
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from typing import Dict, List, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('ShieldClaw.Alerts')


class AlertSystem:
    """Multi-channel alert notification system"""
    
    def __init__(self):
        self.email_config = {
            'enabled': os.getenv('ALERT_EMAIL_ENABLED', 'false').lower() == 'true',
            'smtp_host': os.getenv('SMTP_HOST', 'smtp.gmail.com'),
            'smtp_port': int(os.getenv('SMTP_PORT', '587')),
            'smtp_user': os.getenv('SMTP_USER'),
            'smtp_pass': os.getenv('SMTP_PASS'),
            'from_addr': os.getenv('ALERT_FROM_EMAIL'),
            'to_addrs': os.getenv('ALERT_TO_EMAILS', '').split(',')
        }
        
        self.slack_config = {
            'enabled': os.getenv('ALERT_SLACK_ENABLED', 'false').lower() == 'true',
            'webhook_url': os.getenv('SLACK_WEBHOOK_URL')
        }
        
        self.discord_config = {
            'enabled': os.getenv('ALERT_DISCORD_ENABLED', 'false').lower() == 'true',
            'webhook_url': os.getenv('DISCORD_WEBHOOK_URL')
        }
        
        self.twilio_config = {
            'enabled': os.getenv('ALERT_SMS_ENABLED', 'false').lower() == 'true',
            'account_sid': os.getenv('TWILIO_ACCOUNT_SID'),
            'auth_token': os.getenv('TWILIO_AUTH_TOKEN'),
            'from_number': os.getenv('TWILIO_FROM_NUMBER'),
            'to_numbers': os.getenv('ALERT_TO_NUMBERS', '').split(',')
        }
    
    def send_email(self, subject: str, body: str, html_body: Optional[str] = None) -> bool:
        """Send email alert"""
        if not self.email_config['enabled']:
            logger.info("Email alerts disabled")
            return False
        
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = self.email_config['from_addr']
            msg['To'] = ', '.join(self.email_config['to_addrs'])
            
            # Add plain text
            msg.attach(MIMEText(body, 'plain'))
            
            # Add HTML if provided
            if html_body:
                msg.attach(MIMEText(html_body, 'html'))
            
            # Send email
            with smtplib.SMTP(self.email_config['smtp_host'], self.email_config['smtp_port']) as server:
                server.starttls()
                server.login(self.email_config['smtp_user'], self.email_config['smtp_pass'])
                server.send_message(msg)
            
            logger.info(f"Email sent: {subject}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False
    
    def send_slack(self, message: str, severity: str = 'info', title: Optional[str] = None) -> bool:
        """Send Slack notification"""
        if not self.slack_config['enabled']:
            logger.info("Slack alerts disabled")
            return False
        
        # Map severity to Slack colors
        colors = {
            'info': '#36a64f',
            'warning': '#ff9900',
            'critical': '#ff0000'
        }
        
        payload = {
            'attachments': [{
                'color': colors.get(severity, '#cccccc'),
                'title': title or 'ShieldClaw Security Alert',
                'text': message,
                'footer': 'ShieldClaw Monitor',
                'ts': int(datetime.utcnow().timestamp())
            }]
        }
        
        try:
            response = requests.post(
                self.slack_config['webhook_url'],
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            logger.info("Slack notification sent")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}")
            return False
    
    def send_discord(self, message: str, severity: str = 'info', title: Optional[str] = None) -> bool:
        """Send Discord notification"""
        if not self.discord_config['enabled']:
            logger.info("Discord alerts disabled")
            return False
        
        # Map severity to Discord colors (decimal)
        colors = {
            'info': 3447003,      # Blue
            'warning': 16776960,  # Yellow
            'critical': 16711680  # Red
        }
        
        payload = {
            'embeds': [{
                'title': title or '🛡️ ShieldClaw Security Alert',
                'description': message,
                'color': colors.get(severity, 8421504),
                'footer': {'text': 'ShieldClaw Monitor'},
                'timestamp': datetime.utcnow().isoformat()
            }]
        }
        
        try:
            response = requests.post(
                self.discord_config['webhook_url'],
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            logger.info("Discord notification sent")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send Discord notification: {e}")
            return False
    
    def send_sms(self, message: str) -> bool:
        """Send SMS alert via Twilio"""
        if not self.twilio_config['enabled']:
            logger.info("SMS alerts disabled")
            return False
        
        try:
            from twilio.rest import Client
            
            client = Client(
                self.twilio_config['account_sid'],
                self.twilio_config['auth_token']
            )
            
            for to_number in self.twilio_config['to_numbers']:
                if to_number.strip():
                    client.messages.create(
                        body=message[:160],  # SMS limit
                        from_=self.twilio_config['from_number'],
                        to=to_number.strip()
                    )
            
            logger.info("SMS sent")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send SMS: {e}")
            return False
    
    def send_alert(self, alert_type: str, severity: str, message: str, metadata: Optional[Dict] = None):
        """Send alert via all configured channels"""
        timestamp = datetime.utcnow().isoformat()
        
        # Format alert
        title = f"[{severity.upper()}] {alert_type}"
        full_message = f"""
{title}
Time: {timestamp}

{message}
"""
        
        if metadata:
            full_message += f"\nDetails:\n{json.dumps(metadata, indent=2)}"
        
        # Send via all enabled channels
        if severity == 'critical':
            # Critical alerts go to all channels
            self.send_email(title, full_message)
            self.send_slack(message, severity, title)
            self.send_discord(message, severity, title)
            self.send_sms(f"[CRITICAL] {alert_type}: {message[:100]}")
        
        elif severity == 'warning':
            # Warnings go to email and chat
            self.send_email(title, full_message)
            self.send_slack(message, severity, title)
            self.send_discord(message, severity, title)
        
        else:
            # Info goes to chat only
            self.send_slack(message, severity, title)
            self.send_discord(message, severity, title)
        
        logger.info(f"Alert sent: {alert_type} ({severity})")


class AlertTemplates:
    """Pre-defined alert templates"""
    
    @staticmethod
    def drift_detected(filepath: str, changes: int) -> Dict:
        return {
            'type': 'config_drift',
            'severity': 'warning',
            'message': f"Configuration drift detected in {filepath} ({changes} change(s))",
            'metadata': {'filepath': filepath, 'num_changes': changes}
        }
    
    @staticmethod
    def injection_attempt(pattern: str, line_num: int) -> Dict:
        return {
            'type': 'injection_attempt',
            'severity': 'critical',
            'message': f"Possible prompt injection attempt detected: '{pattern}' at line {line_num}",
            'metadata': {'pattern': pattern, 'line': line_num}
        }
    
    @staticmethod
    def health_degraded(reason: str) -> Dict:
        return {
            'type': 'health_degraded',
            'severity': 'warning',
            'message': f"System health degraded: {reason}",
            'metadata': {'reason': reason}
        }
    
    @staticmethod
    def security_audit_failed(score: int, issues: List[str]) -> Dict:
        return {
            'type': 'audit_failed',
            'severity': 'critical' if score < 50 else 'warning',
            'message': f"Security audit failed (score: {score}/100). Issues: {', '.join(issues[:3])}",
            'metadata': {'score': score, 'issues': issues}
        }
    
    @staticmethod
    def unauthorized_access(ip_addr: str, endpoint: str) -> Dict:
        return {
            'type': 'unauthorized_access',
            'severity': 'critical',
            'message': f"Unauthorized access attempt from {ip_addr} to {endpoint}",
            'metadata': {'ip': ip_addr, 'endpoint': endpoint}
        }


def main():
    """Test alert system"""
    alert_system = AlertSystem()
    
    # Test each channel
    print("Testing alert channels...\n")
    
    test_alert = AlertTemplates.drift_detected('openclaw.json', 3)
    alert_system.send_alert(**test_alert)
    
    print("\nAlert test complete!")


if __name__ == '__main__':
    main()
