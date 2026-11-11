-- READ ONLY, future C/D only. C is currently HOLD and its tables do not exist in production.
select count(*) sources from public.university_official_sources;
select status,count(*) revisions from public.university_news_revisions group by status;
select count(*) duplicate_revisions from (select series_key,revision from public.university_news_revisions group by 1,2 having count(*)>1) d;
select count(*) bad_source_hosts from public.university_news_revisions n left join public.university_official_sources s using(university_id,source_host) where s.university_id is null;
select count(*) malformed_evidence from public.university_news_revisions where source_sha256 !~ '^[a-f0-9]{64}$' or btrim(source_archive_key)='' or btrim(source_locator)='' or btrim(source_title)='' or btrim(title)='';
select count(*) bad_identity from public.university_news_revisions where (kind='schedule' and academic_year is null) or (scope in ('track','division') and (nullif(btrim(admission_round),'') is null or nullif(btrim(admission_type),'') is null)) or (scope='division' and nullif(btrim(department_name),'') is null);
select count(*) future_verification from public.university_news_revisions where verified_at>now();
select count(*) expired_latest from (select distinct on(series_key) * from public.university_news_revisions order by series_key,revision desc) n where status='verified' and expires_at<=now();
select c.relname,c.relrowsecurity from pg_class c where c.oid in ('public.university_official_sources'::regclass,'public.university_news_revisions'::regclass);
select role_name,has_function_privilege(role_name,'public.university_news_feed(uuid[],integer,timestamptz)','EXECUTE') can_read_rpc,
has_table_privilege(role_name,'public.university_news_revisions','SELECT') can_select,
has_table_privilege(role_name,'public.university_news_revisions','INSERT') can_insert,
has_table_privilege(role_name,'public.university_news_revisions','UPDATE') can_update,
has_table_privilege(role_name,'public.university_news_revisions','DELETE') can_delete,
has_table_privilege(role_name,'public.university_news_revisions','TRUNCATE') can_truncate
from (values('anon'),('authenticated')) r(role_name);
-- Real URL ownership, current official notice amendments, exact track/division mapping,
-- PDF SHA256/archive retrieval, and corrected concurrent pagination require separate verification.
