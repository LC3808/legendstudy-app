"""Private-source tests and real existing Worker source lookup in disposable PG17."""
import copy,hashlib,inspect,json,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import test_math_persistence as m
from psycopg.types.json import Jsonb
from essay_lab.live_worker import package,Invalid
from essay_lab.package_registry import bind_registered_package
from essay_lab.task20_priority_packages import registration_sql
R=Path(__file__).resolve().parents[1];O=R/'supabase/candidates/ewha_mock_public_20261112';P=R/'.local/ewha-mock-public-20261112'
plan=json.loads((O/'source-plan.json').read_text())
class SourceTests(unittest.TestCase):
 def test_existing_identity_and_counts(self):
  self.assertEqual(len(plan['files']),58);self.assertEqual(sum(f['pages'] for f in plan['files']),476)
  qs=[q for e in plan['exams'] for q in e['questions']];self.assertEqual(len({q['id'] for q in qs}),24)
  self.assertEqual({q['id'] for q in qs if q['production_registry_exists']},{'f32f7b67-6fcf-52ab-b6b7-06074712c702','4a432fdf-d601-5230-b045-d2123c614773','e7362b80-3f05-5d84-8768-826ab7136233'})
  self.assertEqual(plan['history']['archive_hashes_preserved'],26)
 def test_all_36_essay_packages_and_tamper_rejected(self):
  files=list(P.glob('*.essay.private.json'));self.assertEqual(len(files),12)
  for f in files:
   b=json.loads(f.read_text());c=b['cache'];claim=b['claim'];assignment=b['assignment']
   self.assertEqual(package(claim,c)['answer'],claim['answer'])
   self.assertEqual(len(c['criteria']),1)
   self.assertIn('공식 설명에 근거한 서비스 평가 요소 전체',c['criteria'][0]['label'])
   rubric=next(x for x in c['evidence'] if x['binding']['role']=='scoring_criteria')
   self.assertTrue(any(rubric['binding']['id'] in x['evidence_ids'] for x in c['official_images']))
   self.assertNotIn('예시답안',''.join(rubric['text'].split()))
   for mutate in [lambda x:x['evidence'][0].update(text='changed'),lambda x:x['official_images'][0].update(sha256='0'*64),lambda x:x['official_images'][0].update(evidence_ids=['foreign'])]:
    changed=copy.deepcopy(c);mutate(changed)
    with self.assertRaises(Invalid):package(claim,changed)
   bad=copy.deepcopy(assignment);bad['year']+=1
   with self.assertRaises(Invalid):bind_registered_package(plan,bad,c,binding={},regime='local')
   bnd=bind_registered_package(plan,assignment,c,binding={},regime='local')
   self.assertFalse(bnd.approved_processing)
 def test_raw_files_not_committed_and_no_publication(self):
  self.assertFalse(plan['publication_allowed']);self.assertFalse(plan['provider_allowed'])
  self.assertFalse(list(O.glob('*.pdf')));self.assertFalse(list(O.glob('*.private.json')))

def content_case(c,rpc,new,scalar,A,B):
 c.execute('alter table public.math_subproblems add column essay_question_id uuid references public.essay_questions(id)')
 c.execute("insert into public.universities(id,slug,name) values(%s,'ewha','이화여자대학교')",(plan['exams'][0]['universityId'],))
 for e in plan['exams']:
  c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,field_or_division,is_active) values(%s,%s,%s,%s,%s,%s,%s,false)",(e['examId'],e['universityId'],e['year'],e['sourceKey'].replace('source:','source-',1),'local candidate',e['kind'],e['track']))
  for q in e['questions']:c.execute("insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version,is_published) values(%s,%s,%s,%s,%s,'source-registration-v1',false)",(q['id'],e['examId'],q['sourceKey'],q['label'],q['order']))
 c.execute('create table math_private.task20_hanyang_source_pages(question_id uuid primary key,exam_id uuid,manifest jsonb,images jsonb,content_sha256 text);revoke all on math_private.task20_hanyang_source_pages from public,anon,authenticated;')
 c.execute((R/'tool/fixtures/kau-connection-worker-20261111.sql').read_text())
 packs=[json.loads(f.read_text()) for f in P.glob('*.package.private.json')];assert len(packs)==12
 c.execute(registration_sql(packs));c.execute(registration_sql(packs));results=[]
 for p in packs:
  qid=p['essay_question_id'];w=json.loads((P/(qid+'.worker.private.json')).read_text());assert hashlib.sha256((w['manifest_text']+w['images_text']).encode()).hexdigest()==w['sha256']
  c.execute('insert into math_private.task20_hanyang_source_pages values(%s,%s,%s,%s,%s)',(qid,w['exam_id'],Jsonb(json.loads(w['manifest_text'])),Jsonb(json.loads(w['images_text'])),w['sha256']))
  r=p['existing_schema_rows'];ctx={'leaf':r['math_subproblems'][0],'problem':r['math_problems'][0],'sources':r['math_source_artifacts']}
  out=scalar('select math_private.hanyang_worker_references(%s)',(Jsonb(ctx),));assert out['official_images']==json.loads(w['images_text'])
  wrong=copy.deepcopy(ctx);wrong['sources'][0]['content_sha256']='0'*64
  assert scalar('select math_private.hanyang_worker_references(%s)',(Jsonb(wrong),))=={}
  wrong=copy.deepcopy(ctx);wrong['leaf']['essay_question_id']=new()
  assert scalar('select math_private.hanyang_worker_references(%s)',(Jsonb(wrong),))=={}
  assert all(x['state']=='DRAFT' for t,rows in r.items() for x in rows if 'state'in x)
  results.append(dict(question_id=qid,lookup='PASS',hash_tamper_denied=True,foreign_question_denied=True,draft_only=True))
 report=dict(database='isolated Unix-socket PG17',math_questions=12,source_lookup_checks=36,registration_replay='PASS',production_changes=0,provider_calls=0,questions=results)
 (O/'isolated-worker-results.json').write_text(json.dumps(report,indent=2)+'\n');print('EWHA_MOCK_12_EXISTING_WORKER_36_CHECKS_PASS')
def main():
 result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(SourceTests))
 if not result.wasSuccessful():raise SystemExit(1)
 source=inspect.getsource(m.verify).split(" print('MATH_FULL_NON_SUPERUSER_INSTALL_PASS')")[0]
 source+='\n content_case(c,rpc,new,scalar,A,B)\n';ns=dict(m.__dict__);ns['content_case']=content_case;exec(source,ns);m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
if __name__=='__main__':main()
