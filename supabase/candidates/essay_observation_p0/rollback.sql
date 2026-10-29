-- Only additive read APIs are removed. Existing runs/checkpoints/Credit remain intact.
begin;
drop function public.essay_exam_question_result(uuid,uuid);
drop function public.essay_exam_observation(uuid);
drop function public.essay_exam_request_status(uuid,uuid);
commit;
