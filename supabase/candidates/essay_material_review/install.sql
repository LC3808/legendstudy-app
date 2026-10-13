-- CANDIDATE ONLY. No production application is authorized by this file.
-- Reuses canonical exams/questions/resources; adds private review revisions only.
begin;
create schema if not exists essay_material_private;
revoke all on schema essay_material_private from public,anon,authenticated;
create table if not exists essay_material_private.documents(
 sha256 text primary key check(sha256 ~ '^[a-f0-9]{64}$'),
 resource_id uuid references public.resources(id),
 title text not null check(length(title) between 1 and 250),
 page_count integer not null check(page_count between 1 and 3000),
 object_key text not null unique check(object_key = sha256 || '.pdf'),
 created_at timestamptz not null default now()
);
create table if not exists essay_material_private.reviews(
 exam_id uuid primary key references public.essay_exams(id),
 revision integer not null default 0,
 state text not null default 'UNANALYZED' check(state in ('UNANALYZED','ANALYZED','NEEDS_REVIEW','IN_REVIEW','VERIFIED','PACKAGE_READY','E2E_PASSED','ACTIVE','BLOCKED')),
 body jsonb not null default '{"documents":[],"mappings":[],"checks":{}}',
 updated_at timestamptz not null default now(),
 reviewer uuid references auth.users(id) on delete set null,
 approval_requested boolean not null default false
);
create table if not exists essay_material_private.revisions(
 exam_id uuid not null references essay_material_private.reviews(exam_id),
 revision integer not null,
 state text not null,
 body jsonb not null,
 reviewer uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 primary key(exam_id,revision)
);
alter table essay_material_private.documents enable row level security;
alter table essay_material_private.reviews enable row level security;
alter table essay_material_private.revisions enable row level security;
revoke all on all tables in schema essay_material_private from public,anon,authenticated;

create or replace function public.essay_material_list() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not public.is_quality_operator() then raise exception 'MATERIAL_OPERATOR_REQUIRED' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('examId',e.id,'universityId',e.university_id,'university',u.name,'year',e.admission_year,'kind',e.exam_kind,'track',e.field_or_division,'title',e.exam_name,'questionCount',(select count(*) from public.essay_questions q where q.essay_exam_id=e.id),'state',coalesce(r.state,'UNANALYZED'),'revision',coalesce(r.revision,0),'updatedAt',r.updated_at,'reviewer',r.reviewer,'approvalRequested',coalesce(r.approval_requested,false)) order by u.name,e.admission_year desc,e.id)
 from public.essay_exams e join public.universities u on u.id=e.university_id left join essay_material_private.reviews r on r.exam_id=e.id
 where exists(select 1 from public.essay_questions q where q.essay_exam_id=e.id)), '[]'::jsonb);
end $$;
create or replace function public.essay_material_detail(p_exam uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not public.is_quality_operator() then raise exception 'MATERIAL_OPERATOR_REQUIRED' using errcode='42501'; end if;
 if not exists(select 1 from public.essay_exams where id=p_exam) then raise exception 'EXAM_NOT_FOUND'; end if;
 return jsonb_build_object('examId',p_exam,'review',coalesce((select jsonb_build_object('revision',revision,'state',state,'body',body,'approvalRequested',approval_requested) from essay_material_private.reviews where exam_id=p_exam),'{"revision":0,"state":"UNANALYZED","body":{"documents":[],"mappings":[],"checks":{}},"approvalRequested":false}'::jsonb),
 'questions',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'label',label,'sourceKey',question_key) order by display_order),'[]'::jsonb) from public.essay_questions where essay_exam_id=p_exam),
 'documents',(select coalesce(jsonb_agg(to_jsonb(d)),'[]'::jsonb) from essay_material_private.documents d where exists(select 1 from essay_material_private.reviews r,jsonb_array_elements_text(r.body->'documents') h where r.exam_id=p_exam and h=d.sha256)),
 'history',(select coalesce(jsonb_agg(x order by revision desc),'[]'::jsonb) from (select revision,state,reviewer,created_at from essay_material_private.revisions where exam_id=p_exam order by revision desc limit 30)x));
