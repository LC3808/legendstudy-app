"""Operator-only conditional rollback. Disable worker first. Never deletes IDs."""
from __future__ import annotations
import argparse
import json
import os
from decimal import Decimal
from psycopg import sql
from psycopg.rows import dict_row
from ingestion.daily_sync import require,equal


def equivalent(a,b,key):
    if isinstance(a,Decimal) and isinstance(b,(int,float,str)):
        return a==Decimal(str(b))
    if key=='raw_metadata':
        return (json.loads(a) if isinstance(a,str) else a)==(json.loads(b) if isinstance(b,str) else b)
    if key in ('id','content_item_id','exam_subject_id','source_post_id','subject_id'):
        return str(a or '')==str(b or '')
    return equal(a,b,key)


def rollback(conn,run_id):
    with conn.transaction():
        require(conn.execute('select pg_try_advisory_xact_lock(178431,18) as locked').fetchone()['locked'],'worker_active')
        require(not conn.execute('select enabled from ingestion_ops.config where singleton').fetchone()['enabled'],'disable_first')
        changes=conn.execute('select * from ingestion_ops.changes where run_id=%s order by id desc',(run_id,)).fetchall()
        require(bool(changes),'run_has_no_changes')
        for c in changes:
            table=c['table_name'];require(table in ('source_posts','content_items','exams','exam_subjects','resources'),'table_invalid')
            key='content_item_id' if table=='exams' else 'id'
            row=conn.execute(sql.SQL('select * from {} where {}=%s for update').format(sql.Identifier('public',table),sql.Identifier(key)),(c['row_id'],)).fetchone()
            require(row is not None and all(equivalent(row.get(k),v,k) for k,v in c['after_row'].items()),'later_edit_conflict')
            patch=c['before_row']
            if patch is None:
                patch={'is_active':False} if 'is_active' in row else {}
            if patch:
                conn.execute(sql.SQL('update {} set {} where {}=%s').format(sql.Identifier('public',table),sql.SQL(',').join(sql.SQL('{}=%s').format(sql.Identifier(k)) for k in patch),sql.Identifier(key)),[*patch.values(),c['row_id']])
        conn.execute("update ingestion_ops.runs set status='rolled_back' where id=%s",(run_id,))
    return len(changes)

if __name__=='__main__':
    import psycopg
    p=argparse.ArgumentParser();p.add_argument('run_id');a=p.parse_args()
    with psycopg.connect(os.environ['MATERIAL_SYNC_ROLLBACK_DATABASE_URL'],autocommit=True,row_factory=dict_row) as c:
        print(json.dumps({'restored_changes':rollback(c,a.run_id)}))
