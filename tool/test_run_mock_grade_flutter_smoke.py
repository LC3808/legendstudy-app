"""Offline loopback/fixture safety tests; never uses production credentials or HTTP."""
import contextlib
import io
import json
import unittest
import urllib.error
import urllib.request
import uuid
from unittest.mock import Mock, patch
from argparse import Namespace
from pathlib import Path

import test_verify_mock_scoring_jwt as d1
import run_mock_grade_flutter_smoke as runner


class BridgeTests(unittest.TestCase):
    def test_one_use_config_and_authorized_bounded_control(self):
        admin = Mock()
        bridge = runner.Bridge({'private': 'offline-canary'}, admin)
        try:
            with urllib.request.urlopen(bridge.url) as response:
                self.assertEqual(json.load(response), {'private': 'offline-canary'})
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(bridge.url)
            request = urllib.request.Request(bridge.url, data=b'{"action":"checkpoint"}')
            with urllib.request.urlopen(request) as response:
                self.assertEqual(json.load(response), {'ok': True})
            admin.control.assert_called_once_with({'action': 'checkpoint'})
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(urllib.request.Request(bridge.url+'wrong', data=b'{}'))
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(urllib.request.Request(bridge.url, data=b'x'*513))
            self.assertTrue(bridge.failed)
        finally:
            bridge.close()

    def test_error_redaction_and_control_before_config_denied(self):
        admin = Mock()
        admin.control.side_effect = RuntimeError('offline-secret-canary')
        bridge = runner.Bridge({}, admin)
        try:
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(urllib.request.Request(bridge.url, data=b'{}'))
            admin.control.assert_not_called()
            urllib.request.urlopen(bridge.url).close()
            with self.assertRaises(urllib.error.HTTPError) as error:
                urllib.request.urlopen(urllib.request.Request(bridge.url, data=b'{}'))
            self.assertNotIn(b'offline-secret-canary', error.exception.read())
        finally:
            bridge.close()

    def test_native_output_requires_every_stage_and_zero_exit(self):
        bridge = Mock(url='http://127.0.0.1:1/offline', failed=False)
        for code, missing in [(0, False), (1, False), (0, True)]:
            process = Mock()
            stages = runner.STAGES - ({'retry'} if missing else set())
            process.stdout = io.StringIO('\n'.join('D3_FLUTTER PASS '+s for s in stages))
            process.wait.return_value = code
            process.poll.return_value = code
            with patch.object(runner.subprocess, 'Popen', return_value=process) as launch, \
                 patch.object(runner.subprocess, 'run') as terminate, \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(runner.run_flutter(bridge, 'offline-device'), code == 0 and not missing)
            self.assertNotIn('PASSWORD', ' '.join(launch.call_args.args[0]))
            self.assertEqual(terminate.call_args.args[0][-1], 'com.legendstudy.app')

    def test_output_allowlist(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            seen = runner.safe_forward('secret D3_FLUTTER PASS confirmed_grade\n'
                'D3_FLUTTER PASS confirmed_grade secret\nD3_FLUTTER PASS confirmed_grade\n'
                'D3_FLUTTER FAIL provenance\nD3_FLUTTER PASS invented', runner.STAGES)
        self.assertEqual(seen, {('PASS', 'confirmed_grade'), ('FAIL', 'provenance')})
        self.assertNotIn('secret', output.getvalue())
        self.assertNotIn('invented', output.getvalue())


class DiagnosticTests(unittest.TestCase):
    def test_exception_messages_and_invalid_codes_are_never_printed(self):
        from verify_study_sessions_jwt import Failure
        errors = [RuntimeError(d1.SECRET), FileNotFoundError(d1.SECRET),
                  PermissionError(d1.SECRET), Failure(d1.SECRET),
                  runner.subprocess.CalledProcessError(7, [d1.SECRET], output=d1.SECRET),
                  runner.psycopg.OperationalError(d1.SECRET)]
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            for error in errors: runner.diagnose('db_connect', error)
            runner.diagnostic(d1.SECRET, d1.SECRET, code=d1.SECRET, http_status=d1.SECRET, exit_code=d1.SECRET)
        self.assertNotIn(d1.SECRET, output.getvalue())
        self.assertIn('stage=db_connect kind=file_missing', output.getvalue())
        self.assertIn('exit_code=7', output.getvalue())

    def test_auth_status_and_guard_are_safe(self):
        from verify_study_sessions_jwt import Failure, Response
        app = Mock(stage='login_preflight_A', last=Response(401, {'message': d1.SECRET}))
        output = io.StringIO()
        with contextlib.redirect_stdout(output): runner.diagnose('login_preflight', Failure('LOGIN'), app)
        self.assertEqual(output.getvalue().strip(), 'D3_FLUTTER DIAG stage=login_preflight_A kind=guard code=LOGIN http_status=401')

    def test_native_prefixed_markers_and_diagnostics(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            seen = runner.safe_forward('flutter: D3_FLUTTER PASS provenance\n'
                'flutter: D3_FLUTTER DIAG stage=provenance kind=assertion\n'
                'D3_FLUTTER DIAG stage=confirmed_grade kind=db_error code=23514\n'
                'D3_FLUTTER DIAG stage=login_preflight kind=auth http_status=401\n'
                'D3_FLUTTER DIAG stage=provenance kind=assertion '+d1.SECRET+'\n',runner.STAGES)
        self.assertEqual(seen, {('PASS','provenance')})
        self.assertIn('code=23514',output.getvalue())
        self.assertIn('kind=assertion',output.getvalue())
        self.assertNotIn(d1.SECRET,output.getvalue())

    def test_simulator_is_checked_without_credentials(self):
        for device, guard in [(None,'SIMULATOR_MISSING'),
                              ({'udid':'test','isAvailable':True,'state':'Shutdown'},'SIMULATOR_NOT_BOOTED'),
                              ({'udid':'test','isAvailable':False,'state':'Booted'},'SIMULATOR_UNAVAILABLE')]:
            result = Mock(stdout=json.dumps({'devices': {'runtime': [] if device is None else [device]}}))
            with patch.object(runner.subprocess,'run',return_value=result):
                with self.assertRaisesRegex(Exception,guard):runner.check_device('test')
        with patch.object(runner.subprocess,'run',return_value=Mock(stdout=json.dumps({'devices': {'runtime':[{'udid':'test','isAvailable':True,'state':'Booted'}]}}))):
            runner.check_device('test')

    def test_missing_native_stage_is_identified_without_raw_output(self):
        process=Mock(stdout=io.StringIO(d1.SECRET+'\nD3_FLUTTER FAIL provenance\n'))
        process.wait.return_value=1;process.poll.return_value=1
        bridge=Mock(url='http://127.0.0.1/offline',failed=True)
        output=io.StringIO()
        with patch.object(runner.subprocess,'Popen',return_value=process), patch.object(runner.subprocess,'run',return_value=Mock(returncode=0)), contextlib.redirect_stdout(output):
            self.assertFalse(runner.run_flutter(bridge,'test'))
        self.assertIn('exit_code=1',output.getvalue())
        self.assertIn('stage=provenance kind=missing_stages',output.getvalue())
        self.assertIn('kind=bridge_failed',output.getvalue())
        self.assertNotIn(d1.SECRET,output.getvalue())

    def test_database_error_code_is_allowlisted(self):
        output=io.StringIO()
        with contextlib.redirect_stdout(output):
            runner.diagnose('fixture_create',runner.psycopg.errors.UniqueViolation(d1.SECRET))
        self.assertIn('kind=db_error code=23505',output.getvalue())
        self.assertNotIn(d1.SECRET,output.getvalue())

    def test_diagnostic_bridge_failure_is_redacted(self):
        admin=Mock();admin.control.side_effect=RuntimeError(d1.SECRET)
        output=io.StringIO()
        with contextlib.redirect_stdout(output):
            bridge=runner.DiagnosticBridge({},admin)
            try:
                urllib.request.urlopen(bridge.url).close()
                with self.assertRaises(urllib.error.HTTPError):
                    urllib.request.urlopen(urllib.request.Request(bridge.url,data=b'{"action":"checkpoint"}'))
            finally:bridge.close()
        self.assertIn('stage=bridge_control kind=unexpected',output.getvalue())
        self.assertNotIn(d1.SECRET,output.getvalue())

    def test_finalizer_exceptions_cannot_escape_with_secrets(self):
        args=Namespace(public_config=Path('/private/tmp/offline-public.json'),device='test',preflight_only=True)
        for target in ['auth_users_retained','db_close']:
            app=Mock(sessions={'A':{'id':d1.OWNERS['A']},'B':{'id':d1.OWNERS['B']}})
            app.finish_auth.return_value=True
            db=Mock();admin=Mock(started=False)
            if target=='db_close':db.close.side_effect=RuntimeError(d1.SECRET)
            else:app.finish_auth.side_effect=RuntimeError(d1.SECRET)
            output=io.StringIO()
            with patch.object(runner.argparse.ArgumentParser,'parse_args',return_value=args), patch.object(runner.sys.stdin,'isatty',return_value=True), patch.object(Path,'read_text',return_value=json.dumps(d1.CONFIG)), patch.object(runner.getpass,'getpass',return_value=d1.SECRET), patch('builtins.input',return_value=''), patch.object(runner,'Acceptance',return_value=app), patch.object(runner.psycopg,'connect',return_value=db), patch.object(runner,'RuntimeFixtures',return_value=admin), contextlib.redirect_stdout(output):
                self.assertEqual(runner.main(),1)
            self.assertIn('stage='+target+' kind=unexpected',output.getvalue())
            self.assertNotIn(d1.SECRET,output.getvalue())

    def test_startup_failure_stops_before_hidden_inputs(self):
        output=io.StringIO()
        args=Namespace(public_config=Path('/private/tmp/offline-public.json'),device='test',preflight_only=False)
        with patch.object(runner.argparse.ArgumentParser,'parse_args',return_value=args), patch.object(runner.sys.stdin,'isatty',return_value=False), patch.object(runner.getpass,'getpass') as prompt, contextlib.redirect_stdout(output):
            self.assertEqual(runner.main(),1)
        prompt.assert_not_called()
        self.assertIn('stage=startup kind=guard code=INTERACTIVE_REQUIRED',output.getvalue())



class RuntimeStorageTests(unittest.TestCase):
    setUpClass = classmethod(d1.StorageTests.setUpClass.__func__)
    tearDownClass = classmethod(d1.StorageTests.tearDownClass.__func__)
    setUp = d1.StorageTests.setUp
    tearDown = d1.StorageTests.tearDown

    def runtime(self):
        admin = runner.RuntimeFixtures(self.db)
        admin.preflight(d1.OWNERS)
        admin.create()
        self.app.admin = admin
        return admin

    def submit_three(self, admin):
        payloads = []
        for key, cutoff, status in [('key1','cut1','confirmed'),
                                   ('estimated_key','estimated_cut','estimated'),
                                   ('unavailable_key',None,'unavailable')]:
            study, attempt = str(uuid.uuid4()), str(uuid.uuid4())
            admin.register('study', study)
            self.db.execute('''insert into public.study_sessions(id,user_id,mode,title,planned_duration_seconds,started_at,ended_at,active_segments)
                values(%s,%s,'mock_exam','Synthetic',60,'2026-09-14T00:00:00Z','2026-09-14T00:01:00Z','[[0,60000]]')''',
                (study,d1.OWNERS['A']))
            admin.register('attempt', attempt)
            payload = dict(p_attempt_id=attempt,p_study_session_id=study,
                p_answer_key_version_id=admin.ids[key],p_grade_cutoff_version_id=admin.ids[cutoff] if cutoff else None,
                p_scoring_version='mcq5-v1',p_answers=[{'question_number':1,'choice':1},{'question_number':2,'choice':5}])
            response = self.app.submit(payload)
            self.assertEqual(response.status,200)
            self.assertEqual(response.body['grade_status'],status)
            self.assertEqual(response.body['grade'],None if cutoff is None else 8)
            self.assertEqual(response.body['raw_score'],2)
            self.assertEqual(response.body['unanswered_count'],1)
            admin.capture()
            payloads.append((payload,response.body))
        return payloads

    def test_three_modes_historical_retry_and_atomic_cleanup(self):
        admin=self.runtime();payloads=self.submit_three(admin)
        before=admin.trigger_state()
        admin.control({'action':'switch'})
        self.assertTrue(admin.switched)
        for payload, old in payloads:
            self.assertEqual(self.app.submit(payload).body,old)
            self.assertEqual(self.app.fetch(payload['p_attempt_id']),old)
            self.assertIsNone(self.app.fetch(payload['p_attempt_id'],who='B'))
        with self.assertRaises(Exception):admin.register('attempt',str(uuid.uuid4()))
        admin.capture()
        with contextlib.redirect_stdout(io.StringIO()):admin.cleanup()
        self.assertEqual(admin.snapshot(),admin.baseline)
        self.assertEqual(admin.trigger_state(),before)

    def test_limits_collision_and_repeated_control(self):
        admin=self.runtime()
        with self.assertRaises(Exception):admin.control({'action':'switch'})
        for _ in range(3):
            value=str(uuid.uuid4());admin.register('study',value);admin.register('study',value)
        with self.assertRaises(Exception):admin.register('study',str(uuid.uuid4()))
        with self.assertRaises(Exception):admin.control({'action':'register','kind':'study','id':'bad'})
        with self.assertRaises(Exception):admin.control({'action':'checkpoint','sql':'no'})
        with self.assertRaises(Exception):admin.control({'action':'arbitrary'})
        admin.studies.clear()  # Only empty, never-dispatched test IDs.
        value=str(uuid.uuid4())
        self.db.execute('''insert into public.study_sessions(id,user_id,mode,title,planned_duration_seconds,started_at,ended_at,active_segments)
            values(%s,%s,'mock_exam','Synthetic',60,'2026-09-14T00:00:00Z','2026-09-14T00:01:00Z','[[0,60000]]')''',(value,d1.OWNERS['A']))
        with self.assertRaises(Exception):admin.register('study',value)
        self.assertNotIn(value,admin.studies)

    def test_other_owner_and_digest_changes_rollback_cleanup(self):
        admin=self.runtime();self.submit_three(admin)
        study=next(iter(admin.studies))
        # Existing immutable Study rows cannot be reassigned, so replace only a
        # local test row after deleting dependent attempts in this throwaway DB.
        self.db.execute('delete from public.mock_exam_attempts where study_session_id=%s',(study,))
        self.db.execute('delete from public.study_sessions where id=%s',(study,))
        self.db.execute('''insert into public.study_sessions(id,user_id,mode,title,planned_duration_seconds,started_at,ended_at,active_segments)
            values(%s,%s,'mock_exam','Synthetic',60,'2026-09-14T00:00:00Z','2026-09-14T00:01:00Z','[[0,60000]]')''',(study,d1.OWNERS['B']))
        admin.capture();before=admin.snapshot()
        with self.assertRaises(Exception):admin.cleanup()
        self.assertEqual(admin.snapshot(),before)
        self.assertEqual(admin.trigger_state(),admin.original_triggers)

    def test_cleanup_failure_rolls_back_all_extra_fixtures_and_triggers(self):
        admin=self.runtime();self.submit_three(admin);before=admin.snapshot()
        from verify_mock_scoring_jwt import DELETE_ORDER
        for target in ('disabled',*DELETE_ORDER,'before_commit'):
            def fault(stage):
                if stage==target:raise RuntimeError('offline fault')
            with self.assertRaises(RuntimeError):admin.cleanup(fault)
            self.assertEqual(admin.snapshot(),before)
            self.assertEqual(admin.trigger_state(),admin.original_triggers)
        with contextlib.redirect_stdout(io.StringIO()):admin.cleanup()
        self.assertEqual(admin.snapshot(),admin.baseline)

    def test_partial_creation_still_in_scope(self):
        admin=runner.RuntimeFixtures(self.db);admin.preflight(d1.OWNERS)
        original=admin.publish
        def publish(table,value):
            if value==admin.ids['estimated_cut']:raise RuntimeError(d1.SECRET)
            original(table,value)
        with patch.object(admin,'publish',side_effect=publish),self.assertRaises(RuntimeError):admin.create()
        admin.capture()
        with contextlib.redirect_stdout(io.StringIO()):admin.cleanup()
        self.assertEqual(admin.snapshot(),admin.baseline)

    def test_preflight_only_never_creates_fixture_and_errors_are_redacted(self):
        self.run_main(preflight=True)
        self.assertEqual(self.httpdb.execute('select count(*) from public.answer_key_versions').fetchone()[0],0)

    def run_main(self, preflight=False):
        args=Namespace(public_config=Path('/private/tmp/offline-public.json'),device='offline-device',preflight_only=preflight)
        output=io.StringIO()
        with patch.object(runner.argparse.ArgumentParser,'parse_args',return_value=args), \
             patch.object(Path,'read_text',return_value=json.dumps(d1.CONFIG)), \
             patch.object(runner.sys.stdin,'isatty',return_value=True), \
             patch.object(runner.getpass,'getpass',return_value=d1.SECRET), \
             patch('builtins.input',return_value=''), \
             patch.object(runner,'Acceptance',side_effect=lambda config:d1.Acceptance(config,self.transport)), \
             patch.object(runner.psycopg,'connect',return_value=self.db), \
             patch.object(runner,'check_device'), \
             patch.object(runner,'run_flutter',side_effect=RuntimeError(d1.SECRET)) as flutter, \
             contextlib.redirect_stdout(output):
            self.assertEqual(runner.main(),0 if preflight else 1)
        self.assertNotIn(d1.SECRET,output.getvalue())
        if preflight:flutter.assert_not_called()
        else:
            for stage in runner.CLEANUP:self.assertIn('D3_FLUTTER PASS '+stage,output.getvalue())
            self.assertNotIn('Flutter grade result smoke: PASS',output.getvalue())
        return output.getvalue()

    def test_runner_failure_still_cleans_all_modes(self):
        self.run_main()
        self.assertEqual(self.httpdb.execute('select count(*) from public.answer_key_versions').fetchone()[0],0)

if __name__=='__main__':unittest.main()
