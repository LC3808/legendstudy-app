from pathlib import Path
import hashlib,json
r=Path(__file__).resolve().parents[4]
m=json.loads(Path(__file__).with_name("manifest.json").read_text())
for section in ("prerequisites_inspect_only","ordered_activation"):
 for row in m[section]:
  p=r/"migrations"/row["filename"] if r.name=="supabase" else r/"supabase/migrations"/row["filename"]
  assert hashlib.sha256(p.read_bytes()).hexdigest()==row["sha256"],row["filename"]
print("EXACT_HASH_ALLOWLIST_PASS")
