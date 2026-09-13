"""Dedicated D-Day REST acceptance. No SQL/service credentials/auth-user deletion.

python3 tool/verify_day_target_jwt.py EXTERNAL_PUBLIC_CONFIG [EXTERNAL_ACCOUNTS_JSON]
Without the second argument, passwords are prompted with getpass (never echoed).
Requires A/B profiles to be absent; cleans only this run's fixtures in finally.
"""
import argparse
import inspect
import ssl
import uuid
import getpass
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HOST = "https://stlhijzpjfgwwdgunlsd.supabase.co"
REPO = Path(__file__).resolve().parents[1]
EMAILS = {"A": "legendstudy1@legendstudy.com", "B": "legendstudy2@legendstudy.com"}
FIELDS = "id,display_name,grade_level,neis_office_code,neis_school_code,target_date,target_label"


class AcceptanceFailure(RuntimeError):
    """Codes are controlled by this script; never include server text or credentials."""


def require(condition, code=None):
    if not condition:
        if code is None:
            code = f"CHECK_LINE_{inspect.currentframe().f_back.f_lineno}"
        raise AcceptanceFailure(code)


def failure_code(error):
    if isinstance(error, AcceptanceFailure):
        return str(error)
    if isinstance(error, KeyboardInterrupt):
        return "INTERRUPTED"
    if isinstance(error, urllib.error.URLError):
        if isinstance(error.reason, ssl.SSLCertVerificationError):
            return "TLS_CERTIFICATE_VERIFICATION_FAILED"
        if isinstance(error.reason, ssl.SSLError):
            return "TLS_CONNECTION_FAILED"
        return "NETWORK_URL_ERROR"
    if isinstance(error, ssl.SSLCertVerificationError):
        return "TLS_CERTIFICATE_VERIFICATION_FAILED"
    if isinstance(error, TimeoutError):
        return "NETWORK_TIMEOUT"
    if isinstance(error, json.JSONDecodeError):
        return "INVALID_JSON"
    if isinstance(error, FileNotFoundError):
        return "CONFIG_FILE_NOT_FOUND"
    if isinstance(error, PermissionError):
        return "CONFIG_FILE_PERMISSION_DENIED"
    if isinstance(error, KeyError):
        return "REQUIRED_FIELD_MISSING"
    if isinstance(error, (TypeError, AttributeError)):
        return "UNEXPECTED_VALUE_TYPE"
    return "UNEXPECTED_LOCAL_ERROR"


def normalized_email(value):
    require(isinstance(value, str), "EMAIL_NOT_STRING")
    return value.strip().casefold()


def external_json(name):
    path = Path(name).resolve()
    require(not path.is_relative_to(REPO))
    return json.loads(path.read_text())


