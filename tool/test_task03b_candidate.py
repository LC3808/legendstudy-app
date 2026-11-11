"""Offline reviewed data, identity, source and publication contract checks."""
import collections,hashlib,json,unittest
from pathlib import Path
from task03a_packages import ROOT,expanded
from validate_task03_scoring_package import validate
D=ROOT/'data/mock_expansion/task03b'
def read(n):return json.loads((D/n).read_text())
class Candidate(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.ps=read('verified_papers.json')['papers'];cls.load=read('load_data.json');cls.reg=json.loads((ROOT/'data/mock_expansion/task03/registry_snapshot.json').read_text())
 def test_baseline_byte_and_object_preservation(self):
  for p,h in read('preservation_manifest.json')['files'].items():self.assertEqual(hashlib.sha256((ROOT/p).read_bytes()).hexdigest(),h)
  old=json.loads((ROOT/'data/mock_expansion/task03a/verified_papers.json').read_text())['papers'];self.assertEqual(self.ps[:len(old)],old);self.assertEqual(len(old),412)
 def test_all_packages_and_exact_registry_coverage(self):
  seen=set()
  for p in self.ps:
   self.assertEqual(validate(expanded(p),self.reg),[]);key=(p['exam_subject_id'],p['paper_variant']);self.assertNotIn(key,seen);seen.add(key)
  report=read('verification_report.json');self.assertEqual(report['summary']['status_counts'],{'READY':396,'PARTIAL':12,'NOT_READY':9});self.assertEqual(len(self.ps),443);self.assertEqual(sum(p['question_count'] for p in self.ps),11170)
  self.assertEqual({p['exam_subject_id'] for p in self.ps},{r['exam_subject_id'] for r in report['subjects'] if r['ready']});self.assertEqual(len({p['content_item_id'] for p in self.ps}),17)
 def test_2025_forms_and_crosschecks(self):
  ps=read('2025_image_papers.json')['papers'];self.assertEqual(len(ps),31);checked=[p for p in ps if p.get('legendstudy_crosscheck')];self.assertEqual(len(checked),24)
  self.assertTrue(all(not p['legendstudy_crosscheck']['mismatches'] and p['question_count']==p['legendstudy_crosscheck']['compared_questions'] for p in checked))
  for p in ps:
   if p['variant']!='짝수형':continue
   odd=next(o for o in ps if (o['subject'],o['elective'],o['variant'])==(p['subject'],p['elective'],'홀수형'))
   self.assertEqual([q['points'] for q in p['questions']],[q['points'] for q in odd['questions']])
  audit=read('image_cell_audit.json');self.assertEqual(len(audit['number_exceptions']),92);self.assertEqual(len({r['cell'] for r in audit['even_deltas']}),21)
 def test_aliases_and_foreign_do_not_leak_into_seed(self):
  ids={p['exam_subject_id'] for p in self.ps};aliases=read('alias_mapping.json')['aliases'];self.assertEqual(len(aliases),12)
  for a in aliases:self.assertNotIn(a['exam_subject_id'],ids);self.assertTrue({s['exam_subject_id'] for s in a['targets']}<=ids);self.assertEqual(a['classification'],'ELECTIVE_UMBRELLA_NOT_IDENTICAL_DUPLICATE')
  fs=read('foreign_mapping_review.json')['subjects'];self.assertEqual(len(fs),9)
  for s in fs:self.assertIsNone(s['official_subject_code']);self.assertNotIn(s['exam_subject_id'],ids);self.assertEqual(s['verification_status'],'NOT_READY');self.assertEqual(s['paper']['question_count'],30);self.assertEqual(s['paper']['max_score'],50)
 def test_cutoff_metrics_and_no_inferred_numbers(self):
  review=read('raw_percentile_review.json');self.assertEqual(review['summary']['raw_score_cells'],816);self.assertEqual(review['summary']['percentile_cells'],304);self.assertEqual(review['summary']['source_empty_cells'],160);self.assertEqual(len(review['summary']['original_ocr_numeric_corrections']),5)
  self.assertFalse(review['grade_calculation_eligible']);self.assertEqual(self.load['grade_cutoff_versions'],[])
  for c in review['cells']:
   if c['metric'].startswith('raw_') and c['metric']!='raw_score':self.assertIsNone(c['verified_value'])
  refs=self.load['grade_cutoff_references'];self.assertEqual(len(refs),1029)
  for r in refs:self.assertLess(r['grade'],9);self.assertIsNotNone(r['standard_score']);self.assertEqual(r['standard_certainty'],'confirmed');self.assertEqual(r['raw_certainty'],'unspecified');self.assertFalse(r['is_current']);self.assertEqual(r['status'],'draft')
  ex=read('load_evidence.json')['excluded_reference_facts'];self.assertEqual(collections.Counter(x['comparison'] for x in ex),{'lt':114,'not_assigned':3})
 def test_load_counts_identity_and_old_reference_scope_disjoint(self):
  for table,pk in [('answer_key_versions',('id',)),('exam_questions',('answer_key_version_id','question_number')),('grade_cutoff_references',('id',))]:
   rows=self.load[table];self.assertEqual(len(rows),len({tuple(r[k] for k in pk) for r in rows}))
  old=json.loads((ROOT/'data/grade_cutoffs/task19/reviewed_rows.json').read_text());self.assertFalse({r['content_item_id'] for r in old}&{r['content_item_id'] for r in self.load['grade_cutoff_references']})
  for k in self.load['answer_key_versions']:
   qs=[q for q in self.load['exam_questions'] if q['answer_key_version_id']==k['id']];self.assertEqual(len(qs),k['question_count']);self.assertEqual(sum(q['points'] for q in qs),k['max_score']);self.assertEqual(k['verification_status'],'READY')
 def test_production_account_guard_preserved(self):
  p=(ROOT/'supabase/candidates/task03b_ready_20261111/01_engine.sql').read_text()
  self.assertIn('perform account_private.lock_subject(owner_id); if not account_private.allowed(owner_id)',p)
  self.assertNotIn('create function account_private.',p)
  self.assertEqual(read('production_preflight.json')['registry_readonly_check']['differences'],[])
 def test_sql_hashes_and_no_registry_user_mutations(self):
  m=read('sql_manifest.json');folder=ROOT/'supabase/candidates/task03b_ready_20261111'
  for p,h in m['files'].items():self.assertEqual(hashlib.sha256((folder/p).read_bytes()).hexdigest(),h)
  for p in ['02_seed_drafts.sql','03_publish.sql','05_rollback_visibility.sql']:
   s=(folder/p).read_text().lower()
   for table in ['exam_subjects','content_items','subjects','mock_exam_attempts','mock_exam_answers','grade_cutoff_versions']:
    self.assertNotIn('update public.'+table,s);self.assertNotIn('delete from public.'+table,s);self.assertNotIn('insert into public.'+table,s)
if __name__=='__main__':unittest.main()
