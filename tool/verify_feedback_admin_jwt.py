"""Opt-in LegendStudy Feedback admin REST/JWT acceptance verifier.

Offline-only by default. Production requests require the explicit
``--run-production-admin-acceptance`` flag and the exact LegendStudy project
URL. This verifier creates one A-owned [TEST] feedback fixture for the
admin workflow, never performs cleanup, never uses service-role credentials,
and never tests reverse status transitions.
"""

import argparse
import getpass
import json
import re
import sys
import urllib.parse
import uuid
from pathlib import Path

from verify_feedback_jwt import (
    AUTH_PATH,
    FORBIDDEN_INSERT_COLUMNS,
    HOST,
    ALLOWED_INSERT_COLUMNS,
    AcceptanceFailure,
    Response,
    Transport,
    Verifier,
    as_uuid,
    project_guard,
    require,
)


ADMIN_EMAIL = "admin@legendstudy.com"
EXPECTED_ADMIN_UUID = "d5eab102-da92-4c4c-9adb-16d2c9d20e4c"
EXPECTED_USER_A_UUID = "18f916d4-9fed-4736-b454-02b972e85344"
TABLE = "feedback_submissions"
SAFE_DB_CODES = {"42501", "23502", "23514", "23505", "PGRST116", "PGRST204"}


def admin_marker(run_id):
    return f"[TEST] Feedback admin acceptance {run_id}"


def admin_fixture_payload(run_id):
    payload = {
        "category": "inquiry",
        "title": admin_marker(run_id),
        "body": f"[TEST] admin verifier run {run_id}",
        "app_version": "0.0-test",
        "build_number": "admin-acceptance",
        "platform": "web",
        "os_version": "admin-acceptance",
        "locale": "ko-KR",
    }
    require(tuple(payload) == ALLOWED_INSERT_COLUMNS, "CLIENT_COLUMNS")
    require(not FORBIDDEN_INSERT_COLUMNS.intersection(payload), "FORBIDDEN_CLIENT_COLUMN")
    return payload


def success_or_empty(response, code):
    require(response.status in (200, 201, 204, 206), code)
    require(response.body in (None, []), code)


