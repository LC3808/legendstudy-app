"""Merge public Firebase config into a NEW release config; never build/upload."""
import argparse
import json
from pathlib import Path

FIELDS = {'ANALYTICS_ENABLED', 'FIREBASE_API_KEY', 'FIREBASE_APP_ID',
          'FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_PROJECT_ID'}

def merge(base, analytics, platform):
    if set(analytics) != FIELDS or str(analytics['ANALYTICS_ENABLED']).lower() != 'true':
        raise ValueError('Expected only the five public analytics configuration fields')
    if analytics['FIREBASE_PROJECT_ID'] != 'legendstudyplus' or str(analytics['FIREBASE_MESSAGING_SENDER_ID']) != '323039160298':
        raise ValueError('Unexpected Firebase project')
    if not str(analytics['FIREBASE_APP_ID']).startswith(f'1:323039160298:{platform}:'):
        raise ValueError('Firebase application platform mismatch')
    if not analytics['FIREBASE_API_KEY']:
        raise ValueError('Firebase public API key is missing')
    return {**base, **analytics}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('platform', choices=['ios', 'android'])
    p.add_argument('--base', required=True, type=Path)
    p.add_argument('--analytics', required=True, type=Path)
    p.add_argument('--output', required=True, type=Path)
    a = p.parse_args()
    value = merge(json.loads(a.base.read_text()), json.loads(a.analytics.read_text()), a.platform)
    with a.output.open('x') as out:
        json.dump(value, out, indent=2)
    a.output.chmod(0o600)
    print('Analytics config prepared; all unrelated release settings preserved. No values printed.')

if __name__ == '__main__':
    main()
