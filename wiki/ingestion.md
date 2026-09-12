# Ingestion Strategy

## Goal

Convert legacy and new content from `legendstudy.com` into stable, structured records for native app search, filtering, detail pages, and resource access.

## Design principle

Do not scrape/parse the website during normal app browsing.

Preferred flow:

`legendstudy.com` → ingestion process → normalized database → app

## Initial backfill

1. Discover historical posts through available sitemap/category/archive/index mechanisms.
2. Fetch individual posts.
3. Parse title, publication metadata, grade/exam/year/month/subject signals, and attachment/resource links.
4. Normalize into structured entities.
5. Preserve source URL and source identifiers for traceability.
6. Upsert idempotently.
7. Generate an ingestion report for parse failures and ambiguous records.

## Incremental ingestion

RSS or another lightweight feed may be used for new-post detection if verified reliable, but individual post content remains the source for detailed resource extraction.

## Required re-validation before implementation

Before parser code is finalized, verify:
- sitemap availability and completeness
- RSS/feed behavior
- category/archive pagination
- representative old vs new post HTML patterns
- direct PDF/audio attachment URL behavior
- robots/usage constraints
- duplicate/redirect behavior
- exam naming conventions across years

## Data-quality rule

Parser uncertainty must be recorded instead of silently inventing metadata. Raw source fields/source URLs should remain available for diagnosis.
