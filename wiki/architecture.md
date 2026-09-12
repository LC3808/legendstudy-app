# Architecture

## Baseline direction

Planned client: Flutter mobile app for iOS and Android.
Planned backend: Supabase for authentication, normalized app data, personalization, and server-side support where appropriate.

This is a planned baseline, not a claim that the scaffold/backend currently exists. Always verify `wiki/current-status.md` and the repository.

## High-level components

1. Native Flutter app
2. Supabase Auth
3. Supabase Postgres
4. Optional Supabase Edge Functions for server-side operations
5. Ingestion tooling that converts `legendstudy.com` content into normalized app records
6. Existing website as the public source/content origin where appropriate

## Client architecture goals

- Clear separation between presentation, domain/use-case logic, and data access
- Repository/service abstraction around Supabase and external content
- Typed models
- Router-based navigation
- State management chosen explicitly during scaffold setup
- Testable ingestion-independent UI
- No runtime page scraping for normal app browsing

## Data flow

`legendstudy.com` → ingestion/parser → normalized Supabase records → Flutter app

The app should consume structured records rather than parse the website during normal user interaction.

## Environments

Environment and bundle/package naming are not yet finalized. They must remain independent of Muselry.
