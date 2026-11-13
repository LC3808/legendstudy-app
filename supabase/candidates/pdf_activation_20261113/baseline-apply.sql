-- OWNER REVIEW ONLY. No public downloads are enabled by this candidate.
begin;
create schema material_download_private;
revoke all on schema material_download_private from public, anon, authenticated, service_role;
create table material_download_private.pilot_posts (
 content_item_id uuid primary key references public.content_items(id),
 source_url text not null unique,
 selected_at timestamptz not null default now()
);
create table material_download_private.permissions (
 revision bigint generated always as identity primary key,
 resource_id uuid not null references public.resources(id),
 source_resource_key text not null,
 state text not null default 'PENDING' check(state in ('PENDING','VIEW_ONLY','OFFICIAL_LINK','ALLOWED')),
 filename text,
 sha256 text check(sha256 ~ '^[a-f0-9]{64}$'),
 official_url text check(official_url ~ '^https://[a-zA-Z0-9.-]+(:443)?/[^[:space:]]*$'),
 rights_holder text,
 evidence_url text,
 owner_decision text,
 recorded_at timestamptz not null default now(),
 check(state not in ('ALLOWED','OFFICIAL_LINK') or (nullif(btrim(rights_holder),'') is not null and nullif(btrim(evidence_url),'') is not null and nullif(btrim(owner_decision),'') is not null)),
 check(state <> 'ALLOWED' or (sha256 is not null and filename is not null and filename ~ '^[a-zA-Z0-9가-힣_() .-]{1,150}\.pdf$')),
 check(state <> 'OFFICIAL_LINK' or official_url is not null)
);
create index on material_download_private.permissions(resource_id,revision desc);
alter table material_download_private.pilot_posts enable row level security;
alter table material_download_private.permissions enable row level security;
revoke all on all tables in schema material_download_private from public, anon, authenticated, service_role;
revoke all on all sequences in schema material_download_private from public, anon, authenticated, service_role;
create function material_download_private.immutable_permission() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'Append a new permission revision instead'; end $$;
create trigger permission_history before update or delete on material_download_private.permissions for each row execute function material_download_private.immutable_permission();
revoke all on function material_download_private.immutable_permission() from public;
create function public.resource_download_policy(p_resource_id uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select coalesce((
 select jsonb_build_object('state',p.state,'filename',p.filename,'sha256',p.sha256,'official_url',p.official_url)
 from public.resources r
 join public.content_items c on c.id=r.content_item_id and c.is_active and c.content_type='exam'
 join public.exams e on e.content_item_id=c.id and e.exam_type in ('csat','evaluation_mock','national_mock')
 join public.source_posts sp on sp.id=r.source_post_id and sp.id=c.source_post_id and sp.source='legendstudy' and sp.source_status='available'
 join material_download_private.pilot_posts pp on pp.content_item_id=c.id and pp.source_url=c.source_url
 join lateral (select * from material_download_private.permissions p0 where p0.resource_id=r.id order by revision desc limit 1) p on p.source_resource_key=r.source_resource_key
 where r.id=p_resource_id and r.is_active
 and (r.exam_subject_id is null or exists(select 1 from public.exam_subjects es where es.id=r.exam_subject_id and es.is_active))
 ), '{"state":"PENDING"}'::jsonb)
$$;
revoke all on function public.resource_download_policy(uuid) from public;
grant execute on function public.resource_download_policy(uuid) to anon,authenticated,service_role;
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='c3686e6b-eee1-522a-92ee-278c81bf513e' and source_url='https://legendstudy.com/1700' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='32513dd3-264e-54b7-9156-02b7743c2fa1' and source_url='https://legendstudy.com/1574' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='02ab1c5b-f469-53f0-9eb8-1ed2aea5a79e' and source_url='https://legendstudy.com/1649' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='68b84ef6-0d12-54dc-9dd6-9aea50f58a79' and source_url='https://legendstudy.com/1706' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='c968af3c-768c-5a0f-8eed-c14a9e83322c' and source_url='https://legendstudy.com/1710' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='c90d9fa1-ce5d-5383-a126-6e458e2e8f70' and source_url='https://legendstudy.com/1509' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='1ce76c57-5025-541b-b190-cdc7cf485c5b' and source_url='https://legendstudy.com/1618' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='5a70a5c1-1bc7-55b3-8240-02d0c7c4166f' and source_url='https://legendstudy.com/1487' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='dfaf04a5-7f35-5da6-9a86-4dc860c14f96' and source_url='https://legendstudy.com/1686' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='66d59401-acf9-59ce-b497-ccfb89a9adf2' and source_url='https://legendstudy.com/1516' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='6908d376-7494-53e1-8423-c30acd2b0b66' and source_url='https://legendstudy.com/1634' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='689a5f19-a1f7-5c22-8a4d-9e5ff3a0fe84' and source_url='https://legendstudy.com/1507' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='02e67848-cd05-5b3a-bb99-4de2e9198c2c' and source_url='https://legendstudy.com/1501' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='79113561-dbb5-52b7-a63b-65e761569ec5' and source_url='https://legendstudy.com/1525' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='b0f42638-ee2d-5934-a7ed-d721c9dc6755' and source_url='https://legendstudy.com/1483' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='c605afac-0339-53bf-be77-0d39a9188d51' and source_url='https://legendstudy.com/1665' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='eb59be72-aaf5-583e-871b-ab1211839ba4' and source_url='https://legendstudy.com/1485' and content_type='exam';
insert into material_download_private.pilot_posts(content_item_id,source_url) select id,source_url from public.content_items where id='1c960a5f-63ef-533b-8821-d848e37033cd' and source_url='https://legendstudy.com/1435' and content_type='exam';
commit;
