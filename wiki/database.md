# Database

## Status

No LegendStudy Supabase schema is considered deployed yet. This document records design intent only until verified against the actual project.

## Initial entity direction

Expected entities include:

- users/profiles
- source posts
- exams / exam sessions
- subjects
- resources / attachments (problem PDF, answer/explanation PDF, audio, etc.)
- bookmarks/saved items
- viewing history
- notification preferences

The exact normalized schema must be based on a representative crawl of existing `legendstudy.com` content before migration v1 is finalized.

## Supabase execution policy

By default, the user directly applies Supabase SQL/migrations.

For each DB change, agents should provide:
- migration SQL
- prerequisites
- expected output/state
- validation query
- rollback/repair notes when relevant

A migration file in Git does not prove it has been applied. A successful SQL execution does not prove the repository migration history has been updated. Both sides must be reconciled.

## Security

- RLS should be enabled for user-owned/personal data.
- Public educational catalog data can use explicit public read policies where appropriate.
- service-role credentials must never be committed or embedded in the app.
