"""Offline safety/acceptance orchestration tests; no production requests."""
import contextlib
import io
import json
import unittest
import urllib.parse
from unittest.mock import patch
from verify_study_sessions_jwt import Verifier, Response, EMAILS, base_payload, instant, Transport, NoRedirect, DIRECT_INSERT_REJECTIONS, Failure

CONFIG = {'SUPABASE_URL':'https://stlhijzpjfgwwdgunlsd.supabase.co',
          'SUPABASE_PUBLISHABLE_KEY':'sb_'+'publishable_'+'offline'}
IDS = {'A':'11111111-1111-4111-8111-111111111111','B':'22222222-2222-4222-8222-222222222222'}
SECRET = 'sensitive-response-must-never-appear'


class Fake:
    def __init__(self):
        self.rows = {}
        self.calls = []
        self.profiles = {'A':[{'id':IDS['A'],'display_name':'existing','target_label':'keep','neis_school_code':'keep'}],'B':[]}
        self.fail_after_insert = False
        self.cleanup_fail = False
        self.wrong_duration = False
        self.leak_rls = False
        self.count_missing = False
        self.auth_error = False
        self.profile_mutated = False

    def __call__(self, method, path, data, token, prefer):
        self.calls.append((method,path,data,token,prefer))
        parsed = urllib.parse.urlsplit(path)
        query = {k:v[0] for k,v in urllib.parse.parse_qs(parsed.query).items()}
        label = token.removeprefix('token-') if token else None
        if parsed.path == '/auth/v1/token':
            if self.auth_error:
                return Response(400,{'code':SECRET,'message':SECRET,'access_token':SECRET})
            label = next(x for x,email in EMAILS.items() if email == data['email'])
            return Response(200,{'user':{'id':IDS[label],'email':EMAILS[label]},'access_token':'token-'+label})
        if parsed.path == '/auth/v1/user':
            return Response(200,{'id':IDS[label]})
        if parsed.path == '/auth/v1/logout':
            return Response(204,None)
        if parsed.path == '/rest/v1/profiles':
            assert method == 'GET', 'profiles must never be mutated'
            return Response(200,json.loads(json.dumps(self.profiles[label])))
        assert parsed.path == '/rest/v1/study_sessions'
        row_id = query.get('id','')[3:]
        if method == 'GET':
            rows = [dict(r) for r in self.rows.values() if (r['user_id']==IDS[label] or self.leak_rls)
                    and (not row_id or r['id']==row_id)]
            count = len(rows) if prefer == 'count=exact' and not self.count_missing else None
            return Response(200,rows[:1] if 'limit' in query else rows,count)
        if method == 'PATCH':
            return Response(403,{'code':'42501','message':SECRET})
        if method == 'DELETE':
            if self.cleanup_fail:
                return Response(503,{'code':SECRET})
            row = self.rows.get(row_id)
            if row and row['user_id']==IDS[label]:
                del self.rows[row_id]
                return Response(200,[row])
            return Response(200,[])
        assert method == 'POST'
        if 'duration_seconds' in data:
            return Response(400,{'code':'428C9'})
        if {'user_id','created_at'} & data.keys():
            return Response(403,{'code':'42501'})
        try:
            span = (instant(data['ended_at'])-instant(data['started_at'])).total_seconds()*1000
            assert 0 <= span <= 86400000
            intervals = data['active_segments']
            assert isinstance(intervals,list) and len(intervals)<=256
            end,total = 0,0
            for pair in intervals:
                assert isinstance(pair,list) and len(pair)==2
                a,b = pair
                assert type(a) is int and type(b) is int and end<=a<b<=span
                total+=b-a
                end=b
            assert total>=1000
            assert data['mode'] in ('study','mock_exam')
            for field,n in [('title',80),('subject',40)]:
                value=data.get(field)
                assert value is None or (isinstance(value,str) and value==value.strip() and 1<=len(value)<=n)
            plan=data.get('planned_duration_seconds')
            if data['mode']=='mock_exam':
                assert data.get('title') and type(plan) is int and 60<=plan<=43200 and total<=plan*1000
            else:
                assert plan is None
        except (AssertionError,TypeError,KeyError):
            return Response(400,{'code':'23514'})
        row = {'title':None,'subject':None,'planned_duration_seconds':None,**data,
               'user_id':IDS[label],'duration_seconds':total//1000,
               'created_at':'2026-09-14T01:00:00+00:00'}
        self.rows[row['id']] = row
        if self.profile_mutated:
            self.profiles['A'][0]['display_name']='changed elsewhere'
        if self.fail_after_insert:
            self.fail_after_insert=False
            raise TimeoutError(SECRET)
        if self.wrong_duration:
            row['duration_seconds']=999
        return Response(201,[dict(row)])


