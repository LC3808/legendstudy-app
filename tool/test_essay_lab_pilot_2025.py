import copy
import unittest
from essay_lab.pilot_2025 import load_plan, validate, scope, SCOPE, insert_scope

class PilotTests(unittest.TestCase):
    def setUp(self): self.p=load_plan()
    def test_exact_scope_and_counts(self):
        self.assertEqual([(len(scope(self.p,s)['essay_exams']),len(scope(self.p,s)['essay_exam_resources'])) for s in SCOPE],[(4,14),(7,41),(8,66)])
        self.assertEqual(len({m['resource_id'] for m in self.p['mappings']}),38)
    def test_order_independent_scope(self):
        q=copy.deepcopy(self.p)
        for k in ('universities','exams','mappings','documents'):q[k].reverse()
        for s in SCOPE:self.assertEqual(scope(self.p,s),scope(q,s))
    def test_no_year_or_university_expansion(self):
        for key,value in [('admission_year',2026),('university_id','00000000-0000-0000-0000-000000000000')]:
            q=copy.deepcopy(self.p);q['exams'][0][key]=value
            with self.assertRaises(AssertionError):validate(q)
    def test_duplicate_exam_and_mapping_reject(self):
        for key in ('exams','mappings'):
            q=copy.deepcopy(self.p);q[key].append(copy.deepcopy(q[key][0]))
            with self.assertRaises(AssertionError):validate(q)
    def test_cross_university_resource_reject(self):
        self.p['mappings'][0]['resource_id']=next(d['resource_id'] for d in self.p['documents'] if d['source_post_id']=='1689')
        with self.assertRaises(AssertionError):validate(self.p)
    def test_multi_role_pdf_and_subject_components(self):
        es=[e for e in self.p['exams'] if e['exam_key']=='mock-medicine-pharmacy']
        self.assertEqual(len(es),1)
        ms=[m for m in self.p['mappings'] if m['essay_exam_id']==es[0]['id']]
        self.assertEqual(len({m['resource_id'] for m in ms}),8)
        self.assertTrue(any(len({x['role'] for x in ms if x['resource_id']==m['resource_id']})>=4 for m in ms))
    def test_held_answer_never_verified(self):
        q=self.p['review_queue'][0]
        row=copy.deepcopy(next(m for m in self.p['mappings'] if m['resource_id']==q['resource_id']))
        row['role']='model_answer';self.p['mappings'].append(row)
        with self.assertRaisesRegex(AssertionError,'Held role'):validate(self.p)
    def test_owner_resolved_year_retains_conflict(self):
        self.assertEqual(len(self.p['resolved_reviews']),3)
        rid=self.p['resolved_reviews'][0]['resource_id']
        next(m for m in self.p['mappings'] if m['resource_id']==rid)['evidence_note']='Original conflict omitted'
        with self.assertRaisesRegex(AssertionError,'evidence lost'):validate(self.p)
    def test_missing_official_locator_and_evidence_reject(self):
        for field in ('official_source_url','source_locator','evidence_note'):
            q=copy.deepcopy(self.p);q['mappings'][0][field]=''
            with self.assertRaises(AssertionError):validate(q)
    def test_collision_never_inserts_or_commits(self):
        class Collision:
            calls=[]
            def execute(self,sql,params=()):
                self.calls.append(sql)
                return [('postgres',)] if sql=='SELECT current_user' else [(1,)]
        db=Collision()
        with self.assertRaisesRegex(AssertionError,'collision'):insert_scope(db,self.p,'yonsei')
        self.assertEqual(len(db.calls),2)
        self.assertTrue(all('INSERT' not in sql for sql in db.calls))
    def test_service_insert_restores_operator_not_cli_login(self):
        from unittest.mock import patch
        expected={t:len(v) for t,v in scope(self.p,'yonsei').items()}
        class Session:
            role='postgres'
            def execute(self,sql,params=()):
                if sql=='SELECT current_user':return [(self.role,)]
                if sql=='RESET ROLE':self.role='cli_login_postgres';return []
                if sql.startswith('SET LOCAL ROLE '):self.role=sql.split()[-1];return []
                if sql.startswith('INSERT '):
                    assert self.role=='service_role'
                    return [(1,)]
                raise AssertionError('Unexpected operation')
        db=Session()
        with patch('essay_lab.pilot_2025.preflight',return_value=expected):
            self.assertEqual(insert_scope(db,self.p,'yonsei'),expected)
        self.assertEqual(db.role,'postgres')

    def test_locator_page_bounds(self):
        import re
        ds={d['resource_id']:d for d in self.p['documents']}
        for m in self.p['mappings']:
            loc=m['source_locator'].split(';')[0]
            nums=[int(x) for x in re.findall(r'\d+',loc)]
            self.assertTrue(nums)
            self.assertTrue(all(1<=n<=ds[m['resource_id']]['pages'] for n in nums))
    def test_no_guessed_dates_or_campus(self):
        self.assertTrue(all(e['exam_date'] is None and e['campus'] is None for e in self.p['exams']))

if __name__=='__main__':unittest.main()