end $$;
create or replace function public.essay_material_save(p_exam uuid,p_revision integer,p_body jsonb,p_state text,p_request_approval boolean default false) returns jsonb
language plpgsql security definer set search_path='' as $$
declare old essay_material_private.reviews; package jsonb; m jsonb; h text; n integer; required_checks text[]:=array['university','year','kind','track','sessionCampus','question','passages','questionPages','visuals','length','intent','explanation','criteria','modelAnswer','source','providerRights','studentRights'];
begin
 if not public.is_quality_operator() then raise exception 'MATERIAL_OPERATOR_REQUIRED' using errcode='42501'; end if;
 if p_state is null or p_state not in ('ANALYZED','NEEDS_REVIEW','IN_REVIEW','VERIFIED','BLOCKED') then raise exception 'STATE_TRANSITION_DENIED'; end if;
 if p_revision is null or p_revision < 0 or p_request_approval is null or p_body is null or octet_length(p_body::text)>524288 or jsonb_typeof(p_body) is distinct from 'object' or jsonb_typeof(p_body->'documents') is distinct from 'array' or jsonb_typeof(p_body->'mappings') is distinct from 'array' or jsonb_typeof(p_body->'checks') is distinct from 'object' then raise exception 'INVALID_REVIEW'; end if;
 if jsonb_array_length(p_body->'documents')>100 or jsonb_array_length(p_body->'mappings')>1000 then raise exception 'REVIEW_TOO_LARGE'; end if;
 for h in select jsonb_array_elements_text(p_body->'documents') loop
  if not exists(select 1 from essay_material_private.documents where sha256=h) then raise exception 'DOCUMENT_NOT_REGISTERED'; end if;
 end loop;
 for m in select * from jsonb_array_elements(p_body->'mappings') loop
  if (coalesce(m->>'questionId','')<>'' or p_state='VERIFIED') and not exists(select 1 from public.essay_questions where id=nullif(m->>'questionId','')::uuid and essay_exam_id=p_exam) then raise exception 'QUESTION_NOT_IN_EXAM'; end if;
  if m->>'role' is null or m->>'role' not in ('question','shared_passage','intent','explanation','criteria','scoring','model_answer','image') or not (p_body->'documents' ? (m->>'sourceHash')) then raise exception 'INVALID_MAPPING'; end if;
  select page_count into n from essay_material_private.documents where sha256=m->>'sourceHash';
  if jsonb_typeof(m->'startPage') is distinct from 'number' or jsonb_typeof(m->'endPage') is distinct from 'number' or (m->>'startPage')::numeric<>trunc((m->>'startPage')::numeric) or (m->>'endPage')::numeric<>trunc((m->>'endPage')::numeric) or (m->>'startPage')::integer<1 or (m->>'endPage')::integer<(m->>'startPage')::integer or (m->>'endPage')::integer>n then raise exception 'INVALID_PAGE_RANGE'; end if;
 end loop;
 if p_state='VERIFIED' then
  if exists(select 1 from jsonb_array_elements(p_body->'mappings') x where x->>'verification' is distinct from 'VERIFIED') then raise exception 'MAPPING_REVIEW_REQUIRED'; end if;
  if exists(select 1 from unnest(required_checks) k where p_body->'checks'->>k is distinct from 'true') then raise exception 'CHECKLIST_INCOMPLETE'; end if;
  if not exists(select 1 from jsonb_array_elements(p_body->'mappings') x where x->>'role'='question') then raise exception 'QUESTION_MAPPING_REQUIRED'; end if;
 end if;
 if p_request_approval and p_state<>'VERIFIED' then raise exception 'VERIFICATION_REQUIRED'; end if;
 -- Serialize the initial insert and subsequent updates on an existing canonical row.
 perform 1 from public.essay_exams where id=p_exam for update;
 if not found then raise exception 'EXAM_NOT_FOUND'; end if;
 insert into essay_material_private.reviews(exam_id) values(p_exam) on conflict do nothing;
 select * into old from essay_material_private.reviews where exam_id=p_exam for update;
 if old.revision<>p_revision then raise exception 'REVISION_CONFLICT' using errcode='40001'; end if;
 if old.state in ('PACKAGE_READY','E2E_PASSED','ACTIVE') then raise exception 'APPROVED_VERSION_IMMUTABLE'; end if;
 -- The server builds a versioned evidence package from the reviewed canonical mapping.
 -- It never grants runtime/publication permission and never invents criterion weights.
 p_body := p_body - 'package';
 if p_request_approval then
  select jsonb_build_object('schema','essay-material-package-v1','exam_id',e.id,
   'university_id',e.university_id,'package_version',p_revision+1,
   'exam_identity',jsonb_build_object('academic_year',e.admission_year,'exam_type',e.exam_kind,'track',e.field_or_division,'title',e.exam_name),
   'verification_status','VERIFIED_MANIFEST','runtime_ready',false,
   'rights_status',coalesce(p_body->'rights','{}'::jsonb),
   'questions',(select jsonb_agg(jsonb_build_object('question_id',q.id,'source_key',q.question_key,
      'official_question',(select coalesce(jsonb_agg(x),'[]'::jsonb) from jsonb_array_elements(p_body->'mappings') x where x->>'questionId'=q.id::text and x->>'role'='question'),
      'source_page_references',(select jsonb_agg(x) from jsonb_array_elements(p_body->'mappings') x where x->>'questionId'=q.id::text),
      'criterion_weights',null) order by q.display_order)
    from public.essay_questions q where q.essay_exam_id=p_exam and exists(select 1 from jsonb_array_elements(p_body->'mappings') x where x->>'questionId'=q.id::text and x->>'role'='question')))
  into package from public.essay_exams e where e.id=p_exam;
  package:=package||jsonb_build_object('package_digest',encode(sha256(convert_to(package::text,'UTF8')),'hex'));
  p_body:=p_body||jsonb_build_object('package',package);
 end if;
 update essay_material_private.reviews set revision=revision+1,body=p_body,state=p_state,reviewer=auth.uid(),updated_at=now(),approval_requested=p_request_approval where exam_id=p_exam;
 insert into essay_material_private.revisions(exam_id,revision,state,body,reviewer) values(p_exam,p_revision+1,p_state,p_body,auth.uid());
 return public.essay_material_detail(p_exam);
