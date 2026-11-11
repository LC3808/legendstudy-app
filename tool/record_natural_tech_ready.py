"""Record a single university's existing artifact and fresh offline contract checks.
Does not create/publish content, call Provider, or connect to a database.
"""
import argparse,hashlib,json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 a=argparse.ArgumentParser();a.add_argument('slug',choices=['konkuk','kyunghee','sungkyunkwan','sogang','soongsil']);a.add_argument('--app-log',type=Path,required=True);x=a.parse_args()
 old=R/'supabase/candidates/natural_expansion_20261111/four-university'/x.slug;private=R/'.local/four-university-20261111'/x.slug;out=R/'supabase/candidates/natural_tech_ready_20261112';out.mkdir(exist_ok=True)
 if x.slug in ('sogang','soongsil'):old=out/x.slug;private=R/'.local/natural-tech-20261112'/x.slug
 manifest=json.loads((old/'manifest.json').read_text());items=manifest['packages'];ids={p['question_id'] for p in items};sql=json.loads((old/'sql-receipt.json').read_text())
 for name,h in sql['files'].items():assert sha(private/name)==h,(name,'SQL_DRIFT')
 for p in items:assert sha(private/(p['question_id']+'.package.private.json'))==p['package_sha256'],p['question_id']
 contract=json.loads((private/'contract-report.json').read_text());worker=json.loads((private/'worker-contract-report.json').read_text());web=json.loads((private/'web-contract-report.json').read_text())
 for report in [contract,worker]:
  assert {q['question_id'] for q in report['questions']}==ids
  assert all(q['status']=='PASS' for q in report['questions']) and report['production_writes']==0 and report['provider_calls']==0
 assert web['success'] and web['numFailedTests']==0
 app=x.app_log.read_text();assert 'All tests passed!' in app and 'Exception:' not in app
 count=int(re.findall(r'\+(\d+): All tests passed!',app)[-1]);assert count==len(ids)+1
 for name in ['contract-report.json','worker-contract-report.json']:(out/(x.slug+'-'+name)).write_bytes((private/name).read_bytes())
 production=json.loads((out/(x.slug+'-production-readonly.json')).read_text());byid={r['question_id']:r for r in production}
 for q in items:
  live=byid[q['question_id']];assert live['exam_id']==q['exam_id'] and not live['math_bindings'] and not live['worker_source']
  assert not live['is_active'] and not live['is_published']
 blocked=json.loads((old/'web-expansion-candidate.json').read_text()).get('blockedExams',[])
 receipt=dict(university=x.slug,technical_contract_questions=len(ids),exams=len({p['exam_id'] for p in items}),package_hashes_verified=True,sql_hashes_verified=True,db_checks=len(contract['checks'])+sum(len(q['checks']) for q in contract['questions'])+sum(len(q['checks']) for q in worker['questions']),web_pass=web['numPassedTests'],web_skip=web['numPendingTests'],app_pass=count,app_log_sha256=sha(x.app_log),blocked_partial_exams=len(blocked),production_new_connections=0,production_writes=0,provider_calls=0,review_ready=False,quality_review='DEFERRED_OWNER_INTEGRATED_REVIEW',source_manifest_sha256=sha(old/'manifest.json'),sql_receipt_sha256=sha(old/'sql-receipt.json'))
 (out/(x.slug+'-receipt.json')).write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt))
if __name__=='__main__':main()
