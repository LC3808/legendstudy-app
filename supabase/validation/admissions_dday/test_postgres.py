#!/usr/bin/env python3
"""Real-role, synthetic-only admissions D-Day integration tests.

Uses only the disposable Unix-socket cluster at /private/tmp/legendstudy-dday-pg.
The named test database is rebuilt on each run. There is no remote/DSN override.
Requires PostgreSQL 17 binaries; see README.md for local initialization.
"""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
import json
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
PG_BIN = Path(os.environ.get("DDAY_TEST_PG_BIN", "/opt/homebrew/opt/postgresql@17/bin"))
PSQL = str(PG_BIN / "psql") if (PG_BIN / "psql").exists() else shutil.which("psql")
SOCKET = "/private/tmp"
PORT = "55441"
DB = "admissions_dday_test"
ADMIN = "00000000-0000-4000-8000-000000000001"
NOW = datetime.now(timezone(timedelta(hours=9)))
DATE = (NOW.date() + timedelta(days=30)).isoformat()
DATE2 = (NOW.date() + timedelta(days=32)).isoformat()
YEAR = NOW.year + 1
INSTALL = ROOT / "supabase/candidates/admissions_dday_20261120/install.sql"
RUN_EVIDENCE = {}


def literal(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (dict, list)):
        value = json.dumps(value, ensure_ascii=False)
    return "'" + str(value).replace("'", "''") + "'"


def command(db=DB, user="postgres"):
    if not PSQL:
        raise RuntimeError("PostgreSQL psql is required")
    return [PSQL, "-X", "-h", SOCKET, "-p", PORT, "-U", user, "-d", db,
            "-v", "ON_ERROR_STOP=1", "-v", "VERBOSITY=verbose", "-Atq"]


class DbFailure(RuntimeError):
    pass


def sql(statement, *, actor=None, role=None, db=DB, user="postgres"):
    prefix = "set statement_timeout='8s'; set lock_timeout='6s'; "
    if actor is not None:
        claims = {"sub": actor, "role": "authenticated", "exp": 4102444800}
        prefix += "set request.jwt.claims=" + literal(claims) + "; "
        role = role or "authenticated"
    if role:
        assert role in ("authenticated", "anon"), role
        prefix += f"set role {role}; "
    result = subprocess.run(command(db, user), input=prefix + statement,
                            text=True, capture_output=True, timeout=15)
    if result.returncode:
        raise DbFailure(result.stderr.strip())
    return result.stdout.strip()


def scalar(statement, **kwargs):
    lines = sql(statement, **kwargs).splitlines()
    return lines[-1] if lines else ""


def rpc(name, values=(), *, actor=ADMIN):
    raw = scalar(f"select public.{name}({','.join(literal(v) for v in values)});", actor=actor)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def new_owner():
    owner = str(uuid.uuid4())
    sql(f"insert into auth.users values({literal(owner)}); insert into public.profiles(id) values({literal(owner)});")
    return owner


def new_university():
    ident = str(uuid.uuid4())
    sql(f"insert into public.universities(id,name,slug) values({literal(ident)},'합성대학교',{literal(ident)});")
    return ident


def payload(university, **overrides):
    value = dict(university_id=university, academic_year=YEAR, campus="서울",
                 title="합성대 논술고사", event_type="ESSAY", event_date=DATE,
                 event_time=None, admission_names=["논술", "수리논술"],
                 division_names=["기계공학과"],
                 source_url="https://admissions.example.edu/official.pdf",
                 source_sha256="a" * 64, source_page=2,
                 source_note="격리 합성 fixture: 공식 검수 계약 테스트",
                 verification_status="VERIFIED", is_published=True)
    value.update(overrides)
    return value


def save_schedule(value, existing=None, key=None):
    return rpc("admin_admission_schedule_save", (
        existing["id"] if existing else None,
        existing["revision"] if existing else 0,
        key or str(uuid.uuid4()), value))


def add_application(owner, university, *, division="기계공학과", admission="논술", kind="수시", year=YEAR):
    return rpc("my_application_save", (None, 0, year, university, division, kind,
                                       admission, str(uuid.uuid4())), actor=owner)


def update_application(owner, application, university, *, division="기계공학과", admission="논술", kind="수시"):
    rev = int(scalar(f"select revision from public.student_applications where id={literal(application)}"))
    return rpc("my_application_save", (application, rev, YEAR, university, division,
                                       kind, admission, str(uuid.uuid4())), actor=owner)


def events(owner):
    return rpc("my_admission_day_events", actor=owner)["events"]


def action(owner, row, act, *, key=None):
    return rpc("my_admission_day_event_action", (row["official_event_id"], act,
               row["revision"], key or str(uuid.uuid4())), actor=owner)


def targets(owner):
    value = scalar("select coalesce(jsonb_agg(to_jsonb(d) order by id),'[]') from public.day_targets d;", actor=owner)
    return json.loads(value)


def find_event(owner, schedule):
    return next(e for e in events(owner) if e["official_event_id"] == schedule["id"])


