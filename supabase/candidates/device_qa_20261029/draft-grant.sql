-- NOT APPLIED. psql -v owner_id=<separately approved authenticated owner UUID>.
-- Only the two verified Kwangwoon 2026 humanities period-1 canonical questions.
-- This grants draft storage, never exam visibility, evaluation or free Credit.
begin;
create temporary table approved_draft_owner(id uuid) on commit drop;
insert into approved_draft_owner values (:'owner_id'::uuid);
do $guard$
begin
 if not account_private.allowed((select id from approved_draft_owner))
 or not exists(select 1 from auth.users where id=(select id from approved_draft_owner))
 or (select count(*) from public.essay_questions where essay_exam_id='cc5dfe4e-63ec-5877-be9a-8bdafbb97e8d'
   and id in ('f529765c-7d71-5993-bef9-d2e9e926e020','19e67592-af8f-5231-b7d1-e20f91c6a523') and not is_published)<>2
 then raise exception 'DRAFT_GRANT_SCOPE_CHANGED';end if;
end $guard$;
insert into essay_private.draft_access(user_id,question_id,expires_at,reason)
 select o.id,q.id,clock_timestamp()+interval '14 days','Owner-approved Kwangwoon device QA draft access'
 from approved_draft_owner o cross join public.essay_questions q
 where q.essay_exam_id='cc5dfe4e-63ec-5877-be9a-8bdafbb97e8d'
 and q.id in ('f529765c-7d71-5993-bef9-d2e9e926e020','19e67592-af8f-5231-b7d1-e20f91c6a523');
commit;
