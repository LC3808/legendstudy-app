# Day 9-D1 — Pilot C publication package

Status: **implemented, offline/read-only verified; Production publication NOT EXECUTED.**

The package is `tool/publish_pilot_c.py` with offline contract coverage in
`tool/test_publish_pilot_c.py`. It is separate from the ingestion INSERT writer.
The default CLI path performs read-only preflight; `--publish` additionally
requires `--i-have-owner-approval` and the exact project ref
`stlhijzpjfgwwdgunlsd`. No command was run against Supabase in D1.

## Scope and gates

The fixed scope is the 23 Pilot C `source_posts.external_post_id` values listed
in the tool. Scope is resolved through
`source_posts → content_items → exams → exam_subjects → resources`; downstream
rows must match the exact chain and expected counts 23 / 23 / 23 / 363 / 739.
No slug, year, source URL, or broad table predicate is used as identity.

Read-only preflight fails closed unless the recorded baseline is exact:
subjects 23 and active 23; source_posts 23; content_items 23; exams 23;
exam_subjects 363; resources 739; quarantine 23; all three publication tables
inactive; mappings 363 provisional / 0 verified; signed URLs, duplicates,
orphans, and blocking quarantine all zero; resources are question 360,
answer_explanation 356, listening_audio 23. Any mismatch stops before mutation.

## Publication and idempotency

One transaction performs the exact activation order:

1. `content_items`
2. `exam_subjects`
3. `resources`

Each statement uses `RETURNING id`; the affected ID count must equal exactly
23, 363, or 739. The only explicit mutation is `SET is_active = true` guarded
by `is_active = false`. `exams` has no activation column and is unchanged.
Subjects, source posts, quarantine, mappings, URLs, and all non-activation
fields are unchanged. Existing `updated_at` triggers may update their clock;
the package does not set timestamps itself.

After activation, the same transaction re-runs scope/count/active checks before
COMMIT. Any error rolls back the whole transaction. Exact all-zero active state
is publishable; exact 23/363/739 is `already_published` and rolls back as a
read-only no-op; every partial or foreign active state is rejected and never
repaired automatically.

Rollback statements are included as a guarded package in resource → occurrence
→ content order. They only soft-deactivate the exact Pilot C chain and issue
no DELETE. Rollback was not executed.

## Anon and Search acceptance

`anon_acceptance_sql()` provides a transaction-scoped `SET LOCAL ROLE anon`
read-only check for public counts and an explicit public projection joining
content, exam, occurrence, taxonomy and resources. It also probes the private
source/quarantine tables; expected client visibility is denied. Expected
published counts are content 23, exams 23, occurrences 363, resources 739,
subjects 23. The Owner should additionally run equivalent publishable-key anon
REST queries because SQL `SET ROLE` is not a substitute for HTTP acceptance.

Post-publication Search acceptance covers latest ordering; 2025/2026; 고1/고2/고3;
시험 유형; 국어 including canonical mapping for 국어(화작)/국어(언매); 수학;
영어; 한국사; 통합사회/통합과학; 사회탐구/과학탐구 detail subjects; 문제;
정답/해설; 영어 듣기; Home handoff; Guest; and Auth. Personal bookmark/recent
write acceptance remains a later Auth runtime check and was not executed here.

## Credentials and Owner command

The CLI accepts only the exact project ref, validates the direct host or
Supabase session pooler host, reads the DB password with `getpass`, and uses
`sslmode=require`. Passwords, keys, JWTs and connection settings are not
written to stdout, artifacts, wiki, Git, or shell arguments.

After separate approval and manual preflight, the one publication command is:

```sh
cd ~/development/legendstudy-app && python3 tool/publish_pilot_c.py \
  --project-ref stlhijzpjfgwwdgunlsd --publish --i-have-owner-approval
```

Do not run this command during D1. First run the default read-only command with
the same project ref and inspect its PASS; the Owner must also confirm the
current production project and baseline independently. No migration or RLS
change is required. Flutter code is unchanged.
