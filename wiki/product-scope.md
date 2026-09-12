# Product Scope

## v1.0 target

### Core content experience
- Home with latest/recommended study materials and major exam countdown
- Browse/filter by grade, year, month/exam session, exam type, and subject where data supports it
- Search
- Resource detail page
- PDF viewing
- Answer/explanation access
- English listening/audio access where available
- Recent items
- Saved/bookmarked items

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
