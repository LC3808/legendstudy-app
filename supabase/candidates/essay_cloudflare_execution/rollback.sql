begin;
do $$begin if exists(select 1 from essay_exam_private.checkpoints) then raise exception 'NONEMPTY_CHECKPOINT_ROLLBACK_DENIED';end if;end$$;
drop function public.essay_exam_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb);
drop table essay_exam_private.checkpoints;
commit;
