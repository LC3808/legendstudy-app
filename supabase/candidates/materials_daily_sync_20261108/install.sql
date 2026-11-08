-- CANDIDATE ONLY. Owner approval required. No existing content mutations.
begin;
create role legendstudy_material_sync login nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
-- Password is provisioned separately via a private parameterized admin session.
create schema ingestion_ops;
revoke all on schema ingestion_ops from public;
grant usage on schema ingestion_ops, public to legendstudy_material_sync;
create table ingestion_ops.config (
 singleton boolean primary key default true check(singleton),
 enabled boolean not null default false,
 new_since timestamptz not null
);
-- Current DB baseline, never empty local state or sitemap-wide backfill.
insert into ingestion_ops.config(singleton,new_since)
 select true,max(source_published_at) from public.source_posts where source='legendstudy';
create table ingestion_ops.runs (
 id uuid primary key, trigger_name text not null,
 started_at timestamptz not null default now(), finished_at timestamptz,
 status text not null check(status in ('running','success','partial','failed','interrupted','rolled_back')),
 summary jsonb
);
create table ingestion_ops.changes (
 id bigint generated always as identity primary key,
 run_id uuid not null references ingestion_ops.runs(id),post_id text not null,
 table_name text not null check(table_name in ('source_posts','content_items','exams','exam_subjects','resources')),
 row_id uuid not null,before_row jsonb,after_row jsonb not null,
 created_at timestamptz not null default now()
);
create table ingestion_ops.observations (
 post_id text primary key,lastmod text,status text not null,error_code text,
 observed_at timestamptz not null,last_success_at timestamptz
);
revoke all on all tables in schema ingestion_ops from public,anon,authenticated;
revoke all on all sequences in schema ingestion_ops from public,anon,authenticated;
alter table ingestion_ops.config enable row level security;
alter table ingestion_ops.runs enable row level security;
alter table ingestion_ops.changes enable row level security;
alter table ingestion_ops.observations enable row level security;
create policy sync_config on ingestion_ops.config for select to legendstudy_material_sync using(true);
create policy sync_runs on ingestion_ops.runs to legendstudy_material_sync using(true) with check(true);
create policy sync_changes on ingestion_ops.changes to legendstudy_material_sync using(true) with check(true);
create policy sync_observations on ingestion_ops.observations to legendstudy_material_sync using(true) with check(true);
grant select on ingestion_ops.config to legendstudy_material_sync;
grant select,insert,update on ingestion_ops.runs,ingestion_ops.observations to legendstudy_material_sync;
grant select,insert on ingestion_ops.changes to legendstudy_material_sync;
grant usage on sequence ingestion_ops.changes_id_seq to legendstudy_material_sync;
grant select,insert on public.source_posts,public.content_items,public.exams,public.exam_subjects,public.resources to legendstudy_material_sync;
grant update(title,category,source_published_at,source_updated_at,content_hash,parser_version,last_crawled_at,source_status) on public.source_posts to legendstudy_material_sync;
grant update(title,published_at,source_updated_at) on public.content_items to legendstudy_material_sync;
grant update(title,source_label,source_url,resource_type,file_extension,display_order,file_url,mime_type,file_size,link_status,last_checked_at,link_kind,is_active) on public.resources to legendstudy_material_sync;
create policy material_sync_worker on public.source_posts to legendstudy_material_sync using(source='legendstudy') with check(source='legendstudy');
create policy material_sync_worker on public.content_items to legendstudy_material_sync using(true) with check(true);
create policy material_sync_worker on public.exams to legendstudy_material_sync using(true) with check(true);
create policy material_sync_worker on public.exam_subjects to legendstudy_material_sync using(true) with check(true);
create policy material_sync_worker on public.resources to legendstudy_material_sync using(true) with check(true);
commit;
