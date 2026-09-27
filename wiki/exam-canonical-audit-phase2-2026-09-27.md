# Exam Canonical Audit Phase 2 — 2026-09-27

Status: **OFFLINE AUDIT COMPLETE; strict publication-ready pool NOT established (0).**
The classifier/model and 43-post review are complete; the historical verified
coverage registry is intentionally incomplete. No Production application is authorized.
[Policy](exam-full-set-canonical-policy.md), [Phase1 baseline](exam-canonical-audit-2026-09-27.md),
[rollout](materials-data-rollout.md), [Owner QA](owner-device-qa-2026-09-27.md).

## Result and baseline correction

Phase1's 30 FULL_SET_CANONICAL were metadata-backed candidates under provisional
source profiles, not independently certified complete inventories. Phase2 applies
the Owner's stronger rule: unknown organizer or unverified exam-specific expected
coverage cannot produce automatic FULL_SET. **Those30 are retained as provisional
candidates, but are not counted in the strict ready pool.** This is a more rigorous
audit classification, not evidence that all30 posts are defective or Production
records were changed. Never present `30 + 0 = 30 ready` under the strict rules.

| Population | Input | FULL_SET | PARTIAL_DUPLICATE | REVIEW |
|---|---:|---:|---:|---:|
| Previously ambiguous writer-ready | 27 | 0 | 0 | 27 |
| Previously ambiguous active | 16 | 0 | 0 | 16 |
| Previous provisional writer candidates | 30 | 0 | 0 | 30 |

Strict writer pool: **0 ready / 0 confirmed partial / 57 review**. Original27
review and revalidation30 are reported separately below. No writer-ready inventory
was edited: remaining193 remains exam57 / essay127 / study9. All52 identity holds
and1710 A1 remain unchanged. Active16 remain active despite audit REVIEW.

77 source pages were re-read serially (57 writer +16 active ambiguous +4 case
sources); all attachment keys AND labels exactly match the baseline. These are
bounded source GETs, not a historical crawl. 185 cached exam sources participate
in potential sibling discovery. The43 ambiguous inputs represent43 nominal
identities; one has another cached sibling (1432/1475). Including the2 replacement
case identities gives45 identities /3 multi-post groups of direct interest.
Unknown-office candidates may be potential siblings but cannot win automatic
classification. Absence in185 is not proof that no source exists elsewhere.

No binary PDFs were fetched or PDF body coverage certified. Resource URLs being
signed/expiring does not invalidate stable source_resource_key/filename identity;
it does prevent this audit from claiming fresh HTTP/PDF usability. Every resource
has an explicit metadata-only usability result. A source-key change invalidates
the evidence manifest and requires re-observation. No credentials or user IDs
are in the committed fixture.

## Ambiguity taxonomy

Primary categories are mutually exclusive; secondary reason codes overlap.

| Primary cause | Writer27 | Active16 |
|---|---:|---:|
| KICE June/September/CSAT additional domains | 11 | 7 |
| G3 late-year offered-domain profile | 4 | 1 |
| G2 late-year offered-domain profile | 4 | 1 |
| Resource/occurrence mapping or missing paper | 8 | 6 |
| Nominal/admin identity mismatch | 0 | 1 |
| Other | 0 | 0 |

Writer27 secondary counts: {"elective_bundle_unproven": 12, "exam_identity_uncertain": 13, "expected_coverage_unverified": 26, "expected_paper_missing": 8, "organizer_uncertain": 13, "question_answer_mapping_incomplete": 18, "resource_subject_mapping_incomplete": 4}

`expected_paper_missing` against a provisional profile is a diagnostic lower-bound
gap, not a certified historical absence. A verified-profile gap (1516 extra15)
is stronger evidence. REVIEW confidence means “not eligible for automatic
promotion”; it is not a fabricated numerical probability.

## Expected vs observed model and historical reuse

`tool/ingestion/exam_canonical.py` is pure: immutable ExamIdentity and
ExpectedCoverage, ObservedCoverage, CanonicalClassification and CanonicalReason.
No imports of DB clients, network clients, apply/activation or writer code.
The runner `tool/audit_exam_canonical_phase2.py` combines a fingerprinted Phase1
snapshot with separately dated source/external assertions. No production gate
integration. Re-run without network or operator credentials:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tool/audit_exam_canonical_phase2.py \
  --output /tmp/exam-canonical-phase2.json
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tool \
  -p test_exam_canonical_phase2.py