class VerifierTests(unittest.TestCase):
    def run_fake(self,fake,preflight=False):
        v=Verifier(CONFIG,fake)
        with contextlib.redirect_stdout(io.StringIO()) as out:
            result=v.run({'A':SECRET,'B':SECRET},preflight)
        self.assertNotIn(SECRET,out.getvalue())
        self.assertNotIn('token-A',out.getvalue())
        return result,out.getvalue(),v

    def test_full_acceptance_and_exact_cleanup(self):
        fake=Fake(); before=json.dumps(fake.profiles,sort_keys=True)
        good,output,v=self.run_fake(fake)
        self.assertTrue(good,output)
        self.assertEqual(fake.rows,{})
        self.assertEqual(json.dumps(fake.profiles,sort_keys=True),before)
        for stage in ['normal_study','mock_exam','interval_validation','generated_duration','mode_validation',
                      'text_validation','ownership_isolation','update_denied','owner_delete','fixture_cleanup','auth_users_retained']:
            self.assertIn('STUDY_RUNTIME PASS '+stage,output)
        for method,path,data,token,prefer in fake.calls:
            if method=='DELETE':
                row_id=urllib.parse.parse_qs(urllib.parse.urlsplit(path).query)['id'][0][3:]
                self.assertIn(row_id,v.attempted)
            if path.startswith('/auth/'):
                self.assertNotIn('admin',path)
                self.assertNotEqual(method,'DELETE')

    def test_preflight_only_never_writes_rows(self):
        fake=Fake();good,out,v=self.run_fake(fake,True)
        self.assertTrue(good,out)
        self.assertFalse(v.attempted)
        self.assertFalse(any(m!='GET' and p.startswith('/rest/') for m,p,*_ in fake.calls))

    def test_existing_rows_stop_without_deleting(self):
        fake=Fake();fake.rows['existing']={'id':'existing','user_id':IDS['B']}
        good,out,v=self.run_fake(fake)
        self.assertFalse(good)
        self.assertIn('EXISTING_STUDY_ROWS_STOP',out)
        self.assertIn('existing',fake.rows)
        self.assertFalse(any(m=='DELETE' for m,*_ in fake.calls))

    def test_missing_exact_count_stops_before_writes(self):
        fake=Fake();fake.count_missing=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertIn('EXACT_COUNT_MISSING',out);self.assertFalse(v.attempted)

    def test_uncertain_insert_is_cleaned(self):
        fake=Fake();fake.fail_after_insert=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertTrue(v.attempted);self.assertEqual(fake.rows,{})
        self.assertIn('PASS fixture_cleanup',out)

    def test_cleanup_failure_never_passes(self):
        fake=Fake();fake.cleanup_fail=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertNotIn('PASS fixture_cleanup',out)
        self.assertNotIn('PASS acceptance',out);self.assertTrue(fake.rows)

    def test_wrong_generated_value_not_http_only_pass(self):
        fake=Fake();fake.wrong_duration=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertIn('GENERATED_DURATION',out);self.assertEqual(fake.rows,{})

    def test_rls_visible_row_is_failure(self):
        fake=Fake();fake.leak_rls=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertIn('B_CAN_READ_A',out)

    def test_profile_difference_detected_without_profile_writes(self):
        fake=Fake();fake.profile_mutated=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertIn('PROFILE_CHANGED',out)
        self.assertFalse(any(m!='GET' and '/profiles' in p for m,p,*_ in fake.calls))

    def test_raw_auth_failure_is_redacted(self):
        fake=Fake();fake.auth_error=True
        good,out,v=self.run_fake(fake)
        self.assertFalse(good);self.assertIn('HTTP=400',out);self.assertIn('db_code=UNAVAILABLE',out)

    def test_wrong_project_rejected_before_transport(self):
        fake=Fake()
        with self.assertRaises(Exception):
            Verifier({**CONFIG,'SUPABASE_URL':'https://other.example'},fake)
        self.assertEqual(fake.calls,[])

    def test_same_identity_preflight_rejected(self):
        fake=Fake()
        def call(*args):
            result=fake(*args)
            if args[1].startswith('/auth/v1/token') and result.body['user']['email']==EMAILS['B']:
                result.body['user']['id']=IDS['A']
            return result
        with contextlib.redirect_stdout(io.StringIO()) as out:
            good=Verifier(CONFIG,call).run({'A':'offline','B':'offline'})
        self.assertFalse(good);self.assertIn('IDENTITIES_NOT_DISTINCT',out.getvalue())

    def test_direct_insert_exact_rejection_pairs(self):
        for field in ('duration_seconds', 'user_id', 'created_at'):
            for status, code in [(400,'428C9'), (403,'42501'), (400,'42501'),
                                 (403,'428C9'), (400,'23514'), (400,'PGRST204'),
                                 (400,'unknown'), (500,'428C9'), (201,'428C9')]:
                with self.subTest(field=field,status=status,code=code):
                    fake=Fake()
                    def call(method,path,data,token,prefer):
                        if method=='POST' and path=='/rest/v1/study_sessions':
                            return Response(status,{'code':code,'message':SECRET})
                        return fake(method,path,data,token,prefer)
                    v=Verifier(CONFIG,call)
                    v.sessions={x:{'id':IDS[x],'token':'token-'+x} for x in IDS}
                    payload=base_payload(**{field:999})
                    if (status,code) in DIRECT_INSERT_REJECTIONS[field]:
                        v.reject(payload,expected=DIRECT_INSERT_REJECTIONS[field])
                    else:
                        with self.assertRaisesRegex(Failure,'EXPECTED_REJECTION'):
                            v.reject(payload,expected=DIRECT_INSERT_REJECTIONS[field])

    def test_generated_code_not_accepted_for_unrelated_validation(self):
        fake=Fake()
        def call(method,path,data,token,prefer):
            if method=='POST': return Response(400,{'code':'428C9'})
            return fake(method,path,data,token,prefer)
        v=Verifier(CONFIG,call)
        v.sessions={x:{'id':IDS[x],'token':'token-'+x} for x in IDS}
        with self.assertRaisesRegex(Failure,'EXPECTED_REJECTION'):
            v.reject(base_payload(mode='invalid'))

    def test_allowed_rejection_still_checks_row_absence(self):
        fake=Fake()
        def call(method,path,data,token,prefer):
            if method=='POST':
                fake.rows[data['id']]={'id':data['id'],'user_id':IDS['A']}
                return Response(400,{'code':'428C9'})
            return fake(method,path,data,token,prefer)
        v=Verifier(CONFIG,call)
        v.sessions={x:{'id':IDS[x],'token':'token-'+x} for x in IDS}
        with self.assertRaisesRegex(Failure,'REJECTED_ROW_EXISTS'):
            v.reject(base_payload(duration_seconds=999),expected=DIRECT_INSERT_REJECTIONS['duration_seconds'])

    def test_legacy_generated_privilege_rejection_full_run(self):
        fake=Fake()
        def call(method,path,data,token,prefer):
            if method=='POST' and path=='/rest/v1/study_sessions' and 'duration_seconds' in data:
                return Response(403,{'code':'42501'})
            return fake(method,path,data,token,prefer)
        with contextlib.redirect_stdout(io.StringIO()) as out:
            good=Verifier(CONFIG,call).run({'A':'offline','B':'offline'})
        self.assertTrue(good,out.getvalue())
        self.assertEqual(fake.rows,{})

    def test_transport_count_and_non_json_status(self):
        class Raw:
            code=503
            headers={'Content-Range':'*/0'}
            def read(self): return SECRET.encode()
            def __enter__(self): return self
            def __exit__(self,*args): pass
        transport=Transport('offline')
        with patch.object(transport.opener,'open',return_value=Raw()):
            response=transport('GET','/rest/v1/study_sessions')
        self.assertEqual((response.status,response.body,response.count),(503,None,0))
        self.assertIsNone(NoRedirect().redirect_request(None,None,302,None,None,'https://other.example'))

if __name__=='__main__':
    unittest.main()
