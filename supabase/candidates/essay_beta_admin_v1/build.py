"""Build guarded Owner-review SQL; never connects to Production."""
import json,re,pathlib
p=pathlib.Path(__file__).parent
old=(p.parent/'essay_beta_daily_v2/install.sql').read_text()
identities=['public.essay_beta_daily_claim_v2()','essay_beta_private.eligible(uuid,uuid)','essay_beta_private.revision_open(uuid)','essay_beta_private.revision_deadline(uuid)']
manifest=json.loads((p.parent/'essay_beta_daily_v2/expected-functions.json').read_text())
checks=[]
for ident in identities:
 r=next(x for x in manifest if x['identity'].replace(', ', ',').removeprefix('public.')==ident.removeprefix('public.'))
 checks.append(f"if to_regprocedure('{ident}') is null or (select md5(pg_get_functiondef('{ident}'::regprocedure)))<>'{r['digest']}' then raise exception 'BASELINE_MISMATCH {ident}';end if;")
 checks.append(f"if (select pg_get_userbyid(proowner) from pg_proc where oid='{ident}'::regprocedure)<>'{r['owner']}' or (select proacl::text from pg_proc where oid='{ident}'::regprocedure) is distinct from '{r['acl']}' then raise exception 'BASELINE_PERMISSION_MISMATCH {ident}';end if;")
pre="-- Read-only guards; v2 must be separately approved and verified first.\ndo $$begin\n"+'\n'.join(checks)+"\nif to_regclass('essay_beta_private.operations_config') is not null then raise exception 'ALREADY_INSTALLED_REVIEW_STATE';end if;\nend $$;\n"
(p/'precheck.sql').write_text(pre)
(p/'install.sql').write_text('begin;\n'+pre+'\n'.join((p/n).read_text() for n in ['runtime.sql','allocation.sql','reporting.sql'])+'\ncommit;\n')
(p/'rollback.sql').write_text("""-- Feature disable, not destructive schema rollback. Run as authenticated approved Owner.
-- Use existing auth session; never paste tokens into source control.
begin;
do $$declare item jsonb;c jsonb;lim integer;begin
 for item in select value from jsonb_array_elements(public.admin_essay_beta_config()->'campaigns') loop
  c:=item->'config';
  if c is null or c='null'::jsonb then continue;end if;
  lim:=case when clock_timestamp()>=(c->>'limit_effective_at')::timestamptz then (c->>'next_daily_limit')::integer else (c->>'daily_free_limit')::integer end;
  perform public.admin_essay_beta_save((item->>'campaign_id')::uuid,(c->>'version')::integer,
   jsonb_build_object('beta_enabled',false,'beta_start_at',c->>'beta_start_at',
   'beta_end_at',c->>'beta_end_at','daily_free_limit',lim,'reset_timezone','Asia/Seoul','limit_application','immediate'),
   'Emergency beta feature rollback');
 end loop;
end $$;
commit;
-- Retain grant snapshots, audit, history and accepted-job settlement.
-- Revert WEB/APP UI separately. Do not restore one-credit runtime with active multi-credit grants.
""")
