-- Read-only. Save these results; repeat preservation.sql after installation.
select n.nspname,p.proname,md5(p.prosrc) as body_md5,p.proacl::text
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname in ('essay_exam_quote','essay_exam_submit_cycle','essay_exam_submit','essay_exam_history'))
   or (n.nspname='essay_exam_private' and p.proname in ('reserve','finish'));
-- Expected absent: quote, submit_cycle. Expected original body hashes:
-- submit 379abf07d7782ce331ada81851ea57e7; history a87267707cc9653ee800a4c800132520
-- reserve b32dff5d4b10a2c8e642f9c6a8dfb4bc; finish 289dfa22d51160b601f5faceab084de7
select column_name from information_schema.columns
where table_schema='essay_exam_private' and table_name='runs'
and column_name in ('previous_paid_run_id','submission_index');
