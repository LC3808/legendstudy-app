# Day 9-C1 — Resource Detail + Safe Open Target

Status: **implemented / local delivery validation PASS**. Original C1 evidence
is retained below; C2/C3 and the current delivery increment are separate records.

## Scope

- Reused the existing search-to-detail route, content detail provider, resource
  repository/provider and external-app launcher.
- Detail resources remain scoped to the requested `content_item_id` and preserve
  canonical subject names with raw-label fallback.
- User-facing resource labels are `문제`, `정답·해설`, and `영어 듣기`.

## Release-critical direct-open audit — 2026-09-25

`MATERIALS_DIRECT_PDF_OPEN` is release-critical. Phase A now routes a metadata-
validated PDF through Materials search → `/materials/:slug` `ContentDetailPage`
→ `ResourceSection` → `resolveResourceDelivery` → internal
`/materials/:slug/resource/:resourceId` `PdfViewerPage`. Non-PDF resources still
use `ExternalLinkButton`/`url_launcher` with `LaunchMode.externalApplication`.
Automated validation passes; Owner device acceptance is **FAIL** with viewer
entry count 0 across tested current materials. This is a data-contract gap, not
permission to weaken Safe Open: published modern Kakao resources are
`link_kind='unknown'` with unsigned identity locators, `file_url=NULL`, and no
PDF metadata, so the client correctly uses the original-source fallback.
`MATERIALS_DIRECT_OPEN` remains **RELEASE-CRITICAL GAP**.

The public resource model contains `resource_type`, `title`, `source_label`,
`source_url`, `link_kind`, optional `file_url`, MIME/extension/size, display
order and active status. `question`, `answer`, `explanation`,
`answer_explanation` and `listening_audio` are distinguishable metadata. The app
does not infer authority or PDF-ness from a filename or suffix.

`file` opens only a query-free HTTP(S) `file_url`; a PDF viewer target additionally
requires `application/pdf` MIME or `pdf` extension metadata. `landing_page` opens
the resource `source_url`; unknown/invalid targets fall back to the parent
original source. Auth/transient query names, fragments, userinfo and unsafe
schemes are rejected. Kakao signed/current URL re-resolution is not implemented:
stale or expired targets use Phase A failure UX and source fallback when available.
No raw token/query is displayed or logged. The launcher accepts any validated
HTTP(S) host rather than an explicit LegendStudy/provider allowlist; redirects
and remote availability are not verified locally.

Guest resource reads and direct opens are supported; bookmark and recent-view
writes remain authenticated. A resolved detail records a meaningful recent view
after ten seconds foreground dwell, a resource/original open attempt, or a
successful bookmark; an open attempt counts intent, not confirmed PDF reading.
The current failure UX is inline “외부 링크를 열지 못했어요. 다시 시도해 주세요.”
with source fallback where available.

Phase A uses `pdfrx` `^2.6.5` (MIT; Android/iOS; remote `PdfViewer.uri`, zoom,
scroll and loading/error hooks). It was selected over Syncfusion's Community/
Commercial license requirement and the narrower `flutter_pdfview` feature/
maintenance profile. No annotation, download manager, share, print or PDF byte
mirroring is implemented. Target architecture remains
`Content → stable resource identity → safe-open resolver → current valid target
→ in-app PDF viewer`, with trusted backend/source re-resolution planned for
Phase B and original landing-page fallback. Phase A does not make Kakao
`unknown` rows viewer-eligible.

## Phase B1 trusted resolver foundation — offline only

`supabase/functions/resource-resolver/` now records the minimum resolver
contract without a Supabase client, Edge deployment, or source request. The
client input is only a UUID `resource_id`; canonical resource/active-parent
lookup and a future injected source observer decide the target. Matching uses
`provider + source_resource_key`, never filename, position, or signed-query
equality. Responses are either `resolved/pdf` with the current short-lived
target or a bounded fallback reason (`not_found`, `inactive`,
`not_resolvable`, `source_unavailable`, `ambiguous`, `unsupported`).

