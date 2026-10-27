"""Generate exact, guarded allocator edits from the read-only Production baseline."""
import hashlib,json,pathlib,re
root=pathlib.Path(__file__).parent
rows=json.loads((root/'baseline.private.json').read_text())
names={'reserve','credit_request_v2','scaffold_legacy_essay_request_evaluation','scaffold_request_v13','authorize_billing','math_session_submit'}
guards=[]; patches=[]; baseline=[]; manifest=[]
for row in rows:
 if row['name'] not in names: continue
 before=row['definition']; after=before
 signature=re.search(r'FUNCTION ([^(]+)\((.*?)\)\n',before,re.S)
 # regprocedure resolves argument types, not argument names/defaults.
 args=[]
 for a in signature[2].split(','):
  a=re.sub(r' DEFAULT .*','',a.strip())
  args.append(a.split(' ',1)[1] if a.startswith('p_') else a)
 reg=signature[1]+'('+','.join(args)+')'
 digest=hashlib.md5(before.encode()).hexdigest()
 guards.append(f"if md5(pg_get_functiondef('{reg}'::regprocedure))<>'{digest}' then raise exception 'BASELINE_CHANGED: {reg}';end if;")
 if row['name']=='reserve':
  anchor='from public.credit_grants cg where cg.account_id=p_account and'
  replacement=anchor+'\n   (not essay_beta_private.is_beta(cg.id) or essay_beta_private.eligible(cg.id,p_exam)) and'
  assert after.count(anchor)==1
  after=after.replace(anchor,replacement)
  anchor='order by cg.expires_at nulls last,cg.created_at,cg.id limit 1 for update;'
  # Only beta is promoted. Relative order of every existing non-beta grant is unchanged.
  replacement='order by case when essay_beta_private.is_beta(cg.id) then 0 else 1 end, cg.expires_at nulls last,cg.created_at,cg.id limit 1 for update;'
 else:
  anchor='from public.credit_grants g where g.account_id=account'
  replacement=anchor+' and not essay_beta_private.is_beta(g.id)'
 assert after.count(anchor)==1,(row['name'],after.count(anchor))
 after=after.replace(anchor,replacement)
 patches.append(after+';'); baseline.append(before+';')
 manifest.append({'function':reg,'before_md5':digest,'after_md5':hashlib.md5(after.encode()).hexdigest()})
assert len(patches)==6
(root/'allocators.sql').write_text('\n\n'.join(patches)+'\n')
(root/'allocators-baseline.sql').write_text('\n\n'.join(baseline)+'\n')
(root/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(root/'precheck.sql').write_text('select '+',\n'.join(f"md5(pg_get_functiondef('{m['function']}'::regprocedure))='{m['before_md5']}' as allocator_{i+1}" for i,m in enumerate(manifest))+",\nto_regnamespace('essay_beta_private') is null as new_schema_absent;\n")
(root/'apply.sql').write_text("-- NOT APPLIED. Owner approval required. No campaign activation or real grants.\nbegin;\nset local lock_timeout='5s';\ndo $guard$ begin\n"+'\n'.join(guards)+"\nend $guard$;\n"+(root/'runtime.sql').read_text()+'\n\n'.join(patches)+'\ncommit;\n')
(root/'rollback.sql').write_text("-- Safe shutdown preserves existing grants and reservation settlement.\n-- Do NOT restore old unscoped allocators while any beta grants remain.\nbegin;\nupdate essay_beta_private.campaigns set enabled=false where enabled;\ncommit;\n")
print('Generated six exact allocator patches; candidate remains inactive.')