end $$;
revoke all on function public.essay_material_list(),public.essay_material_detail(uuid),public.essay_material_save(uuid,integer,jsonb,text,boolean) from public,anon;
grant execute on function public.essay_material_list(),public.essay_material_detail(uuid),public.essay_material_save(uuid,integer,jsonb,text,boolean) to authenticated;
-- Private original PDFs: operator-only, immutable paths; no student policy.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('essay-material-originals','essay-material-originals',false,33554432,array['application/pdf']) on conflict(id) do nothing;
do $$ begin
 if exists(select 1 from storage.buckets where id='essay-material-originals' and public) then raise exception 'BUCKET_MUST_BE_PRIVATE'; end if;
end $$;
drop policy if exists essay_material_operator_read on storage.objects;
create policy essay_material_operator_read on storage.objects for select to authenticated
using(bucket_id='essay-material-originals' and public.is_quality_operator());
drop policy if exists essay_material_operator_insert on storage.objects;
create policy essay_material_operator_insert on storage.objects for insert to authenticated
with check(bucket_id='essay-material-originals' and name ~ '^[a-f0-9]{64}\.pdf$' and public.is_quality_operator());
create or replace function public.essay_material_register(p_hash text,p_title text,p_pages integer) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not public.is_quality_operator() then raise exception 'MATERIAL_OPERATOR_REQUIRED' using errcode='42501'; end if;
 if not exists(select 1 from storage.objects where bucket_id='essay-material-originals' and name=p_hash||'.pdf') then raise exception 'UPLOAD_REQUIRED'; end if;
 insert into essay_material_private.documents(sha256,title,page_count,object_key) values(p_hash,p_title,p_pages,p_hash||'.pdf') on conflict(sha256) do nothing;
 if exists(select 1 from essay_material_private.documents where sha256=p_hash and page_count<>p_pages) then raise exception 'DOCUMENT_CONFLICT'; end if;
 return (select to_jsonb(d) from essay_material_private.documents d where sha256=p_hash);
end $$;
create or replace function public.essay_material_documents() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not public.is_quality_operator() then raise exception 'MATERIAL_OPERATOR_REQUIRED' using errcode='42501'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(d) order by created_at desc),'[]'::jsonb) from essay_material_private.documents d);
end $$;
revoke all on function public.essay_material_register(text,text,integer),public.essay_material_documents() from public,anon;
grant execute on function public.essay_material_register(text,text,integer),public.essay_material_documents() to authenticated;
commit;
