# LegendStudy Product Family Architecture

Recorded: 2026-09-20. **OWNER PRODUCT DIRECTION / DOCUMENTATION ONLY.**
This is the canonical long-term product family, shared-engine and B2B boundary.
It does not authorize implementation, deployment, data collection or payment.
Implementation evidence stays in [current status](current-status.md); platform
allocation stays in [platform boundaries](product-platform-boundaries.md).

## Product family

| Product | Audience and role | Long-term capabilities (not a shipped-feature list) |
|---|---|---|
| LegendStudy+ App | Student daily learning execution; Quick / Action / Habit / Notification | Materials search, saved/recent materials, Study Timer, exam/OMR, score records, quick results, notifications, simple learning actions/strategy, activity capture |
| LegendStudy LAB Web | Students and individuals; Deep Analysis / Creation / Intelligence | Academic Analytics, Essay/논술 LAB, AI feedback, admissions and learning analysis, Target University / Gap Analysis, activity Portfolio, other high-value AI modules |
| LegendStudy for Teachers | Teacher work support | Student activities/Portfolio, counseling preparation, creative-experience and subject-specific student-record drafting, evidence search, teacher-configured drafts |
| LegendStudy for Schools | Schools/institutions; B2B management and analysis | Validated batch imports, individual/class/grade analysis, counseling, dashboards and controlled export |

**LegendStudy LAB = LegendStudy's Web Intelligence / Deep Work Platform.**
Essay is one Service Module, not LAB's entire identity. The existing
[Essay roadmap](roadmap-essay-lab.md) owns essay-specific research, rights,
provenance and evaluation gates; it does not define the whole platform.
Materials remains an independent free core product, with Guest access where
appropriate. Existing legendstudy.com remains the public content source.
LegendStudy remains separate from Muselry in all systems and identities.

## Single source of truth and shared engine

Canonical account identity is **auth.users.id** in the dedicated LegendStudy
Supabase project. App and LAB must use the same canonical identity and data,
not independent product-specific user databases or authoritative copies.
Shared long-term domains: profile, academic record, study sessions, mock exam
attempts, scores, answers, essay submissions/evaluations, activity portfolio,
target university and entitlements. This list does not claim these all exist.
Platform-specific views or derived analytics are not independent source records;
future caches/derived results must retain provenance and invalidation rules.

Same identity does not mean shared browser cookies, automatic SSO or unrestricted
access. [Auth](auth-recovery.md) records current code/config/E2E limits; LAB's
Web Auth E2E is now Owner-reported PASS (2026-09-21); App↔LAB identity equality
still needs verification. No session/token handoff is authorized.

Student Analytics: 1 user → Academic Analytics Engine.
School Analytics: N students → **same engine and canonical academic model** →
Batch Processing → Cohort Analytics. Do not build separate B2C/B2B scoring logic.
Batch orchestration and cohort aggregation add scope, not new score semantics.
Import validation must preserve source/provenance, missingness, exam context and
score comparability; do not sum essay evaluations and exam scores onto one scale.
Study-time correlation does not establish causation or admission probability.
Detailed academic dependencies remain in [Analytics roadmap](roadmap-academic-analytics.md).

## Teacher roadmap — PLANNED / NOT IMPLEMENTED

Students may eventually record inquiry, presentations, reading, projects, career,
club, performance and other school/learning activities in App/Web Portfolio.
Activity sources and teacher-confirmed evidence remain distinguishable.
A school/teacher contract and appropriate scoped permissions are required before
teacher use. School profile selection or a school email alone grants no access.

Teacher workflow:
student → subject/area → retrieve actual activity evidence → teacher settings →
length/viewpoint/emphasis → AI draft → evidence review → teacher edits → final use.

**AI must not invent student activities.** Missing evidence produces an explicit
gap/request for evidence, not fabricated achievement. Retrieval must be scoped to
permitted actual student activities/teacher-confirmed data. Preserve traceability
from a draft to its evidence. AI output is never automatically official student
record text and is never entered without teacher review. Final judgment and
record responsibility remain with the teacher. Counseling, creative-experience
records and subject-specific comments are candidates, not deployed services.

## School roadmap — PLANNED / NOT IMPLEMENTED

Example: a school provides Excel/CSV grades for approximately 300 students in a
grade → validate → standardize → batch analysis → individual analysis → class
analysis → grade-wide cohort analysis → counseling → dashboard → result export.
300 is a planning example, not a tested capacity or SLA.

Candidate outputs: per-exam/per-subject distributions, grade-band counts,
improving/declining students, groups needing support, class comparisons,
longitudinal student trends, counseling filters, target-university gaps,
individual counseling reports and Excel/PDF exports. Labels need teacher context;
these are not admissions guarantees or automated consequential decisions.

