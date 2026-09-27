"""Real historical snapshots + counterexamples for conservative offline rules."""
import copy
from dataclasses import replace
import hashlib
import json
import random
import unittest
from audit_exam_canonical_phase2 import BASELINE, EVIDENCE, run, identity_for, expected_for
from ingestion.exam_canonical import (ExamIdentity, ExpectedCoverage, observe, evaluate,
                                     classify_group, paper_code, serializable)

class CanonicalPhase2Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline=json.loads(BASELINE.read_text());cls.evidence=json.loads(EVIDENCE.read_text())
        cls.result=run(cls.baseline,cls.evidence)
        cls.rows={r['external_post_id']:r for r in cls.result['rows']}
        cls.raw={r['external_post_id']:r for r in cls.baseline['rows']}

    def good(self,pid='1'):
        identity=ExamIdentity(1,2026,6,'national_mock','BUSAN',confidence='high',evidence=('fixture:official',))
        resources=[{'key':s+kind,'label':s+kind,'subject':s,'kind':kind,'active':True}
                   for s in ['국어','수학','영어','한국사','사회','과학'] for kind in ['question','answer']]
        observed=observe(resources,identity)
        expected=ExpectedCoverage(identity.key,frozenset(observed.papers),True,('fixture:official',))
        return {'id':pid,'identity':identity,'observed':observed,'expected':expected}

    def test_complete_named_profile(self):
        c=self.good();self.assertEqual(classify_group([c])['1']['classification'],'FULL_SET')

    def test_deterministic_input_order(self):
        shuffled=copy.deepcopy(self.baseline);random.Random(7).shuffle(shuffled['rows'])
        for r in shuffled['rows']:random.Random(9).shuffle(r['resources'])
        self.assertEqual(run(shuffled,self.evidence),self.result)

    def test_no_input_mutation(self):
        a=copy.deepcopy(self.baseline);e=copy.deepcopy(self.evidence);run(a,e)
        self.assertEqual(a,self.baseline);self.assertEqual(e,self.evidence)

    def test_baseline_fingerprint_and_population(self):
        self.assertEqual(hashlib.sha256(BASELINE.read_bytes()).hexdigest(),self.evidence['baseline_sha256'])
        s=self.result['summary'];self.assertEqual(s['ambiguous_input_unique_posts'],43)
        self.assertEqual(len(s['writer_ambiguous']['REVIEW']),27)
        self.assertEqual(len(s['active_ambiguous']['REVIEW']),16)
        self.assertEqual(s['unique_source_posts_analyzed'],77)

    def test_unknown_profile_no_fallback(self):
        c=self.good();c['expected']=None
        self.assertEqual(classify_group([c])['1']['classification'],'REVIEW')
        for year in [2011,2017,2030]:
            row={**self.raw['1514'],'year':year};identity=identity_for(row,self.evidence)
            self.assertFalse(expected_for(row,identity).verified)

    def test_profile_identity_mismatch(self):
        c=self.good();c['expected']=replace(c['expected'],identity_key=(2025,6,1,'national_mock','BUSAN'))
        self.assertIn('expected_coverage_unverified',classify_group([c])['1']['reasons'])

    def test_unknown_organizer_and_date_conflict(self):
        for kw in [{'organizer':None},{'calendar_conflict':True},{'confidence':'low'}]:
            c=self.good();c['identity']=replace(c['identity'],**kw)
            self.assertEqual(classify_group([c])['1']['classification'],'REVIEW')

    def test_one_social_paper_not_whole_domain(self):
        c=self.good();i=replace(c['identity'],grade=3)
        o=observe([{'key':'x','label':'생활과윤리 문제','subject':'생활과윤리','kind':'question'}],i)
        self.assertEqual(o.domains['SOCIAL_STUDIES'],{'life_ethics'})
        self.assertNotIn('economics',o.papers)
        self.assertEqual(paper_code('탐구영역',i),(None,None))

    def test_taxonomy_alias_and_historical_preservation(self):
        i=replace(self.good()['identity'],grade=2)
        self.assertEqual(paper_code('물리학',i),paper_code('물리학Ⅰ',i))
        self.assertNotEqual(paper_code('법과정치',i),paper_code('정치와법',i))
        self.assertNotEqual(paper_code('물리1',i),paper_code('물리학1',i))
        self.assertNotEqual(paper_code('수학가형',i),paper_code('수학나형',i))

    def test_bare_common_not_all_electives(self):
        c=self.good();c['expected']=replace(c['expected'],required_variants=(('math',('기하','미적','확통')),))
        self.assertIn('elective_bundle_unproven',classify_group([c])['1']['reasons'])

    def test_inactive_planned_vs_active_resource(self):
        c=self.good();rs=[{**r,'active':False} for r in c['observed'].resources]
        self.assertFalse(observe(rs,c['identity']).unusable)
        self.assertTrue(observe(rs,c['identity'],require_active=True).unusable)

    def test_more_resources_cannot_win_tie(self):
        a=self.good('1');b=self.good('2');b['observed'].resources*=10
        result=classify_group([a,b])
        self.assertTrue(all(r['classification']=='REVIEW' for r in result.values()))
        self.assertTrue(all(r['reasons']==['canonical_rank_tie'] for r in result.values()))

    def test_evidence_rank_and_missing_rank_evidence(self):
        a=self.good('1');b=self.good('2');b['usability_rank']=2
        self.assertEqual(classify_group([a,b])['2']['classification'],'REVIEW')
        b['ranking_evidence']=['fixture:http_verified']
        result=classify_group([a,b]);self.assertEqual(result['2']['classification'],'FULL_SET')
        self.assertEqual(result['1']['canonical_target'],'2')

    def test_different_organizer_does_not_group(self):
        a=self.good('1');b=self.good('2');b['identity']=replace(b['identity'],organizer='SEOUL')
        b['expected']=replace(b['expected'],identity_key=b['identity'].key)
        self.assertTrue(all(r['classification']=='FULL_SET' for r in classify_group([a,b]).values()))

    def test_subset_points_only_to_full_target(self):
        a=self.good('1');b=self.good('2');a['observed'].papers.pop('integrated_social')
        result=classify_group([a,b]);self.assertEqual(result['1']['classification'],'PARTIAL_DUPLICATE')
        self.assertEqual(result['1']['canonical_target'],'2')
        b['expected']=None;self.assertIsNone(classify_group([a,b])['1']['canonical_target'])

    def test_protected_never_full(self):
        c=self.good();c['protected']=True
        self.assertEqual(classify_group([c])['1']['classification'],'REVIEW')
        self.assertIn('protected_hold',self.rows['1710']['reasons'])
        self.assertIn('protected_hold',self.rows['1431']['reasons'])

    def test_source_revision_blocks_full(self):
        c=self.good();c['source_changed']=True
        self.assertIn('source_snapshot_changed',classify_group([c])['1']['reasons'])

    def test_kice_june_september_csat_real(self):
        for pid in ['1516','1525','1574']:
            self.assertEqual(self.rows[pid]['classification'],'REVIEW')
        june=self.rows['1516'];self.assertTrue(june['expected']['verified'])
        self.assertEqual(len([p for p in june['missing_papers'] if p.startswith('foreign:')]),9)
        self.assertEqual(len([p for p in june['missing_papers'] if p.startswith('vocational:')]),6)
        self.assertFalse(self.rows['1525']['expected']['verified'])
        self.assertFalse(self.rows['1574']['expected']['verified'])

    def test_late_g3_g2_real(self):
        for pid in ['1486','1506','1608','1647']:
            self.assertIn('late_exam_additional_domains_unverified',self.rows[pid]['expected']['unresolved_domains'])
        i=self.rows['1608']['identity'];self.assertEqual(i['nominal_month'],11)
        self.assertEqual(i['administered_month'],12)

    def test_mapping_real_cases(self):
        for pid in ['1479','1496','1498','1646']:
            self.assertTrue(self.rows[pid]['observed']['unknown_keys'])
        self.assertTrue(self.rows['1635']['observed']['raw_splits'])
        self.assertIn('english',self.rows['1707']['missing_papers'])
        self.assertIn('english',self.rows['1712']['missing_papers'])

    def test_1474_1431_real(self):
        a,b=self.rows['1474'],self.rows['1431']
        self.assertEqual(a['classification'],'PARTIAL_DUPLICATE')
        self.assertIn('1431',a['broader_siblings']);self.assertIsNone(a['canonical_target'])
        self.assertEqual(b['identity']['nominal_month'],3)
        self.assertEqual(b['existing_identity'][1],4)
        self.assertIsNone(b['identity']['administered_date'])
        self.assertEqual(b['identity']['source_event_date'],'2020-04-24')
        self.assertEqual(b['resource_count'],38)

    def test_1447_1404_real(self):
        a,b=self.rows['1447'],self.rows['1404']
        self.assertIn('1404',a['sibling_source_posts'])
        self.assertTrue(b['identity']['calendar_conflict'])
        self.assertEqual(a['classification'],'REVIEW')
        self.assertIsNone(a['canonical_target']);self.assertEqual(b['resource_count'],47)
        self.assertFalse(b['expected']['verified'])
        self.assertFalse(b['expected']['papers']) # no modern taxonomy forced on2019

    def test_preserves_existing_30_as_provisional_not_authorized(self):
        self.assertEqual(len(self.result['summary']['previous_ready']['REVIEW']),30)
        self.assertEqual(self.result['summary']['final_canonical_ready_pool'],[])
        self.assertTrue(all(not r['automatic_publication_allowed'] for r in self.result['rows']))

    def test_duplicate_resource_identity(self):
        c=self.good();rs=c['observed'].resources
        c['observed']=observe(rs+[rs[0]],c['identity'])
        self.assertIn('resource_identity_ambiguous',classify_group([c])['1']['reasons'])

    def test_sibling_admin_date_conflict(self):
        a=self.good('1');b=self.good('2')
        a['identity']=replace(a['identity'],administered_date='2026-06-04')
        b['identity']=replace(b['identity'],administered_date='2026-06-05')
        b.update(ranking_evidence=['test'],usability_rank=2)
        self.assertTrue(all('exam_identity_collision' in r['reasons'] for r in classify_group([a,b]).values()))

    def test_metadata_recheck_exact(self):
        self.assertTrue(all(r['resource_metadata_unchanged'] for r in self.evidence['source_evidence'].values()))

    def test_readonly_reference_fixture(self):
        p=self.evidence['production_read_only'];self.assertEqual(p['transaction_read_only'],'on')
        for pid in ['1474','1447']:
            self.assertEqual(p['cases'][pid]['references']['bookmarks'],0)
            self.assertEqual(p['cases'][pid]['references']['recent_views'],1)

if __name__=='__main__':unittest.main()
