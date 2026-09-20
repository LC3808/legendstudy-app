# Day 9-C1 — Resource Detail + Safe Open Target

Status: **implemented / local delivery validation PASS**. Original C1 evidence
is retained below; C2/C3 and the current delivery increment are separate records.

## Scope

- Reused the existing search-to-detail route, content detail provider, resource
  repository/provider and external-app launcher.
- Detail resources remain scoped to the requested `content_item_id` and preserve
  canonical subject names with raw-label fallback.
- User-facing resource labels are `문제`, `정답·해설`, and `영어 듣기`.

## Current delivery contract — 2026-09-20

Materials is an independent free core product, not an Exam Engine prerequisite
or a synonym for Viewer. Search → identify → external access → return →
bookmark/revisit is this increment's scope. No mirrors, new viewer, remote probes,
rights decision, ingestion change or Production mutation.

### Audited data and limits

Checked the explicit `SupabaseResourceRepository.projection`, initial schema
and public column grants against the recorded deployment contract. No live
Production schema/API request was performed in this increment; repository and
prior deployment evidence are not a fresh remote-schema verification.

- Public resource: content/occurrence IDs, type/title/source label, `source_url`,
  `link_kind`, `file_url`, MIME/extension/size, display order, active status and
  nested subject/raw label. MIME/suffix/type alone does not establish a file URL.
- Parent `content_items.source_url` is the curated original-post link.
  `source_posts.url`, source identity and provenance are backend-only; no separate
  public canonical URL or official-source/rights field exists.
- `link_status` (unchecked/available/broken/restricted) and `last_checked_at`
  exist internally but are excluded from public grants/projection. There is no
  public expiry or authentication-required field. Do not query private columns.

| Situation | What today's public contract can establish |
|---|---|
| A: file URL | Explicit file kind + valid file_url; not current HTTP availability |
| B: landing/source | Explicit landing kind uses resource source_url; parent source is separate |
| C: official source | Not independently identifiable; never inferred from host or purpose |
| D: unknown URL kind | Parent original only; never promote resource URL based on .pdf suffix |
| E: no usable URL | Parent fallback if valid, otherwise unavailable |
| F: expiring URL | No authoritative expiry; recognizable transient URLs handled conservatively |
| G: login required | No authoritative flag; recognizable auth routes rejected, hidden restrictions unknown |

### One resolver, one action

`resolveResourceDelivery` in `content_resource.dart` supplies kind, URI, CTA,
explanation and optional original fallback. The old URI helper and model getter
delegate to it. Presentation consumes this action and does not guess URL types.
Local kinds are externalFile/externalPage/sourcePage/unavailable, not DB enums
and not legal rights states.

- Explicit `file`: valid HTTP(S) file_url with no query/fragment or recognizable
  auth path. Extensionless URLs are allowed; source_url is never promoted to file.
- Explicit `landing_page`: valid resource source_url without recognized auth or
  signed/expiry indicators. Ordinary page query parameters remain supported.
- Invalid/missing file or landing target, unknown/future kind, query-bearing file,
  fragments and recognized auth/transient hints fall back to valid parent source.
  If the parent is also unusable there is no enabled open action.
- Conservative limitation: even benign `?download=1` file links fall back today.
  This is uncertainty handling, not a claim that every such URL is expired.
  Hidden auth walls, revoked/404 files and opaque signed paths cannot be detected
  reliably from public metadata. No remote HEAD/download or bypass is attempted.
- The parent fallback applies the same page safety check. Unknown resources never
  open their resource source_url. No fabricated official-source classification.
- File CTAs retain purpose-specific `문제 보기`, `정답·해설 보기`, etc.; landing
  CTAs explicitly say `자료 페이지 보기`; fallback says `원문에서 보기`.
  Only the destination host is displayed, not potentially sensitive path/query.
  Direct/landing actions also offer `원문에서 찾기` when a distinct parent exists,
  including when the browser opens successfully but the destination is unusable.
- `ExternalLinkButton` retains externalApplication launch, duplicate-call guard
  and safe error copy. Failure is now inline at that action with live-region
  semantics and retry; it does not replace content or unrelated resources.
  Replacement URIs clear old errors. OS launch success does not prove file access.

