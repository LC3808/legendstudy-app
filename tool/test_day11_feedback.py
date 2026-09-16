"""Offline contract checks for the Day 11 feedback SQL draft."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DRAFT = ROOT / "supabase/drafts/20260916000100_feedback_operations.sql"


def main() -> None:
    sql = DRAFT.read_text(encoding="utf-8")
    required = (
        "DRAFT ONLY",
        "create table public.admin_users",
        "create table public.feedback_submissions",
        "create table public.feedback_notifications",
        "public.is_feedback_admin()",
        "auth.uid()",
        "feedback_insert_guest",
        "feedback_insert_owner",
        "feedback_admin_status",
        "status text not null default 'new'",
        "unique (feedback_id, channel)",
    )
    for fragment in required:
        assert fragment in sql, fragment

    forbidden = (
        "LEGENDSTUDY_ADMIN_EMAIL =",
        "resend_api_key",
        "service_role_key",
        "BEGIN PRIVATE KEY",
    )
    for fragment in forbidden:
        assert fragment not in sql, fragment

    assert "/migrations/" not in str(DRAFT)
    print("Day 11 feedback SQL draft contract checks passed.")


if __name__ == "__main__":
    main()
