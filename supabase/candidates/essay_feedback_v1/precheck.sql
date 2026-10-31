-- Read only. Verify schema/constraints/gates before Owner approval.
select to_regclass('public.feedback_submissions'),to_regclass('essay_exam_private.runs'),to_regnamespace('feedback_private');
select conname,pg_get_constraintdef(oid) from pg_constraint where conrelid='public.feedback_submissions'::regclass;
select pg_get_functiondef(oid) from pg_proc where oid in ('public.admin_operator()'::regprocedure,'public.is_feedback_admin()'::regprocedure,'account_private.allowed(uuid)'::regprocedure);
