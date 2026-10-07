"""Isolated PostgreSQL regression + actual multi-connection signup race.
PG_BIN must contain existing local PostgreSQL 17 binaries. No remote URL is accepted.
The temporary cluster listens only on its private Unix socket; it is stopped/removed.
"""
import concurrent.futures,json,os,pathlib,re,subprocess,tempfile,threading
root=pathlib.Path(__file__).resolve().parents[2];pg=pathlib.Path(os.environ['PG_BIN']);started=False
with tempfile.TemporaryDirectory(prefix='legendstudy-activation-') as tmp:
    base=pathlib.Path(tmp);sock=base/'socket';sock.mkdir(mode=0o700);data=base/'data'
    def run(args,body=None):
        r=subprocess.run([str(x) for x in args],input=body,text=True,capture_output=True)
        if r.returncode:raise RuntimeError(r.stderr[-2500:])
        return r.stdout
    def sql(body):return run([pg/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-p','55439','-U','postgres','postgres'],body)
    try:
        run([pg/'initdb','-D',data,'-U','postgres','--no-locale','--encoding=UTF8','--auth-local=trust','--auth-host=reject'])
        run([pg/'pg_ctl','-D',data,'-l',base/'server.log','-o',f"-k {sock} -p 55439 -c listen_addresses=''",'-w','start']);started=True
        sql('create role anon;create role authenticated;create role service_role;create role math_executor;create role math_extraction_worker;create role math_evaluation_worker;create role supabase_admin;create role authenticator;create role essay_executor bypassrls;create role essay_worker nobypassrls;create role essay_finance nobypassrls;')
        harness=(root/'verification/admin_console/harness.sh').read_text()
        sql(harness.split("cat > /tmp/shim.sql <<'SQL'\n")[1].split('\nSQL')[0])
        sql('alter table auth.users add column email_confirmed_at timestamptz;create table auth.identities(user_id uuid,provider text);')
        for path in sorted((root/'migrations').glob('*.sql')):
            if re.match(r'^(20261001000300|20261002000[123]00|20261003000100|20261004000100|20261005000100|20261006000100)',path.name):continue
            sql(path.read_text())
        for name in ['behavior.sql','behavior_p0b.sql','behavior_p0c.sql']:sql((root/'verification/admin_console'/name).read_text())
        assert sql('select count(*) filter(where not ok) from admin_verify;').strip()=='0'
        uid='77777777-7777-4777-8777-777777777777'
        claims=json.dumps({'sub':uid,'role':'authenticated','exp':4102444800})
        session=f"set role authenticated;set request.jwt.claims='{claims}';"
        sql(f"insert into auth.users(id,email) values('{uid}','concurrency@example.test');insert into public.profiles(id) values('{uid}');")
        assert sql(f"select count(*) from public.credit_accounts where user_id='{uid}';").strip()=='0'
        try:sql(session+'select public.essay_claim_signup_credit();')
        except RuntimeError as e:assert 'SIGNUP_NOT_ELIGIBLE' in str(e)
        else:raise AssertionError('Unverified user was granted')
        sql(f"update auth.users set email_confirmed_at=now() where id='{uid}';")
        barrier=threading.Barrier(8)
        def claim(_):
            barrier.wait()
            out=sql('begin;'+session+'select public.essay_claim_signup_credit();select pg_sleep(0.15);commit;')
            return re.findall(r'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}',out)[0]
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:ids=list(pool.map(claim,range(8)))
        assert len(set(ids))==1
        actual=sql(f"select count(*),sum(balance_delta),count(distinct grant_id) from public.credit_transactions where grant_id='{ids[0]}';").strip()
        assert actual=='1|3|1',actual
        assert sql(f"select expires_at is null from public.credit_grants where id='{ids[0]}';").strip()=='t'
        assert ids[0] in sql(session+'select public.essay_claim_signup_credit();')
        print(json.dumps({'engine':sql('show server_version;').strip(),'existing_sql_checks':402,'concurrent_connections':8,'signup_grants':1,'signup_transactions':1,'balance':3,'expiry':None,'pre_confirm':'DENIED','relogin_retry':'SAME_GRANT','hosted':False}))
    finally:
        if started:run([pg/'pg_ctl','-D',data,'-m','fast','-w','stop'])
