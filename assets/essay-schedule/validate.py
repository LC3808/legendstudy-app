#!/usr/bin/env python3
"""Validate a 논술 일정 intake CSV against schedule.schema.json + cross-field rules.

Usage:
  python3 assets/essay-schedule/validate.py assets/essay-schedule/schedule-template.csv

Rules enforced (beyond JSON types):
- university_id ∈ university_catalog.dart sourceUniversityId set (if catalog found).
- enums: confirmed, review_status.
- dates/times: YYYY-MM-DD / HH:MM or literal UNKNOWN.
- if exam_date, start_time, end_time all known → start < end.
- 학년도≠시행연도: conduct_year ≠ academic_year 이면 notes 필요(경고).
- 공식 자료 미제공(official_source_url 비거나 source_evidence 빈) → review_status 는
  REVIEWED 가 될 수 없음(운영 승인 후보 차단). 임의 생성 방지.
- No network, no DB. Read-only.
Exit code 0 = all rows valid (warnings allowed), 1 = at least one error.
"""
import csv, json, re, sys, pathlib

HERE = pathlib.Path(__file__).parent
SCHEMA = json.loads((HERE / "schedule.schema.json").read_text())
REQUIRED = SCHEMA["required"]
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
TIME = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")
URL = re.compile(r"^https?://")
UID = re.compile(r"^[a-z][a-z0-9_]+$")

def catalog_ids():
    cat = (HERE / "../../lib/features/essay/university_catalog.dart").resolve()
    if not cat.exists():
        return None
    ids = set(re.findall(r'"sourceUniversityId"\s*:\s*"([a-z0-9_]+)"', cat.read_text()))
    return ids or None

def is_known(v): return v not in ("", "UNKNOWN")

def validate_row(i, row, ids):
    errs, warns = [], []
    for k in REQUIRED:
        if k not in row:
            errs.append(f"missing column '{k}'")
    if errs:
        return errs, warns
    uid = row["university_id"].strip()
    if not UID.match(uid):
        errs.append(f"university_id '{uid}' 형식 오류")
    elif ids is not None and uid not in ids:
        errs.append(f"university_id '{uid}' 가 university_catalog 에 없음")
    for k, yr in (("academic_year", None), ("conduct_year", None)):
        try:
            int(row[k])
        except ValueError:
            errs.append(f"{k} '{row[k]}' 정수 아님")
    for k, rx in (("exam_date", DATE), ("announcement_date", DATE),
                  ("start_time", TIME), ("end_time", TIME)):
        v = row[k].strip()
        if v != "UNKNOWN" and not rx.match(v):
            errs.append(f"{k} '{v}' 형식 오류(또는 UNKNOWN)")
    if row["confirmed"] not in ("CONFIRMED", "TENTATIVE", "UNKNOWN"):
        errs.append(f"confirmed '{row['confirmed']}' enum 오류")
    if row["review_status"] not in ("REVIEW_REQUIRED", "REVIEWED", "REJECTED"):
        errs.append(f"review_status '{row['review_status']}' enum 오류")
    if is_known(row["official_source_url"]) and not URL.match(row["official_source_url"]):
        errs.append("official_source_url 은 http(s) URL 이어야 함")
    # cross-field: start<end when both known with known date
    ed, st, en = row["exam_date"], row["start_time"], row["end_time"]
    if is_known(ed) and is_known(st) and is_known(en) and st >= en:
        errs.append(f"start_time({st}) >= end_time({en})")
    # 공식 근거 없으면 REVIEWED 금지 (임의 생성 차단)
    no_source = not is_known(row["official_source_url"]) or row["source_evidence"].strip() == ""
    if no_source and row["review_status"] == "REVIEWED":
        errs.append("공식 출처/근거 없이 REVIEWED 불가(운영 승인 후보 차단)")
    # 학년도 != 시행연도 안내
    try:
        if int(row["academic_year"]) == int(row["conduct_year"]):
            warns.append("academic_year == conduct_year: 수시논술은 보통 시행연도=학년도-1. 확인 필요")
        if int(row["academic_year"]) != int(row["conduct_year"]) and not row.get("notes", "").strip():
            warns.append("학년도≠시행연도 인데 notes 사유 비어 있음")
    except ValueError:
        pass
    # 날짜 미확정인데 CONFIRMED
    if row["confirmed"] == "CONFIRMED" and not is_known(ed):
        warns.append("confirmed=CONFIRMED 인데 exam_date=UNKNOWN(모순 가능)")
    return errs, warns

def main():
    if len(sys.argv) < 2:
        print("usage: validate.py <csv>"); return 2
    path = pathlib.Path(sys.argv[1])
    ids = catalog_ids()
    if ids is None:
        print("[warn] university_catalog.dart 미발견 — university_id 존재검증 생략")
    total = bad = 0
    with path.open(encoding="utf-8") as f:
        for i, row in enumerate(csv.DictReader(f), start=2):
            total += 1
            errs, warns = validate_row(i, row, ids)
            tag = f"row {i} [{row.get('university_id','?')}/{row.get('track','?')}]"
            for w in warns: print(f"WARN  {tag}: {w}")
            for e in errs: print(f"ERROR {tag}: {e}")
            if errs: bad += 1
    print(f"\n{total} rows, {bad} invalid.")
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(main())
