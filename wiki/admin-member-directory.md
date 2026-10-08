# Admin member directory — 2026-10-08

IMPLEMENTED / LOCAL_VERIFIED; Production009 pending Owner apply. LAB functionality
uses existing Admin gate and Member Detail → Student360008, no duplicate detail.
Existing006 Application+Events and007 Study stay unchanged. Target005 is HELD.

## Authority and contract

`public.admin_member_list` / admin-members-v1; exact auth.users→profiles identity.
`admin_operator()` plus `account_private.allowed(auth.uid())` each request;
normal/quality-only/missing/expired/deleting operator deny. No new admin flag/role.
25 rows/page(default), hard server maximum50. Offset is server-side, stable created_at
plus UUID tie-break, newest/oldest only. No entire user dataset in browser.
`total` is auth.users count, `filtered_total` count after all filters, independent of
page row count. Concurrent membership changes mean separate pages are not a frozen
export; reloading updates totals. No PII bulk export added.

Search: literal case-insensitive email/name substring, UUID exact; max254 chars.
No wildcard expansion or dynamic SQL. Filters: canonical latest account lifecycle,
academic student/retaker/other/unset, optional grade1..3, selected NEIS office/code,
school-unset. No invented parent/teacher values. Existing CANCELLED token preserved.

List fields: internal navigation account_id, display name/email, account status,
school **name** + grade/current status, intended major, created_at. UUID not rendered.
No raw school code, answer/body/artifact, phone, financial credential or free-form
student content returned. Credit is intentionally read in existing Member Detail;
no repeated credit_summary calls or financial arithmetic clone. Recent activity
omitted: no single cross-service activity fact has been adopted for this list.

## School display cache

Production inventory contains no school-name relation. Existing NEIS proxy returned
J10/7530932 진접고등학교 andR10/8750182 순심고등학교.009 contains only a small private
`student_private.school_display_cache` for verified referenced identities, not a
new national master or editable profile school_name. Code remains canonical; cache
name cannot change school selection/ownership. Source=NEIS and resolution time retained.
Owner-reviewed import only; no browser/service_role direct CRUD, RLS enabled.

List query joins cache in the same RPC. External NEIS requests per rendered member:0.
Interactive school **search** reuses the existing proxy only when operator searches;
individual existing Member Detail may still resolve its one school via that proxy.
Existing Dashboard resolver/aggregate is preserved, not rebuilt in this task.

Missing profile school → 학교 미설정. Code exists but cache lacks verified name →
학교명 확인 필요. New codes/name changes require a bounded reviewed cache refresh via
existing NEIS before insertion; no client-provided school name is trusted. No
unverified bulk crawl or extra scheduled infrastructure is installed. The current
2 verified cache entries cover the current Owner inventory, not all future schools.

## Seven preservation checks

1. Read current identity/status; do not manufacture historical school/activity times.
2. No existing member/profile/student fact is updated.
3. Display cache is replaceable external metadata, not student learning/history.
4. auth.users UUID is the existing cross-surface identity, hidden in primary UI.
5. Target/Application/Outcome unaffected; no new member classification collection.
6. Admin allowlist only; no role escalation/PII export/answers in list.
7. Real counts from source, never current-page size or invented activity/Credit.

## Verification and release

PGlite: directory/count/page/no-results/search/UUID/name/literal wildcard/school/status/
grade/sort/unknown-unset/privacy-key allowlist/anonymous-normal-quality-expired-denying
operator PASS. PG17 NOSUPERUSER postgres: exact package install, grants/RLS, actual
Admin read/anonymous-normal denial, collision refusal, rollback preserving users PASS.
LAB full539 tests, lint/typecheck/boundary/static build PASS. Browser fixture1440/390 Admin/normal/quality-only/anonymous, pagination, existing detail/Student360 and0 list NEIS requests PASS; authenticated Production acceptance pending.
APP UI/client unchanged, pinned Flutter runtime unavailable; no claim of Flutter pass.

Apply only009 with `tool/production/prepare_admin_directory.py` pinned to reviewed Git
SHA. Collision/function authority drift aborts entire transaction. No broad db push,
no005 or replay006–008. Postflight is catalog-only; separately verify authenticated
Admin list/detail and normal/quality-only denial. Rollback removes only new RPC/cache;
restore LAB old list first. Existing migration evidence is not silently rewritten.

Payment/Toss/Signup/IAP/global CSS/MY visuals unchanged. Existing Admin detail/QL,
Credit authority, account deletion and Student360 remain authoritative.