def initialize():
    data_dir = scalar("show data_directory", db="postgres", user=os.environ.get("USER", "woojinchang"))
    if Path(data_dir).resolve() != Path("/private/tmp/legendstudy-dday-pg").resolve():
        raise RuntimeError("Refusing to use any non-fixture PostgreSQL cluster")
    admin_user = os.environ.get("USER", "woojinchang")
    sql("""do $$declare r text;begin
        foreach r in array array['postgres','anon','authenticated','service_role'] loop
        if not exists(select 1 from pg_roles where rolname=r) then
          execute format('create role %I nologin nosuperuser',r);end if;
        end loop;end$$;
        alter role postgres login nosuperuser;
        grant authenticated,anon to postgres;
        """, db="postgres", user=admin_user)
    sql(f"drop database if exists {DB};", db="postgres", user=admin_user)
    sql(f"create database {DB} owner postgres;", db="postgres", user=admin_user)
    for path in [HERE / "fixture.sql",
                 ROOT / "supabase/migrations/20260926000100_day_targets.sql",
                 ROOT / "supabase/migrations/20260930000100_day_targets_least_privilege.sql",
                 ROOT / "supabase/migrations/20261008000600_student_application_foundation.sql",
                 HERE / "lifecycle_fixture.sql"]:
        sql(path.read_text())
    # Production has an existing duplicate-header guard beyond historical 006.
    # The reviewed preimage is captured read-only; match it before patch verification.
    sql((INSTALL.parent / "preimage_my_application_save.sql").read_text())
    # Existing synthetic application/history/manual D-Day must survive installation.
    owner = "00000000-0000-4000-8000-000000000002"
    add_application(owner, "10000000-0000-4000-8000-000000000001")
    sql(f"insert into public.day_targets(owner_id,title,event_date,is_primary) values({literal(owner)},'수동 보존',{literal(DATE)},true);", actor=owner)
    def baseline():
        return {table: scalar(f"select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.{table} t")
                for table in ["student_applications", "student_application_events", "day_targets"]}
    before = baseline()
    sql(INSTALL.read_text())
    after = baseline()
    if before != after:
        raise AssertionError(f"Installer rewrote existing rows: {before} != {after}")
    if scalar("select rolsuper from pg_roles where rolname=current_user") != "f":
        raise AssertionError("Suite must use a NOSUPERUSER installer role")
    print("PASS baseline: NOSUPERUSER install preserves application/history/manual hashes", flush=True)
    return {"before":before,"after":after,"unchanged":before==after}


