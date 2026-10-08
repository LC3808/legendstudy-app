"""Owner-run, pinned diagnostic-only deploy; preserve deployed files and JWT gate."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

PROJECT = "stlhijzpjfgwwdgunlsd"
SLUG = "account-deletion-worker"
EXPECTED = {
    "index.ts": "f5a1479b4a7a814a350dad6c66afe56d1ca7926cfac1706ae4a66d8a20352da6",
    "worker.ts": "38c231d865ec45b564284d66a8c07b3433de0c4d7a2541f10a317a24f0dfad8d",
    "server.ts": "696bb1934ce08ac3dba63e71c7f1aee35c98db69c49387f6f7feb9366846bb0d",
    "http.ts": "484d4a135e4f19e3adeb1b726cf70462102a5d00425248c2a0cd502736af2dc7",
}
DELTA = ("worker.ts", "server.ts", "benefit-diagnostics.ts")


def run(*args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True)


def metadata():
    rows = json.loads(run("supabase", "functions", "list", "--project-ref", PROJECT, "--output", "json"))
    matches = [row for row in rows if row.get("slug") == SLUG]
    if len(matches) != 1:
        raise SystemExit("STOP: deployed function metadata unavailable")
    row = matches[0]
    if type(row.get("verify_jwt")) is not bool or not isinstance(row.get("version"), int):
        raise SystemExit("STOP: cannot preserve deployed JWT gate/version; no deploy")
    return row


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--deploy", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9a-f]{40}", args.source):
        raise SystemExit("STOP: full reviewed commit required")
    repo = Path(run("git", "rev-parse", "--show-toplevel").strip())
    if (repo / "supabase/.temp/project-ref").read_text().strip() != PROJECT:
        raise SystemExit("STOP: linked project mismatch")
    source = {name: run("git", "show", f"{args.source}:supabase/functions/{SLUG}/{name}", cwd=repo) for name in DELTA}
    before = metadata()
    root = Path(tempfile.mkdtemp(prefix="legendstudy-benefit-diagnostics-"))
    backup, deploy = root / "before", root / "deploy"
    backup.mkdir()
    subprocess.run(["supabase", "functions", "download", SLUG, "--project-ref", PROJECT, "--use-api"], cwd=backup, check=True)
    function_dir = backup / "supabase/functions" / SLUG
    for name, expected in EXPECTED.items():
        if hashlib.sha256((function_dir / name).read_bytes()).hexdigest() != expected:
            raise SystemExit(f"STOP: deployed {name} changed; no deploy")
    shutil.copytree(backup, deploy)
    config = f'[functions.{SLUG}]\nverify_jwt = {str(before["verify_jwt"]).lower()}\n'
    for directory in (backup, deploy):
        (directory / "supabase/config.toml").write_text(config)
    for name, contents in source.items():
        (deploy / "supabase/functions" / SLUG / name).write_text(contents)
    print(f"ROLLBACK_DIRECTORY={backup}", flush=True)
    print(f"DEPLOY_DIRECTORY={deploy}", flush=True)
    print(f'PRESERVED_VERIFY_JWT={before["verify_jwt"]}', flush=True)
    current = metadata()
    if current["version"] != before["version"] or current["verify_jwt"] != before["verify_jwt"]:
        raise SystemExit("STOP: concurrent deployment/config change; no deploy")
    if not args.deploy:
        print("PREPARED_ONLY")
        return
    subprocess.run(["supabase", "functions", "deploy", SLUG, "--project-ref", PROJECT, "--use-api"], cwd=deploy, check=True)
    after = metadata()
    if after["verify_jwt"] != before["verify_jwt"]:
        raise SystemExit("STOP: verify_jwt changed unexpectedly; retain rollback directory")
    if after["version"] <= before["version"]:
        raise SystemExit("DEPLOYMENT_UNCONFIRMED: version did not advance")
    print(f'DEPLOYED_VERSION={after["version"]}')
    print("BENEFIT_DIAGNOSTICS_DEPLOYED — grant success still unverified")


if __name__ == "__main__":
    main()
