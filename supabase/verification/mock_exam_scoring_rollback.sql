-- DESTRUCTIVE / NEVER part of normal application. Owner approval required.
-- Disable future scoring clients first. This rollback refuses ANY scoring data.
-- Export/retention and a separate forward migration are required when data exists.
begin;
lock table public.answer_key_versions,public.exam_questions,public.grade_cutoff_versions,
 public.mock_exam_attempts,public.mock_exam_answers in access exclusive mode;
do $$ begin
 if exists(select 1 from public.answer_key_versions) or exists(select 1 from public.exam_questions)
 or exists(select 1 from public.grade_cutoff_versions) or exists(select 1 from public.mock_exam_attempts)
 or exists(select 1 from public.mock_exam_answers) then
 raise exception 'ROLLBACK_REFUSED_NONEMPTY_SCORING' using errcode='23514'; end if;
end $$;
drop view public.mock_exam_scoring_availability;
drop function public.submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb);
drop function public.fetch_own_mock_attempt(uuid);
drop trigger scoring_answers_consistency on public.mock_exam_answers;
drop trigger scoring_attempt_consistency on public.mock_exam_attempts;
drop trigger scoring_answer_guard on public.mock_exam_answers;
drop trigger scoring_attempt_guard on public.mock_exam_attempts;
drop trigger scoring_question_guard on public.exam_questions;
drop trigger scoring_key_publication on public.answer_key_versions;
drop trigger scoring_cutoff_publication on public.grade_cutoff_versions;
drop function public.scoring_attempt_consistency();
drop function public.scoring_answer_guard();
drop function public.scoring_attempt_guard();
drop function public.scoring_question_guard();
drop function public.scoring_publication_guard();
drop table public.mock_exam_answers;
drop table public.mock_exam_attempts;
drop table public.grade_cutoff_versions;
drop table public.exam_questions;
drop table public.answer_key_versions;
alter table public.study_sessions drop constraint study_sessions_id_owner;
drop function public.scoring_mcq5(jsonb,jsonb,smallint[],text);
drop function public.scoring_normalize_answers(jsonb,integer);
drop function public.scoring_cutoffs_valid(smallint[],integer);
drop function public.scoring_source_url(text);
drop function public.scoring_text(text,integer);
notify pgrst,'reload schema';
commit;
