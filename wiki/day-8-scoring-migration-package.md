# Day 8-D1 — Scoring migration execution package

**PREPARED / OWNER APPROVAL PENDING / NOT APPLIED.**
Target: LegendStudy / `stlhijzpjfgwwdgunlsd` only. Codex has not contacted production.
Each section is a full, standalone SQL block identical to its linked file. Review now;
execute only after Owner approval, one block at a time: Preflight -> migration -> Postflight.
Stop on any unexpected catalog/baseline result. Do not run rollback as a normal step.

[Final contract, expected grants, publication, parity and JWT acceptance](day-8-scoring-storage-proposal.md).
Preflight: PG17+, all parent/role checks valid, no proposed objects. Postflight: five RLS
tables, six policies, twelve functions, seven triggers, invoker view; expected grants,
SET NULL(study_session_id), zero new rows, all previous row and metadata digests unchanged
(except explicitly excluded additive Study unique). Catalog checks are not real JWT proof.
For large future datasets schedule the all-row baseline hashes outside busy periods.

## 1. Preflight — read only

Source: [mock_exam_scoring_preflight.sql](../supabase/verification/mock_exam_scoring_preflight.sql)

```sql
-- READ ONLY: confirm Dashboard is LegendStudy / stlhijzpjfgwwdgunlsd.
-- SQL cannot prove the Dashboard project ref; Owner checks it before execution.
-- Expected: PG17+, required parents/roles, no new object collisions, adequate deployer.
begin transaction read only;
set local timezone='UTC';
select current_database(),current_user,version(),current_setting('server_version_num')::integer >= 170000 as pg17_or_newer;
select to_regclass('auth.users') as auth_users,to_regprocedure('auth.uid()') as auth_uid,
 to_regclass('public.exam_subjects') as occurrence_parent,to_regclass('public.study_sessions') as study_parent;
select rolname,rolbypassrls from pg_roles where rolname in ('anon','authenticated','service_role') order by rolname;
select has_schema_privilege(current_user,'public','CREATE') as can_create,
 has_table_privilege(current_user,'auth.users','REFERENCES') as can_reference_users,
 pg_has_role(current_user,(select relowner from pg_class where oid='public.study_sessions'::regclass),'USAGE') as can_alter_study;
-- All rows here must be NULL / following collision queries empty. Stop otherwise.
select name,to_regclass('public.'||name) as must_be_null from unnest(array['answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers','mock_exam_scoring_availability']) name;
select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname in ('scoring_text','scoring_source_url','scoring_cutoffs_valid','scoring_normalize_answers','scoring_mcq5','scoring_question_guard','scoring_publication_guard','scoring_attempt_guard','scoring_answer_guard','scoring_attempt_consistency','fetch_own_mock_attempt','submit_mock_attempt');
select conname from pg_constraint where conrelid='public.study_sessions'::regclass and conname='study_sessions_id_owner';
select conrelid::regclass,conname,convalidated,pg_get_constraintdef(oid) from pg_constraint
 where conrelid in ('public.exam_subjects'::regclass,'public.resources'::regclass,'public.study_sessions'::regclass)
 order by conrelid,conname;
-- Compare these row counts/digests exactly before/after; no row contents printed.
select 'source_posts' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.source_posts t
union all
select 'content_items' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.content_items t
union all
select 'exams' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.exams t
union all
select 'subjects' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.subjects t
union all
select 'exam_subjects' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.exam_subjects t
union all
select 'resources' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.resources t
union all
select 'profiles' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.profiles t
union all
select 'bookmarks' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.bookmarks t
union all
select 'recent_views' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.recent_views t
union all
select 'ingestion_quarantine' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.ingestion_quarantine t
union all
select 'study_sessions' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.study_sessions t;
-- Existing constraints remain identical except the new Study composite UNIQUE.
select c.relname,c.relrowsecurity,c.relforcerowsecurity,
 (select md5(coalesce(string_agg(pg_get_constraintdef(k.oid),'|' order by k.conname),''))
  from pg_constraint k where k.conrelid=c.oid and k.conname <> 'study_sessions_id_owner') as constraint_digest,
 (select md5(coalesce(string_agg(concat_ws('|',p.policyname,p.roles,p.cmd,p.qual,p.with_check),'|' order by p.policyname),''))
  from pg_policies p where p.schemaname='public' and p.tablename=c.relname) as policy_digest,
 (select md5(coalesce(string_agg(concat_ws('|',g.grantee,g.privilege_type),'|' order by g.grantee,g.privilege_type),''))
  from information_schema.table_privileges g where g.table_schema='public' and g.table_name=c.relname) as table_grant_digest,
 (select md5(coalesce(string_agg(concat_ws('|',g.grantee,g.column_name,g.privilege_type),'|' order by g.grantee,g.column_name,g.privilege_type),''))
  from information_schema.column_privileges g where g.table_schema='public' and g.table_name=c.relname) as column_grant_digest
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in ('source_posts','content_items','exams','subjects','exam_subjects','resources','profiles','bookmarks','recent_views','ingestion_quarantine','study_sessions') order by c.relname;
commit;
```

## 2. Production migration — full SQL, NOT YET APPLIED

Source: [20260914000200_mock_exam_scoring.sql](../supabase/migrations/20260914000200_mock_exam_scoring.sql)