### Grouping, return and adjacent boundaries

Parent detail identifies the exam; occurrence-ID groups identify subjects and
cards identify resource types. Distinct occurrences sharing a subject label are
not merged. Existing display order, >8-resource initial collapse and expansion
PageStorage keys are preserved; no taxonomy/grouping redesign.

Search query, filters, loaded pages and scroll remain in the existing mounted
Materials branch; detail is pushed above it. Filters/detail/external opening
request keyboard unfocus; native modal/keyboard transitions can briefly retain it. Returning retains state without a new search. Scroll can
clamp to the new maximum or adjust by the bottom safe area when closing an OS
keyboard enlarges the viewport; this is not a reset. No process-kill persistence promise is added.

Recent views are content-level intent/dwell, not confirmed file consumption:
foreground 10 seconds OR resource/original open attempt OR successful bookmark.
Even a failed launcher attempt qualifies intent. Guest performs no recent write.
See [current recent contract](day-11-account-personal-feedback.md#meaningful-recent-views-v2).

Search-row bookmark HOLD from the delivery increment is now resolved separately:
[inline bookmark](day-9-c-personal-state.md#materials-inline-bookmark--2026-09-20)
uses bounded ID-filtered membership queries and one list/detail optimistic store.
The recent-100 saved list is never treated as the complete saved membership set.
Delivery resolution and recent-view rules are unchanged.

Rights and delivery remain independent; externalFile is not OWNED/LICENSED/OPEN.
Future sync can replace URLs or deactivate resources through existing refresh
paths; it cannot be assumed to send private health fields. Scheduler, rights
schema, mirror, viewer, LS LAB and Historical work remain untouched.

## Original C1 validation (historical)

- Relevant repository/UI tests: PASS, 32 tests.
- Coverage includes unknown fallback protection, landing-page routing, file and
  malformed target rejection, labels, subject grouping, loading/error/retry,
  empty resources, long content, 2× text, and 360×640 layout.
- No bookmark, recent-view, MY, DB, ingestion, publication, or Production data
  change is part of C1.

Follow-up integrations are documented in [C2 personal state](day-9-c-personal-state.md)
and [C3 personal lists](day-9-c-personal-lists.md).


## Delivery increment validation — 2026-09-20

- Full Flutter suite **472 PASS / 1 existing skip** (baseline 446); focused
  policy/resource/Core **64 PASS**, Guest widget journey **2 PASS** at 360×640,
  1×/2×. Analyze PASS; Android debug and iOS simulator builds PASS.
- iPhone 16 Pro/iOS18.6 **offline integration 2 PASS**, 1×/2×: real app routes,
  search/filter/three paginated rows → detail → failed direct opener → explicit
  original fallback → simulated background/resume → return, with no repeat
  query, selected row visible and retained input/filter/results. Scroll check
  accounts only for extent clamping and the OS bottom safe-area adjustment.
- Initial native assertion exposed keyboard/safe-area changes (34 logical px),
  not a search reset. Filter keyboard-unfocus request added; test samples settled
  frames and asserts the selected row remains visible rather than demanding
  impossible identical pixels across differently sized viewports.
- Actual simulator screenshots reviewed for normal/large text, resource-local
  failure, source fallback and return; 360×640 widget renders reviewed too.
  Evidence: `/private/tmp/legendstudy-delivery-native/delivery-*.png` and
  `/private/tmp/legendstudy-core-ui/delivery-*.png` (not committed).
- Integration repositories and external opener are doubles: **no real website,
  file availability, browser return or Production E2E success is claimed**.
  The native test is reusable as `integration_test/materials_delivery_test.dart`.
- Credential-pattern/logging scope checks and `git diff --check` PASS. No backend,
  rights, mirror, viewer, Auth/Study/brand or Historical change; mutation 0.
- Owner next: verify representative current file/landing/original destinations
  and actual browser/app return on iPhone/Android. Health/auth/expiry cannot be
  fully certified with the public contract. Existing policy/Auth/deletion release
  gates remain; MATERIALS DELIVERY UX COMPLETE YES (local scoped implementation),
  DIRECT RESOURCE ROUTING READY YES, RELEASE READY NO.
