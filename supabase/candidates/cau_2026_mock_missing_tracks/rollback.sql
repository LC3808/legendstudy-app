-- Separate Owner approval required. Never run after material/runtime/user linkage.
-- REVIEW ONLY. No CASCADE; refuse edited metadata and any learning dependency.
begin;
lock table public.essay_questions,public.essay_exams in share row exclusive mode;
do $body$ declare e jsonb;q jsonb;expected jsonb;actual jsonb;begin
 for e in select value from jsonb_array_elements($registration$[{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654","examId":"c7e17f5e-9037-5a78-8e77-7878a98230ca","existingExam":false,"universityId":"ffad67a6-107f-47b7-a1cb-ab61687ffb9f","year":2026,"kind":"mock","track":"인문사회","session":null,"campus":null,"examKey":"source-5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654","name":"중앙대학교 · 2026 · mock · 인문사회","sourceHashes":[],"resourceIds":["711f74c6-ba77-5d61-ab12-b39b14504f9f","fc2c55e8-7c3c-5d83-9ae3-9ffba848f09e"],"questions":[{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654:1","id":"158faf71-a175-5fb0-9116-d23334a90165","label":"문제 1","order":0},{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654:2","id":"ec43ccb1-5450-5ed0-8bde-225e4f5aa052","label":"문제 2","order":1},{"sourceKey":"source:5dc5bf55af47d4601dd0b467d6d2c49ce3d62d39b907c086ae5935ec3ee8e654:3","id":"ddddb229-a926-5398-b05f-b8815fa3cdf3","label":"문제 3","order":2}]},{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a","examId":"53bdd6f5-78be-548f-ac1b-23081f9bf74c","existingExam":false,"universityId":"ffad67a6-107f-47b7-a1cb-ab61687ffb9f","year":2026,"kind":"mock","track":"경영경제","session":null,"campus":null,"examKey":"source-1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a","name":"중앙대학교 · 2026 · mock · 경영경제","sourceHashes":[],"resourceIds":["99533452-4eb1-5eaf-8e24-6b19151722d6","dc1e6b23-4656-562f-83a3-f6a49f959696"],"questions":[{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a:1","id":"d08c00a8-78ef-5061-af5f-742e8e554798","label":"문제 1","order":0},{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a:2","id":"128810a1-149d-5344-ade7-62f98a5d481e","label":"문제 2","order":1},{"sourceKey":"source:1bdbed85aa6001c06ad62546260836d784eacf3a8f44298a7ed3e4e317e3909a:3","id":"eaf570bf-af83-5e9e-a9b7-ac39fd801fcd","label":"문제 3","order":2}]}]$registration$::jsonb) loop
  for q in select value from jsonb_array_elements(e->'questions') loop
   expected=jsonb_build_object('id',q->>'id','essay_exam_id',e->>'examId','question_key',q->>'sourceKey','label',q->>'label','display_order',(q->>'order')::int,'metadata_version','source-registration-v1','is_published',false);
   select jsonb_strip_nulls(to_jsonb(x)-'created_at') into actual from public.essay_questions x where id=(q->>'id')::uuid;
   if found and actual is distinct from expected then raise exception 'QUESTION_STATE_CHANGED';end if;
   if exists(select 1 from public.essay_practice_sessions where question_id=(q->>'id')::uuid) then raise exception 'LEARNING_RECORDS_EXIST';end if;
   delete from public.essay_questions where id=(q->>'id')::uuid;
  end loop;
  if not (e->>'existingExam')::boolean then
   expected=jsonb_strip_nulls(jsonb_build_object('id',e->>'examId','university_id',e->>'universityId','admission_year',(e->>'year')::int,'exam_key',e->>'examKey','exam_name',e->>'name','exam_kind',e->>'kind','campus',e->>'campus','field_or_division',e->>'track','session_label',e->>'session','verification_status','review','is_active',false));
   select jsonb_strip_nulls(to_jsonb(x)-array['created_at','updated_at']) into actual from public.essay_exams x where id=(e->>'examId')::uuid;
   if found and actual is distinct from expected then raise exception 'EXAM_STATE_CHANGED';end if;
   delete from public.essay_exams where id=(e->>'examId')::uuid;
  end if;
 end loop;
end $body$;
commit;