```sql
-- Day 8-D1: executable package, NOT applied to production by Codex.
-- Requires PostgreSQL 17 (column-specific FK SET NULL), existing LegendStudy migrations.
-- No exam/key fixtures. Owner must review preflight/postflight and apply separately.
begin;

create function public.scoring_text(p_value text, p_max integer)
returns boolean language sql immutable security invoker set search_path = ''
as $$ select p_value is not null and p_value = btrim(p_value, E' \t\n\r\f\013')
  and char_length(p_value) between 1 and p_max $$;

create function public.scoring_source_url(p_value text)
returns boolean language sql immutable security invoker set search_path = ''
as $$ select public.scoring_text(p_value,2048)
  and p_value ~ '^https?://[^/@?#[:space:]]+([/?#][^[:space:]]*)?$' $$;

create function public.scoring_cutoffs_valid(p_values smallint[], p_max integer)
returns boolean language plpgsql immutable security invoker set search_path = ''
as $$
declare i integer;
begin
  if p_values is null or array_ndims(p_values) is distinct from 1
     or array_lower(p_values,1) is distinct from 1 or cardinality(p_values) <> 9
     or p_max is null or p_max < 1 then return false; end if;
  for i in 1..9 loop
    if p_values[i] is null or p_values[i] < 0 or p_values[i] > p_max
       or (i > 1 and p_values[i] >= p_values[i-1]) then return false; end if;
  end loop;
  return p_values[9] = 0;
end;
$$;

-- MCQ5-v1 wire format: [{"question_number":1,"choice":2}, ...]. Missing = blank.
create function public.scoring_normalize_answers(p_answers jsonb, p_count integer)
returns jsonb language plpgsql immutable security invoker set search_path = ''
as $$
declare item jsonb; n integer; c integer; seen integer[] := '{}';
  result jsonb;
begin
  if p_count is null or p_count not between 1 and 100 or p_answers is null
     or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
  if jsonb_array_length(p_answers) > p_count then
    raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
  select jsonb_agg('null'::jsonb) into result from generate_series(1,p_count);
  for item in select value from jsonb_array_elements(p_answers) loop
    if jsonb_typeof(item) <> 'object' then
      raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
    if not (item ? 'question_number' and item ? 'choice')
       or item - array['question_number','choice'] <> '{}'::jsonb
       or jsonb_typeof(item->'question_number') <> 'number'
       or (item->>'question_number') !~ '^[0-9]{1,3}$'
       or jsonb_typeof(item->'choice') not in ('number','null') then
      raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
    n := (item->>'question_number')::integer;
    if n not between 1 and p_count or n = any(seen) then
      raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
    seen := array_append(seen,n);
    if item->'choice' <> 'null'::jsonb then
      if (item->>'choice') !~ '^[1-5]$' then
        raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
      c := (item->>'choice')::integer;
      result := jsonb_set(result,array[(n-1)::text],to_jsonb(c));
    end if;
  end loop;
  return result;
end;
$$;

-- Shared engine vector shape: ordered questions [[number,correct_choice,points],...].
create function public.scoring_mcq5(p_questions jsonb, p_answers jsonb,
  p_cutoffs smallint[], p_certainty text)
returns jsonb language plpgsql immutable security invoker set search_path = ''
as $$
declare q jsonb; i integer := 0; points integer; correct integer;
  raw integer := 0; maximum integer := 0; count_correct integer := 0;
  wrong jsonb := '[]'; blank jsonb := '[]'; grade integer := null;
begin
  if p_questions is null or jsonb_typeof(p_questions) <> 'array'
    or p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  if jsonb_array_length(p_questions) not between 1 and 100
    or jsonb_array_length(p_questions) <> jsonb_array_length(p_answers) then
    raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  for q in select value from jsonb_array_elements(p_questions) loop
    i := i+1;
    if jsonb_typeof(q) <> 'array' then
      raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
    if jsonb_array_length(q) <> 3 or q->0 <> to_jsonb(i)
       or jsonb_typeof(q->1) <> 'number' or (q->>1) !~ '^[1-5]$'
       or jsonb_typeof(q->2) <> 'number' or (q->>2) !~ '^[0-9]{1,3}$' then
      raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
    correct := (q->>1)::integer; points := (q->>2)::integer;
    if points not between 1 and 100 then
      raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
    maximum := maximum+points;
    if p_answers->(i-1) = 'null'::jsonb then
      blank := blank || to_jsonb(i);
    elsif jsonb_typeof(p_answers->(i-1)) <> 'number'
       or (p_answers->>(i-1)) !~ '^[1-5]$' then
      raise exception 'INVALID_ENGINE_INPUT' using errcode='22023';
    elsif (p_answers->>(i-1))::integer = correct then
      raw := raw+points; count_correct := count_correct+1;
    else wrong := wrong || to_jsonb(i); end if;
  end loop;
  if maximum > 1000 then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  if p_cutoffs is null then
    if p_certainty is distinct from 'unavailable' then
      raise exception 'INVALID_GRADE_INPUT' using errcode='22023'; end if;
  else
    if not public.scoring_cutoffs_valid(p_cutoffs,maximum)
       or p_certainty is null or p_certainty not in ('confirmed','estimated') then
      raise exception 'INVALID_GRADE_INPUT' using errcode='22023'; end if;
    for i in 1..9 loop if raw >= p_cutoffs[i] then grade := i; exit; end if; end loop;
  end if;
  return jsonb_build_object('raw_score',raw,'max_score',maximum,
    'question_count',jsonb_array_length(p_questions),'correct_count',count_correct,
    'incorrect_questions',wrong,'unanswered_questions',blank,
    'unanswered_count',jsonb_array_length(blank),'grade',grade,'grade_status',p_certainty);
end;
$$;

create table public.answer_key_versions (
  id uuid primary key default gen_random_uuid(),
  exam_subject_id uuid not null,
  content_item_id uuid not null,
  paper_variant text not null check (public.scoring_text(paper_variant,80)),
  version integer not null check (version > 0),
  status text not null default 'draft' check (status in ('draft','published','withdrawn')),
  is_current boolean not null default false,
  question_count smallint not null check (question_count between 1 and 100),
  max_score integer not null check (max_score between 1 and 1000),
  source_name text not null check (public.scoring_text(source_name,200)),
  source_url text not null check (public.scoring_source_url(source_url)),
  source_digest text not null check (source_digest ~ '^[0-9a-f]{64}$'),
  points_source_name text,
  points_source_url text,
  points_source_digest text,
  content_digest text check (content_digest ~ '^[0-9a-f]{64}$'),
  fetched_at timestamptz not null check (isfinite(fetched_at)),
  verified_at timestamptz check (isfinite(verified_at)),
  published_at timestamptz check (isfinite(published_at)),
  created_at timestamptz not null default now() check (isfinite(created_at)),
  corrected_at timestamptz check (isfinite(corrected_at)),
  correction_note text,
  draft_revision bigint not null default 0 check (draft_revision >= 0),
  constraint answer_key_versions_parent foreign key (exam_subject_id,content_item_id)
    references public.exam_subjects(id,content_item_id) on delete restrict,
  constraint answer_key_versions_family unique (exam_subject_id,paper_variant,version),
  constraint answer_key_versions_scope unique (id,exam_subject_id,paper_variant,max_score),
  constraint answer_key_versions_current check (not is_current or status='published'),
  constraint answer_key_versions_publication check (
    (status='draft' and published_at is null and content_digest is null)
    or (status in ('published','withdrawn') and verified_at is not null
      and published_at is not null and content_digest is not null
      and fetched_at <= verified_at and verified_at <= published_at)),
  constraint answer_key_versions_points_source check (
    (points_source_name is null and points_source_url is null and points_source_digest is null)
    or (points_source_name is not null and points_source_url is not null
      and points_source_digest is not null and public.scoring_text(points_source_name,200)
      and public.scoring_source_url(points_source_url) and points_source_digest ~ '^[0-9a-f]{64}$')),
  constraint answer_key_versions_correction check (
    (corrected_at is null and correction_note is null)
    or (corrected_at is not null and correction_note is not null
      and public.scoring_text(correction_note,1000)))
);
create unique index answer_key_versions_current_idx
  on public.answer_key_versions(exam_subject_id,paper_variant) where is_current;

create table public.exam_questions (
  answer_key_version_id uuid not null references public.answer_key_versions(id) on delete restrict,
  question_number smallint not null check (question_number between 1 and 100),
  answer_type text not null default 'multiple_choice' check (answer_type='multiple_choice'),
  correct_answer smallint not null check (correct_answer between 1 and 5),
  points smallint not null check (points between 1 and 100),
  primary key (answer_key_version_id,question_number)
);

-- Independent cutoff family; a compatible key is not its identity or lifecycle parent.
-- Nine array positions ARE grades 1..9: no duplicate grade and no sixth row table.
create table public.grade_cutoff_versions (
  id uuid primary key default gen_random_uuid(),
  exam_subject_id uuid not null,
  content_item_id uuid not null,
  paper_variant text not null check (public.scoring_text(paper_variant,80)),
  version integer not null check (version > 0),
  status text not null default 'draft' check (status in ('draft','published','withdrawn')),
  is_current boolean not null default false,
  basis text not null check (basis in ('raw_absolute','raw_estimate')),
  certainty text not null check (certainty in ('confirmed','estimated')),
  max_score integer not null check (max_score between 1 and 1000),
  minimum_scores smallint[] not null,
  source_name text not null check (public.scoring_text(source_name,200)),
  source_url text not null check (public.scoring_source_url(source_url)),
  source_digest text not null check (source_digest ~ '^[0-9a-f]{64}$'),
  content_digest text check (content_digest ~ '^[0-9a-f]{64}$'),
  fetched_at timestamptz not null check (isfinite(fetched_at)),
  verified_at timestamptz check (isfinite(verified_at)),
  published_at timestamptz check (isfinite(published_at)),
  created_at timestamptz not null default now() check (isfinite(created_at)),
  corrected_at timestamptz check (isfinite(corrected_at)),
  correction_note text,
  constraint grade_cutoff_versions_parent foreign key (exam_subject_id,content_item_id)
    references public.exam_subjects(id,content_item_id) on delete restrict,
  constraint grade_cutoff_versions_family unique (exam_subject_id,paper_variant,version),
  constraint grade_cutoff_versions_scope unique (id,exam_subject_id,paper_variant,max_score),
  constraint grade_cutoff_versions_current check (not is_current or status='published'),
  constraint grade_cutoff_versions_bands check (public.scoring_cutoffs_valid(minimum_scores,max_score)),
  constraint grade_cutoff_versions_basis check (
    (basis='raw_absolute' and certainty='confirmed') or (basis='raw_estimate' and certainty='estimated')),
  constraint grade_cutoff_versions_publication check (
    (status='draft' and published_at is null and content_digest is null)
    or (status in ('published','withdrawn') and verified_at is not null
      and published_at is not null and content_digest is not null
      and fetched_at <= verified_at and verified_at <= published_at)),
  constraint grade_cutoff_versions_correction check (
    (corrected_at is null and correction_note is null)
    or (corrected_at is not null and correction_note is not null
      and public.scoring_text(correction_note,1000)))
);
create unique index grade_cutoff_versions_current_idx
  on public.grade_cutoff_versions(exam_subject_id,paper_variant) where is_current;

alter table public.study_sessions add constraint study_sessions_id_owner unique(id,user_id);
create table public.mock_exam_attempts (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  study_session_id uuid unique,
  exam_subject_id uuid not null,
  paper_variant text not null,
  answer_key_version_id uuid not null,
  grade_cutoff_version_id uuid,
  scoring_version text not null check (scoring_version='mcq5-v1'),
  submitted_at timestamptz not null default now() check (isfinite(submitted_at)),
  created_at timestamptz not null default now() check (isfinite(created_at)),
  raw_score integer not null check (raw_score >= 0 and raw_score <= max_score),
  max_score integer not null check (max_score between 1 and 1000),
  question_count smallint not null check (question_count between 1 and 100),
  correct_count smallint not null check (correct_count >= 0),
  unanswered_count smallint not null check (unanswered_count >= 0),
  grade smallint check (grade between 1 and 9),
  grade_status text not null check (grade_status in ('unavailable','estimated','confirmed')),
  -- Stored exact normalized request for collision-safe idempotency after Study unlink.
  request_payload jsonb not null check (jsonb_typeof(request_payload)='object'),
  constraint mock_exam_attempts_counts check (correct_count+unanswered_count <= question_count),
  constraint mock_exam_attempts_grade check (
    (grade is null and grade_status='unavailable' and grade_cutoff_version_id is null)
    or (grade is not null and grade_status in ('estimated','confirmed') and grade_cutoff_version_id is not null)),
  constraint mock_exam_attempts_key foreign key (answer_key_version_id,exam_subject_id,paper_variant,max_score)
    references public.answer_key_versions(id,exam_subject_id,paper_variant,max_score) on delete restrict,
  constraint mock_exam_attempts_cutoff foreign key (grade_cutoff_version_id,exam_subject_id,paper_variant,max_score)
    references public.grade_cutoff_versions(id,exam_subject_id,paper_variant,max_score) on delete restrict,
  constraint mock_exam_attempts_study foreign key (study_session_id,user_id)
    references public.study_sessions(id,user_id) on delete set null (study_session_id),
  constraint mock_exam_attempts_id_key unique(id,answer_key_version_id)
);
create index mock_exam_attempts_owner_history_idx on public.mock_exam_attempts(user_id,submitted_at desc,id desc);
create index mock_exam_attempts_key_idx on public.mock_exam_attempts(answer_key_version_id);
create index mock_exam_attempts_cutoff_idx on public.mock_exam_attempts(grade_cutoff_version_id)
  where grade_cutoff_version_id is not null;

create table public.mock_exam_answers (
  attempt_id uuid not null,
  question_number smallint not null,
  answer_key_version_id uuid not null,
  submitted_answer smallint check (submitted_answer between 1 and 5),
  correct_answer_snapshot smallint not null check (correct_answer_snapshot between 1 and 5),
  points_snapshot smallint not null check (points_snapshot between 1 and 100),
  is_correct boolean generated always as (coalesce(submitted_answer=correct_answer_snapshot,false)) stored,
  awarded_points integer generated always as (
    case when submitted_answer=correct_answer_snapshot then points_snapshot else 0 end) stored,
  primary key (attempt_id,question_number),
  constraint mock_exam_answers_attempt foreign key (attempt_id,answer_key_version_id)
    references public.mock_exam_attempts(id,answer_key_version_id) on delete cascade,
  constraint mock_exam_answers_question foreign key (answer_key_version_id,question_number)
    references public.exam_questions(answer_key_version_id,question_number) on delete restrict
);

-- Serializes question edits against publication even under repeatable-read snapshots:
-- every question mutation creates a parent row version, not just an advisory lock.
create function public.scoring_question_guard()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
declare key_id uuid;
begin
  if TG_OP='UPDATE' and new.answer_key_version_id <> old.answer_key_version_id then
    raise exception 'IMMUTABLE_QUESTION_IDENTITY' using errcode='23514'; end if;
  key_id := case when TG_OP='DELETE' then old.answer_key_version_id else new.answer_key_version_id end;
  update public.answer_key_versions set draft_revision=draft_revision+1
    where id=key_id and published_at is null;
  if not found then raise exception 'KEY_IMMUTABLE' using errcode='23514'; end if;
  if TG_OP='DELETE' then return old; end if;
  return new;
end;
$$;
create trigger scoring_question_guard before insert or update or delete on public.exam_questions
  for each row execute function public.scoring_question_guard();

-- Keys and cutoffs share lifecycle immutability; INSERT must start as draft.
create function public.scoring_publication_guard()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
declare n integer; max_n integer; total integer; questions jsonb;
begin
  if TG_OP='DELETE' then
    if old.published_at is not null then raise exception 'PUBLISHED_IMMUTABLE' using errcode='23514'; end if;
    return old;
  end if;
  if TG_OP='INSERT' then
    if new.status <> 'draft' or new.published_at is not null or new.is_current
       or new.content_digest is not null then
      raise exception 'DRAFT_REQUIRED' using errcode='23514'; end if;
    return new;
  end if;
  if old.published_at is not null then
    if (to_jsonb(new)-array['status','is_current']) is distinct from
       (to_jsonb(old)-array['status','is_current']) or new.status='draft' then
      raise exception 'PUBLISHED_IMMUTABLE' using errcode='23514'; end if;
    return new;
  end if;
  if new.status='withdrawn' then raise exception 'PUBLISH_FIRST' using errcode='23514'; end if;
  if new.status='published' then
    if new.verified_at is null or new.verified_at > statement_timestamp() then
      raise exception 'VERIFICATION_REQUIRED' using errcode='23514'; end if;
    perform 1 from public.exam_subjects es join public.content_items c on c.id=es.content_item_id
      where es.id=new.exam_subject_id and es.content_item_id=new.content_item_id
        and es.is_active and c.is_active for share of es,c;
    if not found then raise exception 'INACTIVE_EXAM' using errcode='23514'; end if;
    if TG_TABLE_NAME='answer_key_versions' then
      select count(*),max(question_number),sum(points),
        jsonb_agg(jsonb_build_array(question_number,correct_answer,points) order by question_number)
        into n,max_n,total,questions from public.exam_questions where answer_key_version_id=new.id;
      if n <> new.question_count or max_n is distinct from n or total is distinct from new.max_score then
        raise exception 'INCOMPLETE_KEY' using errcode='23514'; end if;
    else questions := to_jsonb(new.minimum_scores); end if;
    new.published_at := statement_timestamp();
    -- SHA256 in pg_catalog; no extension dependency. Digest describes database JSONB serialization.
    new.content_digest := encode(sha256(convert_to(jsonb_build_object(
      'header',to_jsonb(new)-array['content_digest','status','is_current','draft_revision','created_at','published_at'],
      'data',questions)::text,'UTF8')),'hex');
  end if;
  return new;
end;
$$;
create trigger scoring_key_publication before insert or update or delete on public.answer_key_versions
  for each row execute function public.scoring_publication_guard();
create trigger scoring_cutoff_publication before insert or update or delete on public.grade_cutoff_versions
  for each row execute function public.scoring_publication_guard();

create function public.scoring_attempt_guard()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
begin
  if TG_OP='UPDATE' then
    -- Only FK-trigger unlink after the linked Study row has actually been deleted.
    if old.study_session_id is not null and new.study_session_id is null
       and (to_jsonb(new)-'study_session_id') = (to_jsonb(old)-'study_session_id')
       and not exists (select 1 from public.study_sessions where id=old.study_session_id) then return new; end if;
    raise exception 'ATTEMPT_IMMUTABLE' using errcode='23514';
  end if;
  perform 1 from public.answer_key_versions k join public.exam_subjects es on es.id=k.exam_subject_id
    join public.content_items c on c.id=k.content_item_id
    where k.id=new.answer_key_version_id and k.status='published' and es.is_active and c.is_active
    for share of k,es,c;
  if not found then raise exception 'KEY_UNAVAILABLE' using errcode='23514'; end if;
  if new.grade_cutoff_version_id is not null then
    perform 1 from public.grade_cutoff_versions where id=new.grade_cutoff_version_id and status='published' for share;
    if not found then raise exception 'CUTOFF_UNAVAILABLE' using errcode='23514'; end if;
  end if;
  if new.study_session_id is not null then
    perform 1 from public.study_sessions where id=new.study_session_id and user_id=new.user_id and mode='mock_exam' for share;
    if not found then raise exception 'INVALID_STUDY_LINK' using errcode='23514'; end if;
  end if;
  return new;
end;
$$;
create trigger scoring_attempt_guard before insert or update on public.mock_exam_attempts
  for each row execute function public.scoring_attempt_guard();

create function public.scoring_answer_guard()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
begin
  if TG_OP='UPDATE' then raise exception 'ANSWER_IMMUTABLE' using errcode='23514'; end if;
  if exists (select 1 from public.mock_exam_attempts where id=old.attempt_id) then
    raise exception 'DELETE_ATTEMPT_INSTEAD' using errcode='23514'; end if;
  return old;
end;
$$;
create trigger scoring_answer_guard before update or delete on public.mock_exam_answers
  for each row execute function public.scoring_answer_guard();

-- Deferred total/snapshot verification rejects partial trusted inserts too.
create function public.scoring_attempt_consistency()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
declare a public.mock_exam_attempts; k public.answer_key_versions; g public.grade_cutoff_versions;
  target_id uuid; questions jsonb; answers jsonb; result jsonb; n integer;
begin
  if TG_TABLE_NAME='mock_exam_attempts' then target_id := new.id;
  else target_id := new.attempt_id; end if;
  select * into a from public.mock_exam_attempts where id=target_id;
  if not found then return null; end if;
  select * into k from public.answer_key_versions where id=a.answer_key_version_id;
  select count(*),jsonb_agg(jsonb_build_array(q.question_number,q.correct_answer,q.points) order by q.question_number),
    jsonb_agg(to_jsonb(v.submitted_answer) order by q.question_number)
    into n,questions,answers from public.exam_questions q
    join public.mock_exam_answers v on v.answer_key_version_id=q.answer_key_version_id
      and v.question_number=q.question_number and v.attempt_id=a.id
    where q.answer_key_version_id=k.id
      and v.correct_answer_snapshot=q.correct_answer and v.points_snapshot=q.points;
  if n <> k.question_count then raise exception 'INCONSISTENT_ATTEMPT' using errcode='23514'; end if;
  if a.grade_cutoff_version_id is not null then select * into g from public.grade_cutoff_versions where id=a.grade_cutoff_version_id; end if;
  result := public.scoring_mcq5(questions,answers,g.minimum_scores,coalesce(g.certainty,'unavailable'));
  if a.request_payload->'answers' is distinct from answers
    or a.request_payload->>'key' is distinct from a.answer_key_version_id::text
    or a.request_payload->>'cutoff' is distinct from a.grade_cutoff_version_id::text
    or a.request_payload->>'engine' is distinct from a.scoring_version then
    raise exception 'INCONSISTENT_REQUEST' using errcode='23514'; end if;
  if a.raw_score <> (result->>'raw_score')::integer or a.max_score <> (result->>'max_score')::integer
    or a.correct_count <> (result->>'correct_count')::integer or a.question_count <> n
    or a.unanswered_count <> (result->>'unanswered_count')::integer
    or a.grade is distinct from (result->>'grade')::smallint
    or a.grade_status <> result->>'grade_status' then
    raise exception 'INCONSISTENT_ATTEMPT' using errcode='23514'; end if;
  return null;
end;
$$;
create constraint trigger scoring_attempt_consistency after insert on public.mock_exam_attempts
  deferrable initially deferred for each row execute function public.scoring_attempt_consistency();
create constraint trigger scoring_answers_consistency after insert on public.mock_exam_answers
  deferrable initially deferred for each row execute function public.scoring_attempt_consistency();

create function public.fetch_own_mock_attempt(p_attempt_id uuid)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare a public.mock_exam_attempts; result jsonb;
begin
  if auth.uid() is null then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;
  select * into a from public.mock_exam_attempts where id=p_attempt_id and user_id=auth.uid();
  if not found then return null; end if;
  select (to_jsonb(a)-'request_payload') || jsonb_build_object(
    'answers',(select jsonb_agg(to_jsonb(v) order by question_number) from public.mock_exam_answers v where attempt_id=a.id),
    'key_source',jsonb_build_object('version',k.version,'status',k.status,
      'source_name',k.source_name,'source_url',k.source_url,'verified_at',k.verified_at),
    'cutoff_source',case when g.id is null then null else jsonb_build_object('version',g.version,
      'status',g.status,'basis',g.basis,'certainty',g.certainty,'source_name',g.source_name,
      'source_url',g.source_url,'verified_at',g.verified_at) end)
    into result from public.answer_key_versions k left join public.grade_cutoff_versions g on g.id=a.grade_cutoff_version_id
    where k.id=a.answer_key_version_id;
  return result;
end;
$$;

create function public.submit_mock_attempt(p_attempt_id uuid, p_study_session_id uuid,
  p_answer_key_version_id uuid, p_grade_cutoff_version_id uuid, p_scoring_version text, p_answers jsonb)
returns jsonb language plpgsql volatile security definer set search_path = ''
as $$
declare owner_id uuid := auth.uid(); k public.answer_key_versions; g public.grade_cutoff_versions;
  prior public.mock_exam_attempts; normalized jsonb; request jsonb; questions jsonb; result jsonb;
begin
  if owner_id is null then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;
  if p_attempt_id is null or p_answer_key_version_id is null or p_scoring_version is distinct from 'mcq5-v1' then
    raise exception 'INVALID_REQUEST' using errcode='22023'; end if;
  -- UUID-scoped lock makes identical concurrent retry atomic; collision only serializes.
  perform pg_advisory_xact_lock(hashtextextended(p_attempt_id::text,0));
  select * into prior from public.mock_exam_attempts where id=p_attempt_id;
  if found then
    if prior.user_id <> owner_id then raise exception 'ATTEMPT_CONFLICT' using errcode='23505'; end if;
    normalized := public.scoring_normalize_answers(p_answers,prior.question_count);
  else
    select * into k from public.answer_key_versions where id=p_answer_key_version_id and status='published' for share;
    if not found then raise exception 'KEY_UNAVAILABLE' using errcode='23514'; end if;
    normalized := public.scoring_normalize_answers(p_answers,k.question_count);
  end if;
  request := jsonb_build_object('study_session_id',p_study_session_id,'key',p_answer_key_version_id,
    'cutoff',p_grade_cutoff_version_id,'engine',p_scoring_version,'answers',normalized);
  if prior.id is not null then
    if prior.request_payload <> request then raise exception 'ATTEMPT_CONFLICT' using errcode='23505'; end if;
    return public.fetch_own_mock_attempt(prior.id);
  end if;
  if p_grade_cutoff_version_id is not null then
    select * into g from public.grade_cutoff_versions where id=p_grade_cutoff_version_id and status='published'
      and exam_subject_id=k.exam_subject_id and paper_variant=k.paper_variant and max_score=k.max_score for share;
    if not found then raise exception 'CUTOFF_UNAVAILABLE' using errcode='23514'; end if;
  end if;
  select jsonb_agg(jsonb_build_array(question_number,correct_answer,points) order by question_number)
    into questions from public.exam_questions where answer_key_version_id=k.id;
  result := public.scoring_mcq5(questions,normalized,g.minimum_scores,coalesce(g.certainty,'unavailable'));
  insert into public.mock_exam_attempts(id,user_id,study_session_id,exam_subject_id,paper_variant,
    answer_key_version_id,grade_cutoff_version_id,scoring_version,raw_score,max_score,
    question_count,correct_count,unanswered_count,grade,grade_status,request_payload)
  values(p_attempt_id,owner_id,p_study_session_id,k.exam_subject_id,k.paper_variant,k.id,g.id,p_scoring_version,
    (result->>'raw_score')::integer,(result->>'max_score')::integer,k.question_count,
    (result->>'correct_count')::smallint,(result->>'unanswered_count')::smallint,
    (result->>'grade')::smallint,result->>'grade_status',request);
  insert into public.mock_exam_answers(attempt_id,question_number,answer_key_version_id,
    submitted_answer,correct_answer_snapshot,points_snapshot)
  select p_attempt_id,question_number,k.id,(normalized->>(question_number-1))::smallint,correct_answer,points
    from public.exam_questions where answer_key_version_id=k.id;
  return public.fetch_own_mock_attempt(p_attempt_id);
end;
$$;

-- RLS follows existing active occurrence/content policies. No boolean availability drift.
alter table public.answer_key_versions enable row level security;
revoke all on table public.answer_key_versions from public, anon, authenticated, service_role;
alter table public.exam_questions enable row level security;
revoke all on table public.exam_questions from public, anon, authenticated, service_role;
alter table public.grade_cutoff_versions enable row level security;
revoke all on table public.grade_cutoff_versions from public, anon, authenticated, service_role;
alter table public.mock_exam_attempts enable row level security;
revoke all on table public.mock_exam_attempts from public, anon, authenticated, service_role;
alter table public.mock_exam_answers enable row level security;
revoke all on table public.mock_exam_answers from public, anon, authenticated, service_role;
create policy answer_key_versions_public_select on public.answer_key_versions for select to anon, authenticated
  using (status='published' and exists (select 1 from public.exam_subjects es
    join public.content_items c on c.id=es.content_item_id
    where es.id=answer_key_versions.exam_subject_id and es.content_item_id=answer_key_versions.content_item_id and es.is_active and c.is_active));
create policy grade_cutoff_versions_public_select on public.grade_cutoff_versions for select to anon, authenticated
  using (status='published' and exists (select 1 from public.exam_subjects es
    join public.content_items c on c.id=es.content_item_id
    where es.id=grade_cutoff_versions.exam_subject_id and es.content_item_id=grade_cutoff_versions.content_item_id and es.is_active and c.is_active));
create policy exam_questions_public_select on public.exam_questions for select to anon, authenticated
  using (exists (select 1 from public.answer_key_versions k where k.id=exam_questions.answer_key_version_id));
create policy mock_exam_attempts_owner_select on public.mock_exam_attempts for select to authenticated using ((select auth.uid())=user_id);
create policy mock_exam_attempts_owner_delete on public.mock_exam_attempts for delete to authenticated using ((select auth.uid())=user_id);
create policy mock_exam_answers_owner_select on public.mock_exam_answers for select to authenticated
  using (exists (select 1 from public.mock_exam_attempts a where a.id=mock_exam_answers.attempt_id and a.user_id=(select auth.uid())));

-- Invoker view obeys underlying column grants + RLS. Query by occurrence and variant.
create view public.mock_exam_scoring_availability with (security_invoker=true) as
select es.id as exam_subject_id, k.paper_variant, k.id as answer_key_version_id,
  k.version as answer_key_version, k.content_digest, k.question_count, k.max_score,
  case when k.id is null then 'timer_only' else 'scoring_available' end as availability,
  g.id as grade_cutoff_version_id, g.version as grade_cutoff_version,
  coalesce(g.certainty,'unavailable') as grade_status, 'mcq5-v1'::text as scoring_version
from public.exam_subjects es
left join public.answer_key_versions k on k.exam_subject_id=es.id and k.is_current and k.status='published'
left join public.grade_cutoff_versions g on g.exam_subject_id=k.exam_subject_id
  and g.paper_variant=k.paper_variant and g.max_score=k.max_score and g.is_current and g.status='published';
revoke all on public.mock_exam_scoring_availability from public,anon,authenticated,service_role;
grant select on public.mock_exam_scoring_availability to anon,authenticated,service_role;

grant select(id,exam_subject_id,content_item_id,paper_variant,version,status,is_current,
  question_count,max_score,source_name,source_url,source_digest,points_source_name,
  points_source_url,points_source_digest,content_digest,fetched_at,verified_at,published_at)
  on public.answer_key_versions to anon,authenticated;
grant select on public.exam_questions to anon,authenticated;
grant select(id,exam_subject_id,content_item_id,paper_variant,version,status,is_current,
  basis,certainty,max_score,minimum_scores,source_name,source_url,source_digest,
  content_digest,fetched_at,verified_at,published_at) on public.grade_cutoff_versions to anon,authenticated;
grant select(id,user_id,study_session_id,exam_subject_id,paper_variant,answer_key_version_id,
  grade_cutoff_version_id,scoring_version,submitted_at,created_at,raw_score,max_score,
  question_count,correct_count,unanswered_count,grade,grade_status) on public.mock_exam_attempts to authenticated;
grant delete on public.mock_exam_attempts to authenticated;
grant select on public.mock_exam_answers to authenticated;
-- Existing service_role contracts are untouched; new reviewed content DML is guarded.
grant select,insert,update,delete on public.answer_key_versions,public.exam_questions,public.grade_cutoff_versions to service_role;
grant select,delete on public.mock_exam_attempts to service_role;
grant select on public.mock_exam_answers to service_role;
revoke all on function public.scoring_text(text,integer) from public,anon,authenticated,service_role;
revoke all on function public.scoring_source_url(text) from public,anon,authenticated,service_role;
revoke all on function public.scoring_cutoffs_valid(smallint[],integer) from public,anon,authenticated,service_role;
revoke all on function public.scoring_normalize_answers(jsonb,integer) from public,anon,authenticated,service_role;
revoke all on function public.scoring_mcq5(jsonb,jsonb,smallint[],text) from public,anon,authenticated,service_role;
revoke all on function public.scoring_question_guard() from public,anon,authenticated,service_role;
revoke all on function public.scoring_publication_guard() from public,anon,authenticated,service_role;
revoke all on function public.scoring_attempt_guard() from public,anon,authenticated,service_role;
revoke all on function public.scoring_answer_guard() from public,anon,authenticated,service_role;
revoke all on function public.scoring_attempt_consistency() from public,anon,authenticated,service_role;
revoke all on function public.fetch_own_mock_attempt(uuid) from public,anon,authenticated,service_role;
revoke all on function public.submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.scoring_text(text,integer) to service_role;
grant execute on function public.scoring_source_url(text) to service_role;
grant execute on function public.scoring_cutoffs_valid(smallint[],integer) to service_role;
grant execute on function public.fetch_own_mock_attempt(uuid) to authenticated;
grant execute on function public.submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb) to authenticated;

notify pgrst, 'reload schema';
commit;
```

