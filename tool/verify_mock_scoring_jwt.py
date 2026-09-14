"""Opt-in LegendStudy scoring acceptance; never logs credentials or raw responses.

Requires psycopg[binary]==3.2.10. Administrator credentials are hidden terminal
input, not service-role/API secrets. Only the three Owner-approved USER triggers
may be suspended, exclusively inside the atomic, UUID-scoped cleanup transaction.
"""
import argparse
import getpass
import json
import re
import sys
import urllib.parse
import uuid
import warnings
from pathlib import Path

import psycopg
from psycopg import sql
from verify_study_sessions_jwt import EMAILS, HOST, Transport, require

REF = 'stlhijzpjfgwwdgunlsd'
TRIGGERS = {'answer_key_versions': 'scoring_key_publication',
            'grade_cutoff_versions': 'scoring_cutoff_publication',
            'exam_questions': 'scoring_question_guard'}
SCORING = tuple(TRIGGERS) + ('mock_exam_attempts', 'mock_exam_answers')
DELETE_ORDER = ('mock_exam_attempts', 'study_sessions', 'exam_questions',
                'grade_cutoff_versions', 'answer_key_versions', 'exam_subjects',
                'exams', 'subjects', 'content_items', 'source_posts')
ID_FIELDS = {table: 'id' for table in DELETE_ORDER}
ID_FIELDS.update(exams='content_item_id', exam_questions='answer_key_version_id',
                 mock_exam_answers='attempt_id')
SAFE_CODES = {'23514', '23505', '42501', '22023', '23503', '23502',
              '42P01', '42703', '55P03', '57014', 'PGRST202', 'PGRST204'}
ANSWERS = [{'question_number': 1, 'choice': 1}, {'question_number': 2, 'choice': 5}]


def passed(stage):
    print('SCORING_RUNTIME PASS ' + stage, flush=True)


def identifier(name):
    return sql.Identifier('public', name)


def uuid_value(value):
    return str(uuid.UUID(str(value)))


def admin_settings(host, password):
    """Construct a project-pinned connection. No caller-supplied libpq options."""
    direct = 'db.' + REF + '.supabase.co'
    pooler = re.fullmatch(r'aws-[0-9]+-[a-z0-9-]+\.pooler\.supabase\.com', host)
    require(host == direct or pooler is not None, 'ADMIN_HOST')
    require(bool(password), 'ADMIN_PASSWORD')
    return dict(host=host, port=5432, dbname='postgres',
                user='postgres' if host == direct else 'postgres.' + REF,
                password=password, sslmode='require', connect_timeout=15,
                application_name='legendstudy_scoring_acceptance',
                options='-c statement_timeout=30000 -c lock_timeout=5000', autocommit=True)


