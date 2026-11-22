"""Build a narrow recovery candidate from captured runtime files. Never deploys.

Example: python3 -m tool.cloudflare_essay.admin_recovery_patch LIVE OUTPUT
  --preimage VERIFIED_SHA256_JSON --baseline-ref VERIFIED_SOURCE_COMMIT

The preimage file is a JSON mapping of relative runtime paths to SHA256 hashes.
It must come from the verified deployment capture, not a fresh unreviewed hash of
an arbitrary folder. Baseline-ref identifies the reviewed source before this
patch; only matching methods/modules may be replaced. Other live bytes survive.
"""
import argparse
import ast
from hashlib import sha256
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
EXISTING = ('entry.py', 'essay_lab/admin_run_actions.py', 'essay_lab/cloudflare_http.py',
            'essay_lab/mixed_math_runtime.py')
NEW = 'essay_lab/admin_run_recovery.py'


def repository_path(runtime_path):
    return 'tool/cloudflare_essay/entry.py' if runtime_path == 'entry.py' else 'tool/' + runtime_path


def _method(text, cls, name):
    classes = [n for n in ast.parse(text).body if isinstance(n, ast.ClassDef) and n.name == cls]
    if len(classes) != 1:
        raise ValueError('Production class drift: ' + cls)
    methods = [n for n in classes[0].body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and n.name == name]
    if len(methods) != 1:
        raise ValueError('Production method drift: ' + name)
    node = methods[0]
    return node, ''.join(text.splitlines(keepends=True)[node.lineno - 1:node.end_lineno])


def _replace_method(actual, baseline, current, cls, name):
    node, old = _method(actual, cls, name)
    if old != _method(baseline, cls, name)[1]:
        raise ValueError('Production method drift: ' + name)
    lines = actual.splitlines(keepends=True)
    lines[node.lineno - 1:node.end_lineno] = [_method(current, cls, name)[1]]
    result = ''.join(lines)
    ast.parse(result)
    return result


def prepare(live, baseline, current, preimage):
    """Pure byte mappings; verify every input before producing any candidate."""
    actual = {path: sha256(data).hexdigest() for path, data in live.items()}
    if actual != preimage:
        raise ValueError('Runtime preimage mismatch')
    if NEW in live or not set(EXISTING) <= live.keys():
        raise ValueError('Runtime module layout drift')
    result = dict(live)
    entry = _replace_method(live['entry.py'].decode(), baseline['entry.py'].decode(),
                            current['entry.py'].decode(), 'Default', 'fetch')
    marker = 'from essay_lab.admin_run_actions import retry_admin_run\n'
    if entry.count(marker) != 1:
        raise ValueError('Admin import marker drift')
    result['entry.py'] = entry.replace(marker,
        'from essay_lab.admin_run_actions import retry_admin_run,recover_admin_run\n'
        'from essay_lab.admin_run_recovery import finish_saved_recovery\n').encode()
    path = 'essay_lab/cloudflare_http.py'
    result[path] = _replace_method(live[path].decode(), baseline[path].decode(), current[path].decode(),
                                    'AsyncOperatingTransport', 'rpc').encode()
    for path in ('essay_lab/admin_run_actions.py', 'essay_lab/mixed_math_runtime.py'):
        if live[path] != baseline[path]:
            raise ValueError('Production module drift: ' + path)
        result[path] = current[path]
    result[NEW] = current[NEW]
    changes = []
    for path, data in result.items():
        if data != live.get(path):
            changes.append(dict(module=path, sha256_before=actual.get(path), sha256_after=sha256(data).hexdigest()))
    if {x['module'] for x in changes} != set(EXISTING) | {NEW}:
        raise ValueError('Unexpected changed module set')
    for path in set(EXISTING) | {NEW}:
        ast.parse(result[path])
    return result, dict(changes=changes, preserved={p: actual[p] for p in live if result[p] == live[p]},
                        input_files=len(live), output_files=len(result), deployment_performed=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('live', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--preimage', required=True, type=Path)
    parser.add_argument('--baseline-ref', required=True)
    args = parser.parse_args()
    live_dir, out = args.live.resolve(), args.output.resolve()
    if out.exists() or out == live_dir or live_dir in out.parents:
        raise ValueError('Output must be a new directory outside the live capture')
    live = {}
    for file in sorted(live_dir.rglob('*')):
        if '__pycache__' in file.parts:
            continue
        if file.is_symlink():
            raise ValueError('Runtime capture must not contain symlinks')
        if file.is_file():
            live[str(file.relative_to(live_dir))] = file.read_bytes()
    baseline = {p: subprocess.check_output(['git', 'show', args.baseline_ref + ':' + repository_path(p)], cwd=ROOT)
                for p in EXISTING}
    current = {p: (ROOT / repository_path(p)).read_bytes() for p in (*EXISTING, NEW)}
    candidate, manifest = prepare(live, baseline, current, json.loads(args.preimage.read_text()))
    out.mkdir(parents=True)
    for name, data in candidate.items():
        file = out / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(data)
    manifest['baseline_ref'] = args.baseline_ref
    # Sidecar is outside the runtime folder so packaging cannot include it.
    out.with_name(out.name + '-patch.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'input_files': len(live), 'output_files': len(candidate), 'changed_modules': len(manifest['changes']),
                      'deployment_performed': False}))


if __name__ == '__main__':
    main()
