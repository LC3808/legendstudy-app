-- DRAFT ONLY: schema proposal, not yet applied to any Supabase project.
-- DO NOT EXECUTE in Day 3, including against a local database.
-- Owner review + explicit execution authorization required. See wiki/database.md.
-- Prerequisites: Supabase auth.users/auth.uid(), anon/authenticated/service_role;
-- no conflicting application tables; auth.users REFERENCES privilege for deployer.
-- Single forward migration, not a replay-safe initialization script.
begin;

create table public.source_posts (
    id uuid primary key default gen_random_uuid(),
    source text not null check (btrim(source) <> ''),
    external_post_id text not null check (btrim(external_post_id) <> ''),
    url text not null unique check (url ~* '^https?://[^/[:space:]]+'),
    title text not null check (btrim(title) <> ''),
    category text,
    source_published_at timestamptz,
    source_updated_at timestamptz,
    raw_excerpt text,
    raw_metadata jsonb not null default '{}'::jsonb
        check (jsonb_typeof(raw_metadata) = 'object'),
    content_hash text check (content_hash is null or content_hash ~ '^[0-9a-f]{64}$'),
    parser_version text,
    last_crawled_at timestamptz,
    source_status text not null default 'unknown'
        check (source_status in ('unknown', 'available', 'missing', 'error')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint source_posts_external_identity unique (source, external_post_id)
);

create table public.exams (
    id uuid primary key default gen_random_uuid(),
    source_post_id uuid not null references public.source_posts(id) on delete restrict,
    source_exam_key text not null check (source_exam_key ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    title text not null check (btrim(title) <> ''),
    -- year = actual calendar year; academic_year = source-labelled school/CSAT year.
    year smallint check (year between 1900 and 2200),
    academic_year smallint check (academic_year between 1900 and 2200),
    -- Nominal session month may differ from actual exam_date month (postponements).
    exam_month smallint check (exam_month between 1 and 12),
    exam_date date,
    -- Sorting proxy, not a claim about the historical exam date.
    sort_date date generated always as (
        case when exam_date is not null then exam_date
             when year is not null and exam_month is not null
                 then pg_catalog.make_date(year, exam_month, 1)
             when year is not null then pg_catalog.make_date(year, 1, 1)
             else null end
    ) stored,
    merged_into_exam_id uuid references public.exams(id) on delete restrict,
    grade_level smallint check (grade_level in (1, 2, 3)),
    raw_grade_label text,
    exam_type text check (exam_type in (
        'school_assessment', 'national_mock', 'evaluation_mock',
        'csat', 'preliminary', 'other'
    )),
    raw_exam_type text,
    exam_round text,
    curriculum_version text,
    normalization_note text,
    published_at timestamptz,
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint exams_merge_state check (
        merged_into_exam_id is null or (merged_into_exam_id <> id and not is_active)
    ),
    constraint exams_source_identity unique (source_post_id, source_exam_key),
    constraint exams_calendar_year_matches_date check (
        exam_date is null or year is null or extract(year from exam_date) = year
    )
);

create table public.subjects (
    id uuid primary key default gen_random_uuid(),
    code text not null check (code ~ '^[a-z0-9]+(_[a-z0-9]+)*$'),
    name text not null check (btrim(name) <> ''),
    category text,
    taxonomy_version text not null check (btrim(taxonomy_version) <> ''),
    curriculum_version text,
    parent_id uuid,
    is_active boolean not null default false,
    sort_order integer not null default 0 check (sort_order >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint subjects_versioned_code unique (taxonomy_version, code),
    constraint subjects_id_version unique (id, taxonomy_version),
    constraint subjects_parent_same_version foreign key (parent_id, taxonomy_version)
        references public.subjects(id, taxonomy_version) on delete restrict,
    constraint subjects_not_own_parent check (parent_id is null or parent_id <> id)
);

create table public.exam_subjects (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid not null references public.exams(id) on delete restrict,
    source_subject_key text not null check (btrim(source_subject_key) <> ''),
    subject_id uuid,
    raw_subject_label text,
    taxonomy_version text,
    mapping_status text not null default 'unmapped'
        check (mapping_status in ('unmapped', 'unmappable', 'provisional', 'verified')),
    mapping_confidence numeric(4,3) check (mapping_confidence between 0 and 1),
    mapping_note text,
    mapping_rule_version text,
    verified_at timestamptz,
    display_order integer not null default 0 check (display_order >= 0),
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint exam_subjects_source_identity unique (exam_id, source_subject_key),
    constraint exam_subjects_id_exam unique (id, exam_id),
    -- MATCH FULL: normalized subject and its version must both be NULL or valid.
    constraint exam_subjects_versioned_mapping foreign key (subject_id, taxonomy_version)
        references public.subjects(id, taxonomy_version) match full on delete restrict,
    constraint exam_subjects_mapping_state check (
        (mapping_status in ('unmapped', 'unmappable') and subject_id is null
            and taxonomy_version is null and mapping_confidence is null and verified_at is null)
        or
        (mapping_status = 'provisional' and subject_id is not null and taxonomy_version is not null
            and mapping_confidence is not null and verified_at is null)
        or
        (mapping_status = 'verified' and subject_id is not null and taxonomy_version is not null
            and verified_at is not null)
    )
);

create table public.resources (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid not null references public.exams(id) on delete restrict,
    exam_subject_id uuid,
    -- Actual provenance; may differ from the exam's primary source post.
    source_post_id uuid not null references public.source_posts(id) on delete restrict,
    source_resource_key text not null check (btrim(source_resource_key) <> ''),
    resource_type text not null default 'other' check (resource_type in (
        'question', 'answer', 'explanation', 'answer_explanation',
        'listening_audio', 'listening_script', 'grade_cut', 'reference', 'other'
    )),
    title text not null check (btrim(title) <> ''),
    source_label text,
    -- Preserve observed href exactly. Box links can be landing pages, not MP3 bytes.
    source_url text not null check (source_url ~* '^https?://[^/[:space:]]+'),
    link_kind text not null default 'unknown'
        check (link_kind in ('file', 'landing_page', 'unknown')),
    file_url text check (file_url is null or file_url ~* '^https?://[^/[:space:]]+'),
    mime_type text,
    file_extension text,
    file_size bigint check (file_size >= 0),
    link_status text not null default 'unchecked'
        check (link_status in ('unchecked', 'available', 'broken', 'restricted')),
    last_checked_at timestamptz,
    display_order integer not null default 0 check (display_order >= 0),
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint resources_source_identity unique (exam_id, source_post_id, source_resource_key),
    -- Enforces same-exam attachment; NULL subject means exam-wide material.
    constraint resources_subject_same_exam foreign key (exam_subject_id, exam_id)
        references public.exam_subjects(id, exam_id) on delete restrict
);

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text check (display_name is null or char_length(btrim(display_name)) between 1 and 80),
    grade_level smallint check (grade_level in (1, 2, 3)),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.bookmarks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    exam_id uuid not null references public.exams(id) on delete restrict,
    created_at timestamptz not null default now(),
    constraint bookmarks_user_exam unique (user_id, exam_id)
);

create table public.recent_views (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    exam_id uuid not null references public.exams(id) on delete restrict,
    viewed_at timestamptz not null default now(),
    constraint recent_views_user_exam unique (user_id, exam_id)
);

create table public.ingestion_quarantine (
    id uuid primary key default gen_random_uuid(),
    source_post_id uuid references public.source_posts(id) on delete restrict,
    kind text not null check (btrim(kind) <> ''),
    payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
    status text not null default 'open' check (status in ('open', 'resolved', 'ignored')),
    note text,
    created_at timestamptz not null default now(),
    resolved_at timestamptz,
    constraint ingestion_quarantine_resolution check (
        (status = 'open' and resolved_at is null)
        or (status in ('resolved', 'ignored') and resolved_at is not null)
    )
);

-- Shared update clock, no elevated privileges or client-callable RPC.
create function public.set_updated_at() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
    new.updated_at = pg_catalog.now();
    return new;
end;
$$;
revoke all on function public.set_updated_at() from public, anon, authenticated;

create trigger source_posts_updated_at before update on public.source_posts
    for each row execute function public.set_updated_at();
create trigger exams_updated_at before update on public.exams
    for each row execute function public.set_updated_at();
create trigger subjects_updated_at before update on public.subjects
    for each row execute function public.set_updated_at();
create trigger exam_subjects_updated_at before update on public.exam_subjects
    for each row execute function public.set_updated_at();
create trigger resources_updated_at before update on public.resources
    for each row execute function public.set_updated_at();
create trigger profiles_updated_at before update on public.profiles
    for each row execute function public.set_updated_at();

create function public.set_viewed_at() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
    if tg_op = 'UPDATE' then
        if new.user_id is distinct from old.user_id or new.exam_id is distinct from old.exam_id then
            raise exception 'recent view ownership and exam are immutable' using errcode = '23514';
        end if;
    end if;
    new.viewed_at = pg_catalog.now();
    return new;
end;
$$;
revoke all on function public.set_viewed_at() from public, anon, authenticated;
create trigger recent_views_viewed_at before insert or update on public.recent_views
    for each row execute function public.set_viewed_at();

-- Query-led indexes; PK/unique indexes already cover most parent FK lookups.
create index exams_active_feed on public.exams (sort_date desc nulls last, id desc)
    where is_active;
create index subjects_parent on public.subjects (parent_id, taxonomy_version);
create index exam_subjects_mapping on public.exam_subjects (subject_id, taxonomy_version);
create index resources_subject_exam on public.resources (exam_subject_id, exam_id);
create index resources_source_post on public.resources (source_post_id);
create index bookmarks_owner_recency on public.bookmarks (user_id, created_at desc, id desc);
create index bookmarks_exam on public.bookmarks (exam_id);
create index recent_views_owner_recency on public.recent_views (user_id, viewed_at desc, id desc);
create index recent_views_exam on public.recent_views (exam_id);

-- Explicit grants plus RLS: never rely on Supabase's default grants.
alter table public.ingestion_quarantine enable row level security;
alter table public.source_posts enable row level security;
alter table public.exams enable row level security;
alter table public.subjects enable row level security;
alter table public.exam_subjects enable row level security;
alter table public.resources enable row level security;
alter table public.profiles enable row level security;
alter table public.bookmarks enable row level security;
alter table public.recent_views enable row level security;

revoke all on table public.source_posts, public.exams, public.subjects,
    public.exam_subjects, public.resources, public.profiles, public.bookmarks,
    public.recent_views, public.ingestion_quarantine from public, anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;
-- Explicit projections only: SELECT * is intentionally not a client API.
-- is_active is public so invoker policy subqueries can check publication flags.
grant select (id, slug, title, year, academic_year, exam_month, exam_date, sort_date,
    grade_level, exam_type, exam_round, curriculum_version, published_at, is_active)
    on public.exams to anon, authenticated;
grant select (id, code, name, category, taxonomy_version, curriculum_version,
    parent_id, sort_order, is_active) on public.subjects to anon, authenticated;
grant select (id, exam_id, subject_id, raw_subject_label, taxonomy_version,
    mapping_status, display_order, is_active) on public.exam_subjects to anon, authenticated;
grant select (id, exam_id, exam_subject_id, resource_type, title, source_label,
    source_url, link_kind, file_url, mime_type, file_extension, file_size,
    display_order, is_active) on public.resources to anon, authenticated;
grant select, delete on table public.profiles, public.bookmarks, public.recent_views to authenticated;
grant insert (id, display_name, grade_level) on public.profiles to authenticated;
grant update (id, display_name, grade_level) on public.profiles to authenticated;
grant insert (user_id, exam_id) on public.bookmarks to authenticated;
grant insert (user_id, exam_id) on public.recent_views to authenticated;
-- PostgREST upsert may SET the unchanged conflict-key columns as well.
-- The trigger rejects actual changes to these keys.
grant update (user_id, exam_id) on public.recent_views to authenticated;
-- Trusted ingestion only, keys never enter Flutter. Supabase service_role has BYPASSRLS.
grant select, insert, update, delete on table public.source_posts, public.exams,
    public.subjects, public.exam_subjects, public.resources, public.profiles,
    public.bookmarks, public.recent_views, public.ingestion_quarantine to service_role;

create policy exams_public_active_select on public.exams
    for select to anon, authenticated using (is_active);
create policy subjects_public_active_select on public.subjects
    for select to anon, authenticated using (is_active);
create policy exam_subjects_public_active_select on public.exam_subjects
    for select to anon, authenticated using (
        is_active
        and exists (select 1 from public.exams e where e.id = exam_id and e.is_active)
    );
create policy resources_public_active_select on public.resources
    for select to anon, authenticated using (
        is_active
        and exists (select 1 from public.exams e where e.id = exam_id and e.is_active)
        and (exam_subject_id is null or exists (
            select 1 from public.exam_subjects es
            where es.id = exam_subject_id and es.exam_id = resources.exam_id and es.is_active
        ))
    );
-- No policy/grant exposes source_posts/ingestion_quarantine or permits client content writes.

create policy profiles_owner_select on public.profiles
    for select to authenticated using ((select auth.uid()) = id);
create policy profiles_owner_insert on public.profiles
    for insert to authenticated with check ((select auth.uid()) = id);
create policy profiles_owner_update on public.profiles
    for update to authenticated using ((select auth.uid()) = id)
    with check ((select auth.uid()) = id);
create policy profiles_owner_delete on public.profiles
    for delete to authenticated using ((select auth.uid()) = id);

-- Personal rows remain owner-readable/deletable when an exam is hidden;
-- clients must handle a missing joined exam as unavailable, not display cached content.
create policy bookmarks_owner_select on public.bookmarks
    for select to authenticated using ((select auth.uid()) = user_id);
create policy bookmarks_owner_insert on public.bookmarks
    for insert to authenticated with check (
        (select auth.uid()) = user_id
        and exists (select 1 from public.exams e where e.id = exam_id and e.is_active)
    );
create policy bookmarks_owner_delete on public.bookmarks
    for delete to authenticated using ((select auth.uid()) = user_id);

create policy recent_views_owner_select on public.recent_views
    for select to authenticated using ((select auth.uid()) = user_id);
create policy recent_views_owner_insert on public.recent_views
    for insert to authenticated with check (
        (select auth.uid()) = user_id
        and exists (select 1 from public.exams e where e.id = exam_id and e.is_active)
    );
create policy recent_views_owner_update on public.recent_views
    for update to authenticated using ((select auth.uid()) = user_id)
    with check (
        (select auth.uid()) = user_id
        and exists (select 1 from public.exams e where e.id = exam_id and e.is_active)
    );
create policy recent_views_owner_delete on public.recent_views
    for delete to authenticated using ((select auth.uid()) = user_id);

commit;
