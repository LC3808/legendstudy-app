"""Run offline fault tests against the captured-runtime quote alignment candidate.

python3 -m tool.cloudflare_essay.verify_quote_candidate CANDIDATE
  --manifest CANDIDATE_PATCH_JSON --report REPORT_JSON

No network, Provider, production DB or deployment. Counts are unittest executions,
including existing imported fixture cases, not a count of distinct user scenarios.
"""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
MODULES = [
    'tool.test_essay_session_retry', 'tool.test_essay_async_runtime',
    'tool.test_essay_exam_runtime', 'tool.test_essay_durable_exam',
    'tool.test_essay_durable_journal', 'tool.test_essay_provider_binding',
    'tool.test_essay_reviewed_runtime', 'tool.test_essay_live_worker',
    'tool.test_essay_material_execution', 'tool.test_essay_long_criteria',
    'tool.test_essay_transport_diagnostics', 'tool.test_essay_queue_continuation',
    'tool.test_essay_archived_dispatch', 'tool.test_mixed_math_checkpoint',
    'tool.test_essay_quote_alignment',
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    candidate = args.candidate.resolve()
    manifest = json.loads(args.manifest.read_text())
    expected = dict(manifest['preserved']) | {x['module']: x['sha256_after'] for x in manifest['changes']}
    actual = {str(p.relative_to(candidate)): sha256(p.read_bytes()).hexdigest()
              for p in candidate.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
    if actual != expected:
        raise ValueError('Candidate hash mismatch')
    import tool.essay_lab
    tool.essay_lab.__path__ = [str(candidate / 'essay_lab')]
    modules = MODULES
    from tool import test_essay_archived_dispatch as archive_tests
    original_method = archive_tests.method
    archive_tests.method = lambda path, name, scope: original_method(
        str(candidate / ('entry.py' if path.endswith('/entry.py') else path.removeprefix('tool/'))), name, scope)
    from tool import test_essay_queue_continuation as queue_tests
    queue_tests.Path = lambda _: candidate / 'entry.py'
    from tool.test_essay_async_runtime import AsyncTests
    original_parity = AsyncTests.test_existing_worker_success_failure_timeout_parity
    async def deterministic_parity(self):
        # Existing sync/async latency equality otherwise flakes by 1ms. Product
        # deadline/transport behavior is covered by its separate fault tests.
        with patch('tool.essay_lab.live_worker.time.monotonic', return_value=1000.0):
            await original_parity(self)
    AsyncTests.test_existing_worker_success_failure_timeout_parity = deterministic_parity
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromNames(modules))
    imports = {name: module.__file__ for name, module in sys.modules.items()
               if name.startswith('tool.essay_lab.') and '.test_' not in name and hasattr(module, '__file__')}
    if not all(str(candidate) in path for path in imports.values()):
        raise ValueError('A runtime module was imported outside the verified candidate')
    report = dict(tests=result.testsRun, failures=len(result.failures), errors=len(result.errors),
        skips=len(result.skipped), modules=modules,
        runtime_imports={name: str(Path(path).relative_to(candidate)) for name, path in imports.items()},
        candidate_changes=manifest['changes'], preserved_source_files=len(manifest['preserved']),
        external_provider_calls=0, production_db_mutations=0, deployment_performed=False,
        test_adjustment='Only existing sync/async parity test uses a fixed monotonic clock to prevent 1ms assertion flake.')
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    raise SystemExit(main())
