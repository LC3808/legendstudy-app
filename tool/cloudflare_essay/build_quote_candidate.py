"""Patch an extracted, hash-verified bdee88d0 runtime; never deploy HEAD wholesale.

Input must contain all captured modules (including prompts/python_modules).
Does not contact a Provider, database or deployment endpoint.
"""
import argparse
import ast
from hashlib import sha256
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
PREIMAGE = {
    'live_worker': 'd4f3f1f969f255cf170e38522da9e5e8215a09f1cc6a6427ae55a598c78b9682',
    'cloudflare_runtime': 'a34b560e07ceab531fed7e9a36694bbcdc871ef315eaaff9cb5b38e118949b9b',
}


def function(source, name):
    node = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == name)
    return ''.join(source.splitlines(keepends=True)[node.lineno-1:node.end_lineno]) + '\n'


def build(captured, inventory, destination):
    actual = {str(p.relative_to(captured)): sha256(p.read_bytes()).hexdigest()
              for p in captured.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
    expected = {item['name']: item['sha256'] for item in inventory}
    if actual != expected or len(expected) != 76:
        raise ValueError('Captured inventory mismatch')
    if destination.exists():
        raise ValueError('Destination must be new')
    shutil.copytree(captured, destination, ignore=shutil.ignore_patterns('__pycache__'))
    changes = []
    for module, preimage in PREIMAGE.items():
        relative = f'essay_lab/{module}.py'
        path = destination / relative
        old = path.read_text()
        if sha256(old.encode()).hexdigest() != preimage:
            raise ValueError('Production preimage mismatch: ' + relative)
        source = (ROOT / 'tool' / relative).read_text()
        updated = old
        if module == 'live_worker':
            needle = '            out=parse_provider(result.raw,claim)\n'
            if updated.count(needle) != 1 or updated.count('return validate_output(out,claim)') != 1:
                raise ValueError('Patch context mismatch')
            updated = updated.replace(needle, needle + "            alignment=quote_alignment_receipt(result.raw,out)\n            if alignment is not None:\n                (yield ('receipt_sink', (alignment,)))\n")
            updated = updated.replace('return validate_output(out,claim)', 'return validate_output(align_exact_quote_offsets(out,claim),claim)')
            updated += '\n\n' + function(source, 'align_exact_quote_offsets') + '\n\n' + function(source, 'quote_alignment_receipt')
        else:
            updated = updated.replace(function(old, 'receipt_checkpoint_key'), function(source, 'receipt_checkpoint_key'))
        ast.parse(updated)
        path.write_text(updated)
        changes.append(dict(module=relative, sha256_before=preimage, sha256_after=sha256(updated.encode()).hexdigest()))
    return dict(changes=changes, preserved={key: value for key, value in expected.items()
                if key not in {x['module'] for x in changes}})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('captured', type=Path)
    parser.add_argument('inventory', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('manifest', type=Path)
    args = parser.parse_args()
    result = build(args.captured, json.loads(args.inventory.read_text()), args.destination)
    args.manifest.write_text(json.dumps(result, indent=2) + '\n')