class AdminVerifier(Verifier):
    def login_one(self, label, email, password, expected_uuid):
        require(bool(email.strip()) and bool(password), f"{label}_CREDENTIAL_MISSING")
        response = self.call(
            "POST",
            AUTH_PATH,
            data={"email": email, "password": password},
        )
        require(response.status == 200 and isinstance(response.body, dict), f"{label}_LOGIN_RESULT")
        user = response.body.get("user")
        token = response.body.get("access_token")
        require(isinstance(user, dict) and isinstance(token, str) and token.strip(), f"{label}_LOGIN_SHAPE")
        require(user.get("email", "").strip().casefold() == email.strip().casefold(), f"{label}_LOGIN_IDENTITY")
        actual_uuid = as_uuid(user.get("id"), f"{label}_LOGIN_UUID")
        require(actual_uuid == expected_uuid, f"{label}_UUID_MISMATCH")
        self.sessions[label] = {"id": actual_uuid, "token": token}

    def predicate(self, label):
        response = self.call(
            "POST",
            "/rest/v1/rpc/is_feedback_admin",
            data={},
            label=label,
        )
        require(response.status == 200 and isinstance(response.body, bool), f"{label}_PREDICATE_RESULT")
        return response.body

    def select_title(self, label, title):
        query = urllib.parse.urlencode({"select": "id,user_id,status,title", "title": "eq." + title})
        return self.call("GET", f"/rest/v1/{TABLE}?{query}", label=label)

    def select_id(self, label, row_id):
        query = urllib.parse.urlencode({"select": "id,user_id,status,title", "id": "eq." + row_id})
        return self.call("GET", f"/rest/v1/{TABLE}?{query}", label=label)

    def create_fixture(self):
        payload = admin_fixture_payload(self.run_id)
        response = self.call(
            "POST",
            f"/rest/v1/{TABLE}",
            data=payload,
            label="A",
            prefer="return=minimal",
        )
        success_or_empty(response, "A_FIXTURE_INSERT")
        reread = self.select_title("A", payload["title"])
        require(reread.status in (200, 206) and isinstance(reread.body, list) and len(reread.body) == 1, "A_FIXTURE_RESOLVE")
        row = reread.body[0]
        row_id = as_uuid(row.get("id"), "A_FIXTURE_ID")
        require(row.get("user_id") == self.sessions["A"]["id"], "A_FIXTURE_OWNER")
        require(row.get("status") == "new", "A_FIXTURE_STATUS")
        self.fixture_id = row_id
        self.report("a_fixture_insert_and_own_resolve", response, feedback_id=row_id, owner_matches=True)

    def admin_read(self, expected_status):
        response = self.select_id("ADMIN", self.fixture_id)
        require(response.status in (200, 206) and isinstance(response.body, list) and len(response.body) == 1, "ADMIN_FIXTURE_SELECT")
        row = response.body[0]
        require(row.get("user_id") == self.sessions["A"]["id"], "ADMIN_OWNER_READ")
        require(row.get("status") == expected_status, "ADMIN_STATUS_READ")
        return response

    def update_status(self, label, status, code):
        path = f"/rest/v1/{TABLE}?id=eq.{self.fixture_id}"
        response = self.call(
            "PATCH",
            path,
            data={"status": status},
            label=label,
            prefer="return=minimal",
        )
        if label == "A":
            self.deny_or_empty(response, code)
        else:
            success_or_empty(response, code)
        return response

    def acceptance(self, admin_password, user_a_password, user_a_email):
        self.login_one("ADMIN", ADMIN_EMAIL, admin_password, EXPECTED_ADMIN_UUID)
        self.login_one("A", user_a_email, user_a_password, EXPECTED_USER_A_UUID)
        require(self.sessions["ADMIN"]["id"] != self.sessions["A"]["id"], "IDENTITIES_NOT_DISTINCT")
        self.report("auth_login_and_identity_guard", ADMIN_UUID=self.sessions["ADMIN"]["id"], A_UUID=self.sessions["A"]["id"])

        admin_is_admin = self.predicate("ADMIN")
        require(admin_is_admin is True, "ADMIN_PREDICATE_FALSE")
        self.report("admin_predicate_true", predicate=True)
        user_is_admin = self.predicate("A")
        require(user_is_admin is False, "A_PREDICATE_TRUE")
        self.report("a_predicate_false", predicate=False)

        self.create_fixture()
        self.admin_read("new")
        self.report("admin_fixture_select", fixture_scope=True, owner_matches=True)

        self.update_status("ADMIN", "reviewing", "ADMIN_REVIEWING_UPDATE")
        self.admin_read("reviewing")
        self.report("admin_new_to_reviewing", status="reviewing")

        self.update_status("A", "resolved", "A_STATUS_UPDATE_ALLOWED")
        self.admin_read("reviewing")
        self.report("a_status_update_denied_and_admin_reread_reviewing", status="reviewing")

        self.update_status("ADMIN", "resolved", "ADMIN_RESOLVED_UPDATE")
        self.admin_read("resolved")
        self.report("admin_reviewing_to_resolved", status="resolved")

        print(
            "FEEDBACK_ADMIN_RUNTIME HANDOFF run_id={} fixture_id={} "
            "outbox_exactly_one=OWNER_SQL_READ_ONLY_REQUIRED cleanup=OWNER_ONLY".format(
                self.run_id, self.fixture_id
            ),
            flush=True,
        )


def safe_failure(error, verifier=None):
    code = str(error) if isinstance(error, AcceptanceFailure) else "LOCAL_ERROR"
    if not re.fullmatch(r"[A-Z0-9_]+", code):
        code = "LOCAL_ERROR"
    response = verifier.last if verifier else None
    db_code = response.body.get("code") if response and isinstance(response.body, dict) else None
    if db_code not in SAFE_DB_CODES:
        db_code = "UNAVAILABLE"
    http = response.status if response else "UNAVAILABLE"
    print(f"FEEDBACK_ADMIN_RUNTIME FAIL {code} HTTP={http} db_code={db_code}", flush=True)
    return 1


def main(argv=None):
    parser = argparse.ArgumentParser(description="LegendStudy Feedback admin JWT acceptance; offline by default")
    parser.add_argument("config", nargs="?", help="external JSON containing SUPABASE_URL and publishable/anon key")
    parser.add_argument("--run-production-admin-acceptance", action="store_true", help="explicitly enable Production REST requests")
    args = parser.parse_args(argv)
    if not args.run_production_admin_acceptance:
        print("FEEDBACK_ADMIN_RUNTIME OFFLINE_ONLY no Production requests executed", flush=True)
        return 0
    require(args.config, "CONFIG_PATH_MISSING")
    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    user_a_email = input("User A email: ")
    admin_password = getpass.getpass("Admin password: ")
    user_a_password = getpass.getpass("User A password: ")
    verifier = None
    try:
        verifier = AdminVerifier(config)
        verifier.acceptance(admin_password, user_a_password, user_a_email)
        print("FEEDBACK_ADMIN_RUNTIME PASS acceptance", flush=True)
        return 0
    except Exception as error:
        return safe_failure(error, verifier)


if __name__ == "__main__":
    sys.exit(main())
