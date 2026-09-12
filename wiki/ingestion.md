# Ingestion Strategy

## Goal

Convert legacy and new content from `legendstudy.com` into stable, structured records for native app search, filtering, detail pages, and resource access.

## Design principle

Do not scrape/parse the website during normal app browsing.

Preferred flow:

`legendstudy.com` → ingestion process → normalized database → app

## Verified source observations — 2026-09-12

- The site currently exposes 1,673 items in the overall archive.
- The home/archive listing includes high-school mock exams, CSAT-related material, and university essay/논술 material.
- Exam posts commonly contain multiple downloadable resources inside a single post, including problem PDFs, answer/explanation PDFs, English listening MP3 files, and grade-cut images/information.
- Naming varies by year and subject. Examples include separate Korean language options, mathematics options, social studies subjects, science subjects, and integrated subjects.
- Recent and older posts share the same broad concept but are not guaranteed to use identical filename/title conventions.
- Website access is intentionally public without mandatory login, which should be preserved in the app experience where possible.

These observations support a normalized resource model rather than a one-post-one-file model.

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

## Parser implications

The parser must support multiple resources per post and should separate at least:
- problem
- answer / explanation
- listening audio
- grade-cut / score information
- other supporting documents

It should also preserve the raw resource label/file name because legacy naming conventions are useful for debugging and later taxonomy improvements.

## Remaining re-validation before parser implementation

Verify:
- sitemap availability and completeness
- RSS/feed behavior
- category/archive pagination mechanics
- representative much-older post HTML patterns
- direct PDF/audio attachment URL behavior
- robots/usage constraints
- duplicate/redirect behavior
- exam naming conventions across a broad year range

## Data-quality rule

Parser uncertainty must be recorded instead of silently inventing metadata. Raw source fields/source URLs should remain available for diagnosis.
