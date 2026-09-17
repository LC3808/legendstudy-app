"""Opt-in LegendStudy Feedback REST/JWT acceptance verifier.

Default execution is offline-only. Production requests require the explicit
``--run-production-acceptance`` flag, the exact LegendStudy project URL and an
external public config. Passwords are prompted with getpass and tokens never
leave memory or appear in output. This verifier never performs cleanup.
"""

import argparse
import getpass
import json
import re
import secrets
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from dataclasses import dataclass
from pathlib import Path


HOST = "https://stlhijzpjfgwwdgunlsd.supabase.co"
PROJECT_REF = "stlhijzpjfgwwdgunlsd"
AUTH_PATH = "/auth/v1/token?grant_type=password"
TABLE = "feedback_submissions"
ALLOWED_INSERT_COLUMNS = (
    "category",
    "title",
    "body",
    "app_version",
    "build_number",
    "platform",
    "os_version",
    "locale",
)
FORBIDDEN_INSERT_COLUMNS = {
    "user_id",
    "status",
    "id",
    "created_at",
    "updated_at",
}
SAFE_DB_CODES = {
    "42501",
    "23502",
    "23514",
    "23505",
    "PGRST116",
    "PGRST204",
}


@dataclass
class Response:
    status: int
    body: object


class AcceptanceFailure(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Transport:
    def __init__(self, key: str):
        self.key = key
        self.opener = urllib.request.build_opener(NoRedirect())

    def __call__(self, method, path, data=None, token=None, prefer=None):
        headers = {"apikey": self.key, "Content-Type": "application/json"}
        if token:
            headers["Authorization"] = "Bearer " + token
        if prefer:
            headers["Prefer"] = prefer
        request = urllib.request.Request(
            HOST + path,
            method=method,
            headers=headers,
            data=None if data is None else json.dumps(data).encode(),
        )
        try:
            response = self.opener.open(request, timeout=30)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            raw, status = response.read(), response.code
        try:
            body = json.loads(raw) if raw else None
        except (ValueError, UnicodeDecodeError):
            body = None
        return Response(status, body)


def require(value, code):
    if not value:
        raise AcceptanceFailure(code)


def project_guard(config):
    require(isinstance(config, dict), "CONFIG_SHAPE")
    require(config.get("SUPABASE_URL", "").rstrip("/") == HOST, "PROJECT_URL_MISMATCH")
    key = config.get("SUPABASE_PUBLISHABLE_KEY", config.get("SUPABASE_ANON_KEY"))
    require(isinstance(key, str) and key.strip() == key and bool(key), "PUBLIC_KEY_MISSING")
    require("SUPABASE_SERVICE_ROLE_KEY" not in config, "SERVICE_ROLE_FORBIDDEN")
    return key


def marker(run_id: str, label: str) -> str:
    return f"[TEST] Feedback RLS acceptance {run_id} {label}"


def feedback_payload(run_id: str, label: str):
    payload = {
        "category": "inquiry",
        "title": marker(run_id, label),
        "body": f"[TEST] verifier run {run_id} {label}",
        "app_version": "0.0-test",
        "build_number": "acceptance",
        "platform": "web",
        "os_version": "offline-acceptance",
        "locale": "ko-KR",
    }
    require(tuple(payload) == ALLOWED_INSERT_COLUMNS, "CLIENT_COLUMNS")
    require(not FORBIDDEN_INSERT_COLUMNS.intersection(payload), "FORBIDDEN_CLIENT_COLUMN")
    return payload


def as_uuid(value, code):
    try:
        return str(uuid.UUID(value))
    except (ValueError, TypeError, AttributeError):
        raise AcceptanceFailure(code) from None


class Verifier:
    def __init__(self, config, transport=None, run_id=None):
        key = project_guard(config)
        self.transport = transport or Transport(key)
        self.run_id = run_id or secrets.token_hex(6)
        self.sessions = {}
        self.ids = {}
        self.last = None

    def call(self, method, path, data=None, label=None, prefer=None):
        token = self.sessions[label]["token"] if label else None
        self.last = self.transport(method, path, data, token, prefer)
        return self.last

    def report(self, scenario, response=None, **fields):
        parts = [f"FEEDBACK_RUNTIME PASS {scenario}"]
        if response is not None:
            parts.append(f"HTTP={response.status}")
            if isinstance(response.body, dict) and response.body.get("code") in SAFE_DB_CODES:
                parts.append(f"code={response.body['code']}")
        parts.extend(f"{key}={value}" for key, value in fields.items())
        print(" ".join(parts), flush=True)

    def login(self, emails, passwords):
        for label in ("A", "B"):
            email, password = emails[label], passwords[label]
            require(bool(email.strip()) and bool(password), f"{label}_CREDENTIAL_MISSING")
            response = self.call("POST", AUTH_PATH, {"email": email, "password": password})
            require(response.status == 200 and isinstance(response.body, dict), f"{label}_LOGIN_RESULT")
            user = response.body.get("user")
            token = response.body.get("access_token")
            require(isinstance(user, dict) and isinstance(token, str) and token.strip(), f"{label}_LOGIN_SHAPE")
            require(user.get("email", "").strip().casefold() == email.strip().casefold(), f"{label}_LOGIN_IDENTITY")
            self.sessions[label] = {"id": as_uuid(user.get("id"), f"{label}_LOGIN_UUID"), "token": token}
        require(self.sessions["A"]["id"] != self.sessions["B"]["id"], "IDENTITIES_NOT_DISTINCT")
        self.report("auth_login", A_UUID=self.sessions["A"]["id"], B_UUID=self.sessions["B"]["id"])

    @staticmethod
    def deny_or_empty(response, code):
        if response.status in (401, 403):
            return
        if response.status in (200, 204, 206) and response.body in (None, []):
            return
        raise AcceptanceFailure(code)

    def insert_feedback(self, label, auth_label=None):
        response = self.call(
            "POST",
            f"/rest/v1/{TABLE}",
            feedback_payload(self.run_id, label),
            auth_label,
            "return=representation",
        )
        require(response.status == 201 and isinstance(response.body, list) and len(response.body) == 1, f"{label}_INSERT")
        row = response.body[0]
        require(isinstance(row, dict), f"{label}_ROW_SHAPE")
        row_id = as_uuid(row.get("id"), f"{label}_ROW_ID")
        require(row.get("status") == "new", f"{label}_STATUS")
        if auth_label:
            owner_matches = row.get("user_id") == self.sessions[auth_label]["id"]
            require(owner_matches, f"{label}_OWNER")
        else:
            owner_matches = row.get("user_id") is None
            require(owner_matches, f"{label}_GUEST_OWNER")
        self.ids[label] = row_id
        self.report(f"{label.lower()}_valid_insert", response, owner_matches=owner_matches, feedback_id=row_id)

    def select(self, label, row_id):
        query = urllib.parse.urlencode({"select": "id,user_id,status,title", "id": "eq." + row_id})
        return self.call("GET", f"/rest/v1/{TABLE}?{query}", label=label)

    def acceptance(self, emails, passwords):
        self.login(emails, passwords)

        self.insert_feedback("ANON")
        response = self.select(None, self.ids["ANON"])
        self.deny_or_empty(response, "ANON_READ_ALLOWED")
        self.report("anon_select_denied_or_empty", response)

        self.insert_feedback("A", "A")
        self.insert_feedback("B", "B")

        response = self.select("A", self.ids["A"])
        require(response.status in (200, 206) and isinstance(response.body, list) and len(response.body) == 1, "A_OWN_READ")
        self.report("a_own_select", response)

        response = self.select("A", self.ids["B"])
        self.deny_or_empty(response, "A_CROSS_USER_READ")
        self.report("a_cross_user_select_denied_or_empty", response)

        path = f"/rest/v1/{TABLE}?id=eq.{self.ids['A']}"
        response = self.call("PATCH", path, {"status": "resolved"}, "A", "return=representation")
        self.deny_or_empty(response, "A_STATUS_UPDATE_ALLOWED")
        reread = self.select("A", self.ids["A"])
        require(reread.status in (200, 206) and isinstance(reread.body, list) and len(reread.body) == 1, "A_STATUS_REREAD")
        require(reread.body[0].get("status") == "new", "A_STATUS_CHANGED")
        self.report("a_own_status_update_denied_and_reread_new", response, reread_status="new")

        response = self.call("POST", "/rest/v1/admin_users", {"user_id": self.sessions["A"]["id"]}, "A")
        self.deny_or_empty(response, "A_ADMIN_INSERT_ALLOWED")
        self.report("a_admin_users_insert_denied", response)

        response = self.call("GET", "/rest/v1/feedback_notifications?select=id", None, "A")
        self.deny_or_empty(response, "A_OUTBOX_SELECT_ALLOWED")
        self.report("a_outbox_select_denied", response)

        response = self.call("POST", "/rest/v1/feedback_notifications", {"feedback_id": self.ids["A"]}, "A")
        self.deny_or_empty(response, "A_OUTBOX_INSERT_ALLOWED")
        self.report("a_outbox_insert_denied", response)

        print(
            "FEEDBACK_RUNTIME HANDOFF run_id={} ANON_ID={} A_ID={} B_ID={} "
            "outbox_exactly_one=OWNER_SQL_READ_ONLY_REQUIRED".format(
                self.run_id, self.ids["ANON"], self.ids["A"], self.ids["B"]
            ),
            flush=True,
        )


def safe_failure(error, verifier=None):
    if isinstance(error, AcceptanceFailure):
        code = str(error)
    elif isinstance(error, (urllib.error.URLError, TimeoutError, ssl.SSLError)):
        code = "NETWORK_ERROR"
    else:
        code = "LOCAL_ERROR"
    if not re.fullmatch(r"[A-Z0-9_]+", code):
        code = "LOCAL_ERROR"
    response = verifier.last if verifier else None
    db_code = response.body.get("code") if response and isinstance(response.body, dict) else None
    if db_code not in SAFE_DB_CODES:
        db_code = "UNAVAILABLE"
    http = response.status if response else "UNAVAILABLE"
    print(f"FEEDBACK_RUNTIME FAIL {code} HTTP={http} db_code={db_code}", flush=True)
    return 1


def main(argv=None):
    parser = argparse.ArgumentParser(description="LegendStudy Feedback JWT/RLS acceptance; offline by default")
    parser.add_argument("config", nargs="?", help="external JSON containing SUPABASE_URL and publishable/anon key")
    parser.add_argument("--run-production-acceptance", action="store_true", help="explicitly enable Production REST requests")
    args = parser.parse_args(argv)
    if not args.run_production_acceptance:
        print("FEEDBACK_RUNTIME OFFLINE_ONLY no Production requests executed", flush=True)
        return 0
    require(args.config, "CONFIG_PATH_MISSING")
    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    emails = {"A": input("User A email: "), "B": input("User B email: ")}
    passwords = {"A": getpass.getpass("User A password: "), "B": getpass.getpass("User B password: ")}
    verifier = None
    try:
        verifier = Verifier(config)
        verifier.acceptance(emails, passwords)
        print("FEEDBACK_RUNTIME PASS acceptance", flush=True)
        return 0
    except Exception as error:
        return safe_failure(error, verifier)


if __name__ == "__main__":
    sys.exit(main())
