"""Disposable local PostgreSQL only; synthetic evidence, no remote credential."""
import json,subprocess,tempfile,os
from pathlib import Path
R=Path(__file__).resolve().parents[1];B=Path('/opt/homebrew/opt/postgresql@17/bin')
C=R/'supabase/candidates/essay_hanyang_execution_policy'
E='345d3caa-3438-58c3-8f80-62a6242179ec'
H=['ced37494c6b65531cca30649093846dde665bf401e630e8751f0bc8a3be90060','4f3b87f2197a042c8abdd361584e3e03ab4bd4d15bc5341273dee27b7b6fc73b']
def lit(s):return "'"+s.replace("'","''")+"'"
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 with tempfile.TemporaryDirectory(dir='/private/tmp',prefix='hanyang-policy-') as td:
  p=Path(td);(p/'sock').mkdir()
  def run(args,**kw):return subprocess.run([str(x) for x in args],env=env,text=True,capture_output=True,**kw)
  assert run([B/'initdb','-D',p/'db','-U','local_admin','--auth=trust','--no-locale','--encoding=UTF8']).returncode==0
  assert run([B/'pg_ctl','-D',p/'db','-l',p/'log','-o',f"-k {p/'sock'} -c listen_addresses=''",'-w','start']).returncode==0
  try:
   def sql(s,error=None):
    q=run([B/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',p/'sock','-U','local_admin','-d','postgres'],input=s)
    if error:assert error in q.stderr,(error,q.stderr);return
    assert q.returncode==0,q.stderr
    return q.stdout.strip()
   sql("create role deployer nosuperuser;create schema essay_private authorization deployer;create schema essay_exam_private authorization deployer;create schema essay_material_private authorization deployer;")
   setup="""set role deployer;
create table essay_material_private.reviews(exam_id uuid primary key,revision int,state text,body jsonb,updated_at timestamptz default now(),reviewer uuid,approval_requested boolean);
create table essay_material_private.revisions(exam_id uuid,revision int,state text,body jsonb,reviewer uuid,primary key(exam_id,revision));
create table essay_exam_private.runs(exam_id uuid);
create function essay_private.provider_policy(text) returns jsonb language sql as $$select null::jsonb$$;
create function essay_exam_private.runtime_policy(uuid) returns jsonb language sql as $$select null::jsonb$$;
"""
   actual=(R/'supabase/migrations/20261014023133_essay_exam_operating_api.sql').read_text()
   validator=actual.split('create function essay_private.provider_binding_valid',1)[1].split('end$$;',1)[0]
   sql(setup+'create function essay_private.provider_binding_valid'+validator+'end$$;')
   body={'rights':None,'documents':H,'mappings':[{'evidenceText':'SYNTHETIC, not official material'}],'checks':{},'package':{'package_version':16,'rights_status':{},'questions':[{'question_id':'synthetic'}]}}
   raw=json.dumps(body)
   sql('set role deployer;insert into essay_material_private.reviews values('+lit(E)+',16,\'VERIFIED\','+lit(raw)+"::jsonb,now(),null,true);update essay_material_private.reviews set body=jsonb_set(body,'{package,package_digest}',to_jsonb(encode(sha256(convert_to((body->'package')::text,'UTF8')),'hex')));insert into essay_material_private.revisions select exam_id,revision,state,body,reviewer from essay_material_private.reviews;")
   digest=sql("select body->'package'->>'package_digest' from essay_material_private.reviews")
   install=C.joinpath('install.sql').read_text().replace('09b50772b37f69ec7544a752ba88f5cde6c8de555ab17339a13eb6ef4fdcf106',digest)
   # PostgreSQL cannot rename unnamed original parameters with CREATE OR REPLACE.
   sql('set role deployer;drop function essay_private.provider_policy(text);drop function essay_exam_private.runtime_policy(uuid);create function essay_private.provider_policy(p_regime text) returns jsonb language sql as $$select null::jsonb$$;create function essay_exam_private.runtime_policy(p_exam uuid) returns jsonb language sql as $$select null::jsonb$$;')
   sql('set role deployer;'+install)
   assert sql('select revision from essay_material_private.reviews')=='17'
   assert sql('select count(*) from essay_material_private.revisions')=='2'
   assert sql("select bool_and(body->'rights'->d->>'providerTransmission'='APPROVED') from essay_material_private.reviews cross join lateral jsonb_array_elements_text(body->'documents') t(d)")=='t'
   sql(C.joinpath('verify.sql').read_text())
   assert sql("select (a.body->'mappings'=b.body->'mappings') from essay_material_private.revisions a join essay_material_private.revisions b using(exam_id) where a.revision=16 and b.revision=17")=='t'
   assert sql("select essay_exam_private.runtime_policy('00000000-0000-0000-0000-000000000000') is null")=='t'
   sql('set role deployer;'+install,'POLICY_ALREADY_CONFIGURED')
   sql('set role deployer;'+C.joinpath('rollback.sql').read_text())
   assert sql('select revision from essay_material_private.reviews')=='18'
   assert sql('select count(*) from essay_material_private.revisions')=='3'
   assert sql(f"select essay_exam_private.runtime_policy('{E}') is null")=='t'
   assert sql("select count(*) from essay_exam_private.runs")=='0'
   print('PASS: policy hash, exact exam, rights-only v17, history retained, repeat blocked, rollback v18, no runs')
  finally:run([B/'pg_ctl','-D',p/'db','-m','immediate','-w','stop'])
if __name__=='__main__':main()
