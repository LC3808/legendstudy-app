"""Disposable PostgreSQL proof: canonical draft/session RLS + bounded access candidate.
Account-lifecycle allow/lock functions are isolated stubs (not production E2E).
"""
import uuid


def cases(sql, root, owner, exam, question):
    directory = root/'supabase/candidates/device_qa_20261029'
    other, session, foreign = [str(uuid.uuid4()) for _ in range(3)]
    sql(f"insert into auth.users(id) values('{other}');insert into public.profiles(id) values('{other}');")
    sql("create schema account_private;create table account_private.blocked(id uuid primary key);"
        "create function account_private.lock_subject(uuid) returns void language sql as $$select$$;"
        "create function account_private.allowed(u uuid) returns boolean language sql security definer as $$"
        "select exists(select 1 from auth.users where id=u) and not exists(select 1 from account_private.blocked where id=u)$$;grant usage on schema account_private to essay_executor;")
    sql((directory/'draft-baseline.sql').read_text())
    sql((directory/'draft-install.sql').read_text())
    checks = []
    ledger = sql('select count(*) from public.credit_transactions')
    policies = sql("select md5(string_agg(qual||coalesce(with_check,''),'|' order by tablename,policyname)) from pg_policies where schemaname='public' and tablename in ('essay_drafts','essay_practice_sessions')")
    def call(user, text, error=None):
        return sql(f"set role authenticated;set request.jwt.claim.sub='{user}';"+text, error)
    open_session = f"select public.essay_open_session('{session}','{question}')"
    call('', open_session, 'UNAUTHENTICATED')
    call(owner, open_session, 'INVALID_QUESTION')
    call(other, open_session, 'INVALID_QUESTION')
    sql(f"insert into essay_private.draft_access values('{owner}','{question}',clock_timestamp()+interval '1 day',clock_timestamp(),'Synthetic reviewed access');")
    call(other, open_session, 'INVALID_QUESTION')
    sql('set role authenticated;select * from essay_private.draft_access', 'permission denied')
    checks.append('anonymous_held_ungranted_other_owner_and_direct_grant_access_denied')
    assert call(owner, open_session) == session
    assert call(owner, open_session) == session
    checks.append('authorized_existing_rpc_open_is_idempotent')
    revision = int(sql(f"select revision from public.essay_drafts where session_id='{session}'"))
    assert call(owner, f"select public.essay_save_draft('{session}',{revision},'Synthetic preserved answer')") == str(revision+1)
    call(owner, f"select public.essay_save_draft('{session}',{revision},'stale replacement')", 'STALE_DRAFT')
    call(other, f"select public.essay_save_draft('{session}',{revision+1},'foreign replacement')", 'FORBIDDEN')
    assert call(owner, f"select body from public.essay_drafts where session_id='{session}'") == 'Synthetic preserved answer'
    assert call(other, f"select count(*) from public.essay_drafts where session_id='{session}'") == '0'
    checks.append('draft_save_restore_revision_conflict_owner_rls_preserved')
    sql(f"insert into account_private.blocked values('{owner}')")
    call(owner, open_session, 'insufficient_privilege')
    sql(f"delete from account_private.blocked where id='{owner}'")
    sql(f"update essay_private.draft_access set expires_at=clock_timestamp()-interval '1 second'")
    call(owner, open_session, 'INVALID_QUESTION')
    assert sql(f"select body from public.essay_drafts where session_id='{session}'") == 'Synthetic preserved answer'
    checks.append('lifecycle_restriction_and_expired_grant_deny_open_without_deleting_answer')
    assert sql(f"select is_published from public.essay_questions where id='{question}'") == 'f'
    assert sql('select count(*) from public.credit_transactions') == ledger
    assert sql("select md5(string_agg(qual||coalesce(with_check,''),'|' order by tablename,policyname)) from pg_policies where schemaname='public' and tablename in ('essay_drafts','essay_practice_sessions')") == policies
    checks.append('registry_ledger_and_existing_rls_unchanged')
    sql((directory/'draft-rollback.sql').read_text())
    call(owner, open_session, 'INVALID_QUESTION')
    assert sql(f"select body from public.essay_drafts where session_id='{session}'") == 'Synthetic preserved answer'
    assert sql('select count(*) from essay_private.draft_access') == '1'
    checks.append('rollback_restores_original_gate_preserves_answers_sessions_approval_audit')
    print({'checks': checks, 'count': len(checks), 'productionWrites': 0, 'providerCalls': 0,
           'limitation': 'account lifecycle helpers stubbed; canonical session/draft DDL and RLS are real'})
