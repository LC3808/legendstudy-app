"""Build exact guarded candidate from live read-only preimages. Never connects remotely."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
def build():
 data=json.loads((HERE/'preimage.json').read_text())
 guards=','.join("('%s','%s')"%(f['signature'],f['md5']) for f in data['functions'])
 prefix="""-- OWNER APPROVAL REQUIRED. No production student action or backfill.
begin;
set local lock_timeout='5s';
do $$declare x record;begin
 for x in select * from (values %s) v(signature,expected_md5) loop
  if md5(pg_get_functiondef(x.signature::regprocedure))<>x.expected_md5 then raise exception 'PREIMAGE_CHANGED: %%',x.signature;end if;
 end loop;
 if to_regprocedure('public.admin_lab_run_recovery(uuid)') is not null then raise exception 'RECOVERY_ALREADY_INSTALLED';end if;
 if (select pg_get_constraintdef(oid) from pg_constraint where conrelid='essay_ops_private.run_actions'::regclass and conname='run_actions_action_check') is distinct from 'CHECK ((action = ANY (ARRAY[''retry''::text, ''delete''::text, ''archive''::text, ''restore''::text])))' then raise exception 'AUDIT_CONSTRAINT_CHANGED';end if;
end$$;
alter table essay_ops_private.run_actions drop constraint run_actions_action_check;
alter table essay_ops_private.run_actions add constraint run_actions_action_check check(action in('retry','delete','archive','restore','recover'));
"""%guards
 acl_values=','.join("('%s','%s','%s'::jsonb)"%(f['signature'],f['owner'],json.dumps(f['acl']).replace("'","''")) for f in data['functions'])
 acl_guard="do $$declare x record;p pg_proc;begin for x in select * from (values "+acl_values+") v(signature,owner_name,acl) loop select * into p from pg_proc where oid=x.signature::regprocedure;if pg_get_userbyid(p.proowner)<>x.owner_name or to_jsonb(p.proacl) is distinct from x.acl then raise exception 'PREIMAGE_ACL_CHANGED: %',x.signature;end if;end loop;end$$;\n"
 invariant_constraints=[x for x in data['constraints'] if x['relation']=='essay_exam_private.checkpoints' and x['name'] in ('checkpoints_check','checkpoints_state_check','checkpoints_payload_check')]
 constraint_values=','.join("('%s','%s')"%(x['name'],x['definition'].replace("'","''")) for x in invariant_constraints)
 constraint_guard="do $$declare x record;begin for x in select * from (values "+constraint_values+") v(name,definition) loop if (select pg_get_constraintdef(oid) from pg_constraint where conrelid='essay_exam_private.checkpoints'::regclass and conname=x.name) is distinct from x.definition then raise exception 'CHECKPOINT_INVARIANT_CHANGED: %',x.name;end if;end loop;end$$;\n"
 prefix=prefix.replace('alter table essay_ops_private.run_actions drop constraint',acl_guard+constraint_guard+'alter table essay_ops_private.run_actions drop constraint')
 body=(HERE/'functions.sql').read_text()
 import re
 signatures=[]
 for match in re.finditer(r'create function ([\w.]+)\((.*?)\) returns',body,re.I|re.S):
  args=[]
  for arg in match[2].split(','):
   if arg.strip():args.append(arg.strip().split()[1])
  signatures.append(match[1]+'('+','.join(args)+')')
 suffix='\n'
 for sig in signatures:
  suffix+=f'alter function {sig} owner to postgres;\nrevoke all on function {sig} from public,anon,authenticated,essay_worker,service_role;\n'
  if sig.startswith('public.admin_'):suffix+=f'grant execute on function {sig} to authenticated;\n'
  elif sig.startswith('public.essay_exam_recovery_'):suffix+=f'grant execute on function {sig} to essay_worker;\n'
 suffix+="notify pgrst,'reload schema';\ncommit;\n"
 content=prefix+body+suffix
 (HERE/'install.sql').write_text(content)
 manifest={'status':'NOT_APPLIED','project_id':'stlhijzpjfgwwdgunlsd','migration_cli_generated_name':'20261122064411_admin_run_recovery_20261122.sql','install_sha256':hashlib.sha256(content.encode()).hexdigest(),'new_functions':signatures,'existing_function_preimages':[{'signature':f['signature'],'md5':f['md5'],'acl':f['acl'],'owner':f['owner']} for f in data['functions']]}
 (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 return manifest
if __name__=='__main__':print(json.dumps(build(),indent=2))
