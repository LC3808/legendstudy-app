import unittest
from essay_lab.quality_review import audit
class QualityAuditTest(unittest.TestCase):
 def sample(self,feedback):
  return [{'id':'run','answers':[{'questionId':'q','body':'😀 실제 문장'}],'result':{'questions':[{'questionId':'q','evidenceVersion':'material-17-digest','evaluation':{'sentence_feedback':feedback}}]}}]
 def test_exact_unicode_quote(self):
  self.assertEqual(audit(self.sample([{'start':2,'end':7,'quote':'실제 문장'}]),{'package_digest':'digest'})[0]['quote_status'],'PASS')
 def test_fabricated_quote(self):
  self.assertEqual(audit(self.sample([{'start':2,'end':7,'quote':'없는 문장'}]),{'package_digest':'digest'})[0]['quote_status'],'FAIL')
 def test_missing_not_success(self):
  n=audit(self.sample([]),{'package_digest':'digest'})[0]
  self.assertEqual(n['quote_status'],'NOT_VERIFIED');self.assertEqual(n['quality'],'NOT_VERIFIED')
if __name__=='__main__':unittest.main()
