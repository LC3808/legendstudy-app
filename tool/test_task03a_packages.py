import copy,json,unittest,hashlib
from pathlib import Path
from task03a_packages import ROOT,papers,expanded
from validate_task03_scoring_package import validate
class OfficialPackages(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.ps=papers();cls.reg=json.loads((ROOT/'data/mock_expansion/task03/registry_snapshot.json').read_text())
  cls.report=json.loads((ROOT/'data/mock_expansion/task03a/verification_report.json').read_text())
 def test_every_package_passes_existing_preflight(self):
  identities=set()
  for p in self.ps:
   identity=(p['exam_subject_id'],p['paper_variant']);self.assertNotIn(identity,identities);identities.add(identity)
   self.assertEqual(validate(expanded(p),self.reg),[],identity)
   self.assertEqual(p['grade_status'],'unavailable')
 def test_registry_coverage_and_no_duplicate_alias_publication(self):
  rows=self.report['subjects'];self.assertEqual(len(rows),417)
  self.assertEqual({s['id'] for e in self.reg for s in e['subjects']},{s['exam_subject_id'] for s in rows})
  ready={p['exam_subject_id'] for p in self.ps}
  self.assertEqual(ready,{r['exam_subject_id'] for r in rows if r['ready']})
  self.assertTrue(all(r['paper_count']==sum(p['exam_subject_id']==r['exam_subject_id'] for p in self.ps) for r in rows))
  self.assertFalse(self.report['summary']['production_applied'])
 def test_complete_official_variant_sets(self):
  for row in self.report['subjects']:
   if not row['ready']:continue
   ps=[p for p in self.ps if p['exam_subject_id']==row['exam_subject_id']]
   forms={'홀수형','짝수형'} if row['exam_month']==11 and row['subject_code'] in ('korean','math','english','korean_history') else {'공통'}
   self.assertEqual({p['paper_variant'].split(' · ')[-1] for p in ps},forms)
   for form in forms:
    count=sum(p['paper_variant'].endswith(form) for p in ps)
    expected=2 if row['subject_label']=='국어' else 3 if row['subject_label']=='수학' else 1
    self.assertEqual(count,expected,(row,form))
 def test_original_answer_and_correction_are_both_retained(self):
  for year,month,code,number in [(2022,11,'life_science_2',20),(2023,6,'earth_science_2',14)]:
   matches=[p for p in self.ps if (p['academic_year'],p['exam_month'],p['subject_code'])==(year,month,code)]
   self.assertTrue(matches)
   for p in matches:
    q=p['questions'][number-1];self.assertTrue(q['all_credit']);self.assertEqual(q['accepted_answers'],[]);self.assertIn('original_accepted_answers',q)
    bad=expanded(p);bad['questions'][number-1]['all_credit']=False
    self.assertTrue(validate(bad,self.reg))
 def test_source_manifest_matches_package_digests(self):
  m=json.loads((ROOT/'data/mock_expansion/task03a/source_manifest.json').read_text())
  sources={s['url']:s['sha256'] for s in m['sources']+m['additional_sources']}
  for p in self.ps:
   p=expanded(p)
   for ev in [p['correction_evidence']]+[q[k] for q in p['questions'] for k in ('answer_evidence','points_evidence')]:
    self.assertEqual(sources[ev['url']],ev['sha256'])
 def test_math_types_and_elective_common_sections(self):
  groups={}
  for p in self.ps:
   if p['subject_code'] not in ('korean','math'):continue
   common=22 if p['subject_code']=='math' else 34
   group=(p['academic_year'],p['exam_month'],p['subject_code'],p['paper_variant'].split(' · ')[-1])
   values=[(q['number'],q['accepted_answers'],q['points']) for q in p['questions'][:common]]
   self.assertEqual(groups.setdefault(group,values),values)
   if p['subject_code']=='math':
    self.assertEqual([q['number'] for q in p['questions'] if q['answer_type']=='numeric'],list(range(16,23))+[29,30])
 def test_official_cutoffs_are_separate_from_raw_and_ocr(self):
  d=json.loads((ROOT/'data/mock_expansion/task03a/cutoff_review.json').read_text());rows=d['official_rows']
  self.assertEqual(len(rows),1026);self.assertEqual(len({(r['academic_year'],r['exam_month'],r['subject_label'],r['grade']) for r in rows}),1026)
  self.assertTrue(all(r['metric']=='standard_score' and r['certainty']=='confirmed' for r in rows))
  self.assertTrue(all(r['comparison']=='lt' for r in rows if r['grade']==9))
  self.assertTrue(all(r['score'] is None for r in rows if r['comparison']=='not_assigned'))
  corrected=[r for r in rows if (r['academic_year'],r['exam_month'],r['subject_label'])==(2022,11,'생명과학2')]
  self.assertEqual([r['score'] for r in corrected],[66,63,60,54,46,40,37,35,35])
  self.assertTrue(all(r['correction_applied'] for r in corrected))
if __name__=='__main__':unittest.main()
