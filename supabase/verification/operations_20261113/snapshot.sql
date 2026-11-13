-- Run only on LegendStudy stlhijzpjfgwwdgunlsd. Read-only, no user/query bodies.
-- Capture BEFORE a restart when possible. Never reset statistics for diagnosis.
begin read only;
set local statement_timeout = '5s';
set local lock_timeout = '1s';
select now() observed_at, pg_postmaster_start_time() started_at,
       pg_database_size(current_database()) database_bytes,
       current_setting('max_connections') max_connections;
select state, wait_event_type, count(*) connections,
       max(now()-query_start) filter (where state='active') longest_active
from pg_stat_activity where pid<>pg_backend_pid()
group by state,wait_event_type;
select stats_reset,blks_read,blks_hit,temp_files,temp_bytes,deadlocks
from pg_stat_database where datname=current_database();
select stats_reset,dealloc from extensions.pg_stat_statements_info;
-- IDs only: query text may contain credentials, answers or personal data.
-- showtext=false avoids loading query texts in the underlying statistics function.
select queryid,calls,total_exec_time,mean_exec_time,shared_blks_read,
       shared_blks_hit,temp_blks_read,temp_blks_written
from extensions.pg_stat_statements(false) order by total_exec_time desc limit 20;
select queryid,calls,mean_exec_time,shared_blks_read,temp_blks_written
from extensions.pg_stat_statements(false) where calls>0
order by mean_exec_time desc limit 20;
select queryid,calls,total_exec_time,shared_blks_read,temp_blks_written
from extensions.pg_stat_statements(false) order by calls desc limit 20;
select schemaname,relname,seq_scan,seq_tup_read,idx_scan,n_live_tup,n_dead_tup,
       last_autovacuum,last_autoanalyze
from pg_stat_user_tables order by seq_tup_read desc limit 20;
rollback;
