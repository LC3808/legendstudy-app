-- REVIEW ONLY. Owner authorization required. No publication/evaluation/DDL.
-- Source registry remains unchanged until apply + exact read-back are approved.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
lock table public.essay_exams,public.essay_questions in share row exclusive mode;
do $body$
declare e jsonb; q jsonb; eid uuid;
begin
 for e in select value from jsonb_array_elements($registration$[{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654","examId":"c7e17f5e-9037-5a78-8e77-7878a98230ca","existingExam":false,"universityId":"ffad67a6-107f-47b7-a1cb-ab61687ffb9f","year":2026,"kind":"mock","track":"인문사회","session":null,"campus":null,"examKey":"source-5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654","name":"중앙대학교 · 2026 · mock · 인문사회","sourceHashes":[],"resourceIds":["711f74c6-ba77-5d61-ab12-b39b14504f9f","fc2c55e8-7c3c-5d83-9ae3-9ffba848f09e"],"questions":[{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654:1","id":"158faf71-a175-5fb0-9116-d23334a90165","label":"문제 1","order":0},{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654:2","id":"ec43ccb1-5450-5ed0-8bde-225e4f5aa052","label":"문제 2","order":1},{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654:3","id":"ddddb229-a926-5398-b05f-b8815fa3cdf3","label":"문제 3","order":2}]},{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a","examId":"53bdd6f5-78be-548f-ac1b-23081f9bf74c","existingExam":false,"universityId":"ffad67a6-107f-47b7-a1cb-ab61687ffb9f","year":2026,"kind":"mock","track":"경영경제","session":null,"campus":null,"examKey":"source-1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a","name":"중앙대학교 · 2026 · mock · 경영경제","sourceHashes":[],"resourceIds":["99533452-4eb1-5eaf-8e24-6b19151722d6","dc1e6b23-4656-562f-83a3-f6a49f959696"],"questions":[{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a:1","id":"d08c00a8-78ef-5061-af5f-742e8e554798","label":"문제 1","order":0},{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a:2","id":"128810a1-149d-5344-ade7-62f98a5d481e","label":"문제 2","order":1},{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a:3","id":"eaf570bf-af83-5e9e-a9b7-ac39fd801fcd","label":"문제 3","order":2}]}]$registration$::jsonb) loop
  eid=(e->>'examId')::uuid;
  if exists(select 1 from public.essay_exams x where x.university_id=(e->>'universityId')::uuid and x.admission_year=2026 and x.exam_kind='mock' and x.field_or_division=e->>'track' and x.id<>eid) then raise exception 'TRACK_ALREADY_REGISTERED'; end if;
  if (select count(*) from public.resources where id in (select value::uuid from jsonb_array_elements_text(e->'resourceIds')) and is_active)<>2 then raise exception 'RESOURCE_DRIFT'; end if;
  if not exists(select 1 from public.universities where id=(e->>'universityId')::uuid) then raise exception 'UNIVERSITY_DRIFT';end if;
  if (e->>'existingExam')::boolean then
   if not exists(select 1 from public.essay_exams where id=eid and university_id=(e->>'universityId')::uuid and admission_year=(e->>'year')::int and exam_kind=e->>'kind') then raise exception 'EXAM_DRIFT';end if;
  else
   if exists(select 1 from public.essay_exams where university_id=(e->>'universityId')::uuid and admission_year=(e->>'year')::int and exam_kind=e->>'kind' and id<>eid and exam_key not like 'source-%') then raise exception 'EXAM_RECONCILIATION_REQUIRED';end if;
   insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,campus,field_or_division,session_label)
   values(eid,(e->>'universityId')::uuid,(e->>'year')::int,e->>'examKey',e->>'name',e->>'kind',e->>'campus',e->>'track',e->>'session') on conflict(id) do nothing;
   if not exists(select 1 from public.essay_exams where id=eid and university_id=(e->>'universityId')::uuid and admission_year=(e->>'year')::int and exam_key=e->>'examKey' and exam_kind=e->>'kind' and campus is not distinct from e->>'campus' and field_or_division is not distinct from e->>'track' and session_label is not distinct from e->>'session' and not is_active and verification_status='review') then raise exception 'EXAM_COLLISION_OR_STATE_CHANGED';end if;
  end if;
  for q in select value from jsonb_array_elements(e->'questions') loop
   insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version)
   values((q->>'id')::uuid,eid,q->>'sourceKey',q->>'label',(q->>'order')::int,'source-registration-v1') on conflict(id) do nothing;
   if not exists(select 1 from public.essay_questions where id=(q->>'id')::uuid and essay_exam_id=eid and question_key=q->>'sourceKey' and label=q->>'label' and display_order=(q->>'order')::int and metadata_version='source-registration-v1' and not is_published) then raise exception 'QUESTION_COLLISION_OR_STATE_CHANGED';end if;
  end loop;
 end loop;
end $body$;
commit;
