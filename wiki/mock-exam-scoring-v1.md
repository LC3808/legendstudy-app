# Mock Exam Scoring v1 — Day 8-D architecture proposal

Reviewed: 2026-09-14. **8-D1 migration package prepared / Owner approval pending. Day 8-D NOT COMPLETE.**
No scoring Flutter implementation, production migration application, key import or scraping.
[Executable SQL package](day-8-scoring-migration-package.md) is prepared for review.
Day 8-C implementation and Guest/Auth runtime remain PASS; its physical gate stays
open. Storage details: [Day 8-D storage proposal](day-8-scoring-storage-proposal.md).

## Verified baseline and scope

The checked-in initial migration defines exams.content_item_id as shared PK;
exam_subjects.id is an occurrence, with UNIQUE(id, content_item_id). Resources use
that same-content composite FK. There is no exams.id and no current question/key/
cutoff/attempt table. An answer PDF or grade_cut resource is not a machine-readable
verified scoring key. Ingestion is design-only, with private ingestion_quarantine.
Production Study migration/JWT and8-C runtime evidence are Owner-reported; no fresh
production query was performed for this proposal.

StudyRecord already stores mock_exam time/title/subject/plan, but has no exam subject
association. The current free-text subject is not an identifier. Future scoring setup
must explicitly select a verified exam_subject occurrence and paper variant. Reuse
ExamRepository metadata/resource identity; do not create a second exam catalog.

## Availability and exam selection

Timer permission and scoring availability are independent. All existing custom and
exam-backed timers remain usable without a key, network or login. UI has separate
loading/error/offline states; failed reads do not prove no scoring exists.

| Availability | Required evidence | UI/action |
|---|---|---|
| timerOnly | No reviewed complete supported key, or unsupported question types/unknown variant | 타이머만 사용 가능; start timer unchanged |
| scoringAvailable | Active content + active occurrence + published complete supported key for selected variant | 자동채점 가능; mark answers and score |
| gradeUnavailable | Key valid, no compatible reviewed grade rule | Score available; 등급 정보 준비 중 |

Public availability uses a bounded manifest projection (IDs, display context,
variant, key/version/hash, question count/total, supported engine and optional
cutoff version). Fetch full pinned package before scoring start; verify hash,
questions and points. Missing package offers timer-only explicitly, never a fake key.
Cache permits Guest/offline practice with source/version visible. Cache uncertainty
is labelled; no claim of freshly verified publication status while offline.

Paper variant is required even when value is reviewed `common`: booklet odd/even,
elective combination, curriculum and numbering must match the actual source.
Use existing occurrence id as parent; add version-family `paper_variant` in the new
key table when the occurrence does not distinguish booklets/electives. Do not infer
identity from title or taxonomy name. Variant describes the full response paper,
including common + selected questions. Unknown mapping stays timer-only/quarantined.
No partial math paper may masquerade as a full exam score.

## Questions, scoring and grades

Owner-approved v1: **single-choice 1–5 only**, with per-question integer points.
Every question in a published package must be supported and accounted for. Numeric
short answers, multiple accepted answers/all-credit corrections and essays require
an explicit later typed model/engine revision. Do not drop those questions, guess a
single answer, or rescale a partial score to100. A math paper containing short-answer
questions is timer-only until that support exists. This is a launch-scope choice,
not a claim that Korean exams consist exclusively of multiple-choice questions.

Question definitions and keys belong to an immutable key version. Store question
number, type, correct choice and actual points; totalPossible = sum(points),
rawScore = sum(points for matching submitted choices). Unanswered earns0, is listed
separately from answered-incorrect, and belongs to the denominator. No negative
marking or uniform-points formula. Validate complete numbering1..N, no duplicates,
positive points and exact declared total before publishing. When points and answers
come from different documents, preserve both sources/digests in the key provenance. Product bounds1..100
questions, total1..1000 and points1..100 are ingestion limits, not official exam specs.
Out-of-contract papers remain timer-only rather than being coerced.

### Grade meaning by subject

| Paper | Accurate v1 output | Grade meaning |
|---|---|---|
| English / Korean history with fully verified MCQ key and applicable official absolute rule | Exact raw score; deterministic grade from that rule | `2등급` (confirmed applicable rule; basis in source details), not an official issued score report |
| Korean with fully supported matching common/elective/variant key | Exact raw score; optional compatible raw-score estimate | `예상 2등급 · 원점수 기준`; never inferred official standard score/percentile |
| Mathematics with numeric questions | Timer-only in MCQ-first v1 | No partial-score grade; numeric support is a separate expansion |
| Social/science inquiry or other MCQ papers | Exact raw score where key complete; optional reviewed compatible estimate | Relative-grade estimate only; absent cutoff -> raw score only |
| Older/custom/unidentified cohort | Timer-only or exact score if a complete reviewed package exists | No current-year rule applied automatically |