Before a pilot, separately approve import identity matching (no blind account
creation/email-based merging), correction/duplicate handling, validation feedback,
analysis comparability, tenant access and export/deletion acceptance. No imports,
scheduler, batch code or dataset were created by this documentation.

## Organization and access model — FUTURE DESIGN BOUNDARY

Conceptual scope: Organization → School → Academic Year → Grade → Class, with
Teacher and Student memberships/relationships. This is not a decided SQL tree;
multiple roles/classes and year transitions need explicit future design.

Required: multi-tenant isolation, RBAC (teacher, school administrator, student),
least-privilege scoped access, audit logs, export permission, retention/deletion,
and institutional consent/processing basis. Authentication identifies a person;
organization membership and authorization decide which student data is accessible.
Do not bolt `school_admin` booleans onto B2C profiles as a B2B permission system.
Role assignment/revocation, cross-school transitions and tenant boundaries require
reviewed contracts and tests before implementation. Personal and institutional
retention responsibilities must be resolved without silently granting a school
ownership of all a student's personal history.

## Security and privacy — REQUIREMENTS / TARGETS, NOT VERIFIED CLAIMS

- Encryption in transit and at rest; key/access management verification.
- Tenant isolation, least privilege, RBAC and scoped evidence retrieval.
- Audit logging without unnecessary sensitive payloads; controlled log access.
- Retention and deletion policies, including backups and derived AI artifacts.
- Backup security, export authorization/control and incident response.
- AI processing boundary: permitted fields, processors, retention/training use,
  region/access and output handling must be agreed and verified before use.
- Minimize sensitive student data; establish institutional processing basis and
  necessary consent before a pilot, with responsible review.

These are product requirements, not a legal compliance certification or an audit
of current infrastructure. Do not publish absolute claims such as “all data is
securely encrypted” without implementation-specific evidence. Public security
copy must state only implemented and verified facts.

## Delivery priority and remaining decisions

1. Auth Production completion.
2. App/Web platform boundary (recorded now; implementation is separate).
3. LAB authenticated IA/UX.
4. Core release readiness.
5. Academic Record / Analytics.
6. Essay service.
7. Teacher / School B2B afterward.

This supersedes older essay-first cross-product ordering, not essay research or
rights gates. No B2B, payment, AI drafting, Viewer or ingestion expansion begins.
Daily Sync and other existing backlogs remain recorded but are not advanced by
this decision. Existing Auth/deletion release blockers remain open.

Owner decisions later: first modules and release acceptance; LAB account linking
and authenticated IA; first Teacher/School pilot and responsible data controller/
processor roles; permissions/retention/consent and export policy; evidence and AI
quality gates; budget, packaging and capacity; optional domains. No pricing,
launch date, institutional contract or domain purchase is approved here.

## Academic Analytics three-layer allocation — 2026-09-24

Owner-approved product boundary, not approval to implement all candidates:

| Layer | Role | Scope / candidates |
|---|---|---|
| MY Snapshot | 상태를 본다 — quick current state | Recent recorded score, short deterministic comment, missing input guidance, Mobile LAB detail CTA. No complex simulations, large graphs or acceptance probability |
| Mobile LAB | 무엇을 해야 할지 판단한다 — Actionable Analysis / Strategy | Internal grades, mock scores/trends/strengths, target university/major, official admissions discovery, 수능최저/교과 formula checkers, special-admission official requirements, selection finder, mobile simulation, essay preparation |
| Web LAB | 깊게 분석하고 작업한다 — Deep Analysis / Workbench | Multi-year scores/complex graphs, university/department and scenario comparisons, converted scores, detailed admissions with provenance, reports, long-form essay writing/AI evaluation/history |

This refines earlier “App quick / LAB Web deep” allocation: Mobile LAB is an
analysis/action layer, not merely a Web link hub. Existing native mock detail and
Essay external entry remain; unsupported candidates stay hidden/unavailable.
Same canonical account/data, independent sessions, no token handoff or WebView.
Admissions claims remain [research-gated](research-registry.md); the future4–5band
Owner concept is retained, not approved for this implementation.

## Mock provenance boundary — Owner follow-up 3

[Official vs Free practice](day-8-d2-answer-scoring.md#owner-follow-up-3--dual-practice-modes)
refines execution only. Published-key official results remain eligible for existing
MY snapshot/Mobile LAB history. Local user-entered practice scores are separate
personal records, not confirmed academic data or automatic admissions input.
Three-layer allocation above and future research gates remain unchanged. Daily
Sync implementation, analytics/essay/notification expansion are not part of this task.
