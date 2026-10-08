-- Candidate only. Owner §74 approval required before replacing the old unique constraint.
-- Preserve rows/IDs/nullable legacy year/division and APP insert/delete-by-ID behavior.
begin;
do $$begin
 if not exists(select 1 from pg_constraint where conrelid='public.student_target_universities'::regclass
 and conname='student_target_universities_user_id_university_id_admission_key'
 and pg_get_constraintdef(oid)='UNIQUE NULLS NOT DISTINCT (user_id, university_id, admission_year)') then
 raise exception 'TARGET_UNIQUE_AUTHORITY_DRIFT';end if;
 if exists(select 1 from pg_constraint where confrelid='public.student_target_universities'::regclass and contype='f'
 and confkey=(select conkey from pg_constraint where conrelid='public.student_target_universities'::regclass and conname='student_target_universities_user_id_university_id_admission_key')) then
 raise exception 'TARGET_UNIQUE_HAS_DEPENDENCIES';end if;
 if exists(select 1 from public.student_target_universities where octet_length(intended_division)>1024) then
 raise exception 'TARGET_DIVISION_INDEX_REVIEW_REQUIRED';end if;
end$$;
create unique index student_target_division_identity on public.student_target_universities
 (user_id,university_id,admission_year,(lower(btrim(coalesce(intended_division,''))))) nulls not distinct;
alter table public.student_target_universities drop constraint student_target_universities_user_id_university_id_admission_key;
commit;
-- Rollback only when no university/year has multiple rows. Never delete rows to roll back.
