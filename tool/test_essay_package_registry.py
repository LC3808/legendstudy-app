"""Real registry identities with synthetic evidence: identity/security tests, not E2E."""
import json,unittest
from pathlib import Path
from tool.essay_lab.package_registry import bind_registered_package
from tool.essay_lab.live_worker import digest,Invalid
from tool.essay_lab.registry_materials import connect
R=Path(__file__).resolve().parents[1]
class PackageRegistryTests(unittest.TestCase):
 def test_every_registered_exam_supports_same_adapter_without_activation(self):
  registry=json.loads((R/'supabase/reviews/essay-source-registration/manifest.json').read_text())
  count=0
  for exam in registry['exams']:
   for q in exam['questions']:
    cache={'contract_version':'1.3','evidence':[{'binding':{'role':'question','hash':exam['sourceHashes'][0]}}],'criteria':[{'fixture':True}]}
    a={k:exam[k] for k in ('examId','universityId','year','kind','track','session','campus')}
    a.update(evaluationType='humanities',questionId=q['id'],sourceKey=q['sourceKey'],questionSourceHash=exam['sourceHashes'][0],cacheSha256=digest(cache))
    def bind(v):return bind_registered_package(registry,v,cache,binding={},regime='unconfigured')
    bound=bind(a);self.assertEqual(bound.question_id,q['id']);self.assertFalse(bound.approved_processing);self.assertFalse(bound.reviewed_cache)
    for key,value in [('evaluationType','math'),('year',1900),('track','foreign'),('questionId','foreign'),('sourceKey','foreign'),('cacheSha256','changed')]:
     with self.assertRaises(Invalid):bind(dict(a,**{key:value}))
    count+=1
  self.assertEqual(count,234)
 def test_inventory_never_borrows_foreign_university_source(self):
  exam={'examId':'exam','universityId':'a','sourceHashes':['h']}
  with self.assertRaises(Invalid):connect({'exams':[exam]},[{'sha256':'h','university_id':'b'}])
if __name__=='__main__':unittest.main()