class AdmissionsDdayTests(unittest.TestCase):
    def setUp(self):
        self.owner = new_owner()
        self.university = new_university()
        self.data = payload(self.university)

    def match(self):
        schedule = save_schedule(self.data)
        application = add_application(self.owner, self.university)
        return schedule, application

    def test_application_creation_syncs_without_screen_entry(self):
        schedule, application = self.match()
        self.assertEqual(len(targets(self.owner)), 1)
        self.assertEqual(find_event(self.owner, schedule)["status"], "ACTIVE")
        self.assertEqual(scalar(f"select count(*) from public.student_application_events where application_id={literal(application)}"), "1")

    def test_schedule_creation_syncs_existing_applications(self):
        add_application(self.owner, self.university)
        self.assertEqual(targets(self.owner), [])
        save_schedule(self.data)
        self.assertEqual(len(targets(self.owner)), 1)

    def test_exact_scope_excludes_regular_year_university_track_unit(self):
        save_schedule(self.data)
        cases = [dict(kind="정시"), dict(year=YEAR-1), dict(admission="기회균형"),
                 dict(division="전기공학과"), dict(division="기계공학"), dict(admission="논술 추천")]
        for fields in cases:
            with self.subTest(fields=fields):
                add_application(self.owner, self.university, **fields)
                self.assertEqual(targets(self.owner), [])
        add_application(self.owner, new_university())
        self.assertEqual(targets(self.owner), [])
        add_application(self.owner, self.university, admission="수리논술")
        self.assertEqual(len(targets(self.owner)), 1)

    def test_pending_unpublished_and_missing_dates_do_not_project(self):
        add_application(self.owner, self.university)
        pending = save_schedule(payload(self.university, verification_status="PENDING", is_published=False,
                                        event_date=None, source_url=""))
        self.assertEqual(targets(self.owner), [])
        self.assertEqual(events(self.owner), [], "Unconfirmed candidate metadata must not reach students")
        save_schedule(self.data | {"is_published": False}, existing=pending)
        self.assertEqual(targets(self.owner), [])
        self.assertEqual(events(self.owner), [])

    def test_publication_requires_source_and_verified_single_date(self):
        for fields in [dict(source_url=""), dict(event_date=None), dict(source_url="javascript:alert(1)"),
                       dict(verification_status="PENDING"), dict(division_names=[]), dict(admission_names=[])]:
            with self.subTest(fields=fields):
                with self.assertRaises(DbFailure):
                    save_schedule(self.data | fields)
        self.assertEqual(targets(self.owner), [])

    def test_same_event_multiple_applications_only_one_target(self):
        schedule, first = self.match()
        second = add_application(self.owner, self.university, admission="수리논술")
        self.assertEqual(len(targets(self.owner)), 1)
        self.assertEqual(len(events(self.owner)), 1)
        rpc("my_application_delete", [first], actor=self.owner)
        self.assertEqual(len(targets(self.owner)), 1)
        rpc("my_application_delete", [second], actor=self.owner)
        self.assertEqual(targets(self.owner), [])

    def test_application_edit_reconciles_without_changing_manual_or_history(self):
        schedule, application = self.match()
        before = scalar(f"select jsonb_agg(to_jsonb(e) order by id) from public.student_application_events e where application_id={literal(application)}")
        update_application(self.owner, application, self.university, division="다른학과")
        self.assertEqual(targets(self.owner), [])
        update_application(self.owner, application, self.university)
        self.assertEqual(len(targets(self.owner)), 1)
        self.assertEqual(scalar(f"select count(*) from public.student_application_events where application_id={literal(application)}"), "3")
        self.assertIn(json.loads(before)[0]["id"], scalar(f"select jsonb_agg(id) from public.student_application_events where application_id={literal(application)}"))

    def test_active_date_change_preserves_target_identity_and_primary(self):
        schedule, _ = self.match()
        row = find_event(self.owner, schedule)
        rpc("my_set_primary_day_target", [row["day_target_id"]], actor=self.owner)
        updated = save_schedule(self.data | {"event_date": DATE2}, existing=schedule)
        self.assertEqual(updated["id"], schedule["id"])
        target = targets(self.owner)[0]
        self.assertEqual(target["id"], row["day_target_id"])
        self.assertEqual(target["event_date"], DATE2)
        self.assertTrue(target["is_primary"])

    def test_dismiss_date_change_sync_and_restore_latest(self):
        schedule, _ = self.match()
        row = find_event(self.owner, schedule)
        action(self.owner, row, "dismiss")
        self.assertEqual(targets(self.owner), [])
        save_schedule(self.data | {"event_date": DATE2}, existing=schedule)
        for _ in range(3):
            self.assertEqual(find_event(self.owner, schedule)["status"], "DISMISSED")
            self.assertEqual(targets(self.owner), [])
        action(self.owner, find_event(self.owner, schedule), "restore")
        self.assertEqual(targets(self.owner)[0]["event_date"], DATE2)

    def test_direct_legacy_delete_is_dismissal(self):
        schedule, _ = self.match()
        row = find_event(self.owner, schedule)
        sql(f"delete from public.day_targets where id={literal(row['day_target_id'])};", actor=self.owner)
        self.assertEqual(find_event(self.owner, schedule)["status"], "DISMISSED")
        self.assertEqual(targets(self.owner), [])

    def test_direct_legacy_auto_date_title_changes_denied_primary_allowed(self):
        schedule, _ = self.match()
        ident = find_event(self.owner, schedule)["day_target_id"]
        for assignment in ["title='위조일정'", f"event_date={literal(DATE2)}", f"owner_id={literal(ADMIN)}"]:
            with self.subTest(assignment=assignment):
                with self.assertRaises(DbFailure):
                    sql(f"update public.day_targets set {assignment} where id={literal(ident)};", actor=self.owner)
        sql(f"update public.day_targets set is_primary=true where id={literal(ident)};", actor=self.owner)
        self.assertTrue(targets(self.owner)[0]["is_primary"])

    def test_dismissal_survives_application_delete_and_recreation(self):
        schedule, application = self.match()
        action(self.owner, find_event(self.owner, schedule), "dismiss")
        rpc("my_application_delete", [application], actor=self.owner)
        add_application(self.owner, self.university)
        self.assertEqual(find_event(self.owner, schedule)["status"], "DISMISSED")
        self.assertEqual(targets(self.owner), [])

    def test_manual_crud_unchanged_by_sync_and_auto_actions(self):
        manual = str(uuid.uuid4())
        sql(f"insert into public.day_targets(id,owner_id,title,event_date,is_primary) values({literal(manual)},{literal(self.owner)},'수동 보존',{literal(DATE)},true);", actor=self.owner)
        before = scalar(f"select to_jsonb(d) from public.day_targets d where id={literal(manual)}")
        schedule, _ = self.match()
        action(self.owner, find_event(self.owner, schedule), "dismiss")
        save_schedule(self.data | {"event_date": DATE2}, existing=schedule)
        events(self.owner)
        self.assertEqual(scalar(f"select to_jsonb(d) from public.day_targets d where id={literal(manual)}"), before)
        sql(f"update public.day_targets set title='수동 수정',event_date={literal(DATE2)} where id={literal(manual)};delete from public.day_targets where id={literal(manual)};", actor=self.owner)
        self.assertEqual(targets(self.owner), [])

    def test_cancelled_schedule_suppresses_active_and_cannot_restore(self):
        schedule, _ = self.match()
        cancelled = save_schedule(self.data | {"verification_status":"CANCELLED", "is_published":False}, existing=schedule)
        self.assertEqual(targets(self.owner), [])
        row = find_event(self.owner, schedule)
        self.assertEqual(row["status"], "CANCELLED")
        self.assertFalse(row["can_restore"])
        with self.assertRaises(DbFailure):
            action(self.owner, row, "restore")
        save_schedule(self.data, existing=cancelled)
        self.assertEqual(len(targets(self.owner)), 1)

    def test_cancel_and_republish_does_not_erase_dismissal(self):
        schedule, _ = self.match()
        action(self.owner, find_event(self.owner, schedule), "dismiss")
        cancelled = save_schedule(self.data | {"verification_status":"CANCELLED", "is_published":False}, existing=schedule)
        save_schedule(self.data, existing=cancelled)
        self.assertEqual(find_event(self.owner, schedule)["status"], "DISMISSED")
        self.assertEqual(targets(self.owner), [])

    def test_student_action_request_idempotency_and_stale_revision(self):
        schedule, _ = self.match()
        row = find_event(self.owner, schedule)
        key = str(uuid.uuid4())
        first = action(self.owner, row, "dismiss", key=key)
        self.assertEqual(action(self.owner, row, "dismiss", key=key), first)
        with self.assertRaises(DbFailure):
            action(self.owner, row, "restore")
        with self.assertRaises(DbFailure):
            action(self.owner, row, "restore", key=key)

    def test_admin_idempotency_revision_and_history(self):
        key = str(uuid.uuid4())
        created = save_schedule(self.data, key=key)
        self.assertEqual(save_schedule(self.data, key=key)["id"], created["id"])
        updated = save_schedule(self.data | {"event_date":DATE2}, existing=created)
        self.assertGreater(updated["revision"], created["revision"])
        with self.assertRaises(DbFailure):
            save_schedule(self.data, existing=created)
        with self.assertRaises(DbFailure):
            save_schedule(self.data | {"title":"다른내용"}, key=key)

    def test_non_admin_and_anonymous_rpc_access_denied(self):
        with self.assertRaises(DbFailure):
            rpc("admin_admission_schedules", actor=self.owner)
        with self.assertRaises(DbFailure):
            rpc("admin_admission_schedule_save", [None,0,str(uuid.uuid4()),self.data], actor=self.owner)
        for name in ["my_admission_day_events", "admin_admission_schedules"]:
            with self.subTest(name=name):
                with self.assertRaises(DbFailure):
                    sql(f"select public.{name}();", role="anon")

    def test_cross_owner_isolation_and_primary_denial(self):
        schedule, _ = self.match()
        other = new_owner()
        self.assertEqual(events(other), [])
        row = find_event(self.owner, schedule)
        with self.assertRaises(DbFailure):
            action(other, row, "dismiss")
        with self.assertRaises(DbFailure):
            rpc("my_set_primary_day_target", [row["day_target_id"]], actor=other)
        sql(f"delete from public.day_targets where id={literal(row['day_target_id'])};", actor=other)
        self.assertEqual(len(targets(self.owner)),1)
        self.assertEqual(targets(other),[])

    def test_direct_preference_reads_are_owner_only(self):
        schedule,_=self.match()
        other=new_owner()
        add_application(other,self.university)
        self.assertEqual(scalar(f"select count(*) from public.student_schedule_preferences where owner_id={literal(other)}",actor=self.owner),"0")
        self.assertEqual(scalar("select count(*) from public.student_schedule_preferences",actor=self.owner),"1")
        action(other,find_event(other,schedule),"dismiss")
        self.assertEqual(len(targets(self.owner)),1)
        self.assertEqual(targets(other),[])

    def test_pending_account_cannot_read_or_mutate(self):
        schedule, _ = self.match()
        row = find_event(self.owner, schedule)
        sql(f"insert into public.account_deletion_requests(subject_id,state) values({literal(self.owner)},'DELETION_PENDING');")
        with self.assertRaises(DbFailure):
            events(self.owner)
        with self.assertRaises(DbFailure):
            action(self.owner, row, "dismiss")
        self.assertEqual(targets(self.owner), [])

    def test_revoked_admin_or_expired_admin_claims_are_rejected(self):
        administrator=new_owner()
        sql(f"insert into public.admin_users values({literal(administrator)})")
        rpc("admin_admission_schedules",actor=administrator)
        sql(f"delete from public.admin_users where user_id={literal(administrator)}")
        with self.assertRaises(DbFailure):
            rpc("admin_admission_schedules",actor=administrator)
        claims={"sub":ADMIN,"role":"authenticated","exp":1}
        with self.assertRaises(DbFailure):
            sql("set request.jwt.claims="+literal(claims)+";select public.admin_admission_schedules();",role="authenticated")

    def test_private_functions_and_tables_cannot_be_mutated_by_direct_api(self):
        schedule,_=self.match()
        for statement in [
            f"select admissions_private.sync_owner({literal(self.owner)})",
            f"update public.student_schedule_preferences set status='ACTIVE' where owner_id={literal(self.owner)}",
            "update public.admission_schedule_events set is_published=true",
            "delete from public.student_schedule_actions",
            "delete from public.application_schedule_links",
        ]:
            with self.subTest(statement=statement):
                with self.assertRaises(DbFailure):
                    sql(statement,actor=self.owner)

    def test_past_never_activated_schedule_is_not_backfilled(self):
        yesterday=(NOW.date()-timedelta(days=1)).isoformat()
        schedule=save_schedule(self.data | {"event_date":yesterday})
        add_application(self.owner,self.university)
        self.assertEqual(targets(self.owner),[])
        self.assertEqual(events(self.owner),[])
        self.assertEqual(scalar(f"select status from public.student_schedule_preferences where owner_id={literal(self.owner)} and official_event_id={literal(schedule['id'])}"),"CANCELLED")

    def test_date_only_projection_is_session_timezone_independent(self):
        schedule,_=self.match()
        for zone in ["UTC","Asia/Seoul","America/Los_Angeles"]:
            with self.subTest(zone=zone):
                row=json.loads(scalar(f"set timezone={literal(zone)};select my_admission_day_events();",actor=self.owner))["events"][0]
                self.assertEqual(row["event_date"],DATE)

    def test_different_event_types_on_same_date_are_not_collapsed(self):
        save_schedule(self.data)
        save_schedule(self.data | {"title":"합성대 최초 발표","event_type":"INITIAL_RESULT"})
        add_application(self.owner,self.university)
        self.assertEqual(len(targets(self.owner)),2)

    def test_all_requested_event_types_can_be_published(self):
        kinds=["ESSAY","INTERVIEW","PRACTICAL","STAGE_RESULT","INITIAL_RESULT","REGISTRATION_DEADLINE","OTHER"]
        for kind in kinds:
            save_schedule(self.data | {"event_type":kind})
        add_application(self.owner,self.university)
        self.assertEqual(len(targets(self.owner)),len(kinds))

    def test_duplicate_official_scope_requires_existing_event_edit(self):
        save_schedule(self.data)
        with self.assertRaisesRegex(DbFailure,"DUPLICATE_EVENT_SCOPE_USE_EXISTING"):
            save_schedule(self.data)

    def test_cross_campus_ambiguous_scope_is_not_published(self):
        save_schedule(self.data)
        with self.assertRaisesRegex(DbFailure,"AMBIGUOUS_CAMPUS_SCOPE"):
            save_schedule(self.data | {"campus":"다른캠퍼스"})

    def test_dismissed_unpublished_event_cannot_be_replaced_by_new_uuid(self):
        schedule,_=self.match()
        action(self.owner,find_event(self.owner,schedule),"dismiss")
        unpublished=save_schedule(self.data | {"is_published":False},schedule)
        with self.assertRaisesRegex(DbFailure,"DUPLICATE_EVENT_SCOPE_USE_EXISTING"):
            save_schedule(self.data)
        cancelled=save_schedule(self.data | {"is_published":False,"verification_status":"CANCELLED"},unpublished)
        with self.assertRaisesRegex(DbFailure,"DUPLICATE_EVENT_SCOPE_USE_EXISTING"):
            save_schedule(self.data)
        save_schedule(self.data,cancelled)
        self.assertEqual(find_event(self.owner,schedule)["status"],"DISMISSED")
        self.assertEqual(targets(self.owner),[])

    def test_verified_null_source_is_rejected_by_database_constraint(self):
        schedule,_=self.match()
        with self.assertRaisesRegex(DbFailure,"23514"):
            sql(f"update public.admission_schedule_events set source_url=null where id={literal(schedule['id'])}")

    def test_immutable_revision_and_student_action_history(self):
        schedule,_=self.match()
        action(self.owner,find_event(self.owner,schedule),"dismiss")
        statements=[
            f"update public.admission_schedule_revisions set snapshot='{{}}'::jsonb where event_id={literal(schedule['id'])}",
            f"delete from public.admission_schedule_revisions where event_id={literal(schedule['id'])}",
            f"update public.student_schedule_actions set before_state='{{}}'::jsonb where owner_id={literal(self.owner)}",
            f"delete from public.student_schedule_actions where owner_id={literal(self.owner)}",
        ]
        for statement in statements:
            with self.subTest(statement=statement):
                with self.assertRaisesRegex(DbFailure,"ADMISSION_HISTORY_IMMUTABLE"):
                    sql(statement)

    def test_reviewer_erasure_anonymizes_immutable_revision_only(self):
        reviewer=new_owner()
        sql(f"insert into public.admin_users values({literal(reviewer)})")
        schedule=rpc("admin_admission_schedule_save",(None,0,str(uuid.uuid4()),self.data),actor=reviewer)
        before=scalar(f"select to_jsonb(r)-'actor_id' from public.admission_schedule_revisions r where event_id={literal(schedule['id'])}")
        sql(f"delete from auth.users where id={literal(reviewer)}")
        self.assertEqual(scalar(f"select to_jsonb(r)-'actor_id' from public.admission_schedule_revisions r where event_id={literal(schedule['id'])}"),before)
        self.assertEqual(scalar(f"select actor_id is null from public.admission_schedule_revisions where event_id={literal(schedule['id'])}"),"t")

    def test_auth_delete_cascades_personal_rows(self):
        schedule,_=self.match()
        action(self.owner,find_event(self.owner,schedule),"dismiss")
        self.assertNotEqual(scalar(f"select count(*) from public.student_schedule_actions where owner_id={literal(self.owner)}"),"0")
        sql(f"delete from auth.users where id={literal(self.owner)};")
        self.assertEqual(scalar(f"select count(*) from public.day_targets where owner_id={literal(self.owner)}"),"0")
        self.assertEqual(scalar(f"select count(*) from public.student_applications where user_id={literal(self.owner)}"),"0")
        self.assertEqual(scalar(f"select count(*) from public.student_schedule_actions where owner_id={literal(self.owner)}"),"0")
        with self.assertRaises(DbFailure):
            events(self.owner)

    def test_concurrent_screen_entries_make_one_projection(self):
        self.match()
        with ThreadPoolExecutor(max_workers=8) as executor:
            results = list(executor.map(lambda _:events(self.owner), range(8)))
        self.assertTrue(all(len(result)==1 for result in results))
        self.assertTrue(all(result==results[0] for result in results))
        self.assertEqual(len(targets(self.owner)),1)

    def test_noop_sync_does_not_rewrite_state_or_append_audit(self):
        self.match()
        def snapshot():
            return {name:scalar(f"select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]') from public.{name} t where owner_id={literal(self.owner)}")
                    for name in ["day_targets","application_schedule_links","student_schedule_preferences","student_schedule_actions"]}
        before=snapshot()
        events(self.owner)
        events(self.owner)
        self.assertEqual(snapshot(),before)

    def test_concurrent_dismissals_are_one_state_transition(self):
        schedule, _ = self.match()
        row=find_event(self.owner,schedule)
        def attempt(_):
            try:
                return action(self.owner,row,"dismiss")
            except DbFailure as exc:
                return str(exc)
        with ThreadPoolExecutor(max_workers=4) as executor:
            results=list(executor.map(attempt,range(4)))
        self.assertEqual(sum(isinstance(result,dict) for result in results),1,results)
        self.assertEqual(find_event(self.owner,schedule)["status"],"DISMISSED")
        self.assertEqual(targets(self.owner),[])

    def test_simultaneous_publish_and_application_create_reconcile(self):
        pending=save_schedule(self.data | {"is_published":False})
        with ThreadPoolExecutor(max_workers=2) as executor:
            publish=executor.submit(save_schedule,self.data,pending)
            add=executor.submit(add_application,self.owner,self.university)
            publish.result();add.result()
        self.assertEqual(len(targets(self.owner)),1)

    def test_concurrent_same_request_key_creates_one_catalog_event(self):
        key = str(uuid.uuid4())
        with ThreadPoolExecutor(max_workers=6) as executor:
            results = list(executor.map(lambda _:save_schedule(self.data,key=key),range(6)))
        self.assertEqual(len({row["id"] for row in results}),1)
        add_application(self.owner,self.university)
        self.assertEqual(len(targets(self.owner)),1)

    def test_concurrent_same_dismiss_key_is_replay_not_second_action(self):
        schedule,_=self.match()
        row=find_event(self.owner,schedule)
        key=str(uuid.uuid4())
        with ThreadPoolExecutor(max_workers=6) as executor:
            results=list(executor.map(lambda _:action(self.owner,row,"dismiss",key=key),range(6)))
        self.assertTrue(all(result==results[0] for result in results))
        self.assertEqual(targets(self.owner),[])

    def test_publish_and_existing_owner_sync_are_deadlock_free(self):
        schedule,_=self.match()
        with ThreadPoolExecutor(max_workers=6) as executor:
            reads=[executor.submit(events,self.owner) for _ in range(5)]
            publication=executor.submit(save_schedule,self.data | {"event_date":DATE2},schedule)
            publication.result()
            for read in reads:
                read.result()
        self.assertEqual(targets(self.owner)[0]["event_date"],DATE2)

    def test_publish_and_legacy_delete_preserve_dismissal(self):
        schedule,_=self.match()
        row=find_event(self.owner,schedule)
        with ThreadPoolExecutor(max_workers=2) as executor:
            publication=executor.submit(save_schedule,self.data | {"event_date":DATE2},schedule)
            deletion=executor.submit(sql,f"delete from public.day_targets where id={literal(row['day_target_id'])}",actor=self.owner)
            publication.result();deletion.result()
        self.assertEqual(find_event(self.owner,schedule)["status"],"DISMISSED")
        self.assertEqual(targets(self.owner),[])

    def test_global_catalog_race_deterministic_uncommitted_first_application(self):
        pending=save_schedule(self.data | {"is_published":False})
        args=[None,0,YEAR,self.university,"기계공학과","수시","논술",str(uuid.uuid4())]
        statement="begin;select public.my_application_save("+','.join(literal(x) for x in args)+"); select pg_sleep(0.7);commit;"
        with ThreadPoolExecutor(max_workers=2) as executor:
            add=executor.submit(sql,statement,actor=self.owner)
            # Wait until the uncommitted application RPC has taken its owner lock.
            for _ in range(20):
                if scalar("select count(*) from pg_stat_activity where datname=current_database() and wait_event='PgSleep'")!='0':
                    break
            publication=executor.submit(save_schedule,self.data,pending)
            add.result();publication.result()
        self.assertEqual(len(targets(self.owner)),1)

    def test_new_tables_have_rls_and_no_direct_client_writes(self):
        names=["admission_schedule_events","admission_schedule_revisions","application_schedule_links",
               "student_schedule_preferences","student_schedule_actions"]
        for name in names:
            with self.subTest(table=name):
                self.assertEqual(scalar(f"select relrowsecurity from pg_class where oid='public.{name}'::regclass"),"t")
                self.assertEqual(scalar(f"select has_table_privilege('authenticated','public.{name}','INSERT,UPDATE,DELETE')"),"f")
                self.assertEqual(scalar(f"select has_table_privilege('anon','public.{name}','SELECT,INSERT,UPDATE,DELETE')"),"f")

    def test_y_reviewed_seed_scope_activation_idempotency_and_drift_refusal(self):
        # Public university IDs + anonymous synthetic owner; no copied student IDs.
        fixture=json.loads((HERE / "reviewed_scope_fixture.json").read_text())
        for university in fixture["universities"]:
            sql(f"insert into public.universities(id,name,slug) values({literal(university['id'])},{literal(university['name'])},{literal(university['id'])}) on conflict(id) do nothing")
        for application in fixture["applications"]:
            add_application(self.owner,application["university_id"],division=application["division"],admission=application["admission"],kind=application["kind"],year=2027)
        manual_id=scalar(f"insert into public.day_targets(owner_id,title,event_date,is_primary) values({literal(self.owner)},'수동 보존',{literal(DATE)},true) returning id",actor=self.owner)
        def protected():
            return {name:scalar(f"select coalesce(jsonb_agg(to_jsonb(t) order by id),'[]') from public.{name} t where {column}={literal(self.owner)}") for name,column in [("student_applications","user_id"),("student_application_events","user_id")]} | {"manual":scalar(f"select to_jsonb(t) from public.day_targets t where id={literal(manual_id)}")}
        before=protected()
        seed=(INSTALL.parent / "seed_reviewed.sql").read_text()
        sql(seed)
        reviewed=json.loads((INSTALL.parent / "reviewed_schedules.json").read_text())["schedules"]
        ids=','.join(literal(row["id"]) for row in reviewed)
        catalog=scalar(f"select jsonb_agg(to_jsonb(t) order by id) from public.admission_schedule_events t where id in ({ids})")
        history=scalar(f"select jsonb_agg(to_jsonb(t) order by event_id,revision) from public.admission_schedule_revisions t where event_id in ({ids})")
        sql(seed)
        self.assertEqual(catalog,scalar(f"select jsonb_agg(to_jsonb(t) order by id) from public.admission_schedule_events t where id in ({ids})"))
        self.assertEqual(history,scalar(f"select jsonb_agg(to_jsonb(t) order by event_id,revision) from public.admission_schedule_revisions t where event_id in ({ids})"))
        self.assertEqual(len(targets(self.owner)),1,"Seed alone must not backfill existing users")
        self.assertEqual(protected(),before)
        self.assertEqual(sum(row["is_published"] and row["verification_status"]=="VERIFIED" for row in reviewed),10)
        self.assertEqual(sum(row["verification_status"]=="PENDING" for row in reviewed),5)
        sql((INSTALL.parent / "activate_existing.sql").read_text())
        result=events(self.owner)
        expected_active=sum(row["is_published"] and row["event_date"]>=NOW.date().isoformat() for row in reviewed)
        self.assertEqual(len(result),expected_active,"Never-activated PENDING or past candidates must not reach student RPC")
        self.assertEqual(scalar(f"select count(*) from public.student_schedule_preferences where owner_id={literal(self.owner)}"),"15")
        self.assertEqual(sum(row["status"]=="ACTIVE" for row in result),expected_active)
        self.assertEqual(len(targets(self.owner)),1+expected_active)
        self.assertEqual(scalar(f"select count(*) from public.application_schedule_links where owner_id={literal(self.owner)} and sync_status='MATCHED'"),"12")
        self.assertEqual(scalar(f"select count(distinct application_id) from public.application_schedule_links where owner_id={literal(self.owner)} and sync_status='MATCHED'"),"8")
        self.assertEqual(scalar(f"select count(*) from public.application_schedule_links where owner_id={literal(self.owner)} and sync_status='PENDING'"),"5")
        self.assertEqual(protected(),before)
        active=next((row for row in result if row["status"]=="ACTIVE"),None)
        if active:
            action(self.owner,active,"dismiss")
        changed=reviewed[0]
        changed_data={k:v for k,v in changed.items() if k!='id'} | {"source_note":changed["source_note"]+" 검수 메모 추가"}
        save_schedule(changed_data,{"id":changed["id"],"revision":1})
        after_change=events(self.owner)
        with self.assertRaisesRegex(DbFailure,"SEED_CONTENT_CHANGED"):
            sql(seed)
        self.assertEqual(events(self.owner),after_change)
        self.assertEqual(protected(),before)
        RUN_EVIDENCE["reviewed_seed"]={"synthetic_applications":14,"susi":13,"regular_excluded":1,"schedules":15,"verified_published":10,"pending":5,"matched_application_links":12,"matched_applications":8,"pending_links":5,"distinct_active_targets_at_run":expected_active,"seed_no_backfill":True,"repeated_seed_preserved_rows":True,"edited_seed_drift_refused":True}

    def test_z_soft_rollback_restores_existing_rpc_and_preserves_manual_history(self):
        # Runs last: rollback deliberately disables admin publication and app trigger.
        schedule,_=self.match()
        dismissed=save_schedule(self.data | {"event_type":"INTERVIEW","title":"합성대 면접고사"})
        action(self.owner,find_event(self.owner,dismissed),"dismiss")
        manual_id=scalar(f"insert into public.day_targets(owner_id,title,event_date,is_primary) values({literal(self.owner)},'수동 유지',{literal(DATE)},true) returning id",actor=self.owner)
        def protected():
            return {name:scalar(f"select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.{name} t") for name in ["student_applications","student_application_events"]} | {"manual":scalar(f"select to_jsonb(t) from public.day_targets t where id={literal(manual_id)}")}
        before=protected()
        sql((INSTALL.parent / "rollback.sql").read_text())
        self.assertEqual(protected(),before)
        self.assertEqual(scalar("select md5(pg_get_functiondef('public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid)'::regprocedure))"),"65edac758433cde4a123b95be3da42ee")
        self.assertEqual(scalar("select count(*) from pg_trigger where tgname='admissions_schedule_sync'"),"0")
        self.assertEqual(scalar("select has_function_privilege('authenticated','public.admin_admission_schedule_save(uuid,integer,uuid,jsonb)','EXECUTE')"),"f")
        with self.assertRaises(DbFailure):
            save_schedule(self.data,schedule)
        result=events(self.owner)
        self.assertEqual(next(row for row in result if row["official_event_id"]==schedule["id"])["status"],"CANCELLED")
        self.assertEqual(next(row for row in result if row["official_event_id"]==dismissed["id"])["status"],"DISMISSED")
        self.assertTrue(all(not row["can_restore"] for row in result))
        self.assertEqual([row["id"] for row in targets(self.owner)],[manual_id])
        self.assertEqual(protected(),before)
        # Existing application RPC remains usable and cannot resurrect rolled-back events.
        add_application(self.owner,self.university,division="다른학과")
        self.assertEqual([row["id"] for row in targets(self.owner)],[manual_id])
        events(self.owner)
        self.assertEqual([row["id"] for row in targets(self.owner)],[manual_id])
        RUN_EVIDENCE["rollback"]={"original_rpc_md5":"65edac758433cde4a123b95be3da42ee","application_headers_history_unchanged":True,"manual_target_unchanged":True,"generated_targets_removed":True,"dismissal_retained":True,"client_read_supported":True,"publication_disabled":True}


