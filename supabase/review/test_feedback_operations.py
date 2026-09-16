from pathlib import Path


ROOT = Path(__file__).parents[2]
MIGRATION = ROOT / "supabase/migrations/20260917000100_feedback_operations.sql"
FLUTTER_REPOSITORY = (
    ROOT / "lib/features/feedback/data/supabase_feedback_repository.dart"
)


def test_feedback_candidate_has_server_derived_owner_and_minimal_client_grant():
    sql = MIGRATION.read_text()
    dart = FLUTTER_REPOSITORY.read_text()
    assert "user_id uuid default (auth.uid())" in sql
    assert "grant insert (category, title, body, app_version, build_number, platform, os_version, locale)" in sql
    assert "'user_id'" not in dart
    assert "status = 'new'" in sql


def test_feedback_candidate_has_rls_boundaries_and_no_client_outbox_access():
    sql = MIGRATION.read_text()
    assert sql.count("enable row level security") == 3
    assert "for select to authenticated\n    using ((select auth.uid()) = user_id)" in sql
    assert "for update to authenticated\n    using (public.is_feedback_admin())" in sql
    assert "grant select, update on public.feedback_notifications to service_role" in sql
    assert "grant insert on public.feedback_notifications" not in sql
    assert "grant update on public.feedback_notifications to authenticated" not in sql


def test_feedback_candidate_definer_functions_use_empty_search_path():
    sql = MIGRATION.read_text()
    assert sql.count("security definer") == 2
    assert sql.count("set search_path = ''") == 3
    assert "LEGENDSTUDY_ADMIN_EMAIL" not in sql
    assert "API_KEY" not in sql


def test_feedback_candidate_has_outbox_idempotency_and_bounded_retry_contract():
    sql = MIGRATION.read_text()
    assert "unique (feedback_id, channel)" in sql
    assert "attempt_count integer not null default 0 check (attempt_count between 0 and 8)" in sql
    assert "(status = 'sent') = (sent_at is not null)" in sql
    assert "after insert on public.feedback_submissions" in sql
