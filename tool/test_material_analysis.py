import unittest
from copy import deepcopy
from tool.essay_lab.material_analysis import analyze_pages,freeze_review
class MaterialAnalysisTests(unittest.TestCase):
 def test_integrated_and_composite_remain_unverified(self):
  integrated=analyze_pages(['2024학년도 문제 1 제시문','출제의도 채점기준 예시답안'],'a'*64)
  self.assertEqual(integrated['documentType'],'INTEGRATED');self.assertEqual(integrated['studentDelivery'],'BLOCKED')
  self.assertEqual(integrated['sections'][0]['pdfIndex'],0)
  self.assertIsNone(integrated['sections'][0]['printedPage'])
  self.assertEqual(analyze_pages(['2024학년도 문제 1','2025학년도 문제 2'],'a'*64)['documentType'],'COMPOSITE')
 def test_no_text_requires_visual_review(self):
  self.assertEqual(analyze_pages([''],'a'*64)['visualReviewPages'],[1])
 def test_separate_and_mixed_sources_no_invented_criteria(self):
  q=analyze_pages(['문제 1 제시문'],'a'*64);a=analyze_pages(['해설 예시답안'],'b'*64)
  self.assertEqual(q['documentType'],'SEPARATE');self.assertFalse(any(s['role']=='criteria' for s in q['sections']+a['sections']))
 def test_freeze_exact_binding_and_immutable_digest(self):
  exam=dict(examId='e',universityId='u',year=2024,kind='admission',track='인문',session='오후2',campus=None,questions=[{'id':'q'}],sourceHashes=['a'*64])
  reg={'exams':[exam]};review={'examId':'e','state':'VERIFIED','revision':1,'body':{'mappings':[dict(questionId='q',sourceHash='a'*64,role='question',startPage=1,endPage=2,verification='VERIFIED')]}}
  docs={'a'*64:dict(sourceHash='a'*64,pageCount=3,rights={'providerTransmission':'UNVERIFIED'})}
  first=freeze_review(review,docs,reg,'q');self.assertFalse(first['runtime_ready'])
  review['revision']=2;second=freeze_review(review,docs,reg,'q');self.assertNotEqual(first['package_digest'],second['package_digest']);self.assertEqual(first['package_version'],1)
  with self.assertRaises(Exception):freeze_review(review,docs,reg,'other')
  bad=deepcopy(review);bad['body']['mappings'][0]['endPage']=4
  with self.assertRaises(Exception):freeze_review(bad,docs,reg,'q')
if __name__=='__main__':unittest.main()