The offline security foundation validates the LegendStudy numeric landing-page
host/path, known provider hosts, schemes, userinfo, private/special IPs,
manual redirects, 10-second timeout, 1 MB source response limit and three-hop
redirect limit. It never fetches attachment bytes and never logs a target or
signed query. HTML parsing remains a separate injected contract so the Python
ingestion parser is not silently duplicated in TypeScript. Production DNS
pinning/egress policy and rate limiting remain deployment requirements.

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

## Phase B2 preflight STOP — 2026-09-25

Historical checkpoint; superseded by the Owner-authorized B2 candidate below.

Starting code checkpoint5ef511c, B1ac9ec74 preserved. Owner's final B2 directive
supersedes earlier backend-only scope: eventual acceptance MUST include Guest
resource_id→trusted resolution→Safe Open→existing PdfViewerPage for question,
answer, explanation and answer_explanation. This preflight does NOT deliver that
integration. MATERIALS_DIRECT_OPEN remains RELEASE-CRITICAL GAP; Phase A automated
PASS / Owner device FAIL; B1 OFFLINE FOUNDATION PASS; B2 BLOCKED BEFORE IMPLEMENTATION.

### Stop evidence and boundaries

- B1 index.ts exports nothing: no serve/deploy activation. handler.ts injects fake-
  capable repository and observation, while its bounded fetch observer returns an
  empty attachment list. No production read-only repository/HTML parser exists.
- No shared Guest quota backend, atomic rate counter or trusted actor/gateway
  configuration is present in resource-resolver or Supabase configuration.
  Per-isolate memory limits/cache cannot establish a deployment-wide rate bound
  across restarts/regions/instances. This meets Owner STOP condition for required
  rate-limit infrastructure/configuration outside the currently safe repo scope.
  Do not invent a Redis subscription, DB migration or deploy a gateway here.
