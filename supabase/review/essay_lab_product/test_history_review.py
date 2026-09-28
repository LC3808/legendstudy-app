"""Static negative controls for history guarantees; NEVER claims PostgreSQL runtime."""
import ast as py_ast
from pathlib import Path
import re
import unittest
from pglast import parse_sql
from validate_drafts import validate, HERE, FILES

SQL='\n'.join((HERE/f).read_text() for f in FILES)

def history_checks(sql=SQL):
    validate(sql)
    required=[
        'create trigger essay_ai_runs_frozen',
        'create trigger credit_grant_terms_frozen',
        'create trigger essay_billing_history',
        'create trigger credit_account_identity',
        'create trigger essay_question_identity',
        "old.status in ('completed','failed')",
        'new.timed_out_at is distinct from old.timed_out_at',
        'policy_key text not null',
        'policy_version text not null',
        'unique index credit_decision_posting_once',
        'credit_transactions(decision_id,grant_id,transaction_type)',
        'unique index essay_evaluation_student_request',
        "request_kind = 'student' and status in ('requested','processing','completed')",
        'on delete set null (previous_progress_id)',
        'on delete set null (supersedes_evaluation_id)',
        'foreign key(previous_progress_id,issue_id)',
        'prior_time >= current_time',
        'normalization_status',
        "'open','improved','resolved','unchanged','recurred'",
        'unique index essay_example_first_stage_view',
        'learning_stage,stage_attempt_id) nulls not distinct',
        "array['invalidated_at','invalidation_reason']",
        'terminated_at timestamptz',
        'model_provider text, model_name text, model_version text, prompt_version text',
    ]
    for text in required:
        if text not in sql: raise ValueError('history guard missing: '+text)
    if "references public.essay_improvement_progress(id,issue_id) on delete cascade" in sql:
        raise ValueError('predecessor deletion loses later history')
    return True

class HistoryReviewTests(unittest.TestCase):
    def test_final_guards(self): self.assertTrue(history_checks())
    def reject(self,old,new=''):
        self.assertIn(old,SQL)
        with self.assertRaises(ValueError): history_checks(SQL.replace(old,new,1))
    def test_ai_terminal_guard_required(self): self.reject('create trigger essay_ai_runs_frozen','create trigger removed_ai_guard')
    def test_grant_terms_guard_required(self): self.reject('create trigger credit_grant_terms_frozen','create trigger removed_grant_guard')
    def test_billing_terms_guard_required(self): self.reject('create trigger essay_billing_history','create trigger removed_billing_guard')
    def test_account_transfer_guard_required(self): self.reject('create trigger credit_account_identity','create trigger removed_account_guard')
    def test_question_identity_guard_required(self): self.reject('create trigger essay_question_identity','create trigger removed_question_guard')
    def test_no_predecessor_cascade(self): self.reject('on delete set null (previous_progress_id)','on delete cascade')
    def test_posting_structural_dedupe(self): self.reject('unique index credit_decision_posting_once','index credit_decision_posting_once')
    def test_different_client_uuid_dedupe(self): self.reject('unique index essay_evaluation_student_request','index essay_evaluation_student_request')
    def test_meaningful_stage_first_view(self): self.reject('unique index essay_example_first_stage_view','index essay_example_first_stage_view')
    def test_evaluation_model_snapshot_required(self): self.reject('model_provider text, model_name text, model_version text, prompt_version text','model_provider text, model_name text, model_version text')
    def test_history_queries_read_only(self):
        statements=parse_sql((HERE/'history_queries.sql').read_text())
        self.assertEqual(len(statements),12)
        self.assertTrue(all(n.stmt.__class__.__name__=='SelectStmt' for n in statements))
        q=(HERE/'history_queries.sql').read_text()
        self.assertIn('d2.criterion_id=d1.criterion_id',q)
        self.assertIn('e1.regime_key=e2.regime_key',q)
        self.assertIn("i.normalization_status='reviewed'",q)
        self.assertIn('normalization_version,regime_key order by',q)
    def test_runtime_package_has_no_ai_or_production_connector(self):
        text=(HERE/'runtime/run.py').read_text();py_ast.parse(text)
        self.assertIn("('127.0.0.1','::1')",text)
        self.assertIn(".startswith('essay_review_')",text)
        self.assertIn("ESSAY_REVIEW_DISPOSABLE",text)
        self.assertNotIn('supabase db query',text)
        self.assertNotIn('requests.post',text)
        self.assertIn('Barrier(2)',text)
        self.assertIn('for update',text)
    def test_runtime_literal_sql_parses(self):
        tree=py_ast.parse((HERE/'runtime/run.py').read_text())
        count=0
        for n in py_ast.walk(tree):
            if isinstance(n,py_ast.Call) and isinstance(n.func,py_ast.Attribute) and n.func.attr=='execute' and n.args and isinstance(n.args[0],py_ast.Constant) and isinstance(n.args[0].value,str):
                parse_sql(n.args[0].value.replace('%s','NULL'))
                count+=1
        self.assertGreater(count,30)
    def test_runtime_fixture_explicit_history(self):
        text=(HERE/'runtime/run.py').read_text()
        self.assertIn("[2,3,3,4,4]",text)
        self.assertIn("['open','improved','resolved','recurred','improved']",text)
        self.assertIn('erasing_predecessor_preserves_later_observations',text)
        self.assertIn('same_attempt_versions_coexist',text)

if __name__=='__main__':unittest.main()
