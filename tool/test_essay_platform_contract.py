import unittest
from dataclasses import replace
from essay_platform_contract import Binding,ReviewedQuestion,plan_question,ContractError

def uid(n):return f'00000000-0000-4000-8000-{n:012d}'
def question(category='humanities_social',requirements=frozenset({'humanities_reasoning'}),bindings=None):
    return ReviewedQuestion(uid(1),uid(2),uid(3),2025,category,'question-v1','classification-v1','2026-10-08T00:00:00Z','https://university.example.test/source','a'*64,requirements,bindings if bindings is not None else (Binding('humanities',uid(1),uid(1),'rubric-v1',requirements,uid(2)),))
def run(q,extra=None):return plan_question({'question_id':q.question_id,'exam_id':q.exam_id,'university_id':q.university_id,'admission_year':q.admission_year,**(extra or {})},lambda _:q)
class MixedModeContract(unittest.TestCase):
    def test_humanities_and_math_keep_distinct_typed_bindings(self):
        self.assertEqual(run(question()).evaluators,('humanities',))
        q=question('math',frozenset({'math_solution'}),(Binding('math',uid(4),uid(4),'math-profile-v1',frozenset({'math_solution'}),uid(2)),))
        self.assertEqual(run(q).evaluators,('math',));self.assertFalse(run(q).runtime_enabled)
    def test_one_economics_exam_routes_by_question_not_category(self):
        prose=question('business_economics')
        math=question('business_economics',frozenset({'math_solution'}),(Binding('math',uid(4),uid(4),'v1',frozenset({'math_solution'}),uid(2)),))
        data=question('business_economics',frozenset({'humanities_reasoning','data_interpretation'}),(Binding('humanities',uid(1),uid(1),'v1',frozenset({'humanities_reasoning','data_interpretation'}),uid(2)),))
        self.assertEqual(run(prose).evaluators,('humanities',));self.assertEqual(run(math).evaluators,('math',));self.assertEqual(run(data).evaluators,('humanities',))
    def test_uncovered_mixed_requirement_cannot_be_claimed_complete(self):
        q=replace(question('business_economics'),requirements=frozenset({'humanities_reasoning','quantitative_reasoning'}))
        self.assertEqual(run(q).missing_requirements,('quantitative_reasoning',));self.assertFalse(run(q).runtime_enabled);self.assertEqual(run(q).credit_action,'NONE')
    def test_client_spoofed_routing_is_rejected(self):
        for field in ['capability','category','evaluator','rubric','bindings']:
            with self.assertRaisesRegex(ContractError,'IDENTITY_ONLY'):run(question(),{field:'math'})
    def test_question_exam_university_year_mismatch(self):
        for field,value in [('question_id',uid(9)),('exam_id',uid(9)),('university_id',uid(9)),('admission_year',2027)]:
            with self.assertRaisesRegex(ContractError,'CONTEXT_MISMATCH'):run(question(),{field:value})
    def test_wrong_question_rubric_and_duplicate_coverage_are_blockers(self):
        q=question();b=q.bindings[0]
        for bad in [replace(b,exam_id=uid(8)),replace(b,rubric_subject_id=uid(8)),replace(b,subject_id=uid(8),rubric_subject_id=uid(8))]:
            with self.assertRaises(ContractError):run(replace(q,bindings=(bad,)))
        with self.assertRaises(ContractError):run(replace(q,bindings=(b,b)))
    def test_science_is_missing_not_fallback(self):
        q=question('science',frozenset({'science_reasoning'}),())
        self.assertEqual(run(q).missing_requirements,('science_reasoning',))
        with self.assertRaisesRegex(ContractError,'NOT_IMPLEMENTED'):run(replace(q,bindings=(Binding('humanities',uid(1),uid(1),'v1',q.requirements,uid(2)),)))
    def test_unreviewed_metadata_and_future_codes_fail_closed(self):
        for q in [replace(question(),verified_at=None),replace(question(),source_sha256='fake'),replace(question(),category='unknown')]:
            with self.assertRaises(ContractError):run(q)
if __name__=='__main__':unittest.main()
