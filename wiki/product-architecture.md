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
actual auth configuration is unverified. No session/token handoff is authorized.

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
