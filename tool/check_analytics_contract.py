#!/usr/bin/env python3
"""Read-only APP/WEB Analytics v1 event and parameter drift check."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--web-root', type=Path, required=True)
args = parser.parse_args()
app = Path(__file__).resolve().parents[1]
dart = (app / 'lib/features/analytics/domain/analytics_events.dart').read_text()
ts = (args.web_root / 'src/lib/analytics/events.ts').read_text()
events = dict(re.findall(r"static const (\w+) = '([^']+)';", dart.split('abstract final class AnalyticsEvents {')[1].split('abstract final class AnalyticsParamKeys')[0]))
params = set(re.findall(r"static const \w+ = '([^']+)';", dart.split('abstract final class AnalyticsParamKeys')[1]))
web_events = json.loads(re.search(r'analyticsEvents = (\{.*?\}) as const', ts, re.S)[1])
web_params = set(json.loads(re.search(r'analyticsParamKeys = (\[.*?\]) as const', ts, re.S)[1]))
assert events == web_events, 'APP/WEB event names differ'
assert params == web_params, 'APP/WEB parameter allowlists differ'
print(f'PASS: {len(events)} event names and {len(params)} allowed parameters match')
