-- Owner-reviewed platform university master + Essay canonical foundation.
-- PREPARED / NOT APPLIED. Production execution remains Owner-gated.
-- PostgreSQL17; public.resources and public.set_updated_at() required.
-- No seed/backfill. Replay guards are not schema drift repair; run preflight first.
begin;

-- Platform-wide canonical university master, shared by Onboarding/MY/LAB,
-- admissions guides/results, School and Analytics. Never an Essay-only master.
create table if not exists public.universities (
    id uuid primary key default gen_random_uuid(),
    slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    name text not null check (btrim(name) <> ''),
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.essay_exams (
    id uuid primary key default gen_random_uuid(),
    university_id uuid not null references public.universities(id) on delete restrict,
    admission_year smallint not null check (admission_year between 1900 and 2200),
    -- Assigned once after identity reconciliation, never a post ID/title hash.
    exam_key text not null check (exam_key ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    exam_name text not null check (btrim(exam_name) <> ''),
    exam_kind text not null check (exam_kind in ('admission', 'mock', 'other')),
    campus text check (campus is null or btrim(campus) <> ''),
    admission_track text check (admission_track is null or btrim(admission_track) <> ''),
    field_or_division text check (field_or_division is null or btrim(field_or_division) <> ''),
    session_label text check (session_label is null or btrim(session_label) <> ''),
    -- Fields/session labels retain the university's wording; no detailed taxonomy.
    exam_date date,
    duration_minutes smallint check (duration_minutes > 0),
    question_count smallint check (question_count > 0),
    answer_length_text text,
    exam_format text,
    -- Origin of the factual metadata, NOT the extraction tool or review actor.
    provenance text check (provenance in ('official', 'legendstudy_derived', 'ai_generated')),
    metadata_resource_id uuid references public.resources(id) on delete restrict,
    official_source_url text check (official_source_url ~* '^https?://[^/[:space:]]+'),
    evidence_note text,
    verification_status text not null default 'review'
        check (verification_status in ('review', 'verified')),
    verified_at timestamptz,
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint essay_exams_identity unique (university_id, admission_year, exam_key),
    constraint essay_exams_verification check (
        (verification_status = 'review' and verified_at is null and not is_active)
        or (verification_status = 'verified' and verified_at is not null
            and provenance is not null and nullif(btrim(evidence_note), '') is not null
            and (metadata_resource_id is not null or official_source_url is not null))
    ),
    constraint essay_exams_official_evidence check (
        verification_status <> 'verified' or provenance <> 'official'
        or official_source_url is not null
    )
);

-- campus/track/field/session are context metadata, not identity constraints.
create index if not exists essay_exams_metadata_resource
    on public.essay_exams (metadata_resource_id);

create table if not exists public.essay_exam_resources (
    essay_exam_id uuid not null references public.essay_exams(id) on delete restrict,
    resource_id uuid not null references public.resources(id) on delete restrict,
    role text not null check (role in (
        'question', 'passage', 'exam_intent', 'scoring_criteria', 'model_answer',
        'example_answer', 'high_scoring_answer', 'explanation', 'guidebook', 'other'
    )),
    -- Origin of this evidence, independent of how a role was suggested.
    provenance text check (provenance in ('official', 'legendstudy_derived', 'ai_generated')),
    verification_status text not null default 'review'
        check (verification_status in ('review', 'verified')),
    -- Page/section/question-level citation, including non-contiguous locations.
    -- Example: PDF pp. 3-4; section II; question 2(a), passage B.
    -- A locator is not a Question entity or a machine-parsed question identity.
    -- Public citation only: never extracted answers, prompts or private rubrics.
    source_locator text,
    official_source_url text check (official_source_url ~* '^https?://[^/[:space:]]+'),
    evidence_note text,
    verified_at timestamptz,
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    primary key (essay_exam_id, resource_id, role),
    constraint essay_exam_resources_verification check (
        (verification_status = 'review' and verified_at is null and not is_active)
        or (verification_status = 'verified' and verified_at is not null
            and provenance is not null and nullif(btrim(evidence_note), '') is not null
            and nullif(btrim(source_locator), '') is not null)
    ),
    constraint essay_exam_resources_official_evidence check (
        verification_status <> 'verified' or provenance <> 'official'
        or official_source_url is not null
    )
);
create index if not exists essay_exam_resources_resource on public.essay_exam_resources(resource_id);

alter table public.universities enable row level security;
alter table public.essay_exams enable row level security;
alter table public.essay_exam_resources enable row level security;
revoke all on public.universities, public.essay_exams, public.essay_exam_resources
    from public, anon, authenticated;
grant select on public.universities, public.essay_exams, public.essay_exam_resources
    to anon, authenticated;
grant select, insert, update, delete on public.universities, public.essay_exams,
    public.essay_exam_resources to service_role;

-- Replay only replaces policies/triggers on these three NEW relations.
drop policy if exists universities_public_select on public.universities;
create policy universities_public_select on public.universities
    for select to anon, authenticated using (is_active);
drop policy if exists essay_exams_public_select on public.essay_exams;
create policy essay_exams_public_select on public.essay_exams
    for select to anon, authenticated using (
        is_active and verification_status = 'verified'
        and exists (select 1 from public.universities u
                    where u.id = essay_exams.university_id and u.is_active)
    );
drop policy if exists essay_exam_resources_public_select on public.essay_exam_resources;
create policy essay_exam_resources_public_select on public.essay_exam_resources
    for select to anon, authenticated using (
        is_active and verification_status = 'verified'
        and exists (select 1 from public.essay_exams e
                    where e.id = essay_exam_resources.essay_exam_id and e.is_active
                      and e.verification_status = 'verified')
        -- Invoker RLS on existing resources enforces its active content/subject.
        and exists (select 1 from public.resources r
                    where r.id = essay_exam_resources.resource_id and r.is_active)
    );

create or replace trigger universities_updated_at before update on public.universities
    for each row execute function public.set_updated_at();
create or replace trigger essay_exams_updated_at before update on public.essay_exams
    for each row execute function public.set_updated_at();
create or replace trigger essay_exam_resources_updated_at before update on public.essay_exam_resources
    for each row execute function public.set_updated_at();
commit;
