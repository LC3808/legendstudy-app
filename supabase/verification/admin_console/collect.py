#!/usr/bin/env python3
"""Collect the ADMIN-P0-A isolated verification results into validation.json."""
import json
import subprocess
import sys

DB = sys.argv[1] if len(sys.argv) > 1 else "legendstudy_admin_test"
OUT = "supabase/verification/admin_console/validation.json"


def q(sql: str) -> str:
    return subprocess.run(
        ["sudo", "-n", "-u", "postgres", "psql", "-qtA", "-F", "|", "-d", DB, "-c", sql],
        capture_output=True, text=True,
    ).stdout.strip()


checks = []
for line in q("select name||'|'||ok from admin_verify order by id").splitlines():
    if "|" in line:
        name, ok = line.rsplit("|", 1)
        checks.append({"check": name, "ok": ok.strip() in ("t", "true")})

acl = []
sql = (
    "select p.proname||'|'||pg_get_userbyid(p.proowner)||'|'||p.prosecdef||'|'||"
    "coalesce(array_to_string(p.proconfig,','),'')||'|'||r.r||'|'||"
    "has_function_privilege(r.r,p.oid,'execute') from pg_proc p "
    "join pg_namespace n on n.oid=p.pronamespace cross join "
    "(values('anon'),('authenticated'),('service_role')) r(r) "
    "where n.nspname='public' and p.proname like 'admin\\_%' order by 1, r.r"
)
for line in q(sql).splitlines():
    if "|" in line:
        fn, owner, definer, cfg, role, priv = line.split("|")
        acl.append({
            "function": fn, "owner": owner, "security_definer": definer in ("t", "true"),
            "search_path": cfg, "role": role, "execute": priv in ("t", "true"),
        })

payload = {
    "task": "ADMIN-P0-A",
    "engine": q("select version()").split(",")[0],
    "chain": ("core + quality + HQP applied; account-deletion / Math / payment "
              "candidates excluded because they are NOT_APPLIED"),
    "phases": [
        "PHASE 1 pending subsystems absent -> NOT_INSTALLED reported, never a fake 0",
        "PHASE 2 structural stand-ins present -> installed path executes",
    ],
    "total": len(checks),
    "failed": sum(1 for c in checks if not c["ok"]),
    "checks": checks,
    "acl": acl,
}
with open(OUT, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=1)
print(f"  validation.json: {payload['total']} checks, {payload['failed']} failed")
