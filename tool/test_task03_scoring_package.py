import copy,json,unittest
from pathlib import Path
from validate_task03_scoring_package import validate
R=Path(__file__).resolve().parents[1]
class PackageTest(unittest.TestCase):
 def setUp(self):
  self.reg=[{'content_item_id':'synthetic-exam','academic_year':2022,'exam_month':6,'exam_type':'evaluation_mock','subjects':[{'id':'synthetic-subject','code':'math','is_active':True}]}]
  self.source={'issuer':'KICE','url':'https://example.invalid/synthetic-only.pdf','official_url':'https://www.kice.re.kr/synthetic-test-only','sha256':'0'*64,'page':1,'reviewed':True}
  self.p={'synthetic':True,'verification_status':'READY','engine':'mixed-v2','content_item_id':'synthetic-exam','academic_year':2022,'exam_month':6,'exam_type':'evaluation_mock','exam_subject_id':'synthetic-subject','subject_code':'math','mapping_reviewed':True,'paper_variant':'synthetic','corrections_reviewed':True,'correction_evidence':self.source,'question_count':1,'max_score':3,'questions':[{'number':1,'question_id':'00000000-0000-4000-8000-000000000001','answer_type':'numeric','accepted_answers':[0],'all_credit':False,'points':3,'answer_evidence':self.source,'points_evidence':self.source}]}
 def test_complete_synthetic_contract(self):self.assertEqual(validate(self.p,self.reg),[])
 def test_each_evidence_and_mapping_gate(self):
  for field,value in [('verification_status','PARTIAL'),('academic_year',2023),('exam_subject_id','missing'),('subject_code','korean'),('mapping_reviewed',False),('corrections_reviewed',False),('max_score',4),('question_count',2)]:
   with self.subTest(field=field):
    p=copy.deepcopy(self.p);p[field]=value;self.assertTrue(validate(p,self.reg))
 def test_unverified_points_and_unknown_tags(self):
  p=copy.deepcopy(self.p);p['questions'][0]['points_evidence']['reviewed']=False
  self.assertTrue(validate(p,self.reg));p=copy.deepcopy(self.p);p['questions'][0]['unit']='invented'
  self.assertTrue(validate(p,self.reg))
 def test_numeric_boundaries_and_duplicate_answers(self):
  for values in [[-1],[1000],[True],[0,0],[]]:
   p=copy.deepcopy(self.p);p['questions'][0]['accepted_answers']=values;self.assertTrue(validate(p,self.reg))
 def test_actual_inventory_is_disabled_and_registry_preserved(self):
  reg=json.loads((R/'data/mock_expansion/task03/registry_snapshot.json').read_text())
  coverage=json.loads((R/'data/mock_expansion/task03/verification_coverage.json').read_text())
  ids={s['id'] for e in reg for s in e['subjects']};rows=coverage['subjects']
  self.assertEqual(ids,{x['exam_subject_id'] for x in rows});self.assertEqual(len(rows),417)
  self.assertTrue(all(not x['ready'] for x in rows));self.assertEqual(sum(x['verification_status']=='PARTIAL' for x in rows),1)
 def test_pending_ocr_cannot_be_seed(self):
  d=json.loads((R/'data/grade_cutoffs/task03_pending/ocr_candidates.json').read_text())
  self.assertEqual(len(d['tables']),114)
  self.assertEqual(len({(t['content_item_id'],t['source_sha256']) for t in d['tables']}),114)
  for t in d['tables']:
   self.assertFalse(t['publishable']);self.assertIsNone(t['verified_at']);self.assertEqual(t['review_status'],'PENDING')
 def test_biology_exception_required(self):
  r=copy.deepcopy(self.reg);r[0]['exam_month']=11;r[0]['exam_type']='csat';r[0]['subjects'][0]['code']='life_science_2'
  p=copy.deepcopy(self.p);p.update(exam_month=11,exam_type='csat',subject_code='life_science_2')
  self.assertIn('2022 CSAT biology II correction not applied',validate(p,r))
if __name__=='__main__':unittest.main()
