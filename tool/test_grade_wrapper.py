"""Offline shell dispatch tests. Never runs the credential-bearing verifier."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

WRAPPER = Path(__file__).resolve().with_name('run_mock_grade_flutter_smoke.sh')


class WrapperTests(unittest.TestCase):
    def test_missing_venv_has_setup_guidance_without_global_fallback(self):
        with tempfile.TemporaryDirectory() as folder:
            env = {**os.environ, 'LEGENDSTUDY_VERIFIER_VENV': folder + '/missing'}
            result = subprocess.run([str(WRAPPER), '/external/config.json'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn('--setup', result.stderr)
            self.assertNotIn('Traceback', result.stderr)

    def test_existing_venv_dispatch_preserves_arguments_and_exit(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'bin').mkdir()
            python = root / 'bin/python'
            python.write_text('#!/bin/sh\nif [ "$1" = "-I" ]; then exit 0; fi\nprintf "%s\\n" "$@" > "$WRAPPER_CAPTURE"\nexit 7\n')
            python.chmod(0o700)
            capture = root / 'args'
            env = {**os.environ, 'LEGENDSTUDY_VERIFIER_VENV': folder, 'WRAPPER_CAPTURE': str(capture)}
            result = subprocess.run([str(WRAPPER), '/external/path with spaces.json', '--preflight-only'], env=env, capture_output=True, text=True, cwd='/private/tmp')
            self.assertEqual(result.returncode, 7)
            self.assertEqual(capture.read_text().splitlines(), ['-B', str(WRAPPER.with_suffix('.py')), '/external/path with spaces.json', '--preflight-only'])
            self.assertEqual(result.stdout + result.stderr, '')

    def test_dependency_failure_is_redacted(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); (root / 'bin').mkdir()
            python = root / 'bin/python'
            python.write_text('#!/bin/sh\necho offline-secret-canary >&2\nexit 1\n'); python.chmod(0o700)
            result = subprocess.run([str(WRAPPER), '/external/config.json'], env={**os.environ, 'LEGENDSTUDY_VERIFIER_VENV': folder}, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertNotIn('offline-secret-canary', result.stdout + result.stderr)

    def test_stable_user_venv_is_selected_automatically(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            binary = root / 'Library/Application Support/LegendStudy/verifier-venv/bin/python'
            binary.parent.mkdir(parents=True)
            binary.write_text('#!/bin/sh\nif [ "$1" = "-I" ]; then exit 0; fi\nexit 9\n')
            binary.chmod(0o700)
            env = {**os.environ, 'HOME': folder}
            env.pop('LEGENDSTUDY_VERIFIER_VENV', None)
            result = subprocess.run([str(WRAPPER), '/external/config.json'], env=env, capture_output=True)
            self.assertEqual(result.returncode, 9)

    def test_explicit_setup_only_installs_into_external_venv(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            bin_dir = root / 'fake-bin'; bin_dir.mkdir()
            python = bin_dir / 'python3'
            python.write_text('#!/bin/sh\n[ "$1" = "-m" ] && [ "$2" = "venv" ] || exit 99\nmkdir -p "$3/bin"\ncat > "$3/bin/python" <<\'STUB\'\n#!/bin/sh\n[ "$1" = "-m" ] && [ "$2" = "pip" ] || exit 98\nprintf \'%s\\n\' "$@" > "$SETUP_CAPTURE"\nSTUB\nchmod +x "$3/bin/python"\n')
            python.chmod(0o700)
            capture = root / 'setup-args'
            env = {**os.environ, 'HOME': folder, 'PATH': str(bin_dir) + ':/usr/bin:/bin', 'SETUP_CAPTURE': str(capture)}
            result = subprocess.run([str(WRAPPER), '--setup'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('psycopg[binary]==3.2.10', capture.read_text())
            self.assertNotIn('Password for', result.stdout)

    def test_help_and_setup_cannot_accidentally_run_acceptance(self):
        for args in [[], ['--setup', '/external/config.json']]:
            result = subprocess.run([str(WRAPPER), *args], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertNotIn('Password for', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
