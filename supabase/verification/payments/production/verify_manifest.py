"""Offline verification only. Never connects to a database or applies SQL."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4]
m=json.loads(Path(__file__).with_name('manifest.json').read_text())
assert len(m['ordered_candidates'])==3
for entry in m['ordered_candidates']:
 assert hashlib.sha256((root/entry['path']).read_bytes()).hexdigest()==entry['sha256'],entry['path']
 print(entry['path'],'HASH_PASS')
print('REVIEW_PACKAGE_ONLY; APPLY_NOT_AUTHORIZED')
