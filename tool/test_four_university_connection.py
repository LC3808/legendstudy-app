"""Negative identity/image contracts for official multi-PDF candidate preparation."""
import base64,copy,json,unittest
from pathlib import Path
from essay_lab.four_university_connection import validate,validate_worker,student_page_bottom,student_page_clip
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
class StudentBoundaryTest(unittest.TestCase):
 def test_reviewed_coordinate_avoids_unreliable_text_search(self):
  from types import SimpleNamespace
  page=SimpleNamespace(rect=SimpleNamespace(height=728.52),search_for=lambda _:self.fail('explicit crop must not use text coordinates'))
  self.assertEqual(student_page_bottom(page,{'crop_bottom':568}),568)
  for value in [True,0,50,729,float('nan'),float('inf'),'568']:
   with self.assertRaises(ReviewError):student_page_bottom(page,{'crop_bottom':value})
  with self.assertRaises(ReviewError):student_page_bottom(page,{'crop_bottom':568,'crop_before':'heading'})
 def test_legacy_heading_boundary_and_ambiguity(self):
  from types import SimpleNamespace
  page=SimpleNamespace(rect=SimpleNamespace(height=800),search_for=lambda _:[SimpleNamespace(y0=300)])
  self.assertEqual(student_page_bottom(page,{'crop_before':'heading'}),292)
  page.search_for=lambda _:[SimpleNamespace(y0=300),SimpleNamespace(y0=301)]
  with self.assertRaises(ReviewError):student_page_bottom(page,{'crop_before':'heading'})

 def test_spread_regions_preserve_left_page_and_right_continuation(self):
  from types import SimpleNamespace
  page=SimpleNamespace(rect=SimpleNamespace(width=841,height=595))
  self.assertEqual(student_page_clip(page,{'crop_rect':[0,0,420.5,595]}),(0,0,420.5,595))
  self.assertEqual(student_page_clip(page,{'crop_rect':[420.5,0,841,204]}),(420.5,0,841,204))
 def test_invalid_or_ambiguous_rectangle_rejected(self):
  from types import SimpleNamespace
  page=SimpleNamespace(rect=SimpleNamespace(width=841,height=595))
  for rect in [[-1,0,420,595],[0,0,842,595],[0,0,420,596],[0,0,20,20],[0,0,float('nan'),595],[0,0,float('inf'),595],[False,0,420,595],[0,0,420],None]:
   if rect is None:continue
   with self.assertRaises(ReviewError):student_page_clip(page,{'crop_rect':rect})
  for extra in [{'crop_bottom':204},{'crop_before':'heading'}]:
   with self.assertRaises(ReviewError):student_page_clip(page,dict(crop_rect=[0,0,420,595],**extra))

if __name__=='__main__':unittest.main()