class AdminFixtures:
    """Administrator-only fixture lifecycle. No JWT acceptance is simulated here."""
    def __init__(self, connection):
        self.db = connection
        self.ids = {name: uuid_value(uuid.uuid4()) for name in
                    ('source', 'content', 'subject', 'occurrence', 'key1', 'key2',
                     'incomplete', 'cut1', 'cut2', 'wrongcut', 'study')}
        self.attempts = set()
        self.tables = []
        self.baseline = None
        self.manifest = None
        self.original_triggers = None
        self.started = False
        self.owners = None

    def scopes(self):
        i = self.ids
        return {'source_posts': [i['source']], 'content_items': [i['content']],
                'subjects': [i['subject']], 'exams': [i['content']],
                'exam_subjects': [i['occurrence']],
                'answer_key_versions': [i['key1'], i['key2'], i['incomplete']],
                'exam_questions': [i['key1'], i['key2'], i['incomplete']],
                'grade_cutoff_versions': [i['cut1'], i['cut2'], i['wrongcut']],
                'study_sessions': [i['study']], 'mock_exam_attempts': sorted(self.attempts),
                'mock_exam_answers': sorted(self.attempts)}

    def trigger_state(self):
        return self.db.execute("""select c.relname,t.tgname,t.tgenabled,t.tgisinternal,
          t.tgconstraint::text from pg_trigger t join pg_class c on c.oid=t.tgrelid
          join pg_namespace n on n.oid=c.relnamespace where n.nspname='public'
          order by c.relname,t.tgname""").fetchall()

    def snapshot(self, only_fixture=False, exclude_fixture=False):
        result = {}
        scopes = self.scopes()
        for table in self.tables:
            clause, args = sql.SQL(''), []
            if table in scopes and (only_fixture or exclude_fixture):
                clause = sql.SQL(' where {}{} = any(%s::uuid[])').format(
                    sql.SQL('not ') if exclude_fixture else sql.SQL(''),
                    sql.Identifier(ID_FIELDS[table]))
                args = [scopes[table]]
            elif only_fixture:
                continue
            result[table] = self.db.execute(sql.SQL("""select count(*),
              md5(coalesce(string_agg(to_jsonb(r)::text, E'\\n' order by to_jsonb(r)::text),''))
              from {} r{}""").format(identifier(table), clause), args).fetchone()
        return result

    def preflight(self, owners):
        self.owners = owners
        with self.db.transaction():
            self.db.execute('set transaction isolation level repeatable read, read only')
            self.tables = [r[0] for r in self.db.execute("""select c.relname from pg_class c
              join pg_namespace n on n.oid=c.relnamespace
              where n.nspname='public' and c.relkind in ('r','p') order by c.relname""")]
            require(set(DELETE_ORDER) <= set(self.tables), 'MISSING_TABLES')
            self.baseline = self.snapshot()
            require(all(self.baseline[t][0] == 0 for t in SCORING), 'EXISTING_SCORING_STOP')
            # Read-only identity cross-check pins administrator DB to the JWT project.
            for label, owner in owners.items():
                row = self.db.execute('select id::text,lower(email) from auth.users where id=%s',
                                      (owner,)).fetchone()
                require(row == (owner, EMAILS[label]), 'ADMIN_PROJECT_IDENTITY')
            require(all(v[0] == 0 for v in self.snapshot(only_fixture=True).values()), 'UUID_COLLISION')
            self.original_triggers = self.trigger_state()
            for table in TRIGGERS:
                capable = self.db.execute('''select pg_has_role(current_user,c.relowner,'USAGE')
                  or (select rolsuper from pg_roles where rolname=current_user)
                  from pg_class c join pg_namespace n on n.oid=c.relnamespace
                  where n.nspname='public' and c.relname=%s''', (table,)).fetchone()
                require(capable and capable[0], 'ADMIN_TABLE_OWNER_REQUIRED')
            for table, name in TRIGGERS.items():
                require((table, name, 'O', False, '0') in self.original_triggers, 'TRIGGER_STATE')
            self.manifest = self.snapshot(only_fixture=True)

    def insert(self, table, values):
        self.db.execute(sql.SQL('insert into {} ({}) values ({})').format(
            identifier(table), sql.SQL(',').join(map(sql.Identifier, values)),
            sql.SQL(',').join(sql.Placeholder() for _ in values)), list(values.values()))

    def publish(self, table, row_id):
        self.db.execute(sql.SQL("update {} set status='published',is_current=true,"
            'verified_at=statement_timestamp() where id=%s').format(identifier(table)), (row_id,))

    def create(self):
        i = self.ids
        # Set before dispatch so an uncertain commit still invokes cleanup.
        self.started = True
        with self.db.transaction():
            self.insert('source_posts', dict(id=i['source'], source='synthetic-scoring-acceptance',
                external_post_id=i['source'], url='https://example.invalid/'+i['source'], title='Synthetic scoring fixture'))
            self.insert('content_items', dict(id=i['content'], source_post_id=i['source'],
                source_content_key='scoring-'+i['source'], slug='scoring-'+i['source'], content_type='exam',
                title='Synthetic scoring fixture — not exam data', source_url='https://example.invalid/'+i['source'], is_active=True))
            self.insert('exams', dict(content_item_id=i['content']))
            self.insert('subjects', dict(id=i['subject'], code='synthetic_'+i['subject'].replace('-', '_'),
                name='Synthetic subject', taxonomy_version=i['subject'], is_active=True))
            self.db.execute("""insert into public.exam_subjects(id,content_item_id,source_subject_key,
              subject_id,taxonomy_version,mapping_status,verified_at,is_active)
              values(%s,%s,'synthetic',%s,%s,'verified',statement_timestamp(),true)""",
              (i['occurrence'], i['content'], i['subject'], i['subject']))
            for name, version, variant in [('key1',1,'common'), ('key2',2,'common'), ('incomplete',1,'incomplete')]:
                self.db.execute("""insert into public.answer_key_versions(id,exam_subject_id,content_item_id,
                  paper_variant,version,question_count,max_score,source_name,source_url,source_digest,fetched_at)
                  values(%s,%s,%s,%s,%s,3,9,'Synthetic fixture','https://example.invalid/key',repeat('0',64),now())""",
                  (i[name], i['occurrence'], i['content'], variant, version))
                if name != 'incomplete':
                    for number, answer, points in [(1,2 if name=='key2' else 1,2),(2,2,3),(3,3,4)]:
                        self.insert('exam_questions', dict(answer_key_version_id=i[name],
                            question_number=number, correct_answer=answer, points=points))
            try:
                with self.db.transaction():  # SAVEPOINT; intentionally incomplete publication must roll back.
                    self.publish('answer_key_versions', i['incomplete'])
            except psycopg.Error as error:
                require(error.sqlstate == '23514' and error.diag.message_primary == 'INCOMPLETE_KEY', 'COMPLETENESS')
            else:
                raise RuntimeError('COMPLETENESS')
            self.publish('answer_key_versions', i['key1'])
            for name, version, variant in [('cut1',1,'common'), ('cut2',2,'common'), ('wrongcut',1,'other')]:
                self.db.execute("""insert into public.grade_cutoff_versions(id,exam_subject_id,content_item_id,
                  paper_variant,version,basis,certainty,max_score,minimum_scores,source_name,source_url,source_digest,fetched_at)
                  values(%s,%s,%s,%s,%s,'raw_absolute','confirmed',9,%s,'Synthetic fixture',
                  'https://example.invalid/cutoff',repeat('1',64),now())""",
                  (i[name], i['occurrence'], i['content'], variant, version,
                   [9,8,7,6,5,4,2 if name=='cut2' else 3,1,0]))
                if name != 'cut2':
                    self.publish('grade_cutoff_versions', i[name])
        self.capture()

    def capture(self):
        # Called after each dispatched JWT write (also after network errors). Only
        # pre-registered UUIDs are eligible. Ownership/scope is checked under lock again.
        self.manifest = self.snapshot(only_fixture=True)

    def switch(self):
        with self.db.transaction():
            for table, old, new in [('answer_key_versions','key1','key2'), ('grade_cutoff_versions','cut1','cut2')]:
                self.db.execute(sql.SQL('update {} set is_current=false where id=%s').format(identifier(table)), (self.ids[old],))
                self.publish(table, self.ids[new])
        self.capture()

    def register_attempt(self):
        value = uuid_value(uuid.uuid4())
        require(self.db.execute('select count(*) from public.mock_exam_attempts where id=%s', (value,)).fetchone()[0] == 0,
                'UUID_COLLISION')
        self.attempts.add(value)  # Before HTTP dispatch.
        return value

    def cleanup(self, fault=None):
        """Single atomic cleanup; fault is for offline rollback injection only."""
        require(self.baseline is not None and self.manifest is not None, 'NO_BASELINE')
        with self.db.transaction():
            current_tables = [r[0] for r in self.db.execute('''select c.relname from pg_class c
              join pg_namespace n on n.oid=c.relnamespace where n.nspname='public'
              and c.relkind in ('r','p') order by c.relname''')]
            require(current_tables == self.tables, 'TABLE_CATALOG_CHANGED')
            # Block writes to every baseline table while comparing and deleting.
            self.db.execute(sql.SQL('lock table {} in share row exclusive mode').format(
                sql.SQL(',').join(identifier(t) for t in self.tables)))
            # Acquire the DDL locks BEFORE inspecting trigger state or scope.
            self.db.execute(sql.SQL('lock table {} in access exclusive mode').format(
                sql.SQL(',').join(identifier(t) for t in sorted(TRIGGERS))))
            require(self.trigger_state() == self.original_triggers, 'TRIGGER_DRIFT')
            require(self.snapshot(exclude_fixture=True) == self.baseline, 'EXISTING_DATA_CHANGED')
            actual = self.snapshot(only_fixture=True)
            require(actual == self.manifest, 'FIXTURE_COUNT_OR_DIGEST_CHANGED')
            for row in self.db.execute('select id::text,user_id::text,answer_key_version_id::text from public.mock_exam_attempts where id=any(%s::uuid[])', (sorted(self.attempts),)):
                require(row[0] in self.attempts and row[1] == self.owners['A']
                        and row[2] in self.scopes()['answer_key_versions'], 'ATTEMPT_SCOPE')
            for row in self.db.execute('select user_id::text from public.study_sessions where id=%s', (self.ids['study'],)):
                require(row[0] == self.owners['A'], 'STUDY_SCOPE')
            # Every DELETE below is constrained to this in-memory run registry.
            for table, name in TRIGGERS.items():
                self.db.execute(sql.SQL('alter table {} disable trigger {}').format(identifier(table), sql.Identifier(name)))
            if fault:
                fault('disabled')
            scopes = self.scopes()
            for table in DELETE_ORDER:
                expected = actual[table][0]
                cursor = self.db.execute(sql.SQL('delete from {} where {} = any(%s::uuid[])').format(
                    identifier(table), sql.Identifier(ID_FIELDS[table])), (scopes[table],))
                require(cursor.rowcount == expected, 'DELETE_COUNT')
                if table == 'mock_exam_attempts':
                    require(self.db.execute('select count(*) from public.mock_exam_answers where attempt_id=any(%s::uuid[])',
                                           (sorted(self.attempts),)).fetchone()[0] == 0, 'ANSWERS_CASCADE')
                if fault:
                    fault(table)
            for table, name in TRIGGERS.items():
                self.db.execute(sql.SQL('alter table {} enable trigger {}').format(identifier(table), sql.Identifier(name)))
            require(self.trigger_state() == self.original_triggers, 'TRIGGERS_NOT_RESTORED')
            require(all(v[0] == 0 for v in self.snapshot(only_fixture=True).values()), 'FIXTURE_REMAINS')
            require(self.snapshot() == self.baseline, 'BASELINE_NOT_RESTORED')
            if fault:
                fault('before_commit')
        # No PASS before successful COMMIT. On any error, context rolls back DDL+DML.
        for stage in ('fixture_scope_verified','fixture_cleanup','cleanup_triggers_restored',
                      'scoring_baseline_restored','existing_data_preserved'):
            passed(stage)