def run(config, accounts, *, preflight_only=False):
    require(isinstance(config, dict), "PUBLIC_CONFIG_NOT_OBJECT")
    require(isinstance(accounts, dict), "ACCOUNTS_NOT_OBJECT")
    require(isinstance(config.get("SUPABASE_URL"), str) and config["SUPABASE_URL"].strip().rstrip("/") == HOST, "PROJECT_URL_MISMATCH")
    key = config.get("SUPABASE_PUBLISHABLE_KEY")
    require(isinstance(key, str) and key.startswith("sb_publishable_") and key == key.strip(), "PUBLIC_KEY_FORMAT")
    for label, email in EMAILS.items():
        require(normalized_email(accounts.get(f"TEST_{label}_EMAIL")) == email, f"{label}_INPUT_EMAIL_MISMATCH")
        require(isinstance(accounts.get(f"TEST_{label}_PASSWORD"), str) and bool(accounts[f"TEST_{label}_PASSWORD"]), f"{label}_PASSWORD_MISSING")
    sessions, touched = [], []
    stage = "login and empty-profile preflight"

    def call(method, path, data=None, session=None, prefer=None):
        headers = {"apikey": key, "Content-Type": "application/json"}
        if session:
            headers["Authorization"] = "Bearer " + session["token"]
        if prefer:
            headers["Prefer"] = prefer
        request = urllib.request.Request(
            HOST + path, method=method, headers=headers,
            data=None if data is None else json.dumps(data).encode(),
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                raw, status = response.read(), response.status
        except urllib.error.HTTPError as error:
            raw, status = error.read(), error.code
        # Report status before parsing: HTML/proxy responses must not hide HTTP status.
        print(f"HTTP {method} {'auth' if path.startswith('/auth/') else 'profiles'} status={status}", flush=True)
        try:
            return status, json.loads(raw) if raw else None
        except (ValueError, UnicodeError):
            raise AcceptanceFailure("RESPONSE_NOT_JSON") from None

    def path(owner):
        return "/rest/v1/profiles?" + urllib.parse.urlencode({"id": "eq." + owner})

    def read(session, owner=None):
        query = urllib.parse.urlencode({"id": "eq." + (owner or session["id"]), "select": FIELDS})
        status, rows = call("GET", "/rest/v1/profiles?" + query, session=session)
        print(f"{session['label']} profile read status={status} count={len(rows) if isinstance(rows, list) else 'not-list'}", flush=True)
        require(status == 200, f"{session['label']}_PROFILE_READ_HTTP")
        require(isinstance(rows, list), f"{session['label']}_PROFILE_READ_NOT_ARRAY")
        return rows

    def own(session):
        rows = read(session)
        require(len(rows) == 1 and rows[0]["id"] == session["id"])
        return rows[0]

    def upsert(session, fields):
        if session not in touched:
            touched.append(session)
        status, rows = call("POST", "/rest/v1/profiles?on_conflict=id",
                            {"id": session["id"], **fields}, session,
                            "resolution=merge-duplicates,return=representation")
        require(status in (200, 201) and isinstance(rows, list) and len(rows) == 1)
        require(all(rows[0][k] == v for k, v in fields.items()))
        result = own(session)
        require(all(result[k] == v for k, v in fields.items()))
        return result

    def patch(session, fields):
        status, rows = call("PATCH", path(session["id"]), fields, session, "return=representation")
        require(status == 200 and isinstance(rows, list) and len(rows) == 1)
        require(all(rows[0][k] == v for k, v in fields.items()))
        result = own(session)
        require(all(result[k] == v for k, v in fields.items()))
        return result

    def unchanged_except(before, after, changed):
        require({k: v for k, v in before.items() if k not in changed} ==
                {k: v for k, v in after.items() if k not in changed})

    def denied_patch(session, fields, code="23514"):
        before = own(session)
        status, body = call("PATCH", path(session["id"]), fields, session, "return=representation")
        require(status == 400 and isinstance(body, dict) and body.get("code") == code)
        require(own(session) == before)

    def passed(label):
        print(label + ": PASS", flush=True)

    try:
        print("Target: LegendStudy / stlhijzpjfgwwdgunlsd", flush=True)
        for label in ("A", "B"):
            stage = f"{label} login"
            status, body = call("POST", "/auth/v1/token?grant_type=password", {
                "email": normalized_email(accounts[f"TEST_{label}_EMAIL"]),
                "password": accounts[f"TEST_{label}_PASSWORD"],
            })
            print(f"{label} login status={status}", flush=True)
            require(status == 200, f"{label}_LOGIN_HTTP")
            require(isinstance(body, dict), f"{label}_LOGIN_NOT_OBJECT")
            user = body.get("user")
            require(isinstance(user, dict), f"{label}_LOGIN_USER_MISSING")
            token, owner = body.get("access_token"), user.get("id")
            require(isinstance(token, str) and bool(token.strip()), f"{label}_ACCESS_TOKEN_MISSING")
            require(isinstance(owner, str), f"{label}_USER_ID_MISSING")
            try:
                owner = str(uuid.UUID(owner))
            except ValueError:
                raise AcceptanceFailure(f"{label}_USER_ID_INVALID") from None
            sessions.append({"id": owner, "token": token, "label": label})
            require(normalized_email(user.get("email")) == EMAILS[label], f"{label}_LOGIN_EMAIL_MISMATCH")
            passed(f"{label} login identity/token shape")
        a, b = sessions
        stage = "distinct identities"
        require(a["id"] != b["id"], "A_B_SAME_USER_ID")
        stage = "A empty-profile preflight"
        a_rows = read(a)
        stage = "B empty-profile preflight"
        b_rows = read(b)
        stage = "empty-profile conditions"
        require(a_rows == [], "A_PROFILE_NOT_EMPTY")
        require(b_rows == [], "B_PROFILE_NOT_EMPTY")
        passed("login and empty-profile preflight")
        if preflight_only:
            print("Preflight-only PASS; acceptance mutations not executed", flush=True)
            return
        stage = "legacy profile upsert"
        for session in sessions:
            upsert(session, {"display_name": "D-Day temporary fixture", "grade_level": 2})
        passed(stage)
        original = upsert(a, {"neis_office_code": "J10", "neis_school_code": "7530932"})
        stage = "target save/select and profile/school preservation"
        saved = upsert(a, {"target_date": "2026-10-06", "target_label": "중간고사"})
        unchanged_except(original, saved, {"target_date", "target_label"})
        saved2 = upsert(a, {"target_date": "2026-11-06", "target_label": "기말고사"})
        unchanged_except(saved, saved2, {"target_date", "target_label"})
        passed(stage)
        stage = "profile update preserves target and school"
        updated = upsert(a, {"display_name": "D-Day updated fixture", "grade_level": 3})
        unchanged_except(saved2, updated, {"display_name", "grade_level"})
        passed(stage)
        stage = "school update preserves target and profile"
        cleared_school = upsert(a, {"neis_office_code": None, "neis_school_code": None})
        unchanged_except(updated, cleared_school, {"neis_office_code", "neis_school_code"})
        restored_school = upsert(a, {"neis_office_code": "J10", "neis_school_code": "7530932"})
        require(restored_school == updated)
        passed(stage)
        stage = "partial pair rejects clearing only one side"
        for field in ("target_date", "target_label"):
            denied_patch(a, {field: None})
        passed(stage)
        stage = "target clear preserves profile and school"
        cleared = patch(a, {"target_date": None, "target_label": None})
        unchanged_except(restored_school, cleared, {"target_date", "target_label"})
        require(patch(a, {"target_date": None, "target_label": None}) == cleared)
        passed(stage)
        stage = "partial pair rejects setting only one side"
        denied_patch(a, {"target_date": "2026-10-06"})
        denied_patch(a, {"target_label": "시험"})
        passed(stage)
        stage = "invalid label CHECK and 80-character boundary"
        for label in ("", "   ", "\t\n", " 앞", "뒤 ", "가" * 81):
            denied_patch(a, {"target_date": "2026-10-06", "target_label": label})
        boundary = upsert(a, {"target_date": "2026-10-06", "target_label": "가" * 80})
        unchanged_except(cleared, boundary, {"target_date", "target_label"})
        passed(stage)
        stage = "past date accepted; invalid/infinite dates rejected"
        past = upsert(a, {"target_date": "2000-01-01", "target_label": "지난 시험"})
        unchanged_except(boundary, past, {"target_date", "target_label"})
        denied_patch(a, {"target_date": "2026-02-30", "target_label": "시험"}, "22008")
        for date in ("infinity", "-infinity"):
            denied_patch(a, {"target_date": date, "target_label": "시험"})
        passed(stage)
        stage = "real JWT B cannot SELECT/UPDATE/upsert A profile"
        before = own(a)
        before_b = own(b)
        require(read(b, a["id"]) == [])
        status, rows = call("PATCH", path(a["id"]), {"target_date": None, "target_label": None}, b, "return=representation")
        require(status == 200 and rows == [])
        require(own(a) == before)
        status, error = call("POST", "/rest/v1/profiles?on_conflict=id",
                             {"id": a["id"], "target_date": "2026-10-06", "target_label": "forbidden"}, b,
                             "resolution=merge-duplicates,return=representation")
        require(status == 403 and error.get("code") == "42501")
        require(own(a) == before and own(b) == before_b)
        passed(stage)
        stage = "missing profile clear and minimal save"
        status, _ = call("DELETE", path(a["id"]), session=a)
        require(status in (200, 204) and read(a) == [])
        status, rows = call("PATCH", path(a["id"]), {"target_date": None, "target_label": None}, a, "return=representation")
        require(status == 200 and rows == [] and read(a) == [])
        minimal = upsert(a, {"target_date": "2026-10-06", "target_label": "시험"})
        require(all(minimal[k] is None for k in ("display_name", "grade_level", "neis_office_code", "neis_school_code")))
        passed(stage)
    except BaseException as error:
        print("Stopped at: " + stage + "; reason=" + failure_code(error), flush=True)
        raise
    finally:
        cleanup_failed = False
        for session in touched:
            try:
                status, _ = call("DELETE", path(session["id"]), session=session)
                require(status in (200, 204) and read(session) == [])
            except Exception as error:
                print(f"{session['label']} cleanup reason={failure_code(error)}", flush=True)
                cleanup_failed = True
        print("Fixture cleanup: " + ("FAIL; owner follow-up required" if cleanup_failed else "PASS; only this run's profiles" if touched else "NOT NEEDED; no profiles touched"), flush=True)
        for session in sessions:
            try:
                call("POST", "/auth/v1/logout?scope=local", session=session)
            except Exception:
                pass
        print("Auth users retained; none created or deleted", flush=True)
        require(not cleanup_failed)
    print("D-Day JWT/REST acceptance: PASS", flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("public_config")
    parser.add_argument("accounts", nargs="?")
    parser.add_argument("--preflight-only", action="store_true")
    args = parser.parse_args(argv)
    try:
        config = external_json(args.public_config)
        if args.accounts:
            accounts = external_json(args.accounts)
        else:
            require(sys.stdin.isatty(), "INTERACTIVE_TERMINAL_REQUIRED")
            accounts = {}
            for label, email in EMAILS.items():
                accounts[f"TEST_{label}_EMAIL"] = email
                accounts[f"TEST_{label}_PASSWORD"] = getpass.getpass(f"Password for {label} ({email}) > ")
        run(config, accounts, preflight_only=args.preflight_only)
        return 0
    except (Exception, KeyboardInterrupt) as error:
        print("D-Day verifier FAIL; reason=" + failure_code(error), flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
