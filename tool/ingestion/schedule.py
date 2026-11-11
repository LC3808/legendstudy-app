"""Durable 72-hour due time and one queue for the existing material runner."""
from datetime import timedelta

def next_due(completed):
    return completed + timedelta(hours=72)

def claim(conn):
    """Caller holds the existing session advisory lock; no network while locked rows."""
    with conn.transaction():
        config=conn.execute('select * from ingestion_ops.config where singleton for update').fetchone()
        conn.execute('update ingestion_ops.config set last_poll_at=now() where singleton')
        if not config['enabled']:
            return None
        # A running row without the session lock is an interrupted old process.
        conn.execute("update ingestion_ops.runs set status='interrupted',finished_at=now() where status='running'")
        queued=conn.execute("select id from ingestion_ops.runs where status='queued' order by requested_at limit 1 for update").fetchone()
        if queued:
            conn.execute("update ingestion_ops.runs set status='running',started_at=now() where id=%s",(queued['id'],))
            return str(queued['id']),'admin'
        due=conn.execute('select now()>=next_due_at and (next_retry_at is null or now()>=next_retry_at) as due from ingestion_ops.config where singleton').fetchone()['due']
        if not due:
            return None
        row=conn.execute("insert into ingestion_ops.runs(id,trigger_name,status) values(gen_random_uuid(),'schedule','running') returning id").fetchone()
        return str(row['id']),'schedule'

def finish(conn,report,trigger):
    from psycopg.types.json import Jsonb
    with conn.transaction():
        conn.execute('update ingestion_ops.runs set status=%s,finished_at=now(),summary=%s where id=%s',
                     (report['status'],Jsonb(report),report['run_id']))
        successful=report['status'] in ('success','partial') and not report['counts'].get('failed',0)
        conn.execute('update ingestion_ops.config set last_completed_at=now() where singleton')
        if successful:
            conn.execute('update ingestion_ops.config set last_success_at=now() where singleton')
        if trigger=='schedule':
            if successful:
                conn.execute("update ingestion_ops.config set next_due_at=now()+interval '72 hours',next_retry_at=null where singleton")
            else:
                conn.execute("update ingestion_ops.config set next_retry_at=now()+interval '1 hour' where singleton")