class Acceptance:
    """All application behavior goes through real A/B JWT HTTP requests."""
    def __init__(self, config, transport=None):
        require(isinstance(config, dict) and config.get('SUPABASE_URL','').rstrip('/') == HOST, 'PROJECT')
        key = config.get('SUPABASE_PUBLISHABLE_KEY')
        require(isinstance(key,str) and key.startswith('sb_publishable_') and key==key.strip(), 'KEY')
        self.transport = transport or Transport(key)
        self.sessions = {}
        self.stage = 'login_preflight'
        self.last = None
        self.admin = None

    def call(self, method, path, data=None, who='A', prefer=None):
        self.last = None
        self.last = self.transport(method, path, data,
            self.sessions[who]['token'] if who else None, prefer)
        return self.last

    def login(self, passwords):
        for who, email in EMAILS.items():
            self.stage = 'login_preflight_' + who
            r = self.call('POST','/auth/v1/token?grant_type=password', {'email':email,'password':passwords[who]}, who=None)
            require(r.status==200 and isinstance(r.body,dict), 'LOGIN')
            token = r.body.get('access_token')
            require(isinstance(token,str) and token.strip(), 'TOKEN')
            self.sessions[who] = {'token':token}
            user = r.body.get('user')
            require(isinstance(user,dict) and isinstance(user.get('email'),str)
                    and user['email'].casefold()==email, 'IDENTITY')
            self.sessions[who]['id'] = uuid_value(user['id'])
        require(self.sessions['A']['id'] != self.sessions['B']['id'], 'DISTINCT')

    def read(self, table, fields, filters=None, who='A'):
        query = urllib.parse.urlencode({'select':fields, **(filters or {})})
        r = self.call('GET','/rest/v1/'+table+'?'+query,who=who)
        require(r.status==200 and isinstance(r.body,list), 'READ')
        return r.body

    def dispatch(self, method, path, data=None, who='A'):
        try:
            # attempts has column-level SELECT grants: never request its private payload.
            if path.split('?')[0] == '/rest/v1/mock_exam_attempts':
                path += ('&' if '?' in path else '?') + 'select=id'
            return self.call(method,path,data,who,'return=representation')
        finally:
            # Reconcile uncertain HTTP writes via the separate admin connection.
            self.admin.capture()

    def payload(self, **changes):
        i = self.admin.ids
        result = dict(p_attempt_id=self.admin.register_attempt(), p_study_session_id=None,
                      p_answer_key_version_id=i['key1'], p_grade_cutoff_version_id=i['cut1'],
                      p_scoring_version='mcq5-v1', p_answers=ANSWERS)
        result.update(changes)
        return result

    def submit(self, payload):
        return self.dispatch('POST','/rest/v1/rpc/submit_mock_attempt',payload)

    def fetch(self, attempt, who='A'):
        r = self.call('POST','/rest/v1/rpc/fetch_own_mock_attempt',{'p_attempt_id':attempt},who)
        require(r.status==200, 'FETCH')
        return r.body

    def reject(self, payload, code, message, status=400):
        r = self.submit(payload)
        require(r.status==status and isinstance(r.body,dict) and r.body.get('code')==code
                and r.body.get('message')==message, 'EXPECTED_REJECTION')
        if message != 'ATTEMPT_CONFLICT':
            require(self.fetch(payload['p_attempt_id']) is None, 'REJECTED_ROW_EXISTS')

    def result(self, payload, score=2, grade=8):
        r = self.submit(payload)
        require(r.status==200 and isinstance(r.body,dict), 'SUBMIT')
        body = r.body
        expected = dict(id=payload['p_attempt_id'], user_id=self.sessions['A']['id'],
            raw_score=score,max_score=9,correct_count=1,unanswered_count=1,question_count=3,
            grade=grade,grade_status='confirmed',answer_key_version_id=payload['p_answer_key_version_id'],
            grade_cutoff_version_id=payload['p_grade_cutoff_version_id'],scoring_version='mcq5-v1',
            study_session_id=payload['p_study_session_id'])
        require(all(body.get(k)==v for k,v in expected.items()), 'RESULT')
        require(isinstance(body.get('answers'),list) and len(body['answers'])==3, 'ANSWERS')
        for n, answer in enumerate(body['answers'],1):
            submitted = {v['question_number']:v['choice'] for v in payload['p_answers']}.get(n)
            correct = 2 if n == 1 and payload['p_answer_key_version_id'] == self.admin.ids['key2'] else n
            require(answer['submitted_answer'] == submitted and answer['correct_answer_snapshot'] == correct
                    and answer['is_correct'] == (submitted == correct)
                    and answer['awarded_points'] == (n+1 if submitted == correct else 0), 'ANSWER_VALUES')
            require(answer['question_number']==n and answer['attempt_id']==payload['p_attempt_id']
                    and answer['answer_key_version_id']==payload['p_answer_key_version_id']
                    and answer['points_snapshot']==n+1, 'SNAPSHOT')
        require(body['answers'][2]['submitted_answer'] is None and body['answers'][2]['awarded_points']==0, 'BLANK')
        return body

    def denied(self, method, path, data):
        r = self.dispatch(method,path,data)
        require(r.status==403 and isinstance(r.body,dict) and r.body.get('code')=='42501', 'PRIVILEGE')

    def exercise(self):
        a, i = self.admin, self.admin.ids
        self.stage='publish_fixture'
        self.last=None
        a.create()
        available = self.read('mock_exam_scoring_availability','*',{'exam_subject_id':'eq.'+i['occurrence']})
        require(len(available)==1 and available[0]['availability']=='scoring_available'
                and available[0]['answer_key_version_id']==i['key1'] and available[0]['grade_cutoff_version_id']==i['cut1'], 'AVAILABILITY')
        passed(self.stage)
        self.stage='valid_submit'
        p = self.payload()
        original = self.result(p)
        passed(self.stage)
        self.stage='fetch_own'
        require(self.fetch(p['p_attempt_id'])==original and original['key_source']['version']==1
                and original['cutoff_source']['version']==1, 'FETCH_SNAPSHOT')
        require(len(self.read('mock_exam_attempts','id,raw_score',{'id':'eq.'+p['p_attempt_id']}))==1, 'OWN_READ')
        passed(self.stage)
        self.stage='direct_forgery_denied'
        forged = a.register_attempt()
        self.denied('POST','/rest/v1/mock_exam_attempts',{'id':forged,'user_id':self.sessions['A']['id'],'raw_score':999})
        self.denied('PATCH','/rest/v1/mock_exam_attempts?id=eq.'+p['p_attempt_id'],{'raw_score':9,'grade':1})
        self.denied('POST','/rest/v1/mock_exam_answers',{'attempt_id':forged,'answer_key_version_id':i['key1'],
            'question_number':1,'submitted_answer':1,'correct_answer_snapshot':1,'points_snapshot':2})
        require(self.fetch(forged) is None and self.fetch(p['p_attempt_id'])==original,'FORGERY_EFFECT')
        passed(self.stage)
        self.stage='ownership_isolation'
        require(self.read('mock_exam_attempts','id',{'id':'eq.'+p['p_attempt_id']},'B')==[], 'B_ATTEMPT')
        require(self.read('mock_exam_answers','attempt_id',{'attempt_id':'eq.'+p['p_attempt_id']},'B')==[], 'B_ANSWERS')
        r=self.dispatch('DELETE','/rest/v1/mock_exam_attempts?id=eq.'+p['p_attempt_id'],who='B')
        require(r.status==200 and r.body==[] and self.fetch(p['p_attempt_id'],'B') is None
                and self.fetch(p['p_attempt_id'])==original, 'B_DELETE')
        passed(self.stage)
        self.stage='idempotent_retry'
        require(self.result(p)==original, 'RETRY')
        require(len(self.read('mock_exam_attempts','id',{'id':'eq.'+p['p_attempt_id']}))==1,'DUPLICATE')
        self.reject({**p,'p_answers':[]},'23505','ATTEMPT_CONFLICT',409)
        passed(self.stage)
        self.stage='current_version'
        self.last=None
        a.switch()
        self.reject(self.payload(),'23514','KEY_UNAVAILABLE')
        self.reject(self.payload(p_answer_key_version_id=i['key2']), '23514','CUTOFF_UNAVAILABLE')
        current=self.payload(p_answer_key_version_id=i['key2'],p_grade_cutoff_version_id=i['cut2'],
                             p_answers=[{'question_number':1,'choice':2},{'question_number':2,'choice':5}])
        v2=self.result(current,grade=7)
        require(v2['key_source']['version']==2 and v2['cutoff_source']['version']==2, 'V2_SOURCE')
        require(self.result(p)==original and self.fetch(p['p_attempt_id'])==original,'V1_PRESERVED')
        passed(self.stage)
        self.stage='invalid_inputs'
        base=dict(p_answer_key_version_id=i['key2'],p_grade_cutoff_version_id=i['cut2'])
        for changes, code, message in [
            ({'p_answers':[{'question_number':1,'choice':1}]*2},'22023','INVALID_ANSWERS'),
            ({'p_answers':[{'question_number':1,'choice':6}]},'22023','INVALID_ANSWERS'),
            ({'p_answer_key_version_id':uuid_value(uuid.uuid4())},'23514','KEY_UNAVAILABLE'),
            ({'p_answer_key_version_id':i['incomplete']},'23514','KEY_UNAVAILABLE'),
            ({'p_grade_cutoff_version_id':i['wrongcut']},'23514','CUTOFF_UNAVAILABLE'),
            ({'p_grade_cutoff_version_id':i['cut1']},'23514','CUTOFF_UNAVAILABLE'),
            ({'p_scoring_version':'unsupported'},'22023','INVALID_REQUEST')]:
            self.reject(self.payload(**{**base,**changes}),code,message)
        passed(self.stage)
        self.stage='study_delete_semantics'
        r=self.dispatch('POST','/rest/v1/study_sessions',dict(id=i['study'],mode='mock_exam',title='Synthetic scoring fixture',
            planned_duration_seconds=60,started_at='2026-09-14T00:00:00Z',ended_at='2026-09-14T00:01:00Z',active_segments=[[0,60000]]))
        require(r.status==201 and isinstance(r.body,list) and len(r.body)==1 and r.body[0]['id']==i['study']
                and r.body[0]['user_id']==self.sessions['A']['id'], 'STUDY_INSERT')
        linked={**current,'p_attempt_id':a.register_attempt(),'p_study_session_id':i['study']}
        linked_result=self.result(linked,grade=7)
        r=self.dispatch('DELETE','/rest/v1/study_sessions?id=eq.'+i['study'])
        require(r.status==200 and isinstance(r.body,list) and len(r.body)==1 and r.body[0]['id']==i['study'],'STUDY_DELETE')
        require(self.fetch(linked['p_attempt_id'])=={**linked_result,'study_session_id':None}, 'UNLINK')
        require(self.read('study_sessions','id',{'id':'eq.'+i['study']})==[],'STUDY_REMAINS')
        passed(self.stage)
        self.stage='owner_delete'
        r=self.dispatch('DELETE','/rest/v1/mock_exam_attempts?id=eq.'+linked['p_attempt_id'])
        require(r.status==200 and len(r.body)==1 and r.body[0]['id']==linked['p_attempt_id'], 'OWNER_DELETE')
        require(self.fetch(linked['p_attempt_id']) is None and self.read('mock_exam_answers','attempt_id',
                {'attempt_id':'eq.'+linked['p_attempt_id']})==[], 'CASCADE')
        passed(self.stage)

    def failure(self, error):
        code=getattr(error,'sqlstate',None)
        if code is None and self.last and isinstance(self.last.body,dict):
            code=self.last.body.get('code')
        if not isinstance(code,str) or code not in SAFE_CODES:
            code='UNAVAILABLE'
        status=self.last.status if not isinstance(error,psycopg.Error) and self.last and type(self.last.status) is int else 'UNAVAILABLE'
        print(f'SCORING_RUNTIME FAIL {self.stage} HTTP={status} db_code={code}',flush=True)

    def finish_auth(self):
        ok=len(self.sessions)==2
        for who, session in self.sessions.items():
            try:
                self.stage='auth_users_retained'
                r=self.call('GET','/auth/v1/user',who=who)
                require(r.status==200 and isinstance(r.body,dict) and r.body.get('id')==session.get('id'), 'AUTH_RETAINED')
            except (Exception,KeyboardInterrupt) as error:
                self.failure(error); ok=False
            finally:
                try:
                    self.stage='session_logout'
                    r=self.call('POST','/auth/v1/logout?scope=local',who=who)
                    require(r.status==204,'LOGOUT')
                except (Exception,KeyboardInterrupt) as error:
                    self.failure(error); ok=False
        self.sessions.clear()
        self.last=None
        if ok:
            passed('auth_users_retained')
        return ok


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('public_config',type=Path)
    parser.add_argument('--preflight-only',action='store_true')
    args=parser.parse_args()
    app=None; admin=None; connection=None; passwords={}; settings={}; success=False
    try:
        require(sys.stdin.isatty(),'INTERACTIVE_REQUIRED')
        path=args.public_config.resolve()
        require(not path.is_relative_to(Path(__file__).resolve().parents[1]),'EXTERNAL_CONFIG_REQUIRED')
        app=Acceptance(json.loads(path.read_text()))
        print('Target: LegendStudy / '+REF,flush=True)
        with warnings.catch_warnings():
            warnings.simplefilter('error',getpass.GetPassWarning)
            for who,email in EMAILS.items():
                passwords[who]=getpass.getpass(f'Password for {who} ({email}) > ')
            host=input('Supabase Connect Session pooler host (blank = direct DB) > ').strip()
            settings=admin_settings(host or 'db.'+REF+'.supabase.co',getpass.getpass('LegendStudy DB password > '))
        app.login(passwords)
        passwords.clear()
        app.stage='admin_preflight'; app.last=None
        connection=psycopg.connect(**settings)
        settings.clear()
        admin=AdminFixtures(connection); app.admin=admin
        admin.preflight({who:s['id'] for who,s in app.sessions.items()})
        for who in EMAILS:
            require(app.read('mock_exam_attempts','id',who=who)==[], 'EXISTING_ATTEMPTS')
        passed('login_preflight')
        if not args.preflight_only:
            app.exercise()
        success=True
    except (Exception,KeyboardInterrupt) as error:
        if app:
            app.failure(error)
        else:
            print('SCORING_RUNTIME FAIL local_setup HTTP=UNAVAILABLE db_code=UNAVAILABLE',flush=True)
    finally:
        passwords.clear(); settings.clear()
        if admin and admin.started:
            try:
                app.stage='fixture_cleanup'; app.last=None
                admin.cleanup()
            except (Exception,KeyboardInterrupt) as error:
                app.failure(error); success=False
        if app:
            success=app.finish_auth() and success
        if connection:
            connection.close()
    if success:
        passed('preflight_only' if args.preflight_only else 'acceptance')
    return 0 if success else 1


if __name__=='__main__':
    raise SystemExit(main())
