"""Identity, source safety and non-public DRAFT contracts (no network)."""
import copy
import json
from pathlib import Path
import unittest
from essay_lab.natural_expansion import reconcile, validate_plan, build_review_package, student_crop_limit, ReviewError
from essay_lab.task20_priority_packages import registration_sql

ROOT = Path(__file__).resolve().parents[1]
PLAN = json.loads((ROOT/'supabase/candidates/natural_expansion_20261111/kau-source-plan.json').read_text())


def registry():
    rows=[]
    for e in PLAN['exams']:
        for q in e['questions']:
            r={k:e[k] for k in ['university_id','exam_id','exam_key','admission_year','exam_kind','field_or_division','session_label','campus']}
            r.update(slug='kau',name='한국항공대학교',question_id=q['question_id'],label=q['label'],display_order=q['display_order'],math_bindings=[],is_active=False,is_published=False)
            rows.append(r)
    return rows


def source():
    e=PLAN['exams'][0]
    return dict(key=e['exam_key'],universityId=e['university_id'],sourceUniversityId='kau',year=e['admission_year'],kind=e['exam_kind'],track=e['field_or_division'],session=e['session_label'],campus=e['campus'],sourceHashes=[e['source']['sha256']],questions=[dict(label=q['label']) for q in e['questions']])


class NaturalExpansionTest(unittest.TestCase):
    def test_exact_existing_ids_and_no_readiness_promotion(self):
        result=reconcile([source()],registry())[0]
        self.assertEqual(result['status'],'EXISTING_IDS_MATCHED')
        self.assertEqual(result['exam_ids'],[PLAN['exams'][0]['exam_id']])
        self.assertFalse(result['evaluation_ready']);self.assertFalse(result['publication_allowed'])

    def test_source_colon_alias_only(self):
        s=source();r=registry();s['key']='source:abcdef';r[0]['exam_key']=r[1]['exam_key']='source-abcdef'
        self.assertEqual(reconcile([s],r)[0]['status'],'EXISTING_IDS_MATCHED')

    def test_unresolved_source_does_not_create_uuid(self):
        s=source();s['key']='unregistered-2027'
        result=reconcile([s],registry())[0]
        self.assertEqual(result['status'],'UNRESOLVED_NO_INSERT');self.assertNotIn('exam_ids',result)

    def test_campus_year_track_session_kind_drift_holds(self):
        for k in ['campus','year','track','session','kind']:
            with self.subTest(k=k):
                s=source();s[k]='wrong'
                self.assertEqual(reconcile([s],registry())[0]['status'],'HOLD_IDENTITY_DRIFT')

    def test_duplicate_exam_not_silently_deduplicated(self):
        with self.assertRaisesRegex(ReviewError,'DUPLICATE_SOURCE_EXAM'):reconcile([source(),source()],registry())

    def test_duplicate_label_and_extra_question_hold(self):
        r=registry();r[1]['label']=r[0]['label']
        self.assertEqual(reconcile([source()],r)[0]['status'],'HOLD_IDENTITY_DRIFT')

    def test_question_id_and_order_drift(self):
        s=source();s['questions'][0]['dbQuestionId']='wrong'
        self.assertEqual(reconcile([s],registry())[0]['status'],'HOLD_IDENTITY_DRIFT')
        r=registry();r[1]['display_order']=r[0]['display_order']
        self.assertEqual(reconcile([source()],r)[0]['status'],'HOLD_IDENTITY_DRIFT')

    def test_completed_binding_preserved_in_reconciliation_but_not_rebuilt(self):
        r=registry();r[0]['math_bindings']=[{'leaf_id':'existing'}]
        self.assertEqual(reconcile([source()],r)[0]['questions'][0]['existing_math_bindings'],r[0]['math_bindings'])
        with self.assertRaisesRegex(ReviewError,'QUESTION_ALREADY_BOUND'):validate_plan(PLAN,r)

    def test_plan_has_twelve_unique_existing_questions(self):
        validate_plan(PLAN,registry())
        self.assertEqual(len({q['question_id'] for e in PLAN['exams'] for q in e['questions']}),12)

    def test_owner_hold_and_other_universities_rejected(self):
        for field,value,error in [('university_slug','chungang','SCOPE_NOT_KAU'),('university_slug','yonsei','SCOPE_NOT_KAU')]:
            p=copy.deepcopy(PLAN);p['exams'][0][field]=value
            with self.assertRaisesRegex(ReviewError,error):validate_plan(p,registry())
        p=copy.deepcopy(PLAN);p['exams'][0]['questions'][0]['hold']=True
        with self.assertRaisesRegex(ReviewError,'OWNER_HOLD'):validate_plan(p,registry())

    def test_invalid_page_missing_role_and_changed_registry_rejected(self):
        p=copy.deepcopy(PLAN);p['exams'][0]['questions'][0]['evidence']['rubric']=[99]
        with self.assertRaisesRegex(ReviewError,'PAGE_OUT_OF_BOUNDS'):validate_plan(p,registry())
        p=copy.deepcopy(PLAN);del p['exams'][0]['questions'][0]['evidence']['solution']
        with self.assertRaisesRegex(ReviewError,'SOURCE_ROLE_MISSING'):validate_plan(p,registry())
        r=registry();r[0]['admission_year']=2030
        with self.assertRaisesRegex(ReviewError,'EXAM_CONTEXT_DRIFT'):validate_plan(PLAN,r)

    def test_no_public_or_provider_flag(self):
        for flag in ['publication_allowed','provider_allowed']:
            p=copy.deepcopy(PLAN);p[flag]=True
            with self.assertRaises(ReviewError):validate_plan(p,registry())

    def test_shared_answer_page_requires_crop_before_heading(self):
        for bottom in [None, 450, 500]:
            with self.subTest(bottom=bottom), self.assertRaisesRegex(ReviewError,'ANSWER_LEAK_CROP_REQUIRED'):
                student_crop_limit({'crop_bottom_pt':bottom},842,[450])
        self.assertEqual(student_crop_limit({'crop_bottom_pt':443},842,[450]),443)

    def test_crop_cannot_leave_page_or_hide_missing_bounds(self):
        for bottom in [-1,900]:
            with self.assertRaisesRegex(ReviewError,'CROP_OUT_OF_BOUNDS'):
                student_crop_limit({'crop_bottom_pt':bottom},842,[])
        self.assertEqual(student_crop_limit({'crop_bottom_pt':None},842,[]),842)

    def test_draft_idempotence_and_unreviewed_math_gate(self):
        e=PLAN['exams'][0];q=e['questions'][0];pages=['fixture \ue123']*e['source']['pages']
        a=build_review_package(e,q,pages);b=build_review_package(e,q,pages)
        self.assertEqual(a,b);self.assertTrue(a['extraction_has_private_glyphs'])
        self.assertFalse(a['technical_ready']);self.assertFalse(a['publication_allowed'])
        self.assertEqual(len(a['existing_schema_rows']),8)
        for records in a['existing_schema_rows'].values():
            for r in records:
                if 'state' in r:self.assertEqual(r['state'],'DRAFT')
        sql=registration_sql([a]);self.assertIn('TASK20_QUESTION_ALREADY_BOUND',sql)
        self.assertNotIn('update public.',sql.lower());self.assertNotIn('delete from',sql.lower())


if __name__=='__main__':unittest.main()
