# Product Scope

## v1.0 target

### Core content experience
- Home with recent public content across exam materials, study collections, education/admissions columns and university essays, plus the planned major exam countdown
- Browse by content type; exam-specific grade/year/session/type/subject filters where data supports them
- Unified content search and native content detail; optional resources/type-specific metadata
- Resource detail page
- PDF viewing
- Answer/explanation access
- English listening/audio access where available
- Recent items across all content types
- Saved/bookmarked items across all content types

### Account/personalization
- Google login
- Apple login
- Kakao login
- My page
- Cross-device sync for personalized data when logged in

### Notifications
- New material notifications
- Major exam schedule notifications

### Monetization foundation
- AdMob-compatible architecture
- Architecture must not block a later one-time ad-removal/support purchase

## Explicitly not required for initial v1.0

- Community / free-talk board
- Meal-photo board
- NEIS school meal integration
- Advanced badge/achievement system
- Personalized recommendation engine
- Early-admission acceptance prediction service

These may be promoted into v1.0 only by an explicit product decision recorded in `decisions.md`.

## UX principle

Study material access should not require login unless the operation is inherently personal (save/sync/profile/etc.).

## Day 3 schema boundary

Push notifications remain in v1.0 product scope: new material and major exam
schedule notifications. Data Model v0.1 covers content + basic personalization
only. Device push tokens, notification preferences and delivery backend are
intentionally deferred to a later **v1.0 implementation milestone**, not v1.1/v2.
No profiles.interest_subjects array is added; any future subject preference uses
an explicitly designed normalized relation.

## Unified content boundary

General study PDFs, education/admissions columns, university essay materials and
other reviewed educational content do not require an exam record. Original-post
opening is permitted from native cards/details; a full native article body is not
required in this schema milestone. The app does not scrape HTML during normal use
or become a WebView clone. Home “recent updates” means known source publication/
modification time, not app ingestion time. No recommendation engine, university
master or additional social functionality is introduced by this clarification.
