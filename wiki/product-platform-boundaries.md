# Product Platform Boundaries

Recorded: 2026-09-20. **CANONICAL DIRECTION / DOCUMENTATION ONLY.**
Product family and B2B/security requirements: [product architecture](product-architecture.md).
Actual implementation: [current status](current-status.md).

## App and Web allocation

**APP = Quick / Action / Habit / Notification.**
**WEB = Deep / Analysis / Creation / Management.**

| Journey | LegendStudy+ App | LegendStudy LAB Web |
|---|---|---|
| Materials / daily study | Search, save/revisit, permitted resource access, timer, exam/OMR, quick results | Deep workspace where a module needs it; existing public archive remains legendstudy.com |
| Academic analysis | Recent results, key changes, simple graphs, weak subjects, immediate learning actions | Full periods, exam/subject comparisons, detailed charts and domain analysis, study-time × scores, long-term trends, detailed strategy |
| Essay module | Completion alerts, recent results, key feedback, rewrite reminders | Passages, answer authoring, full feedback, original comparison, detailed evaluation and history comparison |
| Activity Portfolio | Quick evidence/activity capture and reminders | Organize/review evidence, detailed portfolio creation and analysis |
| Teacher / School (future) | Appropriate quick follow-up only, after separate scope approval | Evidence-based creation, batch/cohort analytics, role-scoped management and export |

Do not duplicate every function identically across App/Web. Both are views over
the same canonical data, not separate personal record silos. Notifications and
cross-platform links must respect authentication/authorization and unavailable
states; no automatic SSO, token-in-URL or shared-cookie contract is implied.
This table is a target allocation, not proof that features currently exist.
The native App must not become a WebView wrapper.

## Current implementation boundary

App Home/MY open the public LAB root externally. App and LAB target the same
canonical Supabase identity; Owner reports LAB Web Auth PASS (2026-09-21), while
App↔LAB identity equality still needs [Owner acceptance](auth-native-owner-acceptance.md).
Session handoff, record sync and payment are not implemented or implied. LAB is a separate repository.
The current app entry still uses essay-oriented introductory copy; this is a
known future copy/IA alignment item, not the canonical definition of LAB.
No app/Web code or deployed copy changes are made in this documentation task.

## Public information architecture — TARGET

The LAB/Web public site should provide: service introduction, how to use,
module-specific guides, institution/school use, partnership inquiries, support,
privacy policy, terms, account deletion guidance, security/data protection.
Institution pages may explain school scenarios, onboarding, upload methods,
analysis examples, security/privacy and inquiry/demo requests. Use synthetic or
properly authorized examples; do not expose student records publicly.
These pages are requirements, not claims of existing deployed pages. Policy and
security wording must match actual verified services and responsible review.

## Domain strategy

Current canonical LAB URL: **https://lab.legendstudy.com/**, as already recorded
by the Owner and existing app-entry evidence; no fresh network/deployment check
was performed in this documentation task. legendstudy.com remains the original
public source and archive, not a synonym for LAB.

Long-term candidates only: school.legendstudy.com, teacher.legendstudy.com,
record.legendstudy.com; optional marketing domain ls-school.com. Ownership,
availability, purchase and deployment are not verified or decided. Korean/mixed
names require evaluation of typing, email, sharing and international compatibility.
If a separate domain is purchased, prefer evaluating redirects to the canonical
product URL before creating duplicate sites/identities. No Cloudflare/DNS change,
domain purchase or new live endpoint is authorized by this document.

Module launches, authenticated IA and linking behavior need separate product and
security acceptance. The priority order is maintained only in
[product architecture](product-architecture.md#delivery-priority-and-remaining-decisions).
