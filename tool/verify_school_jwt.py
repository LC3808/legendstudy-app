"""Opt-in LegendStudy REST/JWT acceptance; credentials read only from external files.

Usage: python3 tool/verify_school_jwt.py PUBLIC_CONFIG_JSON TEST_ACCOUNTS_JSON
Test accounts JSON fields: TEST_A_EMAIL, TEST_A_PASSWORD, TEST_B_EMAIL, TEST_B_PASSWORD.
Reuses accounts, refuses existing profile rows, cleans only this run's profile fixtures.
Never runs SQL or uses service credentials. Does not delete auth users.
"""
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HOST = "https://stlhijzpjfgwwdgunlsd.supabase.co"
REPO = Path(__file__).resolve().parents[1]


def external_json(name):
    path = Path(name).resolve()
    if path.is_relative_to(REPO):
        raise ValueError("Configuration must be outside repository")
    return json.loads(path.read_text())


def run(config, accounts):
    assert config["SUPABASE_URL"].rstrip("/") == HOST
    key = config["SUPABASE_PUBLISHABLE_KEY"]
    assert key.startswith("sb_publishable_")
    sessions = []
    touched = []

    def call(method, path, data=None, token=None, prefer=None):
        headers = {"apikey": key, "Content-Type": "application/json"}
        if token:
            headers["Authorization"] = "Bearer " + token
        if prefer:
            headers["Prefer"] = prefer
        request = urllib.request.Request(
            HOST + path, data=None if data is None else json.dumps(data).encode(),
            headers=headers, method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                raw = response.read()
                return response.status, json.loads(raw) if raw else None
        except urllib.error.HTTPError as error:
            raw = error.read()
            return error.code, json.loads(raw) if raw else None

    def read(session, owner=None):
        query = urllib.parse.urlencode({
            "id": "eq." + (owner or session["id"]),
            "select": "id,display_name,grade_level,neis_office_code,neis_school_code",
        })
        status, rows = call("GET", "/rest/v1/profiles?" + query, token=session["token"])
        assert status == 200 and isinstance(rows, list)
        return rows

    def upsert(session, fields):
        if session not in touched:
            touched.append(session)  # Also clean up after uncertain network outcomes.
        status, _ = call("POST", "/rest/v1/profiles?on_conflict=id",
                         {"id": session["id"], **fields}, session["token"],
                         "resolution=merge-duplicates,return=representation")
        assert status in (200, 201)

    cleanup_failed = False
    try:
        for label in ("A", "B"):
            status, body = call("POST", "/auth/v1/token?grant_type=password", {
                "email": accounts[f"TEST_{label}_EMAIL"],
                "password": accounts[f"TEST_{label}_PASSWORD"],
            })
            assert status == 200
            sessions.append({"id": body["user"]["id"], "token": body["access_token"]})
        a, b = sessions
        assert a["id"] != b["id"]
        assert read(a) == [] and read(b) == [], "Refusing existing profile data"
        for session in sessions:
            upsert(session, {"display_name": "Day 7 temporary verification", "grade_level": 2})
        print("legacy profile upsert: PASS")
        upsert(a, {"neis_office_code": "J10", "neis_school_code": "7530932"})
        saved = read(a)[0]
        assert saved["neis_office_code"] == "J10" and saved["neis_school_code"] == "7530932"
        assert saved["display_name"] == "Day 7 temporary verification" and saved["grade_level"] == 2
        print("pair save/select and name/grade preservation: PASS")
        upsert(a, {"display_name": "Day 7 updated verification", "grade_level": 3})
        saved = read(a)[0]
        assert saved["neis_office_code"] == "J10" and saved["neis_school_code"] == "7530932"
        print("profile update preserves school: PASS")
        path_a = "/rest/v1/profiles?" + urllib.parse.urlencode({"id": "eq." + a["id"]})
        status, body = call("PATCH", path_a, {"neis_school_code": None}, a["token"])
        assert status == 400 and body["code"] == "23514"
        assert read(a)[0] == saved
        print("partial pair CHECK violation: PASS")
        assert read(b, a["id"]) == []
        status, body = call("PATCH", path_a, {"neis_office_code": None, "neis_school_code": None}, b["token"], "return=representation")
        assert (status == 200 and body == []) or status == 403
        assert read(a)[0] == saved
        print("real JWT A/B ownership isolation: PASS")
        upsert(a, {"neis_office_code": None, "neis_school_code": None})
        cleared = read(a)[0]
        assert cleared["neis_office_code"] is None and cleared["neis_school_code"] is None
        assert cleared["display_name"] == saved["display_name"] and cleared["grade_level"] == saved["grade_level"]
        print("pair clear preserves profile: PASS")
    finally:
        for session in touched:
            try:
                path = "/rest/v1/profiles?" + urllib.parse.urlencode({"id": "eq." + session["id"]})
                status, _ = call("DELETE", path, token=session["token"])
                assert status in (200, 204) and read(session) == []
            except Exception:
                cleanup_failed = True
        print("profile fixture cleanup: " + ("FAIL — owner intervention required" if cleanup_failed else "PASS (only this run's rows)"))
        for session in sessions:
            try:
                call("POST", "/auth/v1/logout?scope=local", token=session["token"])
            except Exception:
                pass
        print("auth users: retained; no user created or deleted")
        if cleanup_failed:
            raise RuntimeError("Cleanup requires owner follow-up")


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("Two external configuration file paths required")
        run(external_json(sys.argv[1]), external_json(sys.argv[2]))
    except Exception:
        # Do not print exception text: it could contain a password, JWT or URL.
        print("JWT acceptance: FAIL or missing prerequisites; no credential details logged")
        sys.exit(1)
