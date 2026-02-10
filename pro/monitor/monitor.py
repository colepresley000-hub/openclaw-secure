#!/usr/bin/env python3
"""
ShieldClaw Monitor - Runtime Security Monitoring Daemon

Monitors OpenClaw deployments for:
- Configuration drift
- Unauthorized changes
- Security anomalies
- API abuse
- Prompt injection attempts
"""

import os
import sys
import json
import time
import hashlib
import sqlite3
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import subprocess

# Configuration
CONFIG_DIR = os.getenv('SHIELDCLAW_CONFIG_DIR', './config')
LOG_DIR = os.getenv('SHIELDCLAW_LOG_DIR', './logs')
DB_PATH = os.getenv('SHIELDCLAW_DB', './monitor.db')
CHECK_INTERVAL = int(os.getenv('MONITOR_INTERVAL', '60'))  # seconds

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'{LOG_DIR}/monitor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('ShieldClaw.Monitor')


class SecurityMonitor:
    """Main monitoring daemon for ShieldClaw"""
    
    def __init__(self):
        self.db_conn = self._init_database()
        self.baseline_hashes = {}
        self.alert_callbacks = []
        
    def _init_database(self) -> sqlite3.Connection:
        """Initialize SQLite database for storing metrics and alerts"""
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Create tables
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS config_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                file_path TEXT NOT NULL,
                hash TEXT NOT NULL,
                change_type TEXT,
                alert_sent BOOLEAN DEFAULT 0
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS security_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                event_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                description TEXT,
                metadata TEXT,
                resolved BOOLEAN DEFAULT 0
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS api_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                endpoint TEXT,
                method TEXT,
                status_code INTEGER,
                response_time REAL,
                tokens_used INTEGER,
                suspicious BOOLEAN DEFAULT 0
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS drift_alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                file_path TEXT NOT NULL,
                expected_hash TEXT,
                actual_hash TEXT,
                diff_summary TEXT,
                acknowledged BOOLEAN DEFAULT 0
            )
        ''')
        
        conn.commit()
        return conn
    
    def calculate_file_hash(self, filepath: str) -> Optional[str]:
        """Calculate SHA-256 hash of a file"""
        try:
            with open(filepath, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception as e:
            logger.error(f"Error calculating hash for {filepath}: {e}")
            return None
    
    def establish_baseline(self, files: List[str]):
        """Establish baseline hashes for monitored files"""
        logger.info("Establishing baseline hashes...")
        
        for filepath in files:
            if os.path.exists(filepath):
                file_hash = self.calculate_file_hash(filepath)
                if file_hash:
                    self.baseline_hashes[filepath] = file_hash
                    
                    # Store in database
                    cursor = self.db_conn.cursor()
                    cursor.execute('''
                        INSERT INTO config_history (timestamp, file_path, hash, change_type)
                        VALUES (?, ?, ?, ?)
                    ''', (datetime.utcnow().isoformat(), filepath, file_hash, 'baseline'))
                    self.db_conn.commit()
                    
                    logger.info(f"Baseline set for {filepath}: {file_hash[:8]}...")
    
    def detect_drift(self, files: List[str]) -> List[Dict]:
        """Detect configuration drift in monitored files"""
        drifts = []
        
        for filepath in files:
            if not os.path.exists(filepath):
                logger.warning(f"File not found: {filepath}")
                continue
            
            current_hash = self.calculate_file_hash(filepath)
            baseline_hash = self.baseline_hashes.get(filepath)
            
            if baseline_hash and current_hash != baseline_hash:
                drift = {
                    'timestamp': datetime.utcnow().isoformat(),
                    'file': filepath,
                    'expected': baseline_hash,
                    'actual': current_hash,
                    'severity': 'high' if 'SOUL.md' in filepath or 'openclaw.json' in filepath else 'medium'
                }
                
                drifts.append(drift)
                
                # Log drift alert
                cursor = self.db_conn.cursor()
                cursor.execute('''
                    INSERT INTO drift_alerts (timestamp, file_path, expected_hash, actual_hash, diff_summary)
                    VALUES (?, ?, ?, ?, ?)
                ''', (drift['timestamp'], filepath, baseline_hash, current_hash, 
                      f"Hash changed from {baseline_hash[:8]} to {current_hash[:8]}"))
                
                cursor.execute('''
                    INSERT INTO security_events (timestamp, event_type, severity, description, metadata)
                    VALUES (?, ?, ?, ?, ?)
                ''', (drift['timestamp'], 'config_drift', drift['severity'],
                      f"Configuration drift detected in {filepath}",
                      json.dumps(drift)))
                
                self.db_conn.commit()
                
                logger.warning(f"DRIFT DETECTED: {filepath}")
                logger.warning(f"  Expected: {baseline_hash[:16]}...")
                logger.warning(f"  Actual:   {current_hash[:16]}...")
        
        return drifts
    
    def check_injection_patterns(self, log_file: str) -> List[Dict]:
        """Scan logs for prompt injection attempts"""
        injection_patterns = [
            'ignore previous instructions',
            'disregard all previous',
            'you are now',
            'new instructions',
            'system prompt',
            'forget everything',
            'developer mode',
            'jailbreak'
        ]
        
        alerts = []
        
        try:
            if not os.path.exists(log_file):
                return alerts
            
            with open(log_file, 'r') as f:
                for line_num, line in enumerate(f, 1):
                    line_lower = line.lower()
                    
                    for pattern in injection_patterns:
                        if pattern in line_lower:
                            alert = {
                                'timestamp': datetime.utcnow().isoformat(),
                                'line_number': line_num,
                                'pattern': pattern,
                                'excerpt': line.strip()[:200],
                                'severity': 'critical'
                            }
                            
                            alerts.append(alert)
                            
                            # Log security event
                            cursor = self.db_conn.cursor()
                            cursor.execute('''
                                INSERT INTO security_events (timestamp, event_type, severity, description, metadata)
                                VALUES (?, ?, ?, ?, ?)
                            ''', (alert['timestamp'], 'injection_attempt', 'critical',
                                  f"Possible injection attempt detected: {pattern}",
                                  json.dumps(alert)))
                            self.db_conn.commit()
                            
                            logger.critical(f"INJECTION ATTEMPT: Pattern '{pattern}' at line {line_num}")
        
        except Exception as e:
            logger.error(f"Error checking injection patterns: {e}")
        
        return alerts
    
    def get_system_health(self) -> Dict:
        """Get current system health metrics"""
        health = {
            'timestamp': datetime.utcnow().isoformat(),
            'status': 'healthy',
            'checks': {}
        }
        
        # Check if critical files exist
        critical_files = ['openclaw.json', 'SOUL.md', '.env']
        for filepath in critical_files:
            exists = os.path.exists(filepath)
            health['checks'][f'{filepath}_exists'] = exists
            if not exists:
                health['status'] = 'degraded'
        
        # Check database
        try:
            cursor = self.db_conn.cursor()
            cursor.execute('SELECT COUNT(*) FROM security_events WHERE resolved = 0')
            unresolved = cursor.fetchone()[0]
            health['checks']['unresolved_alerts'] = unresolved
            
            if unresolved > 10:
                health['status'] = 'warning'
            if unresolved > 50:
                health['status'] = 'critical'
        except Exception as e:
            logger.error(f"Error checking health: {e}")
            health['status'] = 'error'
        
        return health
    
    def generate_metrics(self) -> Dict:
        """Generate monitoring metrics for dashboard"""
        cursor = self.db_conn.cursor()
        
        # Get recent security events
        cursor.execute('''
            SELECT event_type, severity, COUNT(*) as count
            FROM security_events
            WHERE timestamp > datetime('now', '-24 hours')
            GROUP BY event_type, severity
        ''')
        recent_events = cursor.fetchall()
        
        # Get drift count
        cursor.execute('''
            SELECT COUNT(*) FROM drift_alerts WHERE acknowledged = 0
        ''')
        unacknowledged_drifts = cursor.fetchone()[0]
        
        # Get API metrics
        cursor.execute('''
            SELECT 
                COUNT(*) as total_requests,
                AVG(response_time) as avg_response_time,
                SUM(tokens_used) as total_tokens,
                COUNT(CASE WHEN suspicious = 1 THEN 1 END) as suspicious_requests
            FROM api_metrics
            WHERE timestamp > datetime('now', '-24 hours')
        ''')
        api_stats = cursor.fetchone()
        
        metrics = {
            'timestamp': datetime.utcnow().isoformat(),
            'events': {
                'recent': [{'type': e[0], 'severity': e[1], 'count': e[2]} for e in recent_events]
            },
            'drift': {
                'unacknowledged': unacknowledged_drifts
            },
            'api': {
                'total_requests': api_stats[0] or 0,
                'avg_response_time': api_stats[1] or 0,
                'total_tokens': api_stats[2] or 0,
                'suspicious_requests': api_stats[3] or 0
            },
            'health': self.get_system_health()
        }
        
        return metrics
    
    def run_audit(self) -> Dict:
        """Run comprehensive security audit"""
        logger.info("Running security audit...")
        
        audit_results = {
            'timestamp': datetime.utcnow().isoformat(),
            'checks': [],
            'score': 100,
            'issues': []
        }
        
        # Check 1: File permissions
        sensitive_files = ['.env', 'openclaw.json', 'SOUL.md']
        for filepath in sensitive_files:
            if os.path.exists(filepath):
                stat_info = os.stat(filepath)
                mode = oct(stat_info.st_mode)[-3:]
                
                check = {
                    'name': f'Permissions: {filepath}',
                    'status': 'pass' if mode == '600' else 'fail',
                    'details': f'Mode: {mode}'
                }
                
                audit_results['checks'].append(check)
                
                if check['status'] == 'fail':
                    audit_results['score'] -= 10
                    audit_results['issues'].append(f'Insecure permissions on {filepath}')
        
        # Check 2: Configuration security
        if os.path.exists('openclaw.json'):
            with open('openclaw.json', 'r') as f:
                config = json.load(f)
                
                # Check authentication
                auth_enabled = config.get('security', {}).get('authentication', {}).get('enabled', False)
                check = {
                    'name': 'Authentication enabled',
                    'status': 'pass' if auth_enabled else 'fail',
                    'details': f'Enabled: {auth_enabled}'
                }
                audit_results['checks'].append(check)
                
                if not auth_enabled:
                    audit_results['score'] -= 20
                    audit_results['issues'].append('Authentication is disabled')
                
                # Check injection defense
                injection_defense = config.get('security', {}).get('prompt_injection_defense', {}).get('enabled', False)
                check = {
                    'name': 'Prompt injection defense',
                    'status': 'pass' if injection_defense else 'fail',
                    'details': f'Enabled: {injection_defense}'
                }
                audit_results['checks'].append(check)
                
                if not injection_defense:
                    audit_results['score'] -= 20
                    audit_results['issues'].append('Prompt injection defense is disabled')
        
        # Store audit results
        cursor = self.db_conn.cursor()
        cursor.execute('''
            INSERT INTO security_events (timestamp, event_type, severity, description, metadata)
            VALUES (?, ?, ?, ?, ?)
        ''', (audit_results['timestamp'], 'security_audit', 
              'critical' if audit_results['score'] < 70 else 'info',
              f"Security audit completed. Score: {audit_results['score']}",
              json.dumps(audit_results)))
        self.db_conn.commit()
        
        logger.info(f"Audit complete. Score: {audit_results['score']}/100")
        
        return audit_results
    
    def monitor_loop(self):
        """Main monitoring loop"""
        logger.info("ShieldClaw Monitor starting...")
        
        # Files to monitor
        monitored_files = [
            'openclaw.json',
            'SOUL.md',
            '.env'
        ]
        
        # Establish baseline
        self.establish_baseline(monitored_files)
        
        # Run initial audit
        self.run_audit()
        
        logger.info(f"Monitoring started. Check interval: {CHECK_INTERVAL}s")
        
        try:
            while True:
                logger.info("Running monitoring checks...")
                
                # Check for drift
                drifts = self.detect_drift(monitored_files)
                if drifts:
                    logger.warning(f"Detected {len(drifts)} configuration drift(s)")
                
                # Check for injection attempts
                log_files = ['logs/openclaw.log', 'logs/api.log']
                for log_file in log_files:
                    if os.path.exists(log_file):
                        injections = self.check_injection_patterns(log_file)
                        if injections:
                            logger.critical(f"Detected {len(injections)} potential injection attempt(s)")
                
                # Generate metrics
                metrics = self.generate_metrics()
                
                # Save metrics to file for dashboard
                with open('web/metrics.json', 'w') as f:
                    json.dump(metrics, f, indent=2)
                
                # Sleep until next check
                time.sleep(CHECK_INTERVAL)
                
        except KeyboardInterrupt:
            logger.info("Monitor stopped by user")
        except Exception as e:
            logger.error(f"Monitor error: {e}")
            raise
        finally:
            self.db_conn.close()


def main():
    """Main entry point"""
    # Create necessary directories
    os.makedirs(LOG_DIR, exist_ok=True)
    os.makedirs('web', exist_ok=True)
    
    # Start monitor
    monitor = SecurityMonitor()
    monitor.monitor_loop()


if __name__ == '__main__':
    main()
