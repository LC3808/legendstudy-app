# Day 9-C1 — Resource Detail + Safe Open Target

Status: **implemented / runtime validation PASS**. This is C1 only; Day 9-C
overall is not complete.

## Scope

- Reused the existing search-to-detail route, content detail provider, resource
  repository/provider and external-app launcher.
- Detail resources remain scoped to the requested `content_item_id` and preserve
  canonical subject names with raw-label fallback.
- User-facing resource labels are `문제`, `정답·해설`, and `영어 듣기`.

## Open-target contract

`resolveResourceOpenUri` is the single target resolver used by the detail UI:

- `unknown`: opens `ContentItem.sourceUrl`; `resource.sourceUrl` is never used.
- `landing_page`: opens the resource `sourceUrl` (Pilot C Box listening page).
- `file`: opens only a valid HTTP(S) `fileUrl`; it never infers a file from
  `sourceUrl`.
- Missing, malformed, unsupported, or unsafe targets remain unavailable and do
  not launch.

`ExternalLinkButton` continues to use `LaunchMode.externalApplication` and
suppresses platform/raw URL details on failure.

## Validation

- Relevant repository/UI tests: PASS, 32 tests.
- Coverage includes unknown fallback protection, landing-page routing, file and
  malformed target rejection, labels, subject grouping, loading/error/retry,
  empty resources, long content, 2× text, and 360×640 layout.
- No bookmark, recent-view, MY, DB, ingestion, publication, or Production data
  change is part of C1.
