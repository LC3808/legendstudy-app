-- Owner-only bounded rollback. Destroys HQP judgments; review retention before approval.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
drop function public.ql_list_human_judgments(uuid,integer,timestamptz,uuid);
drop function public.ql_review_state(uuid[]);
drop function public.ql_submit_human_judgment(jsonb);
drop table public.human_quality_findings;
drop table public.human_quality_judgments;
drop function essay_private.hq_projection(jsonb);
drop function essay_private.hq_immutable();
drop function essay_private.hq_finding_valid(jsonb);
drop function essay_private.hq_rubric_valid(jsonb);
commit;
