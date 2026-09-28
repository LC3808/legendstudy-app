"""Negative controls for review checks. No database, provider or private answer access."""
import json
from pathlib import Path
import unittest
from unittest.mock import patch
from validate_drafts import validate, HERE, FILES

SQL='\n'.join((HERE/f).read_text() for f in FILES)

class DraftReviewTests(unittest.TestCase):
    def rejects(self,old,new,message):
        self.assertIn(old,SQL)
        with self.assertRaisesRegex(ValueError,message):
            validate(SQL.replace(old,new,1))
    def test_valid_package(self):
        r=validate(SQL)
        self.assertEqual(r['tables'],19)
        self.assertEqual(r['runtime'],'NOT_RUN')
    def test_missing_rls(self):
        self.rejects('alter table public.essay_attempts enable row level security;','','RLS required')
    def test_unknown_parent(self):
        self.rejects('references public.profiles(id)','references public.essay_users(id)','unknown FK')
    def test_fk_nonunique_target(self):
        self.rejects('references public.essay_questions(id) on delete restrict','references public.essay_questions(question_key) on delete restrict','not UNIQUE')
    def test_wrong_child_column(self):
        self.rejects('foreign key(evidence_id,question_id)','foreign key(bad_evidence_id,question_id)','missing local column')
    def test_fk_type_mismatch(self):
        self.rejects('criterion_id uuid not null','criterion_id text not null','FK type mismatch')
    def test_data_seed_forbidden(self):
        with self.assertRaisesRegex(ValueError,'mutation'):
            validate(SQL+"insert into public.credit_accounts default values;")
    def test_drop_forbidden(self):
        with self.assertRaisesRegex(ValueError,'mutation'):
            validate(SQL+'drop table public.profiles;')
    def test_destructive_alter_forbidden(self):
        with self.assertRaisesRegex(ValueError,'only RLS'):
            validate(SQL+'alter table public.profiles drop column grade_level;')
    def test_student_evaluation_write_grant(self):
        with self.assertRaisesRegex(ValueError,'unsafe client grant'):
            validate(SQL+'grant update on public.essay_evaluations to authenticated;')
    def test_public_student_read(self):
        self.rejects('create policy essay_attempts_read on public.essay_attempts for select to authenticated','create policy essay_attempts_read on public.essay_attempts for select to anon, authenticated','public exposure')
    def test_ledger_delete_grant(self):
        with self.assertRaisesRegex(ValueError,'ledger mutable'):
            validate(SQL+'grant delete on public.credit_transactions to service_role;')
    def test_attempt_pricing_forbidden(self):
        with self.assertRaisesRegex(ValueError,'billing attempt rule'):
            validate(SQL+'\n-- policy attempt_no = 2\n')
    def test_colliding_live_table(self):
        original=Path.read_text
        def read(p,*a,**kw):
            text=original(p,*a,**kw)
            if p.name=='current_schema_inventory.json':
                data=json.loads(text);data['inventory']['tables'].append({'name':'essay_attempts','rls':True});return json.dumps(data)
            return text
        with patch.object(Path,'read_text',read), self.assertRaisesRegex(ValueError,'collision'):
            validate(SQL)
    def test_v1_1_cannot_change(self):
        original=Path.read_bytes
        def read(p):
            b=original(p)
            return b+b' ' if p.name=='evaluation_contract_v1_1.json' else b
        with patch.object(Path,'read_bytes',read), self.assertRaisesRegex(ValueError,'accepted v1.1'):
            validate(SQL)

if __name__=='__main__': unittest.main()
