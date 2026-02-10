#!/usr/bin/env python3
"""
ShieldClaw Drift Detector

Detects and reports configuration drift in OpenClaw deployments.
Compares current state against approved baseline.
"""

import os
import json
import hashlib
import difflib
from datetime import datetime
from typing import Dict, List, Tuple
import sqlite3


class DriftDetector:
    """Detects configuration drift"""
    
    def __init__(self, db_path: str = './monitor.db'):
        self.db_path = db_path
        self.db_conn = sqlite3.connect(db_path)
    
    def get_baseline_hash(self, filepath: str) -> str:
        """Get baseline hash for a file from database"""
        cursor = self.db_conn.cursor()
        cursor.execute('''
            SELECT hash FROM config_history
            WHERE file_path = ? AND change_type = 'baseline'
            ORDER BY timestamp DESC LIMIT 1
        ''', (filepath,))
        
        result = cursor.fetchone()
        return result[0] if result else None
    
    def calculate_hash(self, filepath: str) -> str:
        """Calculate SHA-256 hash of file"""
        try:
            with open(filepath, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except:
            return None
    
    def get_file_diff(self, filepath: str, baseline_content: str, current_content: str) -> str:
        """Generate unified diff between baseline and current"""
        baseline_lines = baseline_content.splitlines(keepends=True)
        current_lines = current_content.splitlines(keepends=True)
        
        diff = difflib.unified_diff(
            baseline_lines,
            current_lines,
            fromfile=f'{filepath} (baseline)',
            tofile=f'{filepath} (current)',
            lineterm=''
        )
        
        return ''.join(diff)
    
    def detect_json_drift(self, filepath: str) -> Dict:
        """Detect drift in JSON configuration files"""
        try:
            with open(filepath, 'r') as f:
                current = json.load(f)
            
            # Get baseline from database
            cursor = self.db_conn.cursor()
            cursor.execute('''
                SELECT metadata FROM config_history
                WHERE file_path = ? AND change_type = 'baseline'
                ORDER BY timestamp DESC LIMIT 1
            ''', (filepath,))
            
            result = cursor.fetchone()
            if not result:
                return {'error': 'No baseline found'}
            
            baseline = json.loads(result[0])
            
            # Compare configurations
            changes = self._compare_dicts(baseline, current)
            
            return {
                'has_drift': len(changes) > 0,
                'changes': changes,
                'filepath': filepath,
                'timestamp': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            return {'error': str(e)}
    
    def _compare_dicts(self, baseline: Dict, current: Dict, path: str = '') -> List[Dict]:
        """Recursively compare two dictionaries"""
        changes = []
        
        # Check for modified or removed keys
        for key in baseline:
            current_path = f'{path}.{key}' if path else key
            
            if key not in current:
                changes.append({
                    'type': 'removed',
                    'path': current_path,
                    'old_value': baseline[key]
                })
            elif isinstance(baseline[key], dict) and isinstance(current[key], dict):
                changes.extend(self._compare_dicts(baseline[key], current[key], current_path))
            elif baseline[key] != current[key]:
                changes.append({
                    'type': 'modified',
                    'path': current_path,
                    'old_value': baseline[key],
                    'new_value': current[key]
                })
        
        # Check for added keys
        for key in current:
            current_path = f'{path}.{key}' if path else key
            
            if key not in baseline:
                changes.append({
                    'type': 'added',
                    'path': current_path,
                    'new_value': current[key]
                })
        
        return changes
    
    def scan_all_monitored_files(self, files: List[str]) -> Dict:
        """Scan all monitored files for drift"""
        results = {
            'timestamp': datetime.utcnow().isoformat(),
            'total_files': len(files),
            'files_with_drift': 0,
            'details': []
        }
        
        for filepath in files:
            if not os.path.exists(filepath):
                results['details'].append({
                    'filepath': filepath,
                    'status': 'missing',
                    'error': 'File not found'
                })
                continue
            
            baseline_hash = self.get_baseline_hash(filepath)
            current_hash = self.calculate_hash(filepath)
            
            if not baseline_hash:
                results['details'].append({
                    'filepath': filepath,
                    'status': 'no_baseline',
                    'error': 'No baseline hash found'
                })
                continue
            
            if baseline_hash != current_hash:
                results['files_with_drift'] += 1
                
                # For JSON files, get detailed changes
                if filepath.endswith('.json'):
                    drift_info = self.detect_json_drift(filepath)
                    results['details'].append({
                        'filepath': filepath,
                        'status': 'drift_detected',
                        'baseline_hash': baseline_hash,
                        'current_hash': current_hash,
                        'changes': drift_info.get('changes', [])
                    })
                else:
                    results['details'].append({
                        'filepath': filepath,
                        'status': 'drift_detected',
                        'baseline_hash': baseline_hash,
                        'current_hash': current_hash
                    })
            else:
                results['details'].append({
                    'filepath': filepath,
                    'status': 'ok'
                })
        
        return results
    
    def approve_drift(self, filepath: str):
        """Approve drift and update baseline"""
        current_hash = self.calculate_hash(filepath)
        
        if not current_hash:
            return {'error': 'Could not calculate hash'}
        
        cursor = self.db_conn.cursor()
        
        # Mark old drifts as acknowledged
        cursor.execute('''
            UPDATE drift_alerts
            SET acknowledged = 1
            WHERE file_path = ? AND acknowledged = 0
        ''', (filepath,))
        
        # Insert new baseline
        cursor.execute('''
            INSERT INTO config_history (timestamp, file_path, hash, change_type)
            VALUES (?, ?, ?, ?)
        ''', (datetime.utcnow().isoformat(), filepath, current_hash, 'approved_change'))
        
        self.db_conn.commit()
        
        return {
            'status': 'approved',
            'filepath': filepath,
            'new_baseline': current_hash
        }


def main():
    """CLI interface for drift detection"""
    import argparse
    
    parser = argparse.ArgumentParser(description='ShieldClaw Drift Detector')
    parser.add_argument('--scan', nargs='+', help='Files to scan for drift')
    parser.add_argument('--approve', help='Approve drift for a file')
    parser.add_argument('--report', action='store_true', help='Generate drift report')
    
    args = parser.parse_args()
    
    detector = DriftDetector()
    
    if args.scan:
        results = detector.scan_all_monitored_files(args.scan)
        print(json.dumps(results, indent=2))
    
    elif args.approve:
        result = detector.approve_drift(args.approve)
        print(json.dumps(result, indent=2))
    
    elif args.report:
        # Default monitored files
        files = ['openclaw.json', 'SOUL.md', '.env']
        results = detector.scan_all_monitored_files(files)
        
        print("\n╔════════════════════════════════════════════════════════╗")
        print("║           ShieldClaw Drift Detection Report           ║")
        print("╚════════════════════════════════════════════════════════╝\n")
        
        print(f"Timestamp: {results['timestamp']}")
        print(f"Total files monitored: {results['total_files']}")
        print(f"Files with drift: {results['files_with_drift']}")
        print("\nDetails:\n")
        
        for detail in results['details']:
            filepath = detail['filepath']
            status = detail['status']
            
            if status == 'ok':
                print(f"✓ {filepath}: OK")
            elif status == 'drift_detected':
                print(f"✗ {filepath}: DRIFT DETECTED")
                if 'changes' in detail:
                    for change in detail['changes'][:5]:  # Show first 5 changes
                        print(f"  - {change['type']}: {change['path']}")
            elif status == 'missing':
                print(f"⚠ {filepath}: MISSING")
            elif status == 'no_baseline':
                print(f"⚠ {filepath}: NO BASELINE")
        
        print()


if __name__ == '__main__':
    main()
