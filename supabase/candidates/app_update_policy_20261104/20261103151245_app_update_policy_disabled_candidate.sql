-- LegendStudy APP update policy candidate. NOT APPLIED to Production or TEST.
-- Creates only isolated release configuration and an anonymous read-only projection.
-- Does not touch Auth, student facts, Credit/Ledger, payments, or other app settings.
-- Both platforms start disabled; local candidate builds are NOT public store releases.
begin;
set local lock_timeout='5s';
set local statement_timeout='60s';
select pg_advisory_xact_lock(hashtextextended('legendstudy-app-update-policy-v1',71661));
do $guard$ begin
 if current_user<>'postgres' or not (select rolbypassrls from pg_roles where rolname=current_user) then
  raise exception 'APP_UPDATE_REQUIRES_OWNER_POSTGRES';end if;
 if to_regnamespace('app_release_private') is not null or to_regprocedure('public.app_update_policy(text)') is not null then
  raise exception 'APP_UPDATE_POLICY_ALREADY_EXISTS_REVIEW_REQUIRED';end if;
end $guard$;

create schema app_release_private authorization postgres;
revoke all on schema app_release_private from public,anon,authenticated,service_role;

-- Same ordering as APP: 2..4 numeric version parts, padded to four, then build.
-- A malformed value returns NULL; it can never turn into a required update.
create function app_release_private.version_key(p_version text,p_build integer) returns integer[]
language plpgsql immutable set search_path='' as $function$
declare parts integer[];
begin
 if p_version is null or p_build is null or p_build<0
  or p_version !~ '^[0-9]{1,7}(\.[0-9]{1,7}){1,3}$' then return null;end if;
 parts=string_to_array(p_version,'.')::integer[];
 return array[parts[1],parts[2],coalesce(parts[3],0),coalesce(parts[4],0),p_build];
end $function$;
revoke all on function app_release_private.version_key(text,integer) from public,anon,authenticated,service_role;

create table app_release_private.platform_policy(
 platform text primary key check(platform in('ios','android')),
 enabled boolean not null default false,
 latest_version text,
 latest_build integer,
 minimum_supported_version text,
 minimum_supported_build integer,
 update_type text not null default 'OPTIONAL' check(update_type in('OPTIONAL','REQUIRED')),
 release_notes text not null default '' check(char_length(release_notes)+char_length(regexp_replace(release_notes,U&'[^\+010000-\+10FFFF]','','g'))<=2000),
 store_url text not null,
 -- Store publication and mandatory-minimum approval are independent explicit facts.
 store_release_verified boolean not null default false,
 verified_store_version text,
 verified_store_build integer,
 verified_at timestamptz,
 verification_reference text check(verification_reference is null or char_length(verification_reference) between 1 and 500),
 required_approved boolean not null default false,
 approved_minimum_version text,
 approved_minimum_build integer,
 required_approved_at timestamptz,
 approval_reference text check(approval_reference is null or char_length(approval_reference) between 1 and 500),
 constraint app_release_latest_pair check((latest_version is null and latest_build is null) or app_release_private.version_key(latest_version,latest_build) is not null),
 constraint app_release_minimum_pair check((minimum_supported_version is null and minimum_supported_build is null) or app_release_private.version_key(minimum_supported_version,minimum_supported_build) is not null),
 constraint app_release_verified_pair check((verified_store_version is null and verified_store_build is null) or app_release_private.version_key(verified_store_version,verified_store_build) is not null),
 constraint app_release_approved_pair check((approved_minimum_version is null and approved_minimum_build is null) or app_release_private.version_key(approved_minimum_version,approved_minimum_build) is not null),
 constraint app_release_minimum_order check(minimum_supported_version is null or (latest_version is not null and app_release_private.version_key(minimum_supported_version,minimum_supported_build)<=app_release_private.version_key(latest_version,latest_build))),
 constraint app_release_official_store check(store_url=case platform when 'ios' then 'https://apps.apple.com/us/app/레전드스터디/id6820826957' when 'android' then 'https://play.google.com/store/apps/details?id=com.legendstudy.app' end),
 constraint app_release_finite_dates check((verified_at is null or isfinite(verified_at)) and (required_approved_at is null or isfinite(required_approved_at)))
);
alter table app_release_private.platform_policy enable row level security;
alter table app_release_private.platform_policy force row level security;
revoke all on table app_release_private.platform_policy from public,anon,authenticated,service_role;

