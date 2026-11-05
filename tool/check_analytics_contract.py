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
native_pdf = {'pdfDownloadClick', 'pdfDownloadSuccess', 'pdfDownloadFailure', 'pdfDownloadCancel'}
native_only = native_pdf | {'gradeCutoffView', 'menuView', 'materialOpen'}
assert {k: v for k, v in events.items() if k not in native_only} == web_events, 'Shared APP/WEB event names differ'
assert all(events.get(k, '').startswith('pdf_download_') for k in native_pdf), 'Native PDF events missing'
native_params = {'post_id', 'resource_id', 'resource_type', 'academic_year', 'subject_code', 'menu_id', 'content_item_id', 'entry_source', 'schema_version'}
assert native_params <= params, 'Native PDF context missing'
assert params - native_params == web_params, 'Shared APP/WEB parameter allowlists differ'
print(f'PASS: {len(events)} event names and {len(params)} parameters validated (shared + native PDF/cutoff/usage extensions)')