Official 2026 CSAT release separately supplies standard-score cutoffs and absolute-
assessment cutoffs. Therefore a standard-score cutoff cannot be compared directly to
rawScore. Source `confirmed` alone is insufficient to justify a confirmed raw-score
grade. [Education Ministry release and attachment list](https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=104758&lev=0&m=020402).
Official assessment briefing describes integrated subject scoring and cohort effects;
v1 does not reconstruct those distributions or selective-subject adjustments.
[Official KICE assessment briefing](https://www.korea.kr/briefing/policyBriefingView.do?newsId=156733254).
Official education-office guidance lists short-answer mathematics, so a universal
five-choice engine would be incomplete. [Incheon education-office guidance](https://www.ice.go.kr/upload/hakjeom/na/bbs_1573/2026/06/001d4dbff0224cca9db081ef7e9b8eca.pdf).
This task inspects architecture-relevant official references only; it does not import
or certify any actual exam key/cutoff values. Exact yearly absolute bands must be
verified from the applicable official attachment before publication.

Absolute rules use the **same versioned grade-cutoff model** as estimates, scoped to
the exact occurrence/cohort/variant/max score, independently of a key revision. Nine grade thresholds, explicit score basis and source;
no hardcoded subject-name branching or universal yearless thresholds in Flutter.
Only raw_absolute + confirmed and raw_estimate + estimated are supported in v1.
Official standard-score tables may be retained in private review evidence but cannot
be published into this raw-score projection. No cutoff -> grade=NULL, never guessed.

## Versioning and trust

Pin answer_key_version_id, optional grade_cutoff_version_id and scoring_version at
start. A released key's answers, points, total, scope and source evidence are immutable.
Correction publishes a new version with corrected_at/correction note and supersedes
current selection; never silently rewrite old attempt82 ->85. Old results retain
original versions and show that a correction exists when known. Explicit regrading
is later work; no automatic UPDATE of immutable attempts or silent cutoff upgrade.
A cutoff-only correction also creates a new version; historic missing grade stays
missing. NEW server submissions require current published key and optional cutoff;
non-current or withdrawn pinned versions require explicit recovery. Existing identical
attempt retries and historical results keep their original versions, score and snapshots.
No automatic upgrade/regrade is permitted when a locally pinned version becomes stale.

Pure Dart domain service (proposed, no implementation) accepts typed QuestionSet,
UserAnswers, nullable GradeRule and supported ScoringVersion. It returns totalPossible,
rawScore, correctCount, answered-incorrect numbers, unanswered numbers, nullable grade,
gradeStatus unavailable/estimated/confirmed, pinned versions and per-question outcome.
No network, widget, clock, current-date lookup or global mutable key in the engine.
Validation errors are distinct from a0 score. Example **synthetic test**, not a real
key: points[2,3,4], answers correct/wrong/blank -> raw2, total9, correct1, wrong[2],
unanswered[3]. Use integer arithmetic and fixed deterministic ordering.

Guest and offline immediate result use Dart. Auth cloud submission is independently
recomputed inside a reviewed transactional PostgreSQL RPC; client raw_score, grade,
is_correct and awarded_points are never trusted inputs. Two engines must share
versioned synthetic conformance fixtures; unknown algorithm version fails explicitly.
Client preview is marked local/pending until acknowledgement. Server mismatch is an
error requiring review, not silent replacement of an already displayed final score.
No anti-cheat/proctoring claim: public keys are intentionally readable for Guests.
Running UI hides keys/explanations and a result is personal practice, not certified
performance. Keys are downloaded public data, never bundled/hardcoded in Flutter.

## Answer entry and submission UX

Study mode switch remains compact. Scoring adds exam/occurrence/variant selection
and an availability badge before start; timer-only custom setup remains unchanged.
Pin the package before starting scoring. Mark answers during running, also paused
because v1 is practice; show compact countdown and `마킹 n/N`.

Use question-number grid plus **five-question page** (next/previous five, jump to
unanswered). Each current question offers1–5 and clear; no45-row unbounded answer
form. Selection is visible with text/check semantics, not only color. At360×640 and
2×, wrap choices while keeping>=48px targets; scroll the page without shrinking type.
Announcements identify question and selected answer, not every countdown tick.
Autosave local draft on each edit; serialize taps, preserve ordered answers and show
local-save failure. No Auth/network wait for each mark. Drafts remain owner-isolated.

On each answer mutation first reconcile timer/epoch; reject an edit at or after the
logical deadline even if a ticker/animation is late. At timeUp lock answers and keep
frozen end; no automatic submission. Show unanswered count and `제출 확인`. Do not
allow late transcription after timeUp in v1; explain before start that marking occurs
within the timer. A later untimed transcription mode would be separately labelled.

Early submit opens `시험을 종료하고 채점할까요? 미응답 n문항`. The running clock
continues in the dialog; a paused clock stays paused. Cancel returns to current state
(timeUp if it elapsed), not a synthetic resume. Confirm reconciles deadline, locks
answers and atomically commits frozen answer snapshot + Study completion + attempt
outbox in original owner namespace. Double taps/expiry and dialog races converge on
one attempt UUID. Under1-second Study work produces no Study row, but a confirmed
scoring attempt may exist without a study_session_id; it adds no study aggregate.

Timer-only follows8-C unchanged. Withdrawn/unavailable scoring must not hold time
completion hostage: retain answers/pinned local result, save time, show scoring sync
issue and offer explicit later recovery. No different key chosen automatically.
The same local transaction needs a versioned envelope extension and migration of
existing v1/v2 data; no competing local file/writer or resetting old outbox.

## Result, storage and privacy

Compact result: `82점 / 100점`, grade with basis/estimated label or `등급 정보 준비 중`,
`정답36 / 45`, separate wrong and unanswered grids. Tap a number to review own answer,
correct answer and actual points after submission. Explanations link later through
existing same-content resources only; no fabricated question-to-PDF-page mapping.
Small `정답·등급 기준 출처` action shows version/source/verified date and safe original
link. Keep long provenance off the primary screen; never imply data is official merely
because hosted on LegendStudy. Estimated provider/cutoff date remains visible.

Guest: local attempts, answers and pinned package; no forced login/no automatic upload.
Auth: local preview then Study outbox first, attempt RPC second when linked; preserve
both on retries. Same UUID + identical payload returns existing result; different
payload with same UUID fails. Re-authenticate as original owner to retry; never send
A's pending answer snapshot using B's token. Logout clears visible score/answers and
stale callbacks immediately; history restoration queries only current owner.

Attempt and Study represent different records; attempt does not add aggregate time.
Owner-approved deletion: deleting an attempt cascades its answers and preserves Study
time. Deleting linked Study time sets only study_session_id to NULL; attempt and answers
survive. Composite owner FK and narrow unlink trigger enforce this independence.
Auth-account deletion cascades personal records. No profile/NEIS/D-Day writes.
Answers/scores are private learning data: no public leaderboard, answer telemetry or
raw-response logging. Future Privacy/Account-deletion policy must disclose local/cloud
learning records and removal; no policy pages or retention automation added now.

## Source review and ingestion

Official evaluation body/education office material first. A publisher's estimate may
only be published as estimated with attribution and explicit operator approval.
No invented cutoffs to fill missing subjects. Future pipeline: raw evidence ->
normalization -> structural/scope/points checks -> independent human review -> atomic
publication. Inspect complete paper identity, question count and total, not filename
alone. Multiple correct answers/contradictory revisions/uncertain variant quarantine.

Reuse ingestion_quarantine(kind,payload,status,note), source_post_id NULL for official
sources not in current LegendStudy source_posts. Bounded private payload stores URLs,
source checksum/page references, parser version, proposed occurrence/variant and
failure reason; never user answers/passwords. Existing source_posts requires the
LegendStudy source identity contract: do not invent posts to fit an official source.
Review publisher locks/version transactions prevent modification of an already
released package. `resolved` quarantine is not automatically `published`. No crawler,
parser, bulk import, automatic answer collection or real seed dataset in this task.

## Delivery and decisions

- **8-D1:** approve storage/trust contract; prepare executable migration, publication
  validators/RPC/grants, read projections, rollback and actual A/B JWT acceptance.
  Owner applies production SQL. A small independently reviewed official paper is a
  separately authorized content prerequisite; empty tables cannot demonstrate scoring.
- **8-D2:** pure Dart engine + cross-engine fixtures, Guest/Auth answer entry, draft
  migration/lock/submit/outbox/version handling; points and raw-score result first.
- **8-D3:** compatible grade rules, result/source/wrong/unanswered UX, actual runtime
  and privacy/deletion validation. Physical8-B/8-C gates remain independent.

Owner approved MCQ-first (unsupported full papers remain timer-only), grade labels
confirmed `2등급` / estimated `예상 2등급` / unavailable `등급 정보 준비 중`, and independent
Study/result deletion. SQL package approval and production execution are still pending.
Numeric-answer coverage and post-timeUp transcription remain separate later scope.

8-D1 now includes five tables, independent cutoff families, twelve functions, trusted
server scoring and invoker availability view. [Final storage contract](day-8-scoring-storage-proposal.md)
is authoritative for SQL names and validation. Local PostgreSQL17.5 synthetic validation
PASS; no real JWT/RPC, real source ingestion or Dart engine parity claim.
Owner may review the full executable package now. Production application remains
Owner-executed after approval; actual JWT acceptance and reviewed content precede
Flutter scoring. Day8-D NOT COMPLETE; no Push/PR/Merge.