insert into app_release_private.platform_policy(platform,store_url) values
 ('ios','https://apps.apple.com/us/app/레전드스터디/id6820826957'),
 ('android','https://play.google.com/store/apps/details?id=com.legendstudy.app');

create function public.app_update_policy(p_platform text) returns jsonb
language plpgsql stable security definer set search_path='' as $function$
declare p app_release_private.platform_policy; latest integer[]; minimum integer[]; approved boolean; official_url text;
begin
 if p_platform is null or p_platform not in('ios','android') then return null;end if;
 select * into p from app_release_private.platform_policy where platform=p_platform;
 if not found or p.enabled is not true then return null;end if;
 official_url=case p_platform when 'ios' then 'https://apps.apple.com/us/app/레전드스터디/id6820826957' else 'https://play.google.com/store/apps/details?id=com.legendstudy.app' end;
 latest=app_release_private.version_key(p.latest_version,p.latest_build);
 minimum=app_release_private.version_key(p.minimum_supported_version,p.minimum_supported_build);
 if latest is null or p.update_type is null or p.update_type not in('OPTIONAL','REQUIRED') or p.store_url is distinct from official_url
  or p.release_notes is null or char_length(p.release_notes)+char_length(regexp_replace(p.release_notes,U&'[^\+010000-\+10FFFF]','','g'))>2000
  or ((p.minimum_supported_version is not null or p.minimum_supported_build is not null) and minimum is null)
  or (minimum is not null and minimum>latest)
  or p.store_release_verified is not true
  or p.verified_store_version is distinct from p.latest_version or p.verified_store_build is distinct from p.latest_build
  or p.verified_at is null or not isfinite(p.verified_at) or p.verified_at>statement_timestamp()
  or nullif(btrim(p.verification_reference),'') is null then return null;end if;
 approved=coalesce(p.update_type='REQUIRED' and p.required_approved and minimum is not null
  and p.approved_minimum_version=p.minimum_supported_version and p.approved_minimum_build=p.minimum_supported_build
  and p.required_approved_at is not null and isfinite(p.required_approved_at) and p.required_approved_at<=statement_timestamp()
  and nullif(btrim(p.approval_reference),'') is not null,false);
 return jsonb_build_object('version','app-update-policy-v1','platform',p.platform,
  'latest_version',p.latest_version,'latest_build',p.latest_build,
  'minimum_supported_version',p.minimum_supported_version,'minimum_supported_build',p.minimum_supported_build,
  'update_type',p.update_type,'release_notes',p.release_notes,'store_url',p.store_url,
  'enabled',true,'store_release_verified',true,'required_approved',approved,'verified_at',p.verified_at);
end $function$;
revoke all on function public.app_update_policy(text) from public,anon,authenticated,service_role;
grant execute on function public.app_update_policy(text) to anon,authenticated;

do $post$ begin
 if (select count(*) from app_release_private.platform_policy)<>2 or exists(select 1 from app_release_private.platform_policy where enabled or update_type<>'OPTIONAL' or latest_version is not null or latest_build is not null or minimum_supported_version is not null or minimum_supported_build is not null or store_release_verified or required_approved) then
  raise exception 'APP_UPDATE_DEFAULT_MUST_BE_DISABLED';end if;
 if not has_function_privilege('anon','public.app_update_policy(text)','EXECUTE') or not has_function_privilege('authenticated','public.app_update_policy(text)','EXECUTE') or has_function_privilege('service_role','public.app_update_policy(text)','EXECUTE') then
  raise exception 'APP_UPDATE_READ_RPC_ACL_INVALID';end if;
 if has_schema_privilege('anon','app_release_private','USAGE') or has_schema_privilege('authenticated','app_release_private','USAGE') or has_schema_privilege('service_role','app_release_private','USAGE') then
  raise exception 'APP_UPDATE_PRIVATE_SCHEMA_EXPOSED';end if;
end $post$;
notify pgrst,'reload schema';
commit;
