# Integrated account/data follow-up — 2026-10-09

Implementation candidate only; NOT integrated into Claude RC. Base b59ca82 (latest
observed RC; Owner's45ac927 is a checkpoint). No APP UI/release/signing file edited.

- Existing profiles no longer require the APP-specific onboarding_completed_at
  marker to skip the full introduction. Missing optional fields remain MY edits;
  loading/error waits, guests and missing profiles retain their routes. This avoids
  treating a Web-created shared profile as a new account. No profile overwrites or
  backfill, email merges, or verification weakening.
- Profile repository rechecks current owner after async fetch. UI/route composition
  stays Claude-owned. Shared UUID, not client-side normalized-email lookup, is the
  authorization identity.
- Android Google SDK canceled can be ambiguous; it now maps to incomplete sign-in,
  not an assertion that the user cancelled. SDK configuration errors get a distinct
  safe message. iOS true cancellation/Apple/Kakao exchange unchanged. Device SDK
  configuration and signing certificate cause NOT confirmed or fixed by this alone.
- General content search/fallback now use published_at DESC, preserving original
  titles/search strings. IMPORTANT: existing advanced search still has exam-first
  sort_date then general streams and discovery year cutoff. Whole-catalog ordering
  is NOT closed; needs a verified query/pagination change, not just a label change.
- Existing Claude materialDisplayTitle already shortens delimiter-based Essay
  titles while preserving original DB titles. No competing presentation helper.

Tests updated for gate/error mapping/publication-order expectations. Could not run
Flutter: pinned3.47.6 absent; official distribution metadata unavailable from this
execution environment. Candidate must pass focused/full Flutter checks on existing
release toolchain before integration. No claimed APP test/device PASS.

Production read-only evidence: Google/Apple/Kakao enabled; confirmation on; verified
email duplicate groups0; linked identity rows share user_id; shared profile with
missing completion marker exists. This does not prove the Owner's exact device
failure. Authenticated test user's own profile/Essay/Math/Credit reads200; foreign
profile filter returned0. No manual merge or account data rewrite.

Materials: latest source_posts crawl Sep26; newest source publication Sep19;
active Essay content135. Only feedback/account cron jobs found; daily ingestion is
not scheduled in inspected DB. legendstudy.com source egress blocked, so recent
post discovery/ingestion/publication NOT performed. Existing bounded pipeline reused
as authority; no blind publication or invented source data.

Math: test token authenticates but its subject is NOT in existing Pages allowlist.
No identity impersonation/admin-key substitution/list expansion/evaluation call.
010 remains applied, switch false, private bucket retained. Four types GATED.

Web personal report consumes canonical Essay sessions/attempts/evaluations and
math_input history/read_input/read_result, credit_summary + existing ledger reads.
No new History DB. Native APP still only reads Essay History; native Math UI handoff
requires Claude integration. All-source query failures remain ERROR, not EMPTY.
