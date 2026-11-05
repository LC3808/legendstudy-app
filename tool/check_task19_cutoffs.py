#!/usr/bin/env python3
"""Validate the reviewed public corpus. No network/DB calls. Prints explicit seed/publish/withdraw SQL candidates only."""
import argparse,json,hashlib
from pathlib import Path
R=Path(__file__).resolve().parents[1];D=R/'data/grade_cutoffs/task19'
def main():
 p=argparse.ArgumentParser();g=p.add_mutually_exclusive_group();g.add_argument('--seed-sql',action='store_true');g.add_argument('--publish-sql',action='store_true');g.add_argument('--withdraw-sql',action='store_true');a=p.parse_args()
 rows=json.loads((D/'reviewed_rows.json').read_text());reg=json.loads((D/'registry_snapshot.json').read_text())
 exams={e['content_item_id']:e for e in reg};seen=set();groups={}
 assert {(e['academic_year'],e['exam_month']) for e in reg}=={(y,m) for y in range(2024,2028) for m in [6,9,11] if (y,m)!=(2027,11)}
 sources=json.loads((D/'source_manifest.json').read_text())+json.loads((D/'absolute_sources.json').read_text());hashes={s['sha256'] for s in sources}
 for r in rows:
  e=exams[r['content_item_id']];ss={s['id']:s for s in e['subjects']};assert r['exam_subject_id'] in ss
  key=tuple(r[k] for k in ['content_item_id','exam_subject_id','elective_key','grade']);assert key not in seen;seen.add(key)
  assert r['status']=='draft' and r['is_current'] is False and r['revision']==1
  assert r['source_digest'] in hashes and r['verified_at'] and r['fetched_at']<=r['verified_at']
  assert 1<=r['grade']<=9 and r['raw_certainty'] in ['unspecified','confirmed','estimated']
  for k in ['raw_score','raw_score_min','raw_score_max','standard_score','percentile']:
   n=r[k];assert n is None or (isinstance(n,(int,float)) and 0<=n<=(200 if k=='standard_score' else 100))
  assert (r['raw_score_min'] is None)==(r['raw_score_max'] is None)
  if r['raw_score_min'] is not None:assert r['raw_score'] is None and r['raw_score_min']<=r['raw_score_max']
  if r['assessment_method']=='absolute':assert r['standard_score'] is None and r['percentile'] is None
  if ss[r['exam_subject_id']]['label'] not in ['국어','수학','영어'] and not ss[r['exam_subject_id']]['label'].startswith(('국어(','수학(')):
   assert r['raw_score'] is None or r['raw_score']<=50
  groups.setdefault(key[:3],[]).append(r)
 for rs in groups.values():
  rs.sort(key=lambda r:r['grade'])
  for k in ['raw_score','raw_score_min','raw_score_max','standard_score','percentile']:
   ns=[r[k] for r in rs if r[k] is not None];assert all(x>=y for x,y in zip(ns,ns[1:])),(k,rs)
 if a.seed_sql or a.publish_sql or a.withdraw_sql:
  cols=list(rows[0]);payload=json.dumps(rows,ensure_ascii=False,separators=(',',':'))
  assert '$task19$' not in payload
  print("-- Candidate only: reviewed public references, draft/non-current. Requires Owner approval.\nbegin;\nset local lock_timeout='5s';\ncreate temporary table task19_rows (like public.grade_cutoff_references including defaults) on commit drop;")
  print('insert into task19_rows('+','.join(cols)+') select '+','.join(cols)+' from jsonb_populate_recordset(null::public.grade_cutoff_references,$task19$'+payload+'$task19$::jsonb);')
  match=' and '.join('r.'+k+' is not distinct from s.'+k for k in cols if k not in ['status','is_current'])
  if a.seed_sql:
   print("do $$ begin if exists(select 1 from public.grade_cutoff_references r join task19_rows s using(content_item_id,exam_subject_id,elective_key,grade,revision)) then raise exception 'Candidate overlaps existing references; review revisions first'; end if; end $$;")
   print('insert into public.grade_cutoff_references('+','.join(cols)+') select '+','.join(cols)+' from task19_rows;')
  else:
   print("do $$ begin if (select count(*) from public.grade_cutoff_references r join task19_rows s on "+match+") <> "+str(len(rows))+" then raise exception 'Candidate data differs; do not apply'; end if; end $$;")
   print("update public.grade_cutoff_references r set status='"+('published' if a.publish_sql else 'withdrawn')+"',is_current="+('true' if a.publish_sql else 'false')+" from task19_rows s where "+match+";")
  print('commit;')
 else:
  print(f'PASS: {len(rows)} rows, {len(reg)} exams, {len(groups)} subject/elective groups; canonical IDs, sources, ranges, ordering, no duplicates, drafts only')
  for e in reg:
   rs=[r for r in rows if r['content_item_id']==e['content_item_id']];raw=sum(r['raw_score'] is not None or r['raw_score_min'] is not None for r in rs)
   std=sum(r['raw_score'] is None and r['raw_score_min'] is None and r['standard_score'] is not None for r in rs)
   print(e['academic_year'],e['exam_month'],e['source_url'],len(rs),raw,std,len(rs)-raw-std)
if __name__=='__main__':main()
