-- Empty installation only. Never erase submissions or detach posted ledger rows.
begin;
do $$begin
 if exists(select 1 from essay_exam_private.runs) then raise exception 'NONEMPTY_EXAM_ROLLBACK_DENIED';end if;
end$$;
drop function essay_exam_private.finish(uuid,jsonb,boolean);
drop function essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid);
drop table essay_exam_private.runs;
drop function essay_exam_private.guard();
drop schema essay_exam_private;
commit;
