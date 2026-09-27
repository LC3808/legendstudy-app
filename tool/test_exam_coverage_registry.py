"""Registry and real historical replay regressions; no DB/network access."""
import copy,json,unittest
from dataclasses import replace
from audit_exam_canonical_phase2 import BASELINE,EVIDENCE
from audit_exam_canonical_phase3 import run,PROVISIONAL,AMBIGUOUS
from ingestion.exam_canonical import ExamIdentity,observe,evaluate,paper_code
from ingestion.exam_coverage_registry import CoverageRegistry,classify_with_registry

class RegistryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.registry=CoverageRegistry.load()
        cls.baseline=json.loads(BASELINE.read_text());cls.evidence=json.loads(EVIDENCE.read_text())
        cls.result=run(cls.baseline,cls.evidence,cls.registry)
        cls.rows={r['post_id']:r for r in cls.result['rows']}
    def identity(self,year=2024,grade=1,month=3,org='SEOUL',family='national_mock'):
        return ExamIdentity(grade,year,month,family,org,confidence='high',evidence=('fixture:source',))
    def candidate(self,pid='1',identity=None,papers=None):
        i=identity or self.identity();e=self.registry.expected(i)
        labels={'korean':'국어','math':'수학','english':'영어','korean_history':'한국사','integrated_social':'통합사회','integrated_science':'통합과학'}
        selected=papers if papers is not None else e.papers
        res=[dict(key=f'{pid}:{p}:{k}',label=f'{p} {k}',subject=labels[p],kind=k) for p in sorted(selected) for k in ['question','answer']]
        return dict(id=pid,identity=i,expected=e,observed=observe(res,i))
    def test_exact_deterministic_lookup(self):
        i=self.identity();self.assertEqual(self.registry.lookup(i),self.registry.lookup(i))
    def test_lookup_cannot_mutate_registry(self):
        e=self.registry.lookup(self.identity());e['required_papers'].clear();self.assertTrue(self.registry.lookup(self.identity())['required_papers'])
    def test_verified_can_be_full(self):
        self.assertEqual(classify_with_registry([self.candidate()])['1']['classification'],'FULL_SET')
    def test_missing_profile_never_falls_back(self):
        for y in [2010,2015,2019,2025,2027]:self.assertIsNone(self.registry.lookup(self.identity(year=y)))
    def test_unknown_organizer_no_lookup(self):self.assertIsNone(self.registry.lookup(self.identity(org='BUSAN')))
    def test_unverified_never_full(self):
        c=self.candidate();c['expected']=None;self.assertEqual(classify_with_registry([c])['1']['classification'],'REVIEW')
    def test_partial_verification_never_full(self):
        c=self.candidate();c['expected']=replace(c['expected'],verified=False);self.assertEqual(classify_with_registry([c])['1']['classification'],'REVIEW')
    def test_missing_required_domain(self):
        c=self.candidate(papers={'korean','math','english'});self.assertIn('expected_paper_missing',classify_with_registry([c])['1']['reasons'])
    def test_partial_requires_full_sibling(self):
        a=self.candidate('1',papers={'korean','math','english'});b=self.candidate('2')
        r=classify_with_registry([a,b]);self.assertEqual(r['1']['classification'],'PARTIAL_DUPLICATE');self.assertEqual(r['1']['canonical_target'],'2')
    def test_broader_unverified_is_not_canonical(self):
        a=self.candidate('1',papers={'korean'});b=self.candidate('2');b['expected']=None
        self.assertEqual(classify_with_registry([a,b])['1']['classification'],'REVIEW')
    def test_tie_and_subset_remain_review(self):
        a=self.candidate('1',papers={'korean'});b=self.candidate('2');c=self.candidate('3')
        r=classify_with_registry([a,b,c]);self.assertTrue(all(x['classification']=='REVIEW' for x in r.values()))
    def test_sibling_order_independent(self):
        c=[self.candidate('1',papers={'korean'}),self.candidate('2')];self.assertEqual(classify_with_registry(c),classify_with_registry(c[::-1]))
    def test_organizer_mismatch_review(self):
        i=self.registry.resolve_identity(self.identity(org='BUSAN'));self.assertEqual(i.organizer,'BUSAN');self.assertEqual(i.confidence,'unverified')
    def test_admin_date_conflict(self):
        i=self.registry.resolve_identity(replace(self.identity(),administered_date='2024-03-29'));self.assertTrue(i.calendar_conflict)
    def test_admin_month_conflict(self):
        i=self.registry.resolve_identity(replace(self.identity(),administered_month=4));self.assertTrue(i.calendar_conflict)
    def test_academic_year_conflict(self):
        i=self.identity(2024,3,6,'KICE','evaluation_mock');self.assertTrue(self.registry.resolve_identity(replace(i,academic_year=2024)).calendar_conflict)
    def test_insufficient_identity_review(self):
        c=self.candidate();c['identity']=replace(c['identity'],confidence='unverified');self.assertIn('exam_identity_uncertain',classify_with_registry([c])['1']['reasons'])
    def test_question_answer_mapping_required(self):
        c=self.candidate();c['observed']=observe([r for r in c['observed'].resources if r['kind']=='question'],c['identity']);self.assertIn('question_answer_mapping_incomplete',classify_with_registry([c])['1']['reasons'])
    def test_subject_mapping_required(self):
        c=self.candidate();rr=c['observed'].resources+[dict(key='unknown',label='자료',subject=None,kind='question')];c['observed']=observe(rr,c['identity']);self.assertIn('resource_subject_mapping_incomplete',classify_with_registry([c])['1']['reasons'])
    def test_conditional_domains_year_month_scoped(self):
        early=self.registry.lookup(self.identity(2024,2,3));late=self.registry.lookup(self.identity(2024,2,10,'GYEONGGI'))
        self.assertFalse(early['conditional_domains']['VOCATIONAL']['offered_papers']);self.assertEqual(len(late['conditional_domains']['VOCATIONAL']['offered_papers']),6)
        self.assertEqual(len(late['conditional_domains']['SECOND_FOREIGN_HANMUN']['offered_papers']),7)
    def test_kice_extra_domains_required(self):
        for y in [2021,2022,2023,2024]:
            for m in [6,9]:
                e=self.registry.expected(self.identity(y,3,m,'KICE','evaluation_mock'))
                self.assertEqual(len([p for p in e.papers if p.startswith('vocational:')]),6)
                self.assertEqual(len([p for p in e.papers if p.startswith('foreign:')]),9)
    def test_missing_extras_cannot_be_full(self):
        for prefix in ['foreign:','vocational:']:
            r=self.rows['1516'];self.assertTrue(any(p.startswith(prefix) for p in r['missing_papers']));self.assertEqual(r['classification'],'REVIEW')
    def test_non_offered_extras_not_required(self):
        e=self.registry.expected(self.identity());self.assertFalse(any(p.startswith(('foreign:','vocational:')) for p in e.papers))
    def test_historical_math_preserved(self):
        e=self.registry.expected(self.identity(2020,3,3));self.assertIn('historical:수학가형',e.papers);self.assertIn('historical:수학나형',e.papers)
    def test_g1_g2_taxonomy_not_collapsed(self):
        self.assertIn('integrated_social',self.registry.expected(self.identity()).papers)
        self.assertNotIn('integrated_social',self.registry.expected(self.identity(2024,2,3)).papers)
    def test_real_1474_1431(self):
        self.assertEqual(self.rows['1474']['classification'],'PARTIAL_DUPLICATE');self.assertEqual(self.rows['1474']['canonical_target'],'1431')
        self.assertEqual(self.rows['1431']['classification'],'FULL_SET');self.assertTrue(self.rows['1431']['publication_hold'])
    def test_real_1447_1404(self):
        for p in ['1447','1404']:self.assertEqual(self.rows[p]['classification'],'REVIEW');self.assertIsNone(self.rows[p]['canonical_target'])
    def test_provisional30_and_ambiguous27(self):
        s=self.result['summary'];self.assertEqual(sum(map(len,s['previous_provisional_30'].values())),30);self.assertEqual(sum(map(len,s['previous_ambiguous_27'].values())),27)
        self.assertEqual(len(s['primary']['FULL_SET']),22);self.assertEqual(len(s['primary']['REVIEW']),35)
    def test_real_calendar_conflicts(self):
        for p in ['1488','1489','1525']:self.assertIn('admin_date_conflict',self.rows[p]['reasons'])
        self.assertNotIn('admin_date_conflict',self.rows['1609']['reasons'])
    def test_real_mapping_regressions(self):
        for p in ['1496','1498','1635']:self.assertEqual(self.rows[p]['classification'],'REVIEW')
    def test_repeat_and_reorder_input(self):
        b=copy.deepcopy(self.baseline);b['rows'].reverse();self.assertEqual(self.result,run(b,self.evidence,self.registry))
    def test_no_evidence_title_count_not_full(self):
        c=self.candidate();c['expected']=None
        c['observed'].resources*=10;c['title']='전과목 FULL SET'
        self.assertEqual(classify_with_registry([c])['1']['classification'],'REVIEW')
    def test_duplicate_registry_key_rejected(self):
        d=copy.deepcopy(self.registry.document);d['entries'].append(copy.deepcopy(d['entries'][0]))
        with self.assertRaises(ValueError):CoverageRegistry(d)
    def test_synthetic_evidenceless_entry_rejected(self):
        d=copy.deepcopy(self.registry.document);e=next(e for e in d['entries'] if e['status']=='VERIFIED');e['evidence']=[]
        with self.assertRaises(ValueError):CoverageRegistry(d)
    def test_inference_cannot_verify(self):
        d=copy.deepcopy(self.registry.document);e=next(e for e in d['entries'] if e['status']=='VERIFIED');e['epistemic_status']='INFERENCE'
        with self.assertRaises(ValueError):CoverageRegistry(d)
    def test_same_month_is_not_same_exam(self):
        a=self.candidate('1',papers={'korean'});b=self.candidate('2')
        b['identity']=replace(b['identity'],exam_year=2023)
        b['expected']=self.registry.expected(b['identity'])
        self.assertEqual(classify_with_registry([a,b])['1']['classification'],'REVIEW')
    def test_existing_kice_evidence_consistency(self):
        from audit_exam_canonical_phase2 import expected_for,identity_for
        row=next(r for r in self.baseline['rows'] if r['external_post_id']=='1516')
        i=identity_for(row,self.evidence)
        self.assertEqual(expected_for(row,i).papers,self.registry.expected(i).papers)
    def test_partial_unknown_attachment_kind_stays_review(self):
        a=self.candidate('1',papers={'korean'});b=self.candidate('2')
        a['observed'].unknown_kind_keys=['opaque-bundle']
        self.assertEqual(classify_with_registry([a,b])['1']['classification'],'REVIEW')
    def test_registry_status_mutation_cannot_certify(self):
        d=copy.deepcopy(self.registry.document)
        e=next(e for e in d['entries'] if e['status']=='PARTIALLY_VERIFIED');e['status']='VERIFIED'
        with self.assertRaises(ValueError):CoverageRegistry(d)
    def test_publication_always_false(self):
        self.assertTrue(all(not r['automatic_publication_allowed'] for r in self.result['rows']))

if __name__=='__main__':unittest.main()
