# Product Research Registry

Recorded2026-09-24 from Owner's “V2 Device Follow-up + Academic Analytics Layer
Canonicalization” handoff. Manus research is evidence/recommendation, not an
Owner-approved product decision. Repository Wiki owns adopted decisions; external
reports never replace it. Research completion dates, report URLs/IDs, authorship
versions and original attachments were not supplied at that initial checkpoint.
**Individual Research A–D full reports NOT INSPECTED** here. The later Owner-provided
synthesis and Phase1 exports are SOURCE ACQUIRED, as recorded below.
No independent legal, statistical or competitive verification is claimed.

## Report inventory and provenance

| Report | Research date / provenance | Key findings available | Adopted / open / deferred |
|---|---|---|---|
| A. Daily Content Sync Production Architecture | Date unknown; Owner handoff2026-09-24, original locator pending | Owner reports research complete; implementation pending. Detailed scheduler/retry/publication recommendations unavailable | Existing source-first ingestion remains canonical; implementation/config/deployment not approved here |
| B. Admissions Data Source Registry | Date unknown; same handoff, original locator pending | Rule checking/public criteria are candidates; official data alone does not establish calibrated personal acceptance probability | Provenance requirement adopted; source inventory and per-rule evidence need original report validation |
| C. Competitive Intelligence | Date unknown; same handoff, original locator pending | Report existence recorded; competitor names/features/prices/findings not supplied | No competitor-derived feature/pricing decision adopted; review pending |
| D. Launch Compliance Audit | Date unknown; same handoff, original locator pending | Compliance P0 evidence audit pending; no certification established | Preserve existing privacy/deletion/Store/Community gates; report-specific P0 checklist remains unverified |
| E. B/C/D Executive Synthesis | Date unknown; same handoff, original locator pending | Admissions claims require research gate, not permanent deletion of Owner concepts | Three-layer allocation is Owner decision, not automatic adoption of all Manus recommendations |

## Research findings boundary

Owner-transmitted P0 **candidates**, not implemented/approved checkers: 수능최저
condition checking, quantitative school-grade formula reproduction, schedules/
recruitment counts/selection factors, official special-admission requirements and
document guidance, historical public outcome comparisons.

Every future calculation/rule must link source, academic year, document version,
effective date, source locator and verification state. Public requirements are
not automatic personal eligibility confirmation. Missing/ambiguous evidence must
stay missing/ambiguous, not a favourable result.

Personal acceptance probability, 안정/소신/위험 labels, automatic special-admission
eligibility and AI admissions judgment: **RESEARCH-GATED / NOT APPROVED FOR CURRENT
IMPLEMENTATION**. Preserve Owner's future4–5band concept. Require individual-level
dataset adequacy, calibration, hold-out validation, bias evaluation, provenance and
claim policy, followed by a separate Owner decision. No permanent product rejection.

## Canonical handoff

- [Academic roadmap and research boundary](roadmap-academic-analytics.md): claim/evidence gates.
- [Three-layer architecture](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24): Owner allocation.
- [Ingestion](ingestion.md) and [pipeline evidence](day-9-ingestion.md): Daily Sync source contracts.
- [Privacy/deletion](account-deletion-privacy.md), [platform safety](product-platform-boundaries.md),
  [current gates](current-status.md): compliance evidence, not research-complete certification.
- [Product strategy](roadmap-monetization-and-in-app-learning.md): existing scope/entitlements.

Next research review obtains original report locators/versions and maps concrete
recommendations to adopted/open/deferred decisions. Do not invent missing report
content or ask Owner to recreate past chat before searching this registry.


## Owner-provided Manus exports — SOURCE ACQUIRED

Owner supplied two actual Markdown exports2026-09-24. SHA256 matched the Manus
reported values before import; canonical files are byte-for-byte copies, including
references, Files to read/change/not-touch, fixture package and acceptance criteria.

| Source | Canonical file | SHA256 | Status |
|---|---|---|---|
| Research A–D Product and Operations Consolidation3.md | [Research synthesis](research-2026-09-24-product-operations-synthesis.md) | `d41725fd78c041922087474cbda4018f75cab476e0b79ef8195b2ebb7054609b` | SOURCE ACQUIRED |
| Daily Sync Phase 1 — Deterministic Source and Delta Core2.md | [Phase1 package](daily-sync-phase-1-deterministic-delta-package.md) | `2b4fe9e40b8fdc333e5ed85ee5900267da4f91c18638bb92e7217301203cba57` | SOURCE ACQUIRED |

Owner-reported Manus branch: `manus/wiki-research-consolidation-20260924`;
package commit: `607ba1731965ee5d394a71d8abd0b32fcf89928f`; consolidation commit:
`1096cbd11d941860e5af372532b48f9bf9aac7eb`. Those Git objects were not available
locally; this import verifies export bytes against Owner-supplied Manus hashes,
not independent Git-object provenance. No cherry-pick or whole-Wiki replacement.
The prior missing-synthesis/package blocker is resolved. Individual report URLs,
versions and full A–D evidence remain separate, not falsely marked reviewed.

### Reconciliation and precedence

- Imported research is evidence/recommendation, not an instruction to implement
  its code, run its SQL, create Cron or reopen settled Owner decisions.
- The synthesis's Owner-decisions list includes approving three-layer analytics.
  That allocation is already approved in current Codex
  [architecture](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24)
  and [decisions](decisions.md). It is not reopened by this historical export.
- Design Systemv2, Owner follow-up2, MY structured snapshot, current Mock workflow
  and719 Flutter PASS/1skip evidence remain canonical. Research general statements
  about absent analytics do not erase those implemented bounded surfaces.
- The Phase1 package§11 permits future offline implementation within its boundary;
  the latest Owner request limits **this task to Wiki import**. Phase1 remains NOT
  IMPLEMENTED. Phase2 stays NOT STARTED/OWNER GATED; runtime recommendations are not
  approved deployment work.
- Historical empty/inactive PilotC wording is preserved as historical evidence;
  [current Owner baseline](current-status.md#daily-sync-status) is PUBLISHED_COMPLETE.
  Quarantine23 expected advisory rows must not be automatically deleted.

### Import handoff self-test

| Request | Evidence route | Result |
|---|---|---|
| A: 사이트에 새 글 올렸는데 앱에 안 보여 | index Daily Sync → ingestion current handoff → Phase1 package → synthesis → current-status | PASS; identifies offline source/delta work, not automatic publication |
| B: Pilot C가 아직 inactive야? | ingestion current handoff → current-status Daily Sync | PASS; Owner PUBLISHED_COMPLETE, older inactive records historical |
| C: quarantine 23개 지워도 돼? | ingestion current handoff → Phase1§2 | PASS; EXPECTED advisory, automatic deletion prohibited |
| D: Daily Sync 바로 Cron 걸자 | ingestion current handoff → Phase1§10/§11 → synthesis phase plan | PASS; Phase1 offline only, Phase2+ Owner gates, no scheduler authorization |
