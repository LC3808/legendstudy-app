from pathlib import Path


ROOT = Path(__file__).parents[2]
SQL = ROOT / "supabase/migrations/20260917000200_feedback_notification_worker.sql"
FUNCTION = ROOT / "supabase/functions/process-feedback-notifications/index.ts"
PROVIDER = ROOT / "supabase/functions/process-feedback-notifications/resend_provider.ts"
TYPES = ROOT / "supabase/functions/process-feedback-notifications/types.ts"
TEST = ROOT / "supabase/functions/process-feedback-notifications/handler_test.ts"


def test_migration_preserves_existing_states_and_adds_claim_contract():
    sql = SQL.read_text()
    assert "add constraint feedback_notifications_status_check" in sql
    assert "'pending', 'processing', 'sent', 'failed'" in sql
    assert "next_attempt_at timestamptz" in sql
    assert "claimed_at timestamptz" in sql
    assert "claim_token uuid" in sql
    assert "for update skip locked" in sql
    assert "attempt_count = n.attempt_count + 1" in sql
    assert "pg_catalog.gen_random_uuid()" in sql
    assert "attempt_count < 8" in sql


def test_worker_functions_are_definer_safe_and_worker_only():
    sql = SQL.read_text()
    assert sql.count("security definer") == 4
    assert sql.count("set search_path = ''") == 4
    assert sql.count("revoke all on function") == 4
    assert "from public, anon, authenticated" in sql
    assert sql.count("to service_role") == 4
    assert "grant execute" in sql
    assert "feedback-email/" not in sql


def test_worker_has_secret_gate_and_no_client_surface():
    source = FUNCTION.read_text()
    assert '"x-feedback-worker-secret"' in source
    assert 'method_not_allowed' in source
    assert 'error: "forbidden"' in source
    assert 'error: "configuration_unavailable"' in source
    assert 'Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")' in source
    assert 'Deno.env.get("RESEND_API_KEY")' in source
    assert 'console.log(JSON.stringify' in source
    assert "request.body" not in source


def test_resend_adapter_is_provider_neutral_at_worker_boundary():
    source = FUNCTION.read_text()
    provider = PROVIDER.read_text()
    types = TYPES.read_text()
    assert "EmailProvider" in types
    assert "ResendEmailProvider" in provider
    assert "new ResendEmailProvider" in source
    assert '"Idempotency-Key": idempotencyKey' in provider
    assert "https://api.resend.com/emails" in provider
    assert "text: message.text" in provider
    assert "html" not in provider


def test_worker_offline_tests_cover_security_and_delivery_contract():
    test = TEST.read_text()
    for expected in [
        "wrong invocation secret",
        "stable idempotency",
        "429",
        "500",
        "400",
        "JWT",
        "plain text",
    ]:
        assert expected in test
