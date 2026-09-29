"""Private synthetic Flutter client fixture; ONLY the prepared disposable local Supabase.
Run existing guarded status_projection_runtime.py --supabase first. Writes credentials to
an explicit /private/tmp file (0600); prints only a safe completion marker. Never Production.
"""
import base64, hashlib, hmac, json, os, subprocess, time, uuid
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
import psycopg
from psycopg import sql
import sys


def main():
    if os.environ.get('ESSAY_REVIEW_DISPOSABLE') != 'YES':
        raise SystemExit('REFUSED: disposable consent required')
    cfg = json.loads(Path(os.environ['ESSAY_REVIEW_SUPABASE_STATUS_FILE']).read_text())
    project = os.environ['ESSAY_REVIEW_LOCAL_PROJECT_ID']
    target = Path(os.environ['ESSAY_L1_CLIENT_FIXTURE']).resolve()
    if not str(target).startswith('/private/tmp/') or not project.startswith('essay-review-'):
        raise SystemExit('REFUSED: private temp / test project required')
    if any(urlparse(cfg[k]).hostname != '127.0.0.1' for k in ['API_URL', 'DB_URL']):
        raise SystemExit('REFUSED: numeric loopback required')
    info=json.loads(subprocess.check_output(['docker','inspect','supabase_db_'+project]))[0]
    assert info['Config']['Labels']['com.supabase.cli.project']==project
    assert any(str(urlparse(cfg['DB_URL']).port)==x['HostPort'] for x in info['NetworkSettings']['Ports']['5432/tcp'])
    def post(path, body, token):
        req=Request(cfg['API_URL']+path,data=json.dumps(body).encode(),headers={'apikey':cfg['ANON_KEY'],'Authorization':'Bearer '+token,'Content-Type':'application/json'})
        with urlopen(req,timeout=20) as response:return json.loads(response.read())
    with psycopg.connect(cfg['DB_URL'],autocommit=True) as c:
        assert c.execute("select to_regprocedure('public.essay_evaluation_status(uuid)') is not null").fetchone()[0]
        if len(sys.argv)>1:
            assert sys.argv[1]=='--clock' and sys.argv[2] in ('0','121')
            expression="select pg_catalog.clock_timestamp()+interval '%s seconds'"%sys.argv[2]
            c.execute('grant essay_executor to current_user')
            c.execute(sql.SQL("create or replace function essay_private.clock() returns timestamptz language sql volatile set search_path='' as {} ").format(sql.Literal(expression)))
            c.execute('revoke essay_executor from current_user')
            print('LOCAL_TEST_CLOCK: SET');return
        q=str(c.execute('select question_id from public.essay_question_evidence group by question_id having count(distinct role)=4 order by question_id limit 1').fetchone()[0])
        users=[]
        for _ in range(2):
            email=str(uuid.uuid4())+'@example.invalid';password=str(uuid.uuid4())+'Aa!9'
            result=post('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},cfg['SERVICE_ROLE_KEY'])
            c.execute('insert into public.profiles(id) values(%s) on conflict do nothing',(result['id'],))
            users.append({'email':email,'password':password})
        criterion=str(c.execute('select id from public.essay_evaluation_criteria where question_id=%s order by id limit 1',(q,)).fetchone()[0])
        evidence=str(c.execute("select id from public.essay_question_evidence where question_id=%s and role='scoring_criteria' limit 1",(q,)).fetchone()[0])
    enc=lambda v:base64.urlsafe_b64encode(json.dumps(v,separators=(',',':')).encode()).decode().rstrip('=')
    body=enc({'alg':'HS256','typ':'JWT'})+'.'+enc({'role':'essay_worker','aud':'authenticated','iat':int(time.time()),'exp':int(time.time())+3600})
    worker=body+'.'+base64.urlsafe_b64encode(hmac.new(cfg['JWT_SECRET'].encode(),body.encode(),hashlib.sha256).digest()).decode().rstrip('=')
    data={'url':cfg['API_URL'],'anon':cfg['ANON_KEY'],'users':users,'worker':worker,'question':q,'criterion':criterion,'evidence':evidence}
    fd=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o600)
    with os.fdopen(fd,'w') as f:json.dump(data,f)
    os.chmod(target,0o600)
    print('LOCAL_SYNTHETIC_CLIENT_FIXTURE: READY (private, no credentials printed)')

if __name__=='__main__':main()