- [Supabase rate-limit example](https://supabase.com/docs/guides/functions/examples/rate-limiting)
  uses external Redis/Upstash. It is evidence for one supported approach, not proof
  Redis is the only solution. No external rate-limit infrastructure is approved
  or configured by this task. A reviewed atomic shared quota/gateway and verified
  actor derivation (not blindly trusted client forwarding headers) are required.
- Existing fetch uses hostname validation then ordinary fetch; no validated-IP
  binding or effective platform egress guarantee is established. DNS lookup then
  a separate fetch would retain a check/use race. The documented
  [Deno HTTP client options](https://docs.deno.com/api/deno/fetch/) expose TLS/proxy
  configuration but do not establish a validated remote-IP binding for this B1
  path. This is UNVERIFIED/OPEN, NOT a claim Supabase universally cannot pin DNS.
  Need a runtime-supported transport preserving TLS hostname/SNI while binding
  validated public destinations, or independently enforced egress, tested on the
  intended runtime without Production/source/PDF traffic before deployment.
- Current security primitive is incomplete for IPv4-mapped IPv6/nonstandard IP
  inputs; redirects admit HTTPS→HTTP and source-boundary/port review remains.
  Existing10 offline tests do not certify these B2 security requirements.
- SOURCE_TIMEOUT_MS is per-fetch10s, not proven total redirect/body deadline.
  Stream byte limit1MB exists; compressed-body adversarial coverage is pending.
- Ingestion parser classifies Kakao provider + first two dna path segments as
  stable key. normalizer intentionally keeps unknown/file_url NULL. apply.py
  persists source_resource_key but not a provider column. Repository mapping
  from canonical provenance must be reviewed; no fabricated provider/key, no
  missing-schema/migration conclusion asserted from this preflight alone.

### Required restart decisions

Select/authorize the shared quota enforcement and actor trust contract, plus a
verifiable egress transport/deployment requirement. Then implement read-only
repository + minimal Python-parity observer + expiry-bounded memory cache + full
security matrix + Flutter integration. A cache is an optimization, not a quota or
correctness guarantee. Keep signed targets ephemeral; do not alter ingestion,
canonical link kind, PDF storage or Safe Open to bypass the gates.

No B2 code, Flutter change, migration, deployment, Production invocation/source
fetch/PDF fetch or Daily Sync Phase2. No B2 integration/security/build PASS claim.
B1 tests rerun offline:10PASS with --no-remote and no network permission. Wiki links,
secret scan and diff checked. Claude can review this blocker handoff; a completed
B2 code candidate is NOT ready. Production deployment remains NO. Owner device
PDF NOT VERIFIED for B2 (historical Phase A device FAIL remains).

## Phase B2 implementation candidate — 2026-09-25

Historical implementation checkpoint. Current activation readiness and Owner-applied
quota evidence are in [Production activation preparation](#production-activation-preparation--2026-09-25) below.

Owner Resume decisions supersede the preflight's no-migration/unknown-egress
assumptions, not ingestion safety. Starting6031fae. **MATERIALS_DIRECT_OPEN_CODE:
IMPLEMENTED candidate; PRODUCTION_DEPLOYED:NO; OWNER_DEVICE_PDF:NOT VERIFIED.**
Phase A Owner FAIL remains historical evidence; release-critical direct-open is
not closed until Claude review, controlled deployment and real device acceptance.

### Architecture gates and security boundary

- **A canonical source:** resources.id→content_items.id→source_posts.id. Require
  the resource and parent source_post_id to agree, source=`legendstudy`, status
  `available`, numeric external_post_id, active resource and parent. Construct
  exactly `https://legendstudy.com/<id>`; no DB/client URL is fetch authority.
  Cross-post provenance is valid elsewhere but conservatively falls back here.
- **B quota:** resolver-only migration20260925000100, repository file only.
  Postgres RPC serializes global/resource decisions with one transaction advisory
  lock, shared across Edge instances and restarts. Fixed minute600 global calls,
  12 per resource. Global counts resource-denied and unknown-UUID calls too;
  malformed input never reaches RPC. Defaults are coarse MVP source-fetch bounds,
  not per-user fairness or protection from invocation/DB-cost denial of service.
  No trusted gateway actor demonstrated: do not trust client X-Forwarded-For.
  No IP/user data collected. No Redis/gateway subscription introduced.
- **C provider:** persisted unsigned resources.source_url must be strict HTTPS
  blog.kakaocdn.net/dna/<segment1>/<segment2>/..., with no query/fragment and exact
  equality to persisted source_resource_key. This reconstructs provider from
  stored provenance, not filename/order/signature. Missing/mismatched evidence
  falls back. No provider schema migration. Supported identity subset is narrower
  than Python's permissive parser; unsupported historical forms fail closed.
- Application guarantee: only one constructed canonical hostname, HTTPS443, no
  credentials/query/fragment, no redirects at all (including same-host/HTTP).
  Literal IPs, mapped IPv6 and nonstandard IPv4 are rejected. No arbitrary proxy.
  **No DNS pinning or verified platform private-IP egress firewall is claimed.**
  Native fetch/TLS performs DNS and certificate validation. Compromise of trusted
  domain/DNS/routing/CA or runtime remains infrastructure residual risk; fixed
  destination removes client-controlled rebinding authority. Claude must assess
  this residual before any activation. DNS lookup followed by ordinary fetch is
  intentionally not presented as pinning.
- Landing fetch10s total including body; actual decoded HTML≤1,000,000bytes,
  regardless of missing/lying Content-Length. Only HTML200. Tests feed a gzip
  decompression stream through the byte limiter; target Supabase runtime decoding
  remains a deployment verification item, not a Production test claim.
- Server repository uses service credential only against fixed configured project
  REST endpoints: three SELECTs and quota RPC. Existing service-role credential
  has broader platform powers; adapter exposes no content writes. It must stay in
  Edge secrets, never Flutter. No claim that this credential is intrinsically
  read-only. index.ts still exports nothing; candidate.ts is not auto-started.

### Observation and delivery

Minimal article-anchor observer recognizes Tistory article containers and current
Kakao href metadata. Shared synthetic fixture derived from existing ingestion
MODERN_HTML is read by Python and Deno. Stable provider/key agree under signature
rotation. Multiple matches decline as ambiguous (unlike ingestion deduplication).
No HTML is stored/logged. Canonical PDF resource type plus current attachment
PDF label/MIME evidence is required; contradictory media metadata declines.
Backend never downloads PDF bytes and cannot verify file contents. Client loader
also requires `%PDF-` before handing bytes to the existing PDF engine.

Signed target exists only in no-store response and transient App memory; expiry
must be in the future. **Cache intentionally absent**: no stale signature cache,
no DB/Storage target persistence. Shared quota bounds repeated source observations.
Cache hit/expiry/isolation tests N/A; adding one later needs expiry-aware review.

Flutter sends resource_id only, supports Guest, keeps DB unknown unchanged and
revalidates response ID/kind/HTTPS/host/path/credentials/expiry using existing
publicWebUri Safe Open plus tighter Kakao rules. Four CTA types use the resolver;
audio/non-PDF existing paths remain. Failures show “자료를 바로 열 수 없어요.”,
retry and original source. No technical errors or targets displayed. Existing
meaningful-action hook remains one call per attempted open; no signed history.
PdfViewerPage is reused. Signed deliveries use bounded in-memory HTTP (30s,
32MiB, no redirects) then PdfViewer.data with a non-URL source name. They never
reach pdfrx's URI/disk-cache path. Retry re-resolves resource_id for a fresh target rather than reusing an expired
signature. Oversize/download failures use existing original source fallback; public Phase A URI delivery behavior is unchanged.

### Migration, validation and rollback handoff

**Do not apply now. Claude independent security review and Owner decision first.**
Then review `supabase/migrations/20260925000100_resource_resolver_quota.sql`:
new quota table only, RLS enabled with no client policy; all direct table grants
revoked including service_role. SECURITY DEFINER function has empty search_path,
fully qualified objects and service_role-only EXECUTE. Global transaction lock
has500ms timeout and failures close access. TTL is two minute-window boundaries;
expired counters are removed lazily, at most128/request. Idle expired rows remain
until traffic resumes; no scheduler. At most600 new resource keys/minute under
this RPC. No personal or content records/URLs in this table.

Before activation in an isolated database, verify:
1. anon/authenticated/public cannot EXECUTE RPC or SELECT quota table.
2. service_role can EXECUTE RPC but cannot access table directly.
3. 12 calls to one UUID succeed,13th declines; a second UUID is independent;
   total600 attempts exhaust global budget; next minute resets.
4. Multiple concurrent connections never exceed12/resource or600/global; timeout
   returns safe fallback. Inspect bounded cleanup and old-window reset.
5. No content/source/resource rows or grants changed.

Permission inspection (read-only, after approved apply):
```sql
select relrowsecurity from pg_class
where oid = 'public.resource_resolver_quota'::regclass;
select rolname,
  has_function_privilege(rolname, 'public.consume_resource_resolver_quota(uuid)', 'EXECUTE') as rpc,
  has_table_privilege(rolname, 'public.resource_resolver_quota', 'SELECT') as direct_read
from pg_roles where rolname in ('anon','authenticated','service_role');
select prosecdef, proconfig from pg_proc
where oid = 'public.consume_resource_resolver_quota(uuid)'::regprocedure;
```
Expected RLS=true; RPC false/false/true, direct_read allfalse, definer=true,
search_path empty. Runtime quota threshold/concurrency tests are **NOT RUN** in
this task (no isolated Postgres available); static lock/threshold/cleanup/grant
contract tests and PostgreSQL grammar parsing are the local evidence.
Rollback only after disabling endpoint: drop function
`public.consume_resource_resolver_quota(uuid)` then drop table
`public.resource_resolver_quota`; no CASCADE or content changes. No target data
needs migration. Do not run rollback while an active endpoint depends on quota.

### Automated validation and remaining gates

Final automated evidence: Flutter788PASS/1existing skip; analyze and both native
builds PASS. Focused resolver23 tests include8 size/text-scale loading/error/retry
cases. Deno48PASS (resolver23), ingestion170PASS, Python parity/quota-static2PASS;
pglast parses9 SQL statements/1 PLpgSQL function. Secret/diff/Wiki checks PASS. Offline tests
cover canonical lookup, provider parity, ambiguity, inactive parent/resource,
URL/IP/redirect abuse, timeout, stream/gzip bounds, quota denial/error, safe errors,
Guest four-CTA viewer routes, network/fallback/unsafe response, in-memory loader,
and360×640/428×926 at1×/2×. No Production requests or device acceptance.

Remaining deployment prerequisites: independent Claude security review; Owner
quota migration with runtime concurrency/permissions acceptance; endpoint/secret
configuration and Guest gateway JWT policy reviewed before index activation;
controlled real source observation/target-runtime egress+decompression verification;
then iPhone/Android acceptance. No deploy, Production migration/invocation/source
fetch/PDF fetch, Storage copy, ingestion modification or Daily Sync Phase2 here.


## Production activation preparation — 2026-09-25

Starting4b90a47. Owner reports Claude final review **B2_CODE_ACCEPTANCE:PASS**,
**PRODUCTION_MIGRATION_READY:YES**. Previous deployment conditions were quota
runtime verification and Guest gateway cost protection. Owner now reports quota
migration applied and runtime acceptance PASS, and explicitly accepts remaining
Guest invocation/DB-cost DoS as **ACCEPTED MVP OPERATIONAL RISK**. This supersedes
prior candidate-only/not-applied and disabled-entrypoint statements above.

**PRODUCTION_ENDPOINT: READY TO DEPLOY / NOT DEPLOYED.**
**OWNER_DEVICE_PDF: NOT VERIFIED.** No new claim that the Materials release gap
has closed; controlled deployment and actual source/PDF/device acceptance follow.

### Owner quota runtime acceptance

Owner-executed Production evidence (not queries run by Codex): RLS=true;
anon/authenticated RPC=false; service_role RPC=true; all direct quota table
SELECT/INSERT/UPDATE/DELETE=false; SECURITY DEFINER=true; search_path empty.
Same resource calls1–12 allowed,13 blocked; different resource independent;
next-minute reset PASS. Global600/min and resource12/min remain unchanged and
mandatory/fail-closed. The supplied evidence does not separately report a global
600-call exhaustion test or parallel-connection stress test; do not invent those
results. Prior local static/grammar tests remain distinct from Owner runtime PASS.
Migration20260925000100 is unchanged by this task; do not reapply it.

### Guest entrypoint and server environment

`supabase/functions/resource-resolver/index.ts` registers the existing reviewed
candidate via Deno.serve when executed as the entry module. Imports have no listener,
secret-read or network side effect, matching the existing worker main-entry guard.
Candidate construction preserves CanonicalRepository, bounded observer and quota
RPC with no alternate unmetered path. Missing/invalid environment uses existing
safe fallback/CORS/method/input handling and never fetches DB or source.

`supabase/config.toml` explicitly sets `[functions.resource-resolver] verify_jwt=false`.
This is an intentionally public Guest endpoint: no sign-in/session JWT is required,
and caller Authorization/apikey values never authorize privileged database access.
Request input remains resource_id only; server canonical relationship checks and
quota remain mandatory. This is not user-authorized personal data access. Existing
personal feature auth boundaries and other function settings are unchanged.

Required platform-provided server environment:
- `SUPABASE_URL`: dedicated LegendStudy HTTPS project URL. Existing repository
  adapter validates hosted-project origin; not supplied by the request.
- `SUPABASE_SERVICE_ROLE_KEY`: existing platform-provided legacy service-role key,
  server-only. Reuse reviewed REST adapter/header contract; no key migration or
  new custom secrets in this task. Never send to Flutter, source HTML fetch, logs,
  responses, command-line arguments or committed config.

No NEIS key, Redis/Upstash/Cloudflare or client secret is required. Before later
controlled deploy, the operator confirms these platform variables exist in the
correct project without disclosing their values. Presence/validity was not checked
by accessing Production secrets in this task. Supabase documents the
[default Edge environment](https://supabase.com/docs/guides/functions/secrets) and
[public-function JWT policy](https://supabase.com/docs/guides/functions/auth).
This implementation reuses the still-provided legacy service-role environment;
modern key/SDK migration is a separate reviewed change, not implicit scope here.

### Accepted risk and unchanged safeguards

The quota protects bounded downstream source work. It **does not protect Edge
invocation cost, prevent all DB-cost DoS, identify Guests, or guarantee fair usage**.
A caller can consume shared capacity or repeatedly invoke the quota RPC through
the public handler, denying others temporarily and incurring cost. Owner accepts
this MVP operational residual; no gateway limiter is falsely claimed. No external
limiter is introduced. Anon/authenticated direct RPC remains forbidden.

Preserved: resource_id-only input; canonical numeric source; HTTPS/no redirects;
mandatory shared quota; ephemeral/no-store signed targets; no PDF backend fetch,
Storage/mirroring or signed persistence; Flutter Safe Open revalidation. Existing
fixed-host DNS/TLS residual remains as assessed in B2 review, not IP-pinning.

### Validation and next handoff

Deno52PASS including27 resolver tests (4 new entrypoint/config tests), executed
without network permission. Real candidate factory is exercised with offline
transport fixtures: Guest/no auth, caller-header isolation, quota-first order,
resolved output, safe config failure, denied/error quota, OPTIONS/input/method
handling and checked-in verify_jwt policy. Entrypoint type check PASS.
Flutter/migration/ingestion code unchanged; Flutter tests/builds not rerun for this
server wiring task (previous788PASS/1skip and both builds remain historical).
Secret-pattern scan, diff and Wiki links/routing PASS. Owner iOS/untracked preserved.

Next authorized *preparation* state is ready for controlled deployment; no deploy
command was executed here. Separate next step: deploy only resource-resolver to
LegendStudy with this checked-in Guest policy, then bounded real resolver/source
acceptance and iPhone/Android PDF checks. Do not confuse repository entrypoint
activation with an already deployed endpoint. Production invocation/source/PDF
fetch/mutation0 in this task. Daily Sync Phase2 NOT STARTED.


## Focused source-unavailable diagnostic — 2026-09-25

Startingfee8112. Owner reports resolver v1 **DEPLOYED / ACTIVE**, Guest invocation
works, but controlled request returned `fallback/source_unavailable`. Resource
74658215-857a-5d14-aceb-1e85252e049c and post1709: active resource/parent,
matching provenance, legendstudy source, available status, question/unknown and
stable key presence verified by Owner. Owner external check of canonical source:
HTTP200, text/html;charset=UTF-8, Content-Length89336. This does not establish the
same network/HTML behavior from Edge. **Root cause NOT YET DETERMINED.** No new
Production/source/PDF invocation by Codex. New diagnostics require separate redeploy.

### Every source_unavailable path

| Code path | Cause | Safe diagnostic |
|---|---|---|
| index configuration catch → failing quota stub → handler catch | missing/empty environment, environment-read exception, invalid project URL/configuration or factory construction exception | config_failed (startup), then quota_failed |
| handler quota await throws | REST fetch/TLS/timeout, non-OK quota RPC status, bounded response failure, JSON parse error, other quota exception | quota_start → quota_failed |
| repository findById throws → handler catch | any of three REST reads: network/timeout, non-OK response, body bound/read/decode failure, JSON parse or unexpected repository exception | repository_start → repository_failed → resolver_failed |
| observer rejects canonical boundary | observer source guard returns null (normal resolver guard rejects earlier as not_resolvable) | source_boundary_rejected → observer_unavailable |
| observer fetch throws | network/DNS/TLS/runtime rejection, without raw exception text | source_fetch_failed |
| observer non-200 response | includes redirects/404/etc.; cancellation failure also caught | source_http_rejected + numeric status |
| observer HTTP200 non-HTML | missing or unsupported content type | source_body_rejected/type |
| observer bounded reader returns null | declared/streamed size, absent body, abort, read failure, invalid UTF-8 decode | source_body_rejected with size/empty/aborted/read_error/decode_error |
| observer deadline | total fetch/body deadline races to null | source_timeout with fetch/body/parser phase |
| HTML parser returns null | leftover raw-text/comment, duplicate attributes, nested anchor, stack/attachment cap, missing article container, unclosed anchor | observer_failed with fixed parser reason |
| observer other exception | parser or other observation work throws; injected observer throws at resolve boundary | observer_failed/exception |
| observer null reaches resolveResource | any null observation above | observer_unavailable (terminal observation marker) |
| other resolver/response exception inside handler try | unexpected post-quota resolution/matching/serialization failure | resolver_failed; preceding stage identifies last boundary |

Not source_unavailable: quota returns false→rate_limited; repository returns
null→not_found; inactive→inactive; unsupported provider/media→unsupported;
no match/invalid current target→not_resolvable; duplicate match→ambiguous.
Malformed request-body parse/read exceptions remain HTTP400 invalid_request.
Exceptions outside the handler's resolution catch may be platform errors, not this
bounded fallback. No raw exception names/messages/stack traces are logged.

### Logging contract and interpretation

Production entrypoint enables JSON console.info via closed stage/reason allowlists.
Each valid request gets an unrelated random trace_id for concurrent log grouping;
no resource ID, key, URL, query, HTML, headers, cookie, credential or user data is
logged. Only HTTP status100–599 and attachment_count0–1001 are numeric details.
Unknown fields/stages/reasons are discarded, and sink failures are swallowed.
Config failure gets its own startup trace; request-level quota failure follows.
No per-byte/attachment logging, extra fetch, retry, quota change or client field.

After a separately authorized diagnostic redeploy, inspect resolver_stage records
for the controlled request: repository_ok confirms lookup returned a canonical
resource; source_fetch_start confirms observer entry; HTTP/body/parser reasons
pinpoint the rejecting boundary. observer_ok attachment_count=0 followed by
match_none differs from parser failure. resolved never includes target. Keep the
full safe stage sequence/trace, not raw HTML or signed attachment evidence.

Deno58PASS (resolver33) including safe-stage/redaction/response-equivalence cases;
no network permission. Existing security/entrypoint tests pass. Logging-disabled,
logging-enabled and throwing-sink successful responses match behavior. Tests cover
configuration/quota/repository exceptions, HTTP/type/size/read/decode/parser failures,
timeout, empty and ambiguous match. Secret/diff/Wiki checks PASS. No Flutter,
repository queries, matching/security/quota policy, migration, ingestion or Daily
Sync changes. **READY_FOR_DIAGNOSTIC_REDEPLOY:YES; THIS TASK DEPLOY:NO.**
Owner device PDF remains NOT VERIFIED; accepted Guest cost risk remains unchanged.


## Scoped duplicate-attribute correction — 2026-09-25

Starting669ad07. Owner reports the diagnostic trace quota_ok → repository_ok →
source_fetch_start → observer_failed/duplicate_attribute → observer_unavailable.
Owner's separate privacy-safe inspection of public post1709 found exactly one
such tag: unrelated head/meta with duplicate content. It was not an attachment,
href or article identity attribute. This supersedes the earlier unknown-cause
checkpoint; Codex did not fetch Production HTML or invoke the resolver.

Reproduced before modification using only synthetic `<meta content="A" content="B">`
plus the existing synthetic article/Kakao fixture. No Production HTML, attribute
values, signed targets, cookies or user data are stored in tests/Wiki/artifacts.

Before: any parsed duplicate attribute anywhere rejected the entire document.
After: duplicate attributes on any anchor, markup within an active attachment
anchor, or div/class (the article trust-boundary attribute) remain fatal. This
conservatively rejects even equal duplicate href/class values and unknown duplicate
anchor attributes. Other unused meta/presentation attributes do not invalidate
observation; their duplicate values are skipped and never used for identity or
boundary decisions. There is no first/last href resolution. Article requirement,
nested/unclosed-anchor rejection, exact Kakao identity matching, ambiguity fallback,
PDF evidence and every transport/quota/security bound are unchanged. Safe stage
logging is retained without added fields or sensitive detail.

Validation: all Deno62PASS (resolver37), offline without network permission;
Python/Deno shared identity + quota static contracts2PASS. Added tests cover meta,
presentation inside/outside article, identical/conflicting/case-folded href,
identity/MIME attributes, ambiguous article classes, nested/unclosed anchors,
rotated signatures and duplicate matching attachments→ambiguous. Existing diagnostic
redaction and security/adversarial tests PASS. Secret-pattern scan, diff check and
Wiki handoff PASS. Flutter/DB/quota/repository/ingestion unchanged.

**READY_FOR_CONTROLLED_REDEPLOY:YES** for this parser correction after checks.
No automatic deploy, Production resolver/source/PDF request or mutation. Next:
Owner-controlled redeploy and bounded acceptance, checking observer_ok then resolved
without logging targets. Actual Production success and Owner device PDF remain
**NOT VERIFIED**; local synthetic success is not a Production acceptance claim.


## Materials detail cleanup and Owner PDF acceptance — 2026-09-25

Owner reports **MATERIALS_DIRECT_PDF: OWNER DEVICE PASS**: actual iPhone problem
and answer PDFs open inside the app; Production resolver resolved/pdf PASS.
This supersedes prior device FAIL/pending and resolver redeploy checkpoints above.
It is Owner evidence, not a Production call performed by this UI task.

Starting7c98778, presentation-only cleanup:
- Shared `materialDisplayTitle` formats search results/detail only for exam titles
  with the explicit exam-name + 기출 - 문제/답(or 정답)/해설 suffix. Unknown patterns
  and other content types keep their original text; DB title/search queries intact.
- Detail omits published/source-updated dates; source attribution and one top
  원문 보기 remain. Existing surface tokens and exam metadata remain unchanged.
- One accordion per canonical display label; occurrence IDs and resource IDs remain
  distinct within it. Existing projected raw_subject_label supplies multi-occurrence
  headings without taxonomy guesses; absent labels are not invented. Single
  occurrences retain the flat existing resource layout. Equal raw labels do not
  deduplicate occurrences/resources. Content+group storage keys retain toggle state.
- Normal resource-local source buttons removed. Unsupported direct links point to
  the top source action. Resolver failure retains 다시 시도 + 원문에서 보기; viewer
  error fallback and audio external-open behavior unchanged. Resolver, PDF viewer,
  Safe Open, backend, projection query and ingestion untouched.

Validation: analyze PASS; full Flutter795PASS/1existing skip; focused Materials,
search, delivery, resolver tests PASS. Group responsive checks360×640/428×926 at
1×/2×; existing render run10PASS with12 PNGs and 2× screenshot inspection. Search
continues to find raw SEO terms despite shorter labels. Date/source, duplicate
occurrence/no-loss/toggle, Guest question/answer/explanation, failure and audio
regressions PASS. No DB/network/Production mutation or deployment.
**UI_CLEANUP: AUTOMATED PASS / OWNER DEVICE NOT VERIFIED.** No EOD closeout yet.
Next Owner checks search/detail title, hidden dates, single source action, one
국어 group with existing variants, direct PDFs and failure fallback; only then
perform a separate whole-day Wiki closeout.


## Owner final title and classification corrections — 2026-09-25

Startingdc415a5. Latest Owner override supersedes the strict mock SEO-suffix rule:
exam titles containing 모의고사/모의평가 display through the first such word.
Existing conservative CSAT suffix handling remains; non-exam titles/raw persisted
values are untouched. One pure materialDisplayTitle is reused by search, detail,
saved/recent (including accessibility label) and shared material cards; no screen
copies or data rewrite. Source copy is now 출처: 레전드스터디 닷컴.

Badge root cause: generic content_type=exam map labeled every exam 모의고사;
personal cards did not read exams.exam_type. Existing batched examMetadataProvider
now hydrates personal-list presentation, without changing bookmark/recent storage.
Shared materialTypeLabel uses csat→수능, national_mock/evaluation_mock→모의고사,
existing non-exam labels unchanged. Missing/other exam metadata→시험 자료, not a
fabricated mock classification. Search results/detail/shared cards use the same
mapping. Search filters already use csat; no title-derived taxonomy/query change.
Home-specific files/layout/behavior were not edited; shared material rendering
naturally uses the same title/badge rules wherever reused.

Analyze PASS; focused72PASS: formatter examples, search/detail, saved/recent
CSAT/mock/evaluation titles/badges, raw-title retention, bookmark/recents isolation
and mutations. Diff/Wiki handoff PASS. No full suite/build rerun required for this
scope. No DB/ingestion/resolver/PDF/OAuth/Production changes. Owner iOS/untracked
preserved. Owner next verifies source copy + search/saved/recent titles and badges.
Prior direct-PDF OWNER DEVICE PASS retained; this UI correction device NOT VERIFIED.