if __name__ == "__main__":
    source_files=[INSTALL,INSTALL.parent / "preimage_my_application_save.sql",INSTALL.parent / "seed_reviewed.sql",INSTALL.parent / "reviewed_schedules.json",INSTALL.parent / "activate_existing.sql",INSTALL.parent / "rollback.sql",Path(__file__),HERE / "fixture.sql",HERE / "lifecycle_fixture.sql",HERE / "reviewed_scope_fixture.json"]
    hashes={str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest() for path in source_files}
    baseline=initialize()
    suite=unittest.defaultTestLoader.loadTestsFromTestCase(AdmissionsDdayTests)
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    source_unchanged=all(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest for path,digest in hashes.items())
    report={"scope":"LOCAL_SYNTHETIC_ONLY","production_writes":0,
            "verified_at_kst":datetime.now(timezone(timedelta(hours=9))).isoformat(),
            "postgres":scalar("select version()"),"installer_role":"postgres NOSUPERUSER",
            "tests_run":result.testsRun,"successful":result.wasSuccessful() and source_unchanged,
            "failures":[test.id() for test,_ in result.failures],"errors":[test.id() for test,_ in result.errors],
            "source_files_unchanged_during_run":source_unchanged,"source_sha256":hashes,
            "baseline_rows":baseline,
            "package_evidence":RUN_EVIDENCE,
            "limits":["Synthetic minimal Auth/profile/admin fixture; hosted JWT verifier not exercised",
                      "Full account erasure worker, Production PostgREST, WEB and Flutter E2E are separate",
                      "Date-only/session timezone invariance tested; no mocked system clock"]}
    (HERE / "result.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    sys.exit(0 if report["successful"] else 1)