```

The JSON includes each resource's title/label, stable key, kind, original subject,
normalized paper/domain, active observation and usability limitation. This avoids
copying the existing1.5MB source fixture into a second canonical data source.
Full titles, dates, kinds, siblings and classification details are in the tables
and per-post evidence ledger below. Baseline hash mismatch stops the CLI.

Identity dimensions: grade, calendar exam_year, academic_year, nominal_month,
administered_month/date, family/type and organizer. Reuse the existing
(year, nominal-month, grade, type) convention, extend offline comparison with an
evidenced organizer. Actual dates are consistency guards, not alternate grouping
months. Distribution events have source_event_date, not fabricated exam_date.
An exact historical profile must specify named papers, included and excluded
domains, choice variants, evidence reference and unresolved domains. Provisional
profiles are diagnostic only. No `subject >= N`, largest-resource-count winner,
current-curriculum historical rewrite, or per-post forced FULL_SET.

Taxonomy v1 and existing safe aliases are reused. Domain membership is retained
as sets of named papers: one 생활과윤리 resource proves that paper, not all SOCIAL_STUDIES.
Bare 탐구영역 remains unmapped. 물리학/물리학1 grade2 formatting can normalize, but
split App occurrences remain a delivery-review issue. Historical 법과정치,
물리1/2 and 수학가/나 remain distinct raw historical papers, not modern aliases.
Foreign/Hanmun and vocational observations are offline domain facts only, not new
Production subject taxonomy entries;1710 mapping/A1 is untouched.

Questions and answers must pair. Audio/script/explanation attachments are retained
but do not substitute for a missing question or answer. Collective answers and
common/elective bundles require explicit association evidence; a generic math
filename is not proof of all three choice papers. Duplicate resource keys,
unknown paper mappings/kinds, raw occurrence splits, missing active resources,
conflicting dates, unknown organizer, profile gaps, or protected holds block FULL_SET.

Ranking: confirmed identity, then complete expected coverage, then independently
evidenced usability, then metadata quality. Resource count never ranks a source.
If no usability/quality evidence is supplied, those ranks are equal. Tied complete
sources REVIEW. Partial requires a confirmed same-identity proper question-paper
subset; its broader sibling need not itself be publishable. Only a uniquely
FULL_SET sibling may populate canonical_target. Neither REVIEW nor PARTIAL can
publish; every result has automatic_publication_allowed=false.

DISCOVERY → existing PARSE/NORMALIZE → EXAM IDENTITY → independently verified
EXPECTED COVERAGE → SIBLING GROUP → CLASSIFICATION → Owner PUBLICATION GATE.
Wave2(2015–2019)/Wave3(2010–2014) reuse the model, not the2026 profile. A new
annual exam-family profile can resolve many posts without manual per-post YES/NO.
Unknown historical curricula remain REVIEW until such a profile and resource
associations are supplied. The interface is reusable; claiming full historical
profile coverage is explicitly out of scope/unproven.

## Source evidence versus external references

SOURCE_EVIDENCE: observed source title/intro/date/office assertions and baseline
attachment metadata. Source category “전과목” records intent only. EXTERNAL_REFERENCE:
a separately scoped independent expected-domain or organizer reference. No year
or family extrapolation from a current schedule page.

- `ebs_2026_scope`: [Explicitly dated 2026 G1 tables only. Undated G2/G3 tables are diagnostic, not historical year profiles.](https://www.ebsi.co.kr/ebs/ent/enta/retrieveExmSchedRng.ebs?tab=3)
- `kice_2023_june`: [2024 academic / 2023 calendar June KICE: core, social9, science8, vocational6, foreign/Hanmun9. No extrapolation to other years.](https://wdown.ebsi.co.kr/W61001/01exam/20230601/go3/press_G66QB3H6.pdf)
- `kice_2023_september`: [2024 academic September vocational papers demonstrably offered; incomplete whole-profile reference, cannot enable FULL_SET.](https://www.ebsi.co.kr/ebs/ent/enta/retrieveEntAnlyStrdDataVw.ebs?bbsCd=B114&datNo=127078)
- `calendar_2021`: [2021 planned calendar/organizers. Source actual grade1/2 March dates differ, do not overwrite actual date.](https://www.moe.go.kr/upload/brochureBoard/1/2021/02/1612743646339_28214575761487136.pdf)
- `ebs_2025_g2_late`: [2025 October G2 interface lists vocational6 and foreign/Hanmun7; no all-years inference.](https://www.ebsi.co.kr/ebs/xip/xipa/retrieveSCVPreparation.ebs?cookieGradeVal=high2&irecord=202511142&targetCd=D200)

Only the explicitly dated2026 G1 profile and2023 June KICE complete domain list
are verified in this bounded registry. EBS's other visible scope tables have
mixed/undated year contexts; they do not certify every2021–2024 profile. The
public2022 education-office spreadsheet could not be retrieved successfully;
no attachment-content claim is made from its notice title. This is the principal
remaining evidence task, not a classifier defect to bypass.

KICE11: June1483/1501/1516/1618; September1485/1507/1525/1634;
CSAT1487/1509/1574. For1516, the2023 June official press document explicitly
establishes vocational6 and foreign/Hanmun9. Its source metadata has none of those
15 question/answer pairs. Therefore “all core domains” cannot resolve it FULL_SET.
For1525, vocational papers are independently shown by the2023 September EBS
analysis, but the full profile is not certified here. The other years remain
additional-domain REVIEW, not assumed optional exclusions. June, September and
CSAT are separate profiles; nine foreign papers in1710 do not prove vocational
coverage or resolve A1. Late G2/G3 tables also cannot be reduced to a calendar
identity issue: actual dates can be known while expected extra domains remain
unproven. Extra domains excluded for an evidenced specific sitting are not gaps.

## Resource findings and remediation proposals (no mutation)

- 1479: combined 국어(화작,매체)/수학(기하,미적,확통) answer labels are not released
  taxonomy mappings. Preserve them; verify answer bundle scope and occurrence
  association before a bounded parser proposal.
- 1482: named question/answer evidence for 경제/동아시아사 absent under Phase1 profile.
- 1496: `생화과윤리` answer filename versus `생활과윤리` question. Do not autocorrect
  a typo into canonical evidence without resource-bound verification.
- 1498: one `탐구영역` question attachment vs separate 사회/과학 answers. PDF header
  inspection could establish a two-domain bundle; filename alone cannot.
- 1513/1517: common/elective question occurrences vs shared answers. Semantic
  domain normalization does not repair separate App accordion associations.
- 1635: 생명과학/생명과학1 and 지구과학/지구과학1 splits; domain normalization succeeds,
  existing raw occurrence structure still needs reviewed delivery correction.
- 1646: `사회문화1` question vs 사회문화 answer;1647 물리학/물리학1 split.
- 1490 한국사 pairing;1618 생활과윤리 pairing; active1684 한국사 missing,
  1705 국어 언매 question missing,1706/1707/1712 영어 pairing,
  1708 세계지리 missing. Active status is not evidence of completeness.

Do not silently patch resource kind, subject, source record or writer plan. Record
resource-key-bound bundle assertions/validated aliases in a reviewed evidence
release, rerun offline, then separately propose parser/delivery changes if needed.
No source attachment is discarded because a label is unknown.

## Replacement case1474 →1431

SAME_EXAM: YES, nominal2020 G3 March national assessment, source event2020-04-24.
1474 has four raw papers (국어, 수학가형, 수학나형, 영어),10 resources.
1431 has18 raw papers/38 resources: those four plus 한국사, social9, scienceI4.
Both dates/nominal titles agree; source1431 explicitly says papers were distributed
rather than a conventional school sitting. The source1474 tag supplies Seoul office
context. No normal exam_date is manufactured. Parser1431 reads prefix4월 while
its nominal month is3; this explains collision with April-partial1475 under the
old parser. April-full1432 instead nominal4/admin5월21일. The offline sidecar
separates them and retains original identity; parser/52-HOLD are not modified.

1474 is confirmed PARTIAL_DUPLICATE.1431 is a broader candidate, **not a ready
canonical target**:52-HOLD plus independent2020 expected-profile verification
remain. Do not equate broad coverage with approved replacement.

## Replacement case1447 →1404

SAME_EXAM: strong nominal relation, calendar2019 / academic2020 June KICE.
Both headers state2019-06-04;1404 prose says June5. Exact-date conflict is retained,
not silently corrected.1447 four raw papers/10 resources;1404 broader22 raw
papers/47 resources including 한국사, social and science. Its historical 법과정치
and 물리1/2 are retained, not forced into modern 정치와법/물리학 codes.

Phase1 called1447 partial; Phase2 records an active partial **replacement candidate**
but returns REVIEW pending the conflicting source date/profile. It does not
fabricate a confirmed full target.1404 is pre-Wave1 calendar2019, observed archive,
unpublished, not in remaining193 and not in52 hold. No foreign/vocational proof
or exact historical expected profile; no automatic target activation/scope expansion.

## Read-only reference audit and safe replacement plan

Fresh read-only transactions reported `transaction_read_only=on`; six canonical
table hashes are unchanged between initial/final reads. Source51/content51/exam33/
exam_subject496/resources1051/quarantine54. Production DML/DDL: NONE.

| Reference | 1474 | 1447 |
|---|---:|---:|
| bookmarks | 0 | 0 |
| recent_views | 1 | 1 |
| incoming merge pointers | 0 | 0 |
| exam_subjects | 4 | 4 |
| resources | 10 | 10 |
| answer_key_versions / grade_cutoff_versions | 0 /0 | 0 /0 |
| exam_questions / mock_exam_attempts / mock_exam_answers | 0 /0 /0 | 0 /0 /0 |
| linked study_sessions through attempts | 0 | 0 |

Target1431/1404 content rows and references:0. Counts are point-in-time and require
fresh recheck before any future apply. Schema FK inventory includes content→exam→
occurrence→answer/cutoff versions→attempts/answers, with attempts→study_sessions.
Study_sessions has no direct content FK. Local device navigation/cache/external
slug links are not enumerable from DB; they are not claimed zero.

CURRENT_SCHEMA_SUFFICIENT for HOLD, provenance and a single supersede pointer:
`content_items.merged_into_content_item_id` already exists with non-self/inactive
constraint; resources preserve independent source_post_id and content_item_id.
No additional canonical_content_item_id or status column is required for these
cases. Canonical-status/coverage metadata can remain a versioned offline manifest.
A general many-source content provenance join might eventually need design, but
neither current case establishes a safe multi-source merge requirement. Do not
create speculative schema. MULTI_SOURCE_CANONICAL_REQUIRED: NOT ESTABLISHED;
no source union was applied.

**SAFE_TO_REPLACE: NO for both.** Existing content projection has no merge pointer,
and `fetchContentBySlug`/`fetchContentByIds` filter is_active=true. Public RLS also
hides inactive content. Bookmark/recent owner rows themselves can remain readable,
but App resolution may omit their content. A pointer alone cannot redirect them.
Live `set_viewed_at` rejects changing recent content/user identity and overwrites
viewed_at on INSERT/UPDATE. A naïve upsert/rekey loses chronology or fails.

Future bounded plan, requiring separate Owner approval:

1. Verify target full expected coverage, dates, parser identity and source scope;
   resolve1431 individual hold through its own gate, not blanket52 release.
   Approve1404 pre2020 scope separately if still the best target.
2. Design/test a narrow read-side redirect for old ID/slug using the existing
   pointer and a privacy-preserving privileged resolution boundary (no exposing
   arbitrary inactive content). Cycle/missing-target guard; retain old UUID/slug.
   Bookmarks/recent rendering deduplicates display by canonical target while
   retaining original rows/timestamps. Old detail links and cached navigation
   must resolve after replacement. Implement separately; no redirect exists now.
3. Prefer preserving old user references over rewriting them. If Owner requires
   consolidation, specify a separate atomic operation with user/content collision
   policy and timestamp preservation; do not disable triggers casually. Scoring
   history must retain historical occurrence/version IDs, never be relabelled.
4. Fresh exact-ID source/private preflight and all reference counts, then separately
   authorized controlled target apply/activation and old suppression/pointer update
   in a reviewed sequence. Require rollback plan for target/old visibility and
   pointer; never delete old source/content/resources. App read-path changes must
   ship before old suppression. Verify guest/auth, saved/recent, slug/deep links,
   subject/PDF contracts and old-history access; compare unrelated table hashes.

## Preserved scope and tests

Busan1593: other resource, actual PDF known, signed resolver direct-open unresolved,
source fallback retained. No semantic reclassification or guidebook fix in Phase2.
Owner iOS2, previous QA wiki/code, accepted-state and identity-review fixture hashes
are unchanged. No Flutter code changed; Flutter analyze/full suite not rerun (not
applicable to this offline change). Phase1's known Flutter failures are neither
claimed fixed nor counted as new regressions.

27 focused Phase2 tests PASS: deterministic permutations/no mutation, expected
profiles/unknown years, KICE June/September/CSAT real cases, taxonomy/historical
preservation, sibling ties/ranking/date collision, resource identity, both replacement
fixtures, protected holds,2026 mapping cases. Existing ingestion190 PASS. Python
available offline suite344 PASS;25 native-PostgreSQL storage tests excluded because
SCORING_PG_BIN/native binaries are unavailable. Initial broad attempts exposed
missing system psycopg / sandbox loopback / native-PG prerequisites; venv+loopback
resolved the first two. Full native-PG suite is NOT claimed PASS.

## Decision gate

| Gate | Owner/ChatGPT decision |
|---|---|
| A SAFE_CANONICAL_EXAMS | Strict0. Prior30 provisional, newly resolved0. None approved for publication. Review annual profile evidence before reinstatement. |
| B PARTIAL_DUPLICATES | Writer0. Active1474 confirmed subset→1431 broader HOLD.1447→1404 remains replacement candidate with date/profile review. Preserve all source/archive. |
| C STILL_AMBIGUOUS | Original writer27, active16; additionally previous30 require strict profile revalidation. Reasons/counts/IDs below. Registry/bundle evidence, not per-post YES/NO, is next. |
| D ACTIVE_REPLACEMENTS | Both unsafe now, bookmark0/recent1 each; scoring/study refs0. Separate target, identity/scope and redirect/reference-preservation gates required. |
| E SCHEMA | CURRENT_SCHEMA_SUFFICIENT for present holds/single-target pointer. Read-path/operation work needed; no migration written/applied. |
| F NEXT PUBLICATION | No IDs selected. Only independently evidenced FULL_SET after profile+mapping completion; exclude REVIEW/PARTIAL/52/1710. Suggest at most10 posts/100 resources, fresh source and private Production preflight, exact Owner-ID approval, existing writer/apply/activation. Limits are a proposal, not authorization. |

NEXT: Owner/ChatGPT review. No next Materials publication.

## Exact pools

Previous30 provisional: 1480, 1481, 1488, 1489, 1494, 1495, 1497, 1499, 1500, 1502, 1503, 1504, 1505, 1510, 1511, 1512, 1514, 1515, 1523, 1524, 1609, 1614, 1615, 1616, 1617, 1619, 1620, 1621, 1636, 1648

Original27 REVIEW: 1479, 1482, 1483, 1484, 1485, 1486, 1487, 1490, 1496, 1498, 1501, 1506, 1507, 1508, 1509, 1513, 1516, 1517, 1525, 1530, 1574, 1608, 1618, 1634, 1635, 1646, 1647

Active16 REVIEW: 1432, 1453, 1649, 1665, 1684, 1686, 1693, 1694, 1700, 1702, 1705, 1706, 1707, 1708, 1710, 1712

Strict canonical ready IDs: none. Writer partial IDs: none. Confirmed active partial:1474; additional replacement candidate:1447.

## Original27 writer ambiguity: identity and resource ledger

| ID / title | grade / calendar year / nominal month | admin evidence | organizer / family | resources / kinds | siblings | primary / result |
|---|---|---|---|---|---|---|
| [1479](https://legendstudy.com/1479) → 2021년 3월 고3 모의고사 문제, 답, 해설, 등급, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2021 /3 | 2021-03-25 | SEOUL /national_mock | 36 /answer_explanation:17, listening_audio:1, listening_script:1, question:17 | none | RESOURCE_MAPPING /REVIEW |
| [1482](https://legendstudy.com/1482) → 2021년 4월 고3 모의고사 문제, 답, 해설, 등급, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2021 /4 | 2021-04-14 | GYEONGGI /national_mock | 44 /answer_explanation:21, listening_audio:1, listening_script:1, question:21 | none | RESOURCE_MAPPING /REVIEW |
| [1483](https://legendstudy.com/1483) → [2021년 6월 시행] 2022학년도 6월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/사탐/과탐 | G3 /2021 /6 | 2021-06-03 | KICE /evaluation_mock | 47 /answer_explanation:21, listening_audio:1, question:25 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1484](https://legendstudy.com/1484) → 2021년 7월 고3 모의고사 문제, 답, 해설, 등급, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2021 /7 | 2021-07-07 | INCHEON /national_mock | 48 /answer_explanation:21, listening_audio:1, question:26 | none | RESOURCE_MAPPING /REVIEW |
| [1485](https://legendstudy.com/1485) → [2021년 9월 시행] 2022학년도 9월 모의평가 - 문제, 답, 해설, 등급컷 - 국어/영어/수학/사탐/과탐 | G3 /2021 /9 | 2021-09-01 | KICE /evaluation_mock | 44 /answer_explanation:21, listening_audio:1, listening_script:1, question:21 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1486](https://legendstudy.com/1486) → 2021년 10월 고3 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2021 /10 | 2021-10-12 | SEOUL /national_mock | 44 /answer_explanation:21, listening_audio:1, listening_script:1, question:21 | none | G3_YEAR_END /REVIEW |
| [1487](https://legendstudy.com/1487) → [2021년 11월 시행] 2022학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2021 /11 | month 11 | KICE /csat | 47 /answer_explanation:21, listening_audio:1, listening_script:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1490](https://legendstudy.com/1490) → 2021년 11월 고2 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G2 /2021 /11 | 2021-11-24 | GYEONGGI /national_mock | 34 /answer_explanation:17, listening_audio:1, question:16 | none | G2_YEAR_END /REVIEW |
| [1496](https://legendstudy.com/1496) → 2022년 3월 고2 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/사탐/과탐 | G2 /2022 /3 | unknown | SEOUL /national_mock | 35 /answer_explanation:17, listening_audio:1, question:17 | none | RESOURCE_MAPPING /REVIEW |
| [1498](https://legendstudy.com/1498) → 2022년 6월 고1 모의고사 기출 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사회/과학 | G1 /2022 /6 | unknown | UNKNOWN /national_mock | 12 /answer_explanation:6, listening_audio:1, question:5 | none | RESOURCE_MAPPING /REVIEW |
| [1501](https://legendstudy.com/1501) → [2022년 6월 시행] 2023학년도 6월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/사탐/과탐 | G3 /2022 /6 | 2022-06-09 | UNKNOWN /evaluation_mock | 46 /answer_explanation:24, listening_audio:1, question:21 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1506](https://legendstudy.com/1506) → 2022년 11월 고2 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/사탐/과탐 | G2 /2022 /11 | 2022-11-23 | UNKNOWN /national_mock | 36 /answer_explanation:17, listening_audio:1, listening_script:1, question:17 | none | G2_YEAR_END /REVIEW |
| [1507](https://legendstudy.com/1507) → [2022년 9월 시행] 2023학년도 9월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/사탐/과탐 | G3 /2022 /9 | 2022-08-31 | KICE /evaluation_mock | 47 /answer_explanation:24, listening_audio:1, listening_script:1, question:21 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1508](https://legendstudy.com/1508) → 2022년 10월 고3 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/사탐/과탐 | G3 /2022 /10 | 2022-10-12 | UNKNOWN /national_mock | 44 /answer_explanation:21, listening_audio:1, listening_script:1, question:21 | none | G3_YEAR_END /REVIEW |
| [1509](https://legendstudy.com/1509) → [2022년 11월 시행] 2023학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2022 /11 | 2022-11-17 | UNKNOWN /csat | 50 /answer_explanation:24, listening_audio:1, listening_script:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1513](https://legendstudy.com/1513) → (2023년 5월 시행) 2023년 4월 고3 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2023 /4 | 2023-05-10 | UNKNOWN /national_mock | 48 /answer_explanation:21, listening_audio:1, question:26 | none | RESOURCE_MAPPING /REVIEW |
| [1516](https://legendstudy.com/1516) → [2023년 6월 시행] 2024학년도 6월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2023 /6 | 2023-06-01 | KICE /evaluation_mock | 47 /answer_explanation:24, listening_audio:1, listening_script:1, question:21 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1517](https://legendstudy.com/1517) → 2023년 7월 고3 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2023 /7 | 2023-07-11 | INCHEON /national_mock | 49 /answer_explanation:21, listening_audio:1, listening_script:1, question:26 | none | RESOURCE_MAPPING /REVIEW |
| [1525](https://legendstudy.com/1525) → [2023년 9월 시행] 2024학년도 9월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사회/과학 | G3 /2023 /9 | 2023-09-07 | UNKNOWN /evaluation_mock | 44 /answer_explanation:21, listening_audio:1, listening_script:1, question:21 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1530](https://legendstudy.com/1530) → 2023년 10월 고3 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2023 /10 | 2023-10-12 | UNKNOWN /national_mock | 44 /answer_explanation:21, listening_audio:1, listening_script:1, question:21 | none | G3_YEAR_END /REVIEW |
| [1574](https://legendstudy.com/1574) → [2023년 11월 시행] 2024학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/수학/영어/한국사/사탐/과탐 | G3 /2023 /11 | 2023-11-16 | UNKNOWN /csat | 50 /answer_explanation:24, listening_audio:1, listening_script:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1608](https://legendstudy.com/1608) → [2023년 12월 시행] 2023학년도 11월 고2 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G2 /2023 /11 | month 12 | UNKNOWN /national_mock | 36 /answer_explanation:17, listening_audio:1, listening_script:1, question:17 | none | G2_YEAR_END /REVIEW |
| [1618](https://legendstudy.com/1618) → [2024년 6월 시행] 2025학년도 6월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2024 /6 | month 6 | KICE /evaluation_mock | 44 /answer_explanation:20, listening_audio:1, listening_script:1, question:22 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1634](https://legendstudy.com/1634) → [2024년 9월 시행] 2025학년도 9월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/수학/영어/한국사/사탐/과탐 | G3 /2024 /9 | 2024-09-04 | UNKNOWN /evaluation_mock | 47 /answer_explanation:21, listening_audio:1, listening_script:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1635](https://legendstudy.com/1635) → 2024년 9월 고2 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 - 국어/수학/영어/한국사/사탐/과탐 | G2 /2024 /9 | 2024-09-04 | UNKNOWN /national_mock | 35 /answer_explanation:17, listening_audio:1, question:17 | none | RESOURCE_MAPPING /REVIEW |
| [1646](https://legendstudy.com/1646) → [2024년 10월 시행] 2024년 10월 고3 모의고사 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2024 /10 | 2024-10-15 | SEOUL /national_mock | 43 /answer_explanation:21, listening_audio:1, question:21 | none | G3_YEAR_END /REVIEW |
| [1647](https://legendstudy.com/1647) → 2024년 10월 고2 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G2 /2024 /10 | unknown | UNKNOWN /national_mock | 36 /answer_explanation:17, listening_audio:1, listening_script:1, question:17 | none | G2_YEAR_END /REVIEW |

All rows have confidence=review_required. Detected named papers, differences and evidence:

### 1479 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(화작,매체), 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하,미적,확통), 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): korean, math.
- Raw occurrence splits: 국어, 수학.
- Unmapped paper resources: cSGn0Z/btq2zeWlcu7 — 2021-3월-국어 정답,해설(화작,매체).pdf; cyQOsc/btq2yuSE4HQ — 2021-3월-수학 정답,해설(기하,미적,확통).pdf.
- Reasons: elective_bundle_unproven, expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete, resource_subject_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: external:calendar_2021, source:1479; expected refs: phase1:provisional_source_profile.

### 1482 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 국어, 국어-언매, 국어-화작, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): east_asian_history, economics.
- Raw occurrence splits: 국어-언매, 국어-화작.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: external:calendar_2021, source:1482; expected refs: phase1:provisional_source_profile.

### 1483 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: external:calendar_2021, source:1483; expected refs: phase1:provisional_source_profile.

### 1484 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어(언매), 국어(화작), 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: external:calendar_2021, source:1484; expected refs: phase1:provisional_source_profile.

### 1485 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_coverage_unverified. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: external:calendar_2021, source:1485; expected refs: phase1:provisional_source_profile.

### 1486 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_coverage_unverified. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: external:calendar_2021, source:1486; expected refs: phase1:provisional_source_profile.

### 1487 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: external:calendar_2021, source:1487; expected refs: phase1:provisional_source_profile.

### 1490 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학.
- Missing paired papers (profile verified=false): korean_history.
- Raw occurrence splits: 한국사.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1490; expected refs: phase1:provisional_source_profile.

### 1496 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생화과윤리, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학.
- Missing paired papers (profile verified=false): life_ethics.
- Raw occurrence splits: 생활과윤리.
- Unmapped paper resources: dro2Yr/btrxlDZ64s9 — 2022년 3월 고2 사회- 생화과윤리 정답,해설.pdf.
- Reasons: expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete, resource_subject_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1496; expected refs: phase1:provisional_source_profile.

### 1498 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: integrated_science; SOCIAL_STUDIES: integrated_social.
- Source labels: 과학, 국어, 사회, 수학, 영어, 탐구영역, 한국사.
- Missing paired papers (profile verified=false): integrated_science, integrated_social.
- Raw occurrence splits: 과학, 사회.
- Unmapped paper resources: bWjNCh/btrHOAkgm96 — 2022년 6월 고1 모의고사 - 탐구영역 문제.pdf.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, expected_paper_missing, organizer_uncertain, question_answer_mapping_incomplete, resource_subject_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1498; expected refs: phase1:provisional_source_profile.

### 1501 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(+언매), 국어(+화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(+기하), 수학(+미적), 수학(+확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어(+언매), 국어(+화작), 수학, 수학(+기하), 수학(+미적), 수학(+확통).
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1501; expected refs: phase1:provisional_source_profile.

### 1506 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1506; expected refs: phase1:provisional_source_profile.

### 1507 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1507; expected refs: phase1:provisional_source_profile.

### 1508 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1508; expected refs: phase1:provisional_source_profile.

### 1509 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1509; expected refs: phase1:provisional_source_profile.

### 1513 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(공통), 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(공통), 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어(공통), 국어(언매), 국어(화작), 수학, 수학(공통), 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1513; expected refs: phase1:provisional_source_profile.

### 1516 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=true): foreign:독일어, foreign:러시아어, foreign:베트남어, foreign:스페인어, foreign:아랍어, foreign:일본어, foreign:중국어, foreign:프랑스어, foreign:한문, vocational:공업일반, vocational:농업기초기술, vocational:상업경제, vocational:성공적인직업생활, vocational:수산해운산업기초, vocational:인간발달.
- Raw occurrence splits: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1516; expected refs: external:kice_2023_june.

### 1517 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어_공통, 국어_언매, 국어_화작, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학_공통, 수학_기하, 수학_미적, 수학_확통, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어_공통, 국어_언매, 국어_화작, 수학, 수학_공통, 수학_기하, 수학_미적, 수학_확통.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1517; expected refs: phase1:provisional_source_profile.

### 1525 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1525; expected refs: phase1:provisional_source_profile.

### 1530 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1530; expected refs: phase1:provisional_source_profile.

### 1574 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1574; expected refs: phase1:provisional_source_profile.

### 1608 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1608; expected refs: phase1:provisional_source_profile.

### 1618 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): life_ethics.
- Raw occurrence splits: 생활과윤리.
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1618; expected refs: phase1:provisional_source_profile.

### 1634 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1634; expected refs: phase1:provisional_source_profile.

### 1635 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 생명과학, 생명과학1, 지구과학, 지구과학1.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1635; expected refs: phase1:provisional_source_profile.

### 1646 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 사회문화1, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): society_culture.
- Raw occurrence splits: 사회문화.
- Unmapped paper resources: CjUv0/btsKajnvhDE — 2024년 10월 사탐_사회문화1 문제.pdf.
- Reasons: elective_bundle_unproven, expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete, resource_subject_mapping_incomplete. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1646; expected refs: phase1:provisional_source_profile.

### 1647 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 물리학, 물리학1.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain, question_answer_mapping_incomplete. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1647; expected refs: phase1:provisional_source_profile.

## Active16 ambiguity: identity and resource ledger

| ID / title | grade / calendar year / nominal month | admin evidence | organizer / family | resources / kinds | siblings | primary / result |
|---|---|---|---|---|---|---|
| [1432](https://legendstudy.com/1432) → (5월 시행) 2020년 4월 고3 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/사회/과학 | G3 /2020 /4 | 2020-05-21 | UNKNOWN /national_mock | 46 /answer_explanation:22, listening_audio:1, listening_script:1, question:22 | 1475 | IDENTITY_CONFLICT /REVIEW |
| [1453](https://legendstudy.com/1453) → [2020년 12월 시행] 2021학년도 수능 기출 문제, 답, 해설, 등급, 듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2020 /12 | 2020-12-03 | KICE /csat | 46 /answer_explanation:22, listening_audio:1, listening_script:1, question:22 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1649](https://legendstudy.com/1649) → [2024년 11월 시행] 2025학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2024 /11 | 2024-11-14 | UNKNOWN /csat | 50 /answer_explanation:24, listening_audio:1, listening_script:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1665](https://legendstudy.com/1665) → [2025년 6월 시행] 2026학년도 6월 모의평가 문제, 답, 등급컷, 영어듣기 - 국어/영어/수학/사탐/과탐 | G3 /2025 /6 | 2025-06-04 | KICE /evaluation_mock | 43 /answer_explanation:21, listening_audio:1, question:21 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1684](https://legendstudy.com/1684) → 2025년 9월 고1 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 파일 | G1 /2025 /9 | 2025-09-03 | INCHEON /national_mock | 11 /answer_explanation:5, listening_audio:1, question:5 | none | RESOURCE_MAPPING /REVIEW |
| [1686](https://legendstudy.com/1686) → [2025년 9월 시행] 2026학년도 9월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2025 /9 | 2025-09-03 | UNKNOWN /evaluation_mock | 49 /answer_explanation:24, listening_audio:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1693](https://legendstudy.com/1693) → 2025년 10월 고3 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2025 /10 | 2025-10-14 | SEOUL /national_mock | 49 /answer_explanation:24, listening_audio:1, question:24 | none | G3_YEAR_END /REVIEW |
| [1694](https://legendstudy.com/1694) → 2025년 10월 고2 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G2 /2025 /10 | 2025-10-14 | GYEONGGI /national_mock | 35 /answer_explanation:17, listening_audio:1, question:17 | none | G2_YEAR_END /REVIEW |
| [1700](https://legendstudy.com/1700) →[2025년 11월 시행] 2026학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사회/과학 | G3 /2025 /11 | 2025-11-13 | UNKNOWN /csat | 49 /answer_explanation:24, listening_audio:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1702](https://legendstudy.com/1702) → [2026년 3월 시행] 2026년 3월 고3 모의고사 문제, 답, 해설, 등급컷, 영어듣기 - 국어/영어/수학/한국사/사탐/과탐 | G3 /2026 /3 | month 3 | SEOUL /national_mock | 38 /answer_explanation:17, listening_audio:1, question:20 | none | RESOURCE_MAPPING /REVIEW |
| [1705](https://legendstudy.com/1705) → [2026년 5월 시행] 2026년 5월 고3 모의고사 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2026 /5 | month 5 | GYEONGGI /national_mock | 48 /answer_explanation:24, listening_audio:1, question:23 | none | RESOURCE_MAPPING /REVIEW |
| [1706](https://legendstudy.com/1706) → [2026년 6월 시행] 2027학년도 6월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐 | G3 /2026 /6 | month 6 | KICE /evaluation_mock | 48 /answer_explanation:23, listening_audio:1, question:24 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1707](https://legendstudy.com/1707) → 2026년 6월 고1 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사회/과학 | G1 /2026 /6 | unknown | BUSAN /national_mock | 12 /answer_explanation:5, listening_audio:1, question:6 | none | RESOURCE_MAPPING /REVIEW |
| [1708](https://legendstudy.com/1708) → [2026년 7월 시행] 2026학년도 7월 고3 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/사탐/과탐 | G3 /2026 /7 | 2026-07-08 | INCHEON /national_mock | 47 /answer_explanation:23, listening_audio:1, question:23 | none | RESOURCE_MAPPING /REVIEW |
| [1710](https://legendstudy.com/1710) → [2026년 9월 시행] 2027학년도 9월 모의평가 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사탐/과탐/제2외국어 | G3 /2026 /9 | 2026-09-02 | UNKNOWN /evaluation_mock | 67 /answer_explanation:33, listening_audio:1, question:33 | none | KICE_EXTRA_DOMAINS /REVIEW |
| [1712](https://legendstudy.com/1712) → 2026년 9월 고1 모의고사 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/한국사/사회/과학 | G1 /2026 /9 | 2026-09-02 | INCHEON /national_mock | 12 /answer_explanation:5, listening_audio:1, question:6 | none | RESOURCE_MAPPING /REVIEW |

All rows have confidence=review_required. Detected named papers, differences and evidence:

### 1432 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: historical:수학가형, historical:수학나형; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학 가형, 수학 나형, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: none.
- Identity evidence refs: source:1432; expected refs: phase1:provisional_source_profile.

### 1453 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: historical:수학가형, historical:수학나형; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학 가형, 수학 나형, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1453; expected refs: phase1:provisional_source_profile.

### 1649 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1649; expected refs: phase1:provisional_source_profile.

### 1665 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: admin_date_conflict, elective_bundle_unproven, expected_coverage_unverified. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1665; expected refs: phase1:provisional_source_profile.

### 1684 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; MATH: math; SCIENCE: integrated_science; SOCIAL_STUDIES: integrated_social.
- Source labels: 과학탐구, 국어, 사회탐구, 수학, 영어.
- Missing paired papers (profile verified=false): korean_history.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, expected_paper_missing. Expected unresolved domains: none.
- Identity evidence refs: source:1684; expected refs: phase1:provisional_source_profile.

### 1686 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1686; expected refs: phase1:provisional_source_profile.

### 1693 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1693; expected refs: phase1:provisional_source_profile.

### 1694 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified. Expected unresolved domains: late_exam_additional_domains_unverified.
- Identity evidence refs: source:1694; expected refs: phase1:provisional_source_profile.

### 1700 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1700; expected refs: phase1:provisional_source_profile.

### 1702 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, earth_science_1, life_science_1, physics_1; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통).
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1702; expected refs: phase1:provisional_source_profile.

### 1705 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: 국어(언매).
- Unmapped paper resources: none.
- Reasons: elective_bundle_unproven, expected_coverage_unverified, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1705; expected refs: phase1:provisional_source_profile.

### 1706 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): english.
- Raw occurrence splits: 영어.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1706; expected refs: phase1:provisional_source_profile.

### 1707 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: integrated_science; SOCIAL_STUDIES: integrated_social.
- Source labels: 국어, 수학, 영어, 통합과학, 통합사회, 한국사.
- Missing paired papers (profile verified=true): english.
- Raw occurrence splits: 영어.
- Unmapped paper resources: none.
- Reasons: expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1707; expected refs: external:ebs_2026_scope.

### 1708 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2.
- Missing paired papers (profile verified=false): world_geography.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: expected_coverage_unverified, expected_paper_missing. Expected unresolved domains: none.
- Identity evidence refs: source:1708; expected refs: phase1:provisional_source_profile.

### 1710 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: chemistry_1, chemistry_2, earth_science_1, earth_science_2, life_science_1, life_science_2, physics_1, physics_2; SECOND_FOREIGN_HANMUN: foreign:독일어, foreign:러시아어, foreign:베트남어, foreign:스페인어, foreign:아랍어, foreign:일본어, foreign:중국어, foreign:프랑스어, foreign:한문; SOCIAL_STUDIES: east_asian_history, economics, ethics_thought, korean_geography, life_ethics, politics_law, society_culture, world_geography, world_history.
- Source labels: 경제, 국어(언매), 국어(화작), 독일어, 동아시아사, 러시아어, 물리학1, 물리학2, 베트남어, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 스페인어, 아랍어, 영어, 윤리와사상, 일본어, 정치와법, 중국어, 지구과학1, 지구과학2, 프랑스어, 한국사, 한국지리, 한문, 화학1, 화학2.
- Missing paired papers (profile verified=false): none.
- Raw occurrence splits: none.
- Unmapped paper resources: none.
- Reasons: exam_identity_uncertain, expected_coverage_unverified, organizer_uncertain, protected_hold. Expected unresolved domains: vocational_domain_uncertain, second_foreign_domain_uncertain.
- Identity evidence refs: source:1710; expected refs: phase1:provisional_source_profile.

### 1712 evidence

- Observed paper/domain evidence: ENGLISH: english; KOREAN: korean; KOREAN_HISTORY: korean_history; MATH: math; SCIENCE: integrated_science; SOCIAL_STUDIES: integrated_social.
- Source labels: 국어, 수학, 영어, 통합과학, 통합사회, 한국사.
- Missing paired papers (profile verified=true): english.
- Raw occurrence splits: 영어.
- Unmapped paper resources: none.
- Reasons: expected_paper_missing, question_answer_mapping_incomplete. Expected unresolved domains: none.
- Identity evidence refs: source:1712; expected refs: external:ebs_2026_scope.


Final checks: deterministic rerun byte-identical; git diff --check PASS; scoped secret scan PASS; Wiki handoff PASS (current-status11983 bytes). Commit/push hashes are in Git, not permanent status definitions.
