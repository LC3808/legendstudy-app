-- DESIGN ONLY / NOT APPROVED / NOT INSTALLABLE. 2026-11-25 PHASE A.
-- Owner must approve rules, retention, correction and backfill before a real migration.
-- Deliberate unconditional guard prevents accidental installation.
begin;
do $$ begin raise exception 'DESIGN_ONLY_OWNER_APPROVAL_REQUIRED'; end $$;

create schema if not exists badge_private;
revoke all on schema badge_private from public, anon, authenticated, service_role;

create table badge_private.catalog (
 badge_key text not null,
 rule_version integer not null check (rule_version > 0),
 kind text not null check (kind in ('BEHAVIOUR','GROWTH')),
 title text not null,
 grade text not null check (grade in ('Bronze','Silver','Gold','Platinum','Legend')),
 periodicity text not null check (periodicity in ('LIFETIME','KST_DAY','KST_MONTH')),
 definition jsonb not null,
 enabled boolean not null default false,
 created_at timestamptz not null default now(),
 primary key (badge_key, rule_version)
);
create table badge_private.awards (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 badge_key text not null,
 rule_version integer not null,
 award_key text not null default 'lifetime',
 achieved_at timestamptz,
 awarded_at timestamptz not null default now(),
 state text not null check (state in ('ACTIVE','RETRACTED')),
 evidence_digest text not null,
 observed_cutoff timestamptz not null,
 unique (user_id,badge_key,award_key),
 unique (user_id,id),
 foreign key (badge_key,rule_version) references badge_private.catalog
);
create table badge_private.award_events (
 id uuid primary key default gen_random_uuid(),
 award_id uuid not null references badge_private.awards(id) on delete cascade,
 event_type text not null check (event_type in ('AWARDED','RETRACTED','RESTORED')),
 reason text not null,
 source_revision bigint not null,
 recorded_at timestamptz not null default now()
);
create table badge_private.progress (
 user_id uuid not null references auth.users(id) on delete cascade,
 metric_key text not null,
 period_key text not null,
 metric_version integer not null,
 value_ms bigint not null check (value_ms >= 0),
 source_revision bigint not null,
 computed_at timestamptz not null,
 primary key(user_id,metric_key,period_key)
);
create table badge_private.profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 representative_award_id uuid,
 foreign key(user_id,representative_award_id)
   references badge_private.awards(user_id,id)
);
create table badge_private.recompute_jobs (
 user_id uuid primary key references auth.users(id) on delete cascade,
 dirty_from date not null,
 dirty_to date not null check (dirty_to >= dirty_from),
 source_revision bigint not null,
 processed_revision bigint not null default 0,
 state text not null check (state in ('PENDING','RUNNING','FAILED','DONE')),
 updated_at timestamptz not null default now()
);
alter table badge_private.catalog enable row level security;
alter table badge_private.awards enable row level security;
alter table badge_private.award_events enable row level security;
alter table badge_private.progress enable row level security;
alter table badge_private.profiles enable row level security;
alter table badge_private.recompute_jobs enable row level security;
revoke all on all tables in schema badge_private from public,anon,authenticated,service_role;

-- No RPC, trigger, INSERT seed or backfill is included or authorized.
-- Future own-reader RPC must use auth.uid(); admin mutation requires existing role check.
-- Future award writer must lock user, compare source_revision, enforce uniqueness and
-- commit award+event atomically. Representative selection must check own ACTIVE award.
-- Metric semantics are specified in wiki/study-badge-system-v1-design.md.
-- Retention/deletion of derived audit evidence must follow account deletion policy.
-- No policies granting direct access are proposed in this phase.
rollback;
