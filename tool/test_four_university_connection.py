"""Negative identity/image contracts for official multi-PDF candidate preparation."""
import base64,copy,json,unittest
from pathlib import Path
from essay_lab.four_university_connection import validate,validate_worker
from essay_lab.natural_expansion import ReviewError,digest
R=Path(__file__).resolve().parents[1]
class FourConnectionTest(unittest.TestCase):
 def setUp(self):
  self.plan=json.loads((R/'supabase/candidates/natural_expansion_20261111/four-university/konkuk-source-plan.json').read_text());self.rows=[]
  for e in self.plan['exams']:
   for q in e['questions']:
    row={k:e[k] for k in ['exam_id','university_id','exam_key','admission_year','exam_kind','field_or_division','session_label','campus']};row.update(slug=e['university_slug'],question_id=q['question_id'],label=q['label'],display_order=q['display_order'],math_bindings=[],is_active=False,is_published=False,worker_source=False);self.rows.append(row)
 def test_identity_and_prior_connections(self):
  validate(self.plan,self.rows)
  for field,value in [('math_bindings',[{'leaf':'existing'}]),('worker_source',True),('is_published',True),('display_order',99)]:
   rows=copy.deepcopy(self.rows);rows[0][field]=value
   with self.assertRaises(ReviewError):validate(self.plan,rows)
 def test_missing_roles_pages_and_flags(self):
  for edit in [lambda p:p.update(provider_allowed=True),lambda p:p.update(publication_allowed=True),lambda p:p['exams'][0]['questions'][0]['refs'].pop('intent'),lambda p:p['exams'][0]['questions'][0]['refs']['problem'].update(pages=[999])]:
   p=copy.deepcopy(self.plan);edit(p)
   with self.assertRaises(ReviewError):validate(p,self.rows)
 def payload(self):
  e=self.plan['exams'][2];q=e['questions'][0];refs={k:{f:v[f] for f in ['file','sha256','pages']} for k,v in q['refs'].items()};images=[];data=b'\x89PNG\r\n\x1a\nsynthetic'
  for h,n in sorted({(r['sha256'],n) for r in refs.values() for n in r['pages']}):images.append(dict(data=base64.b64encode(data).decode(),sha256=digest(data),source_sha256=h,physical_page=n,roles=[k for k,r in refs.items() if r['sha256']==h and n in r['pages']]))
  m=json.dumps(refs);s=json.dumps(images);return e,q,dict(exam_id=e['exam_id'],question_id=q['question_id'],manifest_text=m,images_text=s,sha256=digest((m+s).encode()))
 def test_different_pdfs_can_share_physical_page_number(self):
  e,q,p=self.payload();self.assertGreater(validate_worker(p,e,q),0)
 def test_wrong_original_pdf_or_missing_image_rejected(self):
  for edit in [lambda a:a[0].update(source_sha256='0'*64),lambda a:a.pop(),lambda a:a.append(a[0]),lambda a:a[0].update(data='broken')]:
   e,q,p=self.payload();images=json.loads(p['images_text']);edit(images);p['images_text']=json.dumps(images);p['sha256']=digest((p['manifest_text']+p['images_text']).encode())
   with self.assertRaises((ReviewError,ValueError)):validate_worker(p,e,q)
if __name__=='__main__':unittest.main()
