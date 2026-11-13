-- Logged monitoring SELECT; evidence only, do not execute as a health probe.
with normalized_pg_stat_statements as (
    select
        calls,
        -- Truncate query by 10000 characters, because likely we don't need more than that in WHERE clauses
        lower(regexp_replace(trim(left(query, 10000)), E'\\s+', ' ', 'g')) as query
    from
        extensions.pg_stat_statements
    where
      userid not in (
        select oid
        from   pg_roles
        where  rolname in ('authenticator', 'pgbouncer', 'supabase_admin', 'supabase_storage_admin')
      )
      and not pg_is_in_recovery()
)

select
    coalesce(sum(calls), 0) as user_queries_total
from
    normalized_pg_stat_statements
where
    -- Some of the more generic queries below are categorized under the most
    -- likely known source, but may possibly come from some other source.
    query not in (
        -- auth
        'insert into schema_migrations (version) values ($1)',
        'insert into schema_migrations (version) values (''00'')',
        'select * from schema_migrations',
        'select exists (select schema_migrations.* from schema_migrations as schema_migrations where version = $1)',
        'show max_connections',
        -- dashboard
        'select pid, query, query_start from pg_stat_activity where state = $1 and datname = $2',
        -- dashboard: storage
        'select "id" from "buckets" where "id" = $1 and "public" = $2 limit $3',
        'select "id", "file_size_limit", "allowed_mime_types" from "buckets" where "id" = $1 limit $2',
        'select "id", "name", "public", "owner", "created_at", "updated_at", "file_size_limit", "allowed_mime_types" from "buckets"',
        'select "id", "public" from "buckets" where "id" = $1 and "public" = $2 limit $3',
        'select "id", "version" from "objects" where "name" = $1 and "bucket_id" = $2 limit $3',
        'select id from storage.buckets limit $1',
        'select id from storage.buckets limit 1',
        -- pg_cron
        'delete from cron.job_run_details where end_time < now() - interval $1',
        'insert into cron.job_run_details (jobid, runid, database, username, command, status) values ($1,$2,$3,$4,$5,$6)',
        -- pg-meta
        'select e.name, n.nspname as schema, e.default_version, x.extversion as installed_version, e.comment from pg_available_extensions() e(name, default_version, comment) left join pg_extension x on e.name = x.extname left join pg_namespace n on x.extnamespace = n.oid',
        -- pg_net
        'with rows as ( select ctid from net._http_response where created < now() - $1 order by created limit $2 ) delete from net._http_response r using rows where r.ctid = rows.ctid',
        -- version of query above before https://github.com/supabase/pg_net/commit/eaa721e11761da07d01fc04b5114c90cd7973b83
        'with rows as ( select ctid from net._http_response where created < $1 - $2 order by created limit $3 ) delete from net._http_response r using rows where r.ctid = rows.ctid',
        'with rows as ( select id from net.http_request_queue order by id limit $1 ) delete from net.http_request_queue q using rows where q.id = rows.id returning q.id, q.method, q.url, timeout_milliseconds, array(select key || $2 || value from jsonb_each_text(q.headers)), q.body',
        -- https://github.com/sqlalchemy/sqlalchemy/blob/800932af467109f06c0196c42ae86272a5d7f96a/lib/sqlalchemy/dialects/postgresql/base.py#L3290
        'select current_schema()',
        -- https://github.com/sqlalchemy/sqlalchemy/blob/800932af467109f06c0196c42ae86272a5d7f96a/lib/sqlalchemy/dialects/postgresql/base.py#L3383
        'select pg_catalog.version()',
        -- https://github.com/aio-libs/aiopg/blob/7b01833100b83f65ba64a5ba877eabc369242b8b/aiopg/connection.py#L1206
        'select t.oid, typarray from pg_type t join pg_namespace ns on typnamespace = ns.oid where typname = $1',
        -- https://github.com/supabase/supavisor/blob/9f56b879e7421a6245846d3b9a61dc81756d6afd/lib/supavisor/helpers.ex#L57
        'select version()',
        -- https://github.com/supabase/platform/blob/develop/worker/src/lib/pg-api.ts
        'select concat(conrelid::regclass, $1, conname) as fk from pg_constraint where contype = $2 order by 1 desc',
        'select concat(schemaname, $1, tablename, $2, policyname) as policy from pg_policies order by 1 desc',
        'select concat(table_schema, $1, table_name) as table from information_schema.tables where table_schema not like $2 and table_schema <> $3 order by 1 desc',
        'select count(*) > $1 as keys_created from pgsodium.key',
        'select count(*) > $1 as pgsodium_enabled from pg_extension where extname = $2',
        'select datname from pg_database where datallowconn = $1 order by oid asc',
        -- misc
        'begin isolation level read committed read only',
        'begin',
        'commit',
        'select $1',
        'select * from migrations order by id',
        'select * from migrations',
        'select b.oid, b.typarray from pg_catalog.pg_type a left join pg_catalog.pg_type b on b.oid = a.typelem where a.typcategory = $1 group by b.oid, b.typarray order by b.oid',
        'select current_setting($1)::integer, current_setting($2)',
        'select pg_advisory_lock($1)',
        'select pg_advisory_unlock($1)',
        'select pg_advisory_unlock(hashtext($1)::bigint)',
        'select pg_advisory_unlock_all()',
        'select pg_advisory_xact_lock($1)',
        'select pg_try_advisory_lock($1)',
        'select pg_try_advisory_lock(hashtext($1)::bigint)',
        'select typname::text, oid::int4, typarray::int4 from pg_type where typname in ($1,$2) order by typname')
    -- auth
    and query not like '%-- source: auth_system_query%'
    and query not like '%auth_migration:%'
    and query not like 'select am.amname from pg_class%'
    and query not like 'select c.relname as index_name%'
    -- dashboard
    and query not like '%left join pg_description%d on d.objoid = %'
    and query not like '%select c.oid::int8 as "id",%'
    and query not like '%select con.oid as id, con.conname as %'
    and query not like '%select sum(pg_database_size(pg_database.datname))::bigint as db_size from pg_database'
    and query not like '%select tbl.schemaname, tbl.tablename,%'
    and query not like '%select word from pg_get_keywords()'
    and query not like '-- source: dashboard%show default_transaction_read_only'
    and query not like 'select pg_temp.pg_get_tabledef ( $1, $2, $3, $4, $5 ) as definition -- source: dashboard%'
    -- https://github.com/supabase/supabase/blob/c670708244784d04f5dcb69595c15f17cf70c17a/apps/studio/data/service-status/postgres-service-status-query.ts#L25
    and query not like 'select $1 -- source: dashboard%'
    and query not like 'select 1 -- source: dashboard%'
    -- pg-meta
    and query not like '%join pg_namespace sch on sch.oid = tbl.relnamespace%'
    and query not like '-- adapted from information_schema.%'
    and query not like 'select p.oid :: int8 as id, p.pubname as name,%'
    and query not like 'select t.oid::int8 as id, t.typname as name,%'
    and query not like 'set idle_session_timeout%'
    and query not like 'set statement_timeout%'
    and query not like 'with f as ( -- cte with sane arg_modes,%'
    and query not similar to '%select %.oid ?:: ?int8 as "?id"?, %.nspname as "?schema"?, c.relname as %'
    -- pg_cron
    and query not like 'update cron.job_run_details set %'
    -- pg_net
    and query not like '%net.http_request_queue%'
    -- https://github.com/supabase/storage/blob/b548ed1245dca64dc73917a2b307bce1a32532af/src/internal/database/connection.ts#L238
    and query not like 'select set_config(%'
    -- https://github.com/supabase/platform/blob/develop/worker/src/lib/pg-api.ts
    and query not like 'select name, setting from pg_settings %'
    -- misc
    and query not like '%left join (pg_collation co join pg_namespace nco on co.collnamespace = nco.oid)%'
    and query not like 'select%pg_wal_lsn_diff(%restart_lsn)%from pg_replication_slots%'
    and query not like 'set client_encoding%''unicode'''
    and query not like 'set client_encoding%''utf8'''
    and query not like 'set client_min_messages%notice'
    and query not like 'set client_min_messages%warning';