## 3. Postflight — read only

Source: [mock_exam_scoring_postflight.sql](../supabase/verification/mock_exam_scoring_postflight.sql)

```sql
-- READ ONLY: run after the exact migration, same LegendStudy project.
-- Expected: five RLS tables, six policies, twelve functions, seven triggers,
-- one security_invoker view; no new rows. Compare baseline digests to preflight.
begin transaction read only;
set local timezone='UTC';
select table_name,column_name,data_type,is_nullable,is_generated,generation_expression
 from information_schema.columns where table_schema='public' and table_name in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by table_name,ordinal_position;
select c.relname,c.relrowsecurity,c.relforcerowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relname in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by c.relname;
select conrelid::regclass,conname,convalidated,pg_get_constraintdef(oid) from pg_constraint
 where conrelid in (select oid from pg_class where relnamespace='public'::regnamespace and relname in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers'))
 or (conrelid='public.study_sessions'::regclass and conname='study_sessions_id_owner') order by conrelid,conname;
select tablename,indexname,indexdef from pg_indexes where schemaname='public'
 and (tablename in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') or indexname='study_sessions_id_owner') order by tablename,indexname;
select tablename,policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' and tablename in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by tablename,policyname;
select p.oid::regprocedure,p.provolatile,p.prosecdef,p.proconfig,pg_get_userbyid(p.proowner) as owner,
 has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as auth_execute,
 has_function_privilege('service_role',p.oid,'EXECUTE') as backend_execute
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('scoring_text','scoring_source_url','scoring_cutoffs_valid','scoring_normalize_answers','scoring_mcq5','scoring_question_guard','scoring_publication_guard','scoring_attempt_guard','scoring_answer_guard','scoring_attempt_consistency','fetch_own_mock_attempt','submit_mock_attempt') order by p.proname;
select c.relname,t.tgname,t.tgenabled,t.tgdeferrable,t.tginitdeferred,pg_get_triggerdef(t.oid)
 from pg_trigger t join pg_class c on c.oid=t.tgrelid where not t.tgisinternal and c.relnamespace='public'::regnamespace
 and c.relname in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by c.relname,t.tgname;
select table_name,grantee,privilege_type from information_schema.table_privileges
 where table_schema='public' and table_name in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by 1,2,3;
select table_name,grantee,column_name,privilege_type from information_schema.column_privileges
 where table_schema='public' and table_name in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by 1,2,3,4;
select relname,reloptions,pg_get_viewdef(oid,true) from pg_class where oid='public.mock_exam_scoring_availability'::regclass;
select has_table_privilege('authenticated','public.mock_exam_attempts','INSERT') as must_be_false_insert,
 has_table_privilege('authenticated','public.mock_exam_attempts','UPDATE') as must_be_false_update,
 has_table_privilege('authenticated','public.mock_exam_attempts','DELETE') as must_be_true_delete,
 has_any_column_privilege('anon','public.mock_exam_attempts','SELECT') as must_be_false_anon_personal,
 has_any_column_privilege('authenticated','public.mock_exam_answers','INSERT') as must_be_false_answer_insert;
-- Pure synthetic computation, no INSERT, not a real exam key/cutoff.
select public.scoring_mcq5('[[1,1,2],[2,2,3],[3,3,4]]','[1,5,null]',null,'unavailable') as expected_raw2_max9_correct1_blank1;
select 'answer_key_versions' as relation,count(*) as must_be_zero from public.answer_key_versions
union all
select 'exam_questions' as relation,count(*) as must_be_zero from public.exam_questions
union all
select 'grade_cutoff_versions' as relation,count(*) as must_be_zero from public.grade_cutoff_versions
union all
select 'mock_exam_attempts' as relation,count(*) as must_be_zero from public.mock_exam_attempts
union all
select 'mock_exam_answers' as relation,count(*) as must_be_zero from public.mock_exam_answers;
-- Compare these row counts/digests exactly before/after; no row contents printed.
select 'source_posts' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.source_posts t
union all
select 'content_items' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.content_items t
union all
select 'exams' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.exams t
union all
select 'subjects' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.subjects t
union all
select 'exam_subjects' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.exam_subjects t
union all
select 'resources' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.resources t
union all
select 'profiles' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.profiles t
union all
select 'bookmarks' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.bookmarks t
union all
select 'recent_views' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.recent_views t
union all
select 'ingestion_quarantine' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.ingestion_quarantine t
union all
select 'study_sessions' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.study_sessions t;
-- Existing constraints remain identical except the new Study composite UNIQUE.
select c.relname,c.relrowsecurity,c.relforcerowsecurity,
 (select md5(coalesce(string_agg(pg_get_constraintdef(k.oid),'|' order by k.conname),''))
  from pg_constraint k where k.conrelid=c.oid and k.conname <> 'study_sessions_id_owner') as constraint_digest,
 (select md5(coalesce(string_agg(concat_ws('|',p.policyname,p.roles,p.cmd,p.qual,p.with_check),'|' order by p.policyname),''))
  from pg_policies p where p.schemaname='public' and p.tablename=c.relname) as policy_digest,
 (select md5(coalesce(string_agg(concat_ws('|',g.grantee,g.privilege_type),'|' order by g.grantee,g.privilege_type),''))
  from information_schema.table_privileges g where g.table_schema='public' and g.table_name=c.relname) as table_grant_digest,
 (select md5(coalesce(string_agg(concat_ws('|',g.grantee,g.column_name,g.privilege_type),'|' order by g.grantee,g.column_name,g.privilege_type),''))
  from information_schema.column_privileges g where g.table_schema='public' and g.table_name=c.relname) as column_grant_digest
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in ('source_posts','content_items','exams','subjects','exam_subjects','resources','profiles','bookmarks','recent_views','ingestion_quarantine','study_sessions') order by c.relname;
commit;
```

## 4. Rollback — explicit Owner decision, empty scoring storage only

Source: [mock_exam_scoring_rollback.sql](../supabase/verification/mock_exam_scoring_rollback.sql)

```sql
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
```

## Local verification reproduction

No production URL/password accepted by the local runner. Install test-only dependencies
outside the repository; no Flutter dependency change:

```sh
npm install --prefix /tmp/legendstudy-scoring-pg @electric-sql/pglite@0.3.14
PGLITE_MODULE=/tmp/legendstudy-scoring-pg/node_modules/@electric-sql/pglite/dist/index.js node tool/test_scoring_storage.mjs
```

Use the existing `supabase/review/requirements.txt` (pglast8.4) in a local Python venv,
then `python supabase/review/check_scoring_storage.py` for grammar/scope/package checks.
The local role simulation is not real Auth/JWT acceptance. Parallel sessions, REST/RPC
schema cache, real source verification and future Dart engine parity remain separate gates.
