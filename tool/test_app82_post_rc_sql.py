"""Disposable Unix-socket PostgreSQL only. No remote URL or production writes."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
C = ROOT / 'supabase/candidates/app82_post_rc_ux_20261112'
PG = Path('/opt/homebrew/opt/postgresql@17/bin')


def main():
    env = {k: v for k, v in os.environ.items() if not k.startswith('PG')}
    env['LC_ALL'] = 'C'
    checks = 0
    with tempfile.TemporaryDirectory(prefix='post-rc-sql-', dir='/private/tmp') as tmp:
        root = Path(tmp)
        sock = root / 'socket'
        sock.mkdir()
        data = root / 'db'

        def run(args, **kw):
            return subprocess.run([str(a) for a in args], env=env, text=True, capture_output=True, **kw)

        def command(args):
            p = run(args)
            assert p.returncode == 0, p.stderr

        command([PG / 'initdb', '-D', data, '-U', 'postgres', '--auth=trust', '--no-locale', '--encoding=UTF8'])
        command([PG / 'pg_ctl', '-D', data, '-l', root / 'server.log', '-o', f"-k {sock} -c listen_addresses=''", '-w', 'start'])
        args = [PG / 'psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', sock, '-U', 'postgres']

        def sql(s, error=None):
            nonlocal checks
            p = run(args, input=s)
            if error:
                assert p.returncode and error in p.stderr, p.stderr
            else:
                assert p.returncode == 0, p.stderr
            checks += 1
            return p.stdout.strip()

        def uid(n):
            return f'00000000-0000-0000-0000-{n:012d}'

        def auth(n=1):
            return f"set role authenticated; set request.jwt.claim.sub='{uid(n)}';"

        def rpc(query, n=1):
            return json.loads(sql(auth(n) + 'select ' + query + ';').splitlines()[-1])

        def page(period='all', metric='total', scope='ranked', offset=0, snapshot=None):
            stamp = 'null' if snapshot is None else f"'{snapshot['as_of']}'"
            rev = 'null' if snapshot is None else f"'{snapshot['revision']}'"
            return f"public.student_school_ranking_page('{period}','{metric}','{scope}',{offset},10,{stamp},{rev})"

        try:
            sql("""
            create role anon; create role authenticated; create role service_role;
            create schema auth; create schema account_private; create schema student_private;
            create function auth.uid() returns uuid language sql stable as $$
              select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
            create function account_private.allowed(u uuid) returns boolean language sql stable as $$
              select u is not null and u <> '00000000-0000-0000-0000-000000999999'::uuid $$;
            grant usage on schema auth to authenticated;
            create table public.profiles(id uuid primary key, neis_office_code text, neis_school_code text);
            create table public.study_sessions(user_id uuid, started_at timestamptz, ended_at timestamptz,
              active_segments jsonb, include_in_study_total boolean);
            alter table public.profiles enable row level security;
            alter table public.study_sessions enable row level security;
            """)
            baseline = json.loads((C / 'private_baseline.json').read_text()) + json.loads((C / 'baseline.json').read_text())
            sql('\n'.join(d['definition'] + ';' for d in baseline))
            # 31 ranked schools, 12 active but under threshold schools; a zero-record school.
            sql("""
            insert into public.profiles
              select ('00000000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,'B10',lpad(((i-1)/3+1)::text,3,'0')
              from generate_series(1,93) i;
            insert into public.profiles
              select ('00000000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,'B10',i::text from generate_series(100,111) i;
            insert into public.profiles values ('00000000-0000-0000-0000-000000000200','B10','empty');
            insert into public.study_sessions
              select id,now()-interval '1 day',now()-interval '1 day'+interval '1 hour','[[0,3600000]]',true
              from public.profiles where neis_school_code<>'empty';
            """)
            fingerprint = "select md5(coalesce(jsonb_agg(to_jsonb(t) order by user_id,started_at)::text,'')) from public.study_sessions t;"
            before = sql(fingerprint)
            defs = "select jsonb_agg(pg_get_functiondef(p.oid) order by p.proname) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('student_school_ranking','student_school_card','my_study_summary');"
            before_defs = sql(defs)
            sql((C / 'apply.sql').read_text())
            assert sql(fingerprint) == before and sql(defs) == before_defs
            sql((C / 'apply.sql').read_text(), 'CANDIDATE_ALREADY_EXISTS')
            for fn in ['my_study_percentile()', page()]:
                sql('set role anon; select public.' + fn if '.' not in fn else 'set role anon; select ' + fn, 'permission denied')
                sql('set role authenticated; select ' + ('public.' if '.' not in fn else '') + fn, 'insufficient_privilege')
                sql(auth(999999) + 'select ' + ('public.' if '.' not in fn else '') + fn, 'insufficient_privilege')
            sql(auth() + 'select * from public.study_sessions;', 'permission denied')
            # Identical first page and tie rank to existing production contract for all filters.
            for period in ['all', 'week', 'last_week', 'month']:
                for metric in ['total', 'participation', 'average']:
                    result = json.loads(sql(auth() + f"begin; select jsonb_build_array(public.student_school_ranking('{period}','{metric}'),{page(period,metric)});commit;").splitlines()[-1])
                    assert result[0]['top'] == result[1]['rows']
                    assert result[0]['my_school'] == result[1]['my_school']
            first = rpc(page())
            assert len(first['rows']) == 10 and first['next_offset'] == 10
            assert len(first['unranked']) == 10 and first['unranked_next_offset'] == 10
            assert first['min_recorders'] == first['min_rank_recorders'] == 3
            all_rows = first['rows'][:]
            for offset in [10, 20, 30]:
                p = rpc(page(offset=offset, snapshot=first))
                all_rows += p['rows']
                assert p['next_offset'] == (offset + 10 if offset < 30 else None)
            assert len(all_rows) == 31 and len({r['school_code'] for r in all_rows}) == 31
            assert all(r['rank'] == 1 for r in all_rows)
            assert all(r['active_users'] is None and r['registered_users'] is None for r in all_rows[1:])
            outside = first['unranked'] + rpc(page(scope='unranked', offset=10, snapshot=first))['rows']
            assert len(outside) == 12 and all(r['rank'] is None and r['ms'] is None and r['active_users'] is None for r in outside)
            own_outside = rpc(page(), n=100)
            assert own_outside['my_school'] is None
            assert next(r for r in own_outside['unranked'] if r['school_code'] == '100')['active_users'] == 1
            assert not rpc(page(metric='participation'))['unranked']
            sql(auth() + 'select ' + page(offset=10), 'RANK_SNAPSHOT_EXPIRED')
            sql(auth() + "select public.student_school_ranking_page(p_limit=>11);", 'INVALID_RANK_QUERY')
            sql(auth() + "select public.student_school_ranking_page(p_period=>null);", 'INVALID_RANK_QUERY')
            sql(auth() + "select public.student_school_ranking_page(p_as_of=>now()-interval '1 day');", 'RANK_SNAPSHOT_EXPIRED')
            # An intervening completed record changes visible projection; refuse mixed pages.
            sql(f"insert into public.study_sessions values('{uid(1)}',now()-interval '2 days',now()-interval '2 days'+interval '2 hours','[[0,7200000]]',true);")
            sql(auth() + 'select ' + page(offset=10, snapshot=first), 'RANK_SNAPSHOT_CHANGED')
            assert rpc(page())['revision'] != first['revision']
            # Highest student: ceil(100/105)=1, never client calculated. Ties share upper bound.
            p = rpc('public.my_study_percentile()')
            assert p['population'] == 105 and p['top_percent'] == 1 and p['rank'] == 1 and p['tie_count'] == 1
            p2 = rpc('public.my_study_percentile()', n=2)
            assert p2['rank'] == 2 and p2['tie_count'] == 104 and p2['top_percent'] == 100
            assert rpc('public.my_study_percentile()', n=200)['status'] == 'no_records'
            # No database mutations by the query and exact rollback of additive functions.
            read_before = sql(fingerprint)
            for _ in range(3):
                rpc(page()); rpc('public.my_study_percentile()')
            assert sql(fingerprint) == read_before
            # Isolate percentile boundary, overlap, exclusions and tie rounding in fixtures.
            sql('truncate public.study_sessions;')
            assert rpc('public.my_study_percentile()')['top_percent'] is None
            sql("""insert into public.study_sessions select id,now()-interval '1 day',now()-interval '1 day'+interval '1 hour','[[0,3600000]]',true from public.profiles order by id limit 19;""")
            assert rpc('public.my_study_percentile()')['status'] == 'insufficient_sample'
            sql(f"insert into public.study_sessions values('{uid(20)}',now()-interval '1 day',now()-interval '1 day'+interval '1 hour','[[0,3600000]]',true);")
            assert rpc('public.my_study_percentile()')['top_percent'] == 100
            # Duplicate overlapping records must not inflate this student's percentile.
            sql(f"insert into public.study_sessions select * from public.study_sessions where user_id='{uid(1)}';")
            assert rpc('public.my_study_percentile()')['tie_count'] == 20
            sql(f"insert into public.study_sessions values('{uid(1)}',now()-interval '2 days',now()-interval '2 days'+interval '1 hour','[[0,3600000]]',true);")
            assert rpc('public.my_study_percentile()')['top_percent'] == 5
            sql(f"insert into public.study_sessions values('{uid(2)}',now()-interval '3 days',now()-interval '3 days'+interval '1 hour','[[0,3600000]]',true);")
            assert rpc('public.my_study_percentile()')['top_percent'] == 10
            assert rpc('public.my_study_percentile()', n=2)['top_percent'] == 10
            sql(f"insert into public.study_sessions values('{uid(3)}',now()-interval '10 days',now()-interval '9 days','[[0,86400000]]',false),('{uid(3)}',now()+interval '1 day',now()+interval '2 days','[[0,86400000]]',true);")
            assert rpc('public.my_study_percentile()')['top_percent'] == 10
            sql((C / 'rollback.sql').read_text())
            assert sql(defs) == before_defs
            assert sql("select to_regprocedure('public.my_study_percentile()') is null;") == 't'
            print(f'PASS: {checks} isolated SQL checks; threshold/tie/page/privacy/ownership/overlap/read-only/rollback assertions')
        finally:
            command([PG / 'pg_ctl', '-D', data, '-m', 'fast', '-w', 'stop'])


if __name__ == '__main__':
    main()
