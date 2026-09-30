"""E1–E20 offline structural guards; reviewed classification remains a human gate."""
import copy,unittest
from hashlib import sha256
from tool.essay_lab.official_evidence_package import *
from tool.essay_lab.live_worker import Invalid


def fixture():
    blobs={'pdf':b'official retained PDF','student':b'student manuscript'}
    c={'question':{'id':'question-a'},'sources':[dict(id='official',path='pdf',sha256=sha256(blobs['pdf']).hexdigest(),provenance='official_university_source'),dict(id='answer',path='student',sha256=sha256(blobs['student']).hexdigest(),provenance='student_submission')], 'derivatives':[],'criteria':{},'allowed_evidence':[],'selected_transcription':'transcript-2'}
    for ident,role in [('Q','question'),('intent','official_intent'),('criterion','scoring_criterion'),('nominal','question_length_rule'),('scoring','scoring_length_rule'),('excluded','explicit_non_criterion'),('example-a','accepted_example'),('example-b','accepted_example'),('transcript-1','student_transcription'),('transcript-2','student_transcription')]:
        blobs[ident]=('old uncertainty' if ident=='transcript-1' else 'reviewed '+ident).encode()
        c['derivatives'].append(dict(id=ident,identity='answer' if role=='student_transcription' else ident,question_id='question-a',source_id='answer' if role=='student_transcription' else 'official',page=1,locator='page1 selected region',semantic_role=role,canonical_role=BASE_ROLES.get(role),version='2' if ident=='transcript-2' else '1',review_state='reviewed',current=ident!='transcript-1',path=ident,sha256=sha256(blobs[ident]).hexdigest(),prior_id='transcript-1' if ident=='transcript-2' else None,correction_reason='source verified' if ident=='transcript-2' else None,reviewer='operator',reviewed_at='2026-09-30',media_type='text/plain'))
        if role!='student_transcription':c['allowed_evidence'].append(ident)
    c['criteria']={'criterion-a':dict(source_evidence='criterion',origin='official',official_weight=None)}
    return c,blobs

class Evidence(unittest.TestCase):
    def setUp(self):self.c,self.b=fixture()
    def check(self):return validate(freeze_manifest(self.c),self.c,self.b.__getitem__)
    def reject(self):
        with self.assertRaises((Invalid,KeyError)):self.check()
    def item(self,key):return next(d for d in self.c['derivatives'] if d['id']==key)
    def test_E1_source_match(self):self.check()
    def test_E2_source_hash(self):self.b['pdf']=b'changed';self.reject()
    def test_E3_locator(self):self.item('Q')['locator']='';self.reject()
    def test_E4_example_as_criterion(self):self.item('example-a')['semantic_role']='scoring_criterion';self.reject()
    def test_E5_question_as_tolerance(self):self.item('nominal')['semantic_role']='scoring_length_rule';self.reject()
    def test_E6_noncriterion_distinct(self):self.check();self.assertEqual(self.item('excluded')['semantic_role'],'explicit_non_criterion')
    def test_E7_noncriterion_mandatory(self):self.c['criteria']['criterion-a']['source_evidence']='excluded';self.reject()
    def test_E8_multiple_examples_blind(self):
        p=self.check();v=blind_input(p,self.c,self.b.__getitem__)
        self.assertEqual(sum(x.startswith('example') for x in p['evidence']),2)
        self.assertFalse(any(x['semantic_role'] in EXAMPLES for x in v['evidence']))
    def test_E9_duplicate_example(self):self.c['derivatives'].append(copy.deepcopy(self.item('example-a')));self.reject()
    def test_E10_corrected_version(self):self.check();self.assertEqual(self.item('transcript-2')['prior_id'],'transcript-1')
    def test_E11_historical_unchanged(self):
        before=copy.deepcopy(self.b);self.check();self.assertEqual(before,self.b)
    def test_E12_student_in_official(self):self.c['allowed_evidence'].append('transcript-2');self.reject()
    def test_E13_model_contamination(self):self.c['sources'][0]['provenance']='model_output';self.reject()
    def test_E14_owner_preference(self):self.c['sources'][0]['provenance']='owner_product_decision';self.reject()
    def test_E15_deterministic(self):
        import json
        p=self.check(); restored=json.loads(json.dumps(self.c,sort_keys=True))
        self.assertEqual(p,freeze_manifest(restored))
    def test_relocated_files_preserve_identity(self):
        before=freeze_manifest(self.c)
        for group in ('sources','derivatives'):
            for d in self.c[group]: d['path']='relocated/'+d['path']
        self.assertEqual(before,freeze_manifest(self.c))
    def test_E16_criterion_missing_evidence(self):self.c['criteria']['criterion-a']['source_evidence']='absent';self.reject()
    def test_E17_other_question(self):self.item('Q')['question_id']='question-b';self.reject()
    def test_E18_unknown_role(self):self.item('Q')['semantic_role']='unknown';self.reject()
    def test_E19_intent_not_mandatory(self):
        self.check();self.c['criteria']['criterion-a']['source_evidence']='intent';self.reject()
    def test_E20_absent_weight(self):self.check();self.assertIsNone(self.c['criteria']['criterion-a']['official_weight'])
    def test_derivative_hash(self):self.b['Q']=b'changed';self.reject()
    def test_duplicate_current_version(self):
        d=copy.deepcopy(self.item('Q'));d['id']='Q2';self.c['derivatives'].append(d);self.reject()
    def test_unavailable_source(self):del self.b['pdf'];self.reject()
    def test_transcription_version(self):self.c['selected_transcription']='transcript-1';self.reject()
    def test_catalog_pinning(self):
        p=freeze_manifest(self.c);self.c['criteria']['criterion-a']['official_weight']=5
        with self.assertRaisesRegex(Invalid,'CATALOG_BINDING'):validate(p,self.c,self.b.__getitem__)
    def test_unlisted_evidence(self):
        p=freeze_manifest(self.c);p['evidence'].append('absent')
        with self.assertRaisesRegex(Invalid,'EVIDENCE_ALLOWLIST'):validate(p,self.c,self.b.__getitem__)

if __name__=='__main__':unittest.main()
