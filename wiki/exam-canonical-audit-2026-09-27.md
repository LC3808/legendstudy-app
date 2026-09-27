# Exam canonical audit — 2026-09-27

> Phase2 follow-up: [strict classifier and evidence ledger](exam-canonical-audit-phase2-2026-09-27.md).
> Counts below are the preserved Phase1 baseline. Its30 provisional full-set
> candidates are **not** the strict Phase2 ready pool (currently0); do not publish
> from this historical report. Original27 + active16 remain REVIEW under stricter
> evidence rules. No Production changes were made.

Status: READ-ONLY AUDIT COMPLETE / APPLICATION STOPPED AT OWNER GATE.
[Canonical policy](exam-full-set-canonical-policy.md) and
[Owner QA diagnosis](owner-device-qa-2026-09-27.md) are the governing handoff.
Starting HEAD4379636, branch codex/day-7-school-neis. Prior QA changes and Owner
files preserved; no source/parser/publication/schema rewrite in this audit.

## Scope and reproducibility

Fresh private Production reads: source51/content51/exam33/occurrence496/resource1051/
quarantine54; all33 exams active. Existing remaining writer-ready193 reconfirmed:
exam57/essay127/study9/column0. **Writer-ready is the old technical gate, not the
new full-set policy approval.** Non-exam136 remain under their existing gates.

Source evidence covers781 Wave1 discovery observations +13 bounded scope-sanity
observations;185 are parsed exams, including pre2020 posts. No exhaustive2010s crawl
or whole-blog estimate. Three original pages1431/1432/1474 and guidebook1593 were
freshly re-observed; other source rows reuse dated2026-09-27 observations.
Active coverage uses fresh DB rows, not a presumed live parser projection.

Existing parser139 identity groups; title-backed nominal-month comparison138.
The report preserves both identities. It does not correct DB month values.
Exam actual dates are NULL in this snapshot; the table's month is nominal source
comparison and never an invented exam_date. Education-office name is unverified
where not independently evidenced. KICE organizer is inferred from typed metadata.

Reproduce offline (no network, DB, accepted-state or writer calls):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tool/audit_exam_canonical.py \
  --input tool/ingestion/samples/exam-canonical-audit-2026-09-27.json \
  --output /tmp/legendstudy-exam-canonical-audit.json
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tool -p test_exam_canonical_audit.py
```

[Input evidence](../tool/ingestion/samples/exam-canonical-audit-2026-09-27.json)
contains every resource's stable key, original label, parsed/DB occurrence and
kind, source/category/identity and state. No signed URLs, credentials, full body,
PDF binaries or personal rows. [Audit code](../tool/audit_exam_canonical.py) emits
expected sets, missing labels, per-subject kinds, sibling IDs and held decisions.
Every row has automatic_publication_allowed=false. This tool is not integrated
with, and does not strengthen, the existing writer's runtime gate.

## Counts and decision gate

| State | FULL_SET_CANONICAL | PARTIAL_DUPLICATE | AMBIGUOUS | OTHER |
|---|---:|---:|---:|---:|
| Remaining writer-ready57 |30|0|27|0|
| Active33 |15|2|16|0|
| Protected identity-review52 (coverage only) |7|33|12|0|
| Other observed/archive43 |0|6|37|0|
| All185 observed exams |52|41|92|0|

AFTER_CANONICAL_READY=30 **review candidates**, not newly approved publication.
Potential policy-eligible remaining pool166=30 exams+136 non-exams; old manifest193
is intentionally unchanged. The7 broad/full sources inside52 stay HOLD and are
not counted in30.1710 remains active; its extra-domain review is not A1 work.

Within185: full52(28.1%), partial41(22.2%), ambiguous92(49.7%);138 compared exam
identities. These are observed-sample ratios, not a projected historical catalogue.
No unique nonduplicate partial is promoted to exam browse; incomplete singleton
sources stay ambiguous. No multi-source union is confirmed necessary under the
reviewed profiles; unproven extra domains can require a future investigation.

27 writer reviews by primary cause (mutually exclusive): KICE/CSAT extra domains11;
grade3 late additional domains4; grade2 late additional domains4; remaining
subject/resource/occurrence issues8. Secondary causes overlap in the table.

DECISION_GATE:
A. Safe canonical review pool30; Owner approval + fresh source/private preflight
   still required. No next IDs selected.
B. Remaining57 partial0; observed archive/held/active partial41. Examples1474→1431,
   1447→1404. Broader siblings are not automatically approved full-set sources.
C.27 review cases; resolve offered-domain and attachment/occurrence evidence first.
D.2 active replacement candidates; both have recent-view references. No action.
E. Current schema sufficient for this single-source selection/HOLD/soft-pointer
   policy. No migration; multi-source writer handling would need separate design.
F. After review, bound a future batch to approved full-set decisions, include
   grade/year variety and exact source/DB/read-path checks; exclude all27,52 holds
   and reconciliation work. Do not select batch IDs in this task.

## 2020 고3 3월 case and active replacement safety

CURRENT_ACTIVE_PARTIAL:1474, content48d6495a-7138-5d95-ba44-d2010441bf1d,
source dd844749-fc41-52f5-84f8-ae7cd19f692f, same shared-ID exam,4 occurrences,
10 resources. Coverage: 국어, 수학 가형, 수학 나형, 영어;9 PDFs+1 audio landing.
Occurrence IDs: 국어2a17c603-594f-5659-8d24-043f2b85b6b8;
수학 가형780a9e92-d803-58cf-aefe-a70be1cb8d0e;
수학 나형af28427d-8376-5c0b-a924-fee66707772b;
영어a658920e-7839-513a-979f-a9a6943ffcf3.

FULL_SET_SOURCE / CANONICAL_CANDIDATE: [1431](https://legendstudy.com/1431),
38 resources/18 raw subjects, source 전과목 category. It adds 한국사,9 social and
4 science-I papers with answers. Fresh1431/1474 bodies identify the same nominal
March paper distributed on2020-04-24. Different attachment keys do not by themselves
prove identical PDF bytes; this is source/title/sitting/subject-subset evidence.

FULL_SET_CURRENT_STATE: IDENTITY_REVIEW_52, not ingested/active. Existing parser
assigns1431 month4 versus1474 month3.1431's current false April sibling group also
contains1475;1432's April exam is parsed month5. Report nominal comparison only;
no parser/identity-review manifest changes. Coverage is broad, identity remains
AMBIGUOUS until a separate bounded correction/review gate.

REPLACEMENT_SAFE: NO. 1474 has bookmarks0/recent_views1 at read time. No deletion,
deactivation, redirect or user-reference migration performed. Controlled replacement
must first review nominal identity and52-HOLD boundary, then refresh source/private
state and all user-reference integrity. Keep1474 active pending explicit approval.

Second active partial: [1447](https://legendstudy.com/1447),2019-calendar/2020-academic
June KICE,10 resources/4 subjects. Broader sibling [1404](https://legendstudy.com/1404)
was already in the13 scope-sanity observations:47 resources, not ingested,
pre2020 publication (outside current Wave1 publication scope). Additional-language/
vocational completeness is unproven, so1404 is not automatically a full-set PASS.
1447 bookmarks0/recent_views1. Replacement_safe=NO; no new publication scope.

## Coverage rules and limitations

Profiles enumerate named sets, not thresholds: grade1 six domains; grade2 under
2015-curriculum core+9 social+4 science-I domains;2026 grade2 source integrated
social/science; grade3 nominalMarch excludes science-II, later national core+
9 social+8 science-I/II domains.2020 가/나 are separate. Later common/elective
bundles retain raw occurrences and undergo missing/elective checks. Late grade2
and grade3, KICE/CSAT extra domains are deliberately reviewed, never waived.
Year-specific references and boundaries are in the policy; profiles are not a
universal statement about every historical examination.

Comparison-only spelling/domain families do not alter taxonomy: 물리학 versus
물리학1 or 통합사회 versus 사회 can describe coverage, while mismatched raw
question/answer occurrences still trigger review.1496 has 생화과윤리 typo;
1635/1647 split science labels;1498 collective 탐구영역 answer needs evidence;
1482 lacks named 경제/동아시아사 evidence;1618 생활과윤리 answer coverage needs
review. These are gaps in available metadata/association, not claims that the
original PDF contents definitely lack a subject. No forced parser repair.

FULL_SET requires every expected subject with question+answer evidence and source
full-set intent, no identity/coverage/split review reasons, and a unique full source
in the compared group. A group with multiple equal full candidates is ambiguous.
Older unreviewed profiles remain ambiguous even with many attachments. PDFs were
not downloaded/extracted to certify all pages; future live publication checks remain.

## Complete57 writer-ready table

Source URL is the post link. Identity tuple is calendar year/nominal month/grade/type;
academic year and current actual-date evidence are separate. Sibling “—” means
none in these185 observations, not proof of absence elsewhere.

| Post / source | Normalized identity | Grade / year / academic / month / actual date | Organizer/type evidence | Detected raw subjects | Resources | Full-set? | Siblings | Classification / evidence |
|---|---|---|---|---|---:|---|---|---|
| [1479](https://legendstudy.com/1479) | 2021/3/3/national_mock | 고3 / 2021 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 국어(화작,매체), 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하,미적,확통), 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(화작,매체), 수학, 수학(기하,미적,확통) |
| [1480](https://legendstudy.com/1480) | 2021/3/2/national_mock | 고2 / 2021 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 36 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1481](https://legendstudy.com/1481) | 2021/3/1/national_mock | 고1 / 2021 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1482](https://legendstudy.com/1482) | 2021/4/3/national_mock | 고3 / 2021 / — / 4 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 국어-언매, 국어-화작, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 필요 영역의 label 근거 부족; 문제/답 또는 occurrence 분리 검토; 미입증 label: 경제, 동아시아사; 분리/누락 검토: 국어-언매, 국어-화작 |
| [1483](https://legendstudy.com/1483) | 2021/6/3/evaluation_mock | 고3 / 2021 / 2022 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 47 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통) |
| [1484](https://legendstudy.com/1484) | 2021/7/3/national_mock | 고3 / 2021 / — / 7 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 48 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어(언매), 국어(화작), 수학(기하), 수학(미적), 수학(확통) |
| [1485](https://legendstudy.com/1485) | 2021/9/3/evaluation_mock | 고3 / 2021 / 2022 / 9 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1486](https://legendstudy.com/1486) | 2021/10/3/national_mock | 고3 / 2021 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 고3 연말 추가영역 검토 |
| [1487](https://legendstudy.com/1487) | 2021/11/3/csat | 고3 / 2021 / 2022 / 11 / NULL | 한국교육과정평가원 (type) / csat | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 47 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통) |
| [1488](https://legendstudy.com/1488) | 2021/6/2/national_mock | 고2 / 2021 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1489](https://legendstudy.com/1489) | 2021/9/2/national_mock | 고2 / 2021 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1490](https://legendstudy.com/1490) | 2021/11/2/national_mock | 고2 / 2021 / — / 11 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 34 | REVIEW/HOLD | — | **AMBIGUOUS** — 고2 연말 추가영역 검토; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 한국사 |
| [1494](https://legendstudy.com/1494) | 2021/11/1/national_mock | 고1 / 2021 / — / 11 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1495](https://legendstudy.com/1495) | 2022/3/3/national_mock | 고3 / 2022 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1496](https://legendstudy.com/1496) | 2022/3/2/national_mock | 고2 / 2022 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생화과윤리, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 35 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 생화과윤리, 생활과윤리 |
| [1497](https://legendstudy.com/1497) | 2022/3/1/national_mock | 고1 / 2022 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1498](https://legendstudy.com/1498) | 2022/6/1/national_mock | 고1 / 2022 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 탐구영역, 한국사 | 12 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 과학, 사회, 탐구영역 |
| [1499](https://legendstudy.com/1499) | 2022/6/2/national_mock | 고2 / 2022 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1500](https://legendstudy.com/1500) | 2022/4/3/national_mock | 고3 / 2022 / — / 4 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 43 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1501](https://legendstudy.com/1501) | 2022/6/3/evaluation_mock | 고3 / 2022 / 2023 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 국어(+언매), 국어(+화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(+기하), 수학(+미적), 수학(+확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 46 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(+언매), 국어(+화작), 수학, 수학(+기하), 수학(+미적), 수학(+확통) |
| [1502](https://legendstudy.com/1502) | 2022/7/3/national_mock | 고3 / 2022 / — / 7 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 53 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1503](https://legendstudy.com/1503) | 2022/9/1/national_mock | 고1 / 2022 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1504](https://legendstudy.com/1504) | 2022/9/2/national_mock | 고2 / 2022 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1505](https://legendstudy.com/1505) | 2022/11/1/national_mock | 고1 / 2022 / — / 11 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1506](https://legendstudy.com/1506) | 2022/11/2/national_mock | 고2 / 2022 / — / 11 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | REVIEW/HOLD | — | **AMBIGUOUS** — 고2 연말 추가영역 검토 |
| [1507](https://legendstudy.com/1507) | 2022/9/3/evaluation_mock | 고3 / 2022 / 2023 / 9 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 47 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통) |
| [1508](https://legendstudy.com/1508) | 2022/10/3/national_mock | 고3 / 2022 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 고3 연말 추가영역 검토 |
| [1509](https://legendstudy.com/1509) | 2022/11/3/csat | 고3 / 2022 / 2023 / 11 / NULL | 한국교육과정평가원 (type) / csat | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 50 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1510](https://legendstudy.com/1510) | 2023/3/3/national_mock | 고3 / 2023 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1511](https://legendstudy.com/1511) | 2023/3/2/national_mock | 고2 / 2023 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1512](https://legendstudy.com/1512) | 2023/3/1/national_mock | 고1 / 2023 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1513](https://legendstudy.com/1513) | 2023/4/3/national_mock | 고3 / 2023 / — / 4 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 국어(공통), 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(공통), 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 48 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(공통), 국어(언매), 국어(화작), 수학, 수학(공통), 수학(기하), 수학(미적), 수학(확통) |
| [1514](https://legendstudy.com/1514) | 2023/6/1/national_mock | 고1 / 2023 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1515](https://legendstudy.com/1515) | 2023/6/2/national_mock | 고2 / 2023 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1516](https://legendstudy.com/1516) | 2023/6/3/evaluation_mock | 고3 / 2023 / 2024 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 47 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통) |
| [1517](https://legendstudy.com/1517) | 2023/7/3/national_mock | 고3 / 2023 / — / 7 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 국어_공통, 국어_언매, 국어_화작, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학_공통, 수학_기하, 수학_미적, 수학_확통, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 49 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어_공통, 국어_언매, 국어_화작, 수학, 수학_공통, 수학_기하, 수학_미적, 수학_확통 |
| [1523](https://legendstudy.com/1523) | 2023/9/1/national_mock | 고1 / 2023 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1524](https://legendstudy.com/1524) | 2023/9/2/national_mock | 고2 / 2023 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1525](https://legendstudy.com/1525) | 2023/9/3/evaluation_mock | 고3 / 2023 / 2024 / 9 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1530](https://legendstudy.com/1530) | 2023/10/3/national_mock | 고3 / 2023 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 고3 연말 추가영역 검토 |
| [1574](https://legendstudy.com/1574) | 2023/11/3/csat | 고3 / 2023 / 2024 / 11 / NULL | 한국교육과정평가원 (type) / csat | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 50 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1608](https://legendstudy.com/1608) | 2023/11/2/national_mock | 고2 / 2023 / — / 11 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | REVIEW/HOLD | — | **AMBIGUOUS** — 고2 연말 추가영역 검토 |
| [1609](https://legendstudy.com/1609) | 2023/11/1/national_mock | 고1 / 2023 / — / 11 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1614](https://legendstudy.com/1614) | 2024/3/3/national_mock | 고3 / 2024 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1615](https://legendstudy.com/1615) | 2024/3/2/national_mock | 고2 / 2024 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 36 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1616](https://legendstudy.com/1616) | 2024/3/1/national_mock | 고1 / 2024 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1617](https://legendstudy.com/1617) | 2024/5/3/national_mock | 고3 / 2024 / — / 5 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1618](https://legendstudy.com/1618) | 2024/6/3/evaluation_mock | 고3 / 2024 / 2025 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 44 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 생활과윤리 |
| [1619](https://legendstudy.com/1619) | 2024/6/2/national_mock | 고2 / 2024 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 사회문화, 생명과학, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 한국사, 한국지리, 화학 | 36 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1620](https://legendstudy.com/1620) | 2024/6/1/national_mock | 고1 / 2024 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1621](https://legendstudy.com/1621) | 2024/7/3/national_mock | 고3 / 2024 / — / 7 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 43 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1634](https://legendstudy.com/1634) | 2024/9/3/evaluation_mock | 고3 / 2024 / 2025 / 9 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 47 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통) |
| [1635](https://legendstudy.com/1635) | 2024/9/2/national_mock | 고2 / 2024 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학, 지구과학1, 한국사, 한국지리, 화학1 | 35 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 생명과학, 생명과학1, 지구과학, 지구과학1 |
| [1636](https://legendstudy.com/1636) | 2024/9/1/national_mock | 고1 / 2024 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1646](https://legendstudy.com/1646) | 2024/10/3/national_mock | 고3 / 2024 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 사회문화1, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 43 | REVIEW/HOLD | — | **AMBIGUOUS** — 고3 연말 추가영역 검토; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 사회문화, 사회문화1 |
| [1647](https://legendstudy.com/1647) | 2024/10/2/national_mock | 고2 / 2024 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 36 | REVIEW/HOLD | — | **AMBIGUOUS** — 고2 연말 추가영역 검토; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 물리학, 물리학1 |
| [1648](https://legendstudy.com/1648) | 2024/10/1/national_mock | 고1 / 2024 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 14 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |

## Complete33 active exam table

No row was deactivated or corrected. ACTIVE_AMBIGUOUS is review, not a finding
that every such source is a duplicate.

| Post / source | Normalized identity | Grade / year / academic / month / actual date | Organizer/type evidence | Detected raw subjects | Resources | Full-set? | Siblings | Classification / evidence |
|---|---|---|---|---|---:|---|---|---|
| [1432](https://legendstudy.com/1432) | 2020/4/3/national_mock | 고3 / 2020 / — / 4 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학 가형, 수학 나형, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 46 | REVIEW/HOLD | 1475 | **AMBIGUOUS** — 명목월/시행월 충돌 |
| [1447](https://legendstudy.com/1447) | 2019/6/3/evaluation_mock | 고3 / 2019 / 2020 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 국어, 수학 가형, 수학 나형, 영어 | 10 | REVIEW/HOLD | 1404 | **PARTIAL_DUPLICATE** — 동일 시험의 더 넓은 source 1404에 과목 부분집합; 삭제/게시 없음 |
| [1453](https://legendstudy.com/1453) | 2020/12/3/csat | 고3 / 2020 / 2021 / 12 / NULL | 한국교육과정평가원 (type) / csat | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학 가형, 수학 나형, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 46 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1474](https://legendstudy.com/1474) | 2020/3/3/national_mock | 고3 / 2020 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학 가형, 수학 나형, 영어 | 10 | REVIEW/HOLD | 1431 | **PARTIAL_DUPLICATE** — 동일 시험의 더 넓은 source 1431에 과목 부분집합; 삭제/게시 없음 |
| [1492](https://legendstudy.com/1492) | 2021/6/1/national_mock | 고1 / 2021 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1493](https://legendstudy.com/1493) | 2021/9/1/national_mock | 고1 / 2021 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1649](https://legendstudy.com/1649) | 2024/11/3/csat | 고3 / 2024 / 2025 / 11 / NULL | 한국교육과정평가원 (type) / csat | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 50 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1661](https://legendstudy.com/1661) | 2025/3/1/national_mock | 고1 / 2025 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1662](https://legendstudy.com/1662) | 2025/3/2/national_mock | 고2 / 2025 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1663](https://legendstudy.com/1663) | 2025/3/3/national_mock | 고3 / 2025 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1664](https://legendstudy.com/1664) | 2025/5/3/national_mock | 고3 / 2025 / — / 5 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 43 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1665](https://legendstudy.com/1665) | 2025/6/3/evaluation_mock | 고3 / 2025 / 2026 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어, 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 43 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1666](https://legendstudy.com/1666) | 2025/6/1/national_mock | 고1 / 2025 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 사회, 수학, 영어, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1667](https://legendstudy.com/1667) | 2025/6/2/national_mock | 고2 / 2025 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1668](https://legendstudy.com/1668) | 2025/7/3/national_mock | 고3 / 2025 / — / 7 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 49 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1684](https://legendstudy.com/1684) | 2025/9/1/national_mock | 고1 / 2025 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 과학탐구, 국어, 사회탐구, 수학, 영어 | 11 | REVIEW/HOLD | — | **AMBIGUOUS** — 필요 영역의 label 근거 부족; 미입증 label: 한국사 |
| [1685](https://legendstudy.com/1685) | 2025/9/2/national_mock | 고2 / 2025 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1686](https://legendstudy.com/1686) | 2025/9/3/evaluation_mock | 고3 / 2025 / 2026 / 9 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 49 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1693](https://legendstudy.com/1693) | 2025/10/3/national_mock | 고3 / 2025 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 49 | REVIEW/HOLD | — | **AMBIGUOUS** — 고3 연말 추가영역 검토 |
| [1694](https://legendstudy.com/1694) | 2025/10/2/national_mock | 고2 / 2025 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 35 | REVIEW/HOLD | — | **AMBIGUOUS** — 고2 연말 추가영역 검토 |
| [1695](https://legendstudy.com/1695) | 2025/10/1/national_mock | 고1 / 2025 / — / 10 / NULL | 교육청 (specific office unverified) / national_mock | 과학, 국어, 수학, 영어, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1700](https://legendstudy.com/1700) | 2025/11/3/csat | 고3 / 2025 / 2026 / 11 / NULL | 한국교육과정평가원 (type) / csat | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 49 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1702](https://legendstudy.com/1702) | 2026/3/3/national_mock | 고3 / 2026 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어, 국어(언매), 국어(화작), 동아시아사, 물리학1, 사회문화, 생명과학1, 생활과윤리, 세계사, 세계지리, 수학, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 한국사, 한국지리, 화학1 | 38 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 국어, 국어(언매), 국어(화작), 수학, 수학(기하), 수학(미적), 수학(확통) |
| [1703](https://legendstudy.com/1703) | 2026/3/2/national_mock | 고2 / 2026 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1704](https://legendstudy.com/1704) | 2026/3/1/national_mock | 고1 / 2026 / — / 3 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1705](https://legendstudy.com/1705) | 2026/5/3/national_mock | 고3 / 2026 / — / 5 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 48 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 선택과목 coverage 검토; 분리/누락 검토: 국어(언매) |
| [1706](https://legendstudy.com/1706) | 2026/6/3/evaluation_mock | 고3 / 2026 / 2027 / 6 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 48 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 영어 |
| [1707](https://legendstudy.com/1707) | 2026/6/1/national_mock | 고1 / 2026 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 12 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 영어 |
| [1708](https://legendstudy.com/1708) | 2026/7/3/national_mock | 고3 / 2026 / — / 7 / NULL | 교육청 (specific office unverified) / national_mock | 경제, 국어(언매), 국어(화작), 동아시아사, 물리학1, 물리학2, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 수학(기하), 수학(미적), 수학(확통), 영어, 윤리와사상, 정치와법, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 | 47 | REVIEW/HOLD | — | **AMBIGUOUS** — 필요 영역의 label 근거 부족; 미입증 label: 세계지리 |
| [1709](https://legendstudy.com/1709) | 2026/6/2/national_mock | 고2 / 2026 / — / 6 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1710](https://legendstudy.com/1710) | 2026/9/3/evaluation_mock | 고3 / 2026 / 2027 / 9 / NULL | 한국교육과정평가원 (type) / evaluation_mock | 경제, 국어(언매), 국어(화작), 독일어, 동아시아사, 러시아어, 물리학1, 물리학2, 베트남어, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 수학(기하), 수학(미적), 수학(확통), 스페인어, 아랍어, 영어, 윤리와사상, 일본어, 정치와법, 중국어, 지구과학1, 지구과학2, 프랑스어, 한국사, 한국지리, 한문, 화학1, 화학2 | 67 | REVIEW/HOLD | — | **AMBIGUOUS** — 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1711](https://legendstudy.com/1711) | 2026/9/2/national_mock | 고2 / 2026 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 13 | YES | — | **FULL_SET_CANONICAL** — source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1712](https://legendstudy.com/1712) | 2026/9/1/national_mock | 고1 / 2026 / — / 9 / NULL | 교육청 (specific office unverified) / national_mock | 국어, 수학, 영어, 통합과학, 통합사회, 한국사 | 12 | REVIEW/HOLD | — | **AMBIGUOUS** — 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 영어 |

## Other observed sources and protected holds

Coverage classification does not release52. Full resources still require identity
review; all rows below have canonical_review_eligible=false.

| Post | State | Existing → comparison identity | Class | Siblings | Evidence |
|---|---|---|---|---|---|
| [240](https://legendstudy.com/240) | OBSERVED_ARCHIVE | 2010/9/1/national_mock → 2010/9/1/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 과목 없는 문제/답 첨부 |
| [265](https://legendstudy.com/265) | OBSERVED_ARCHIVE | 2008/11/1/national_mock → 2008/11/1/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 과학탐구, 사회탐구 |
| [297](https://legendstudy.com/297) | OBSERVED_ARCHIVE | 2013/11/2/national_mock → 2013/11/2/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 고2 연말 추가영역 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; source 전과목 의도 미확인; 분리/누락 검토: 영어 |
| [453](https://legendstudy.com/453) | OBSERVED_ARCHIVE | 2007/4/3/national_mock → 2007/4/3/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; source 전과목 의도 미확인; 분리/누락 검토: 수학 가형, 수학 나형 |
| [469](https://legendstudy.com/469) | OBSERVED_ARCHIVE | 2009/4/3/national_mock → 2009/4/3/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; source 전과목 의도 미확인; 분리/누락 검토: 수학 가형, 수학 나형 |
| [592](https://legendstudy.com/592) | OBSERVED_ARCHIVE | 2014/6/2/national_mock → 2014/6/2/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; source 전과목 의도 미확인; 분리/누락 검토: 국어, 수학 |
| [610](https://legendstudy.com/610) | OBSERVED_ARCHIVE | 2014/6/3/evaluation_mock → 2014/6/3/evaluation_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 경제, 동아시아사, 물리1, 물리2, 법과정치, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 영어, 윤리와사상, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 |
| [677](https://legendstudy.com/677) | OBSERVED_ARCHIVE | 2014/11/3/csat → 2014/11/3/csat | PARTIAL_DUPLICATE | 689 | 동일 시험의 더 넓은 source 689에 과목 부분집합; 삭제/게시 없음 |
| [689](https://legendstudy.com/689) | OBSERVED_ARCHIVE | 2014/11/3/csat → 2014/11/3/csat | AMBIGUOUS | 677 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부 |
| [742](https://legendstudy.com/742) | OBSERVED_ARCHIVE | 2015/6/3/evaluation_mock → 2015/6/3/evaluation_mock | AMBIGUOUS | 746 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 경제, 동아시아사, 물리1, 물리2, 법과정치, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 영어, 윤리와사상, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 |
| [746](https://legendstudy.com/746) | OBSERVED_ARCHIVE | 2015/6/3/evaluation_mock → 2015/6/3/evaluation_mock | AMBIGUOUS | 742 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 러시아어, 베트남어, 아랍어, 일본어, 중국어, 한문 |
| [787](https://legendstudy.com/787) | OBSERVED_ARCHIVE | 2015/9/3/evaluation_mock → 2015/9/3/evaluation_mock | AMBIGUOUS | 798 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 경제, 동아시아사, 물리1, 물리2, 법과정치, 사회문화, 생명과학1, 생명과학2, 생활과윤리, 세계사, 세계지리, 영어, 윤리와사상, 지구과학1, 지구과학2, 한국사, 한국지리, 화학1, 화학2 |
| [798](https://legendstudy.com/798) | OBSERVED_ARCHIVE | 2015/9/3/evaluation_mock → 2015/9/3/evaluation_mock | AMBIGUOUS | 787 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 독일어, 러시아어, 베트남어, 스페인어, 아랍어, 일본어, 중국어, 프랑스어, 한문 |
| [820](https://legendstudy.com/820) | OBSERVED_ARCHIVE | 2015/11/3/csat → 2015/11/3/csat | AMBIGUOUS | 823 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부 |
| [823](https://legendstudy.com/823) | OBSERVED_ARCHIVE | 2015/11/3/csat → 2015/11/3/csat | AMBIGUOUS | 820 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부 |
| [877](https://legendstudy.com/877) | OBSERVED_ARCHIVE | 2007/6/1/national_mock → 2007/6/1/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; source 전과목 의도 미확인; 분리/누락 검토: 과학탐구, 사회탐구 |
| [895](https://legendstudy.com/895) | OBSERVED_ARCHIVE | 2005/9/3/evaluation_mock → 2005/9/3/evaluation_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부; source 전과목 의도 미확인 |
| [963](https://legendstudy.com/963) | OBSERVED_ARCHIVE | 2016/6/3/evaluation_mock → 2016/6/3/evaluation_mock | AMBIGUOUS | — | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1006](https://legendstudy.com/1006) | OBSERVED_ARCHIVE | 2016/9/3/evaluation_mock → 2016/9/3/evaluation_mock | AMBIGUOUS | 1007 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1007](https://legendstudy.com/1007) | OBSERVED_ARCHIVE | 2016/9/3/evaluation_mock → 2016/9/3/evaluation_mock | AMBIGUOUS | 1006 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부 |
| [1034](https://legendstudy.com/1034) | OBSERVED_ARCHIVE | 2016/10/3/national_mock → 2016/10/3/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 고3 연말 추가영역 검토; 과목 없는 문제/답 첨부 |
| [1051](https://legendstudy.com/1051) | OBSERVED_ARCHIVE | 2016/11/3/csat → 2016/11/3/csat | AMBIGUOUS | 1059 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 생화과윤리, 생활과윤리 |
| [1059](https://legendstudy.com/1059) | OBSERVED_ARCHIVE | 2016/11/3/csat → 2016/11/3/csat | AMBIGUOUS | 1051 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1121](https://legendstudy.com/1121) | OBSERVED_ARCHIVE | 2017/6/3/evaluation_mock → 2017/6/3/evaluation_mock | AMBIGUOUS | — | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1123](https://legendstudy.com/1123) | OBSERVED_ARCHIVE | 2017/6/1/national_mock → 2017/6/1/national_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 과목 없는 문제/답 첨부 |
| [1190](https://legendstudy.com/1190) | OBSERVED_ARCHIVE | 2017/9/3/evaluation_mock → 2017/9/3/evaluation_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 지구과학2 |
| [1231](https://legendstudy.com/1231) | OBSERVED_ARCHIVE | 2017/11/3/csat → 2017/11/3/csat | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1282](https://legendstudy.com/1282) | OBSERVED_ARCHIVE | 2018/6/3/evaluation_mock → 2018/6/3/evaluation_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부 |
| [1339](https://legendstudy.com/1339) | OBSERVED_ARCHIVE | 2018/9/3/evaluation_mock → 2018/9/3/evaluation_mock | AMBIGUOUS | — | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 과목 없는 문제/답 첨부 |
| [1369](https://legendstudy.com/1369) | OBSERVED_ARCHIVE | 2018/11/3/csat → 2018/11/3/csat | AMBIGUOUS | 1378 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1378](https://legendstudy.com/1378) | OBSERVED_ARCHIVE | 2018/11/3/csat → 2018/11/3/csat | PARTIAL_DUPLICATE | 1369 | 동일 시험의 더 넓은 source 1369에 과목 부분집합; 삭제/게시 없음 |
| [1391](https://legendstudy.com/1391) | OBSERVED_ARCHIVE | 2019/3/3/national_mock → 2019/3/3/national_mock | AMBIGUOUS | 1393 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 과목 없는 문제/답 첨부 |
| [1393](https://legendstudy.com/1393) | OBSERVED_ARCHIVE | 2019/3/3/national_mock → 2019/3/3/national_mock | PARTIAL_DUPLICATE | 1391 | 동일 시험의 더 넓은 source 1391에 과목 부분집합; 삭제/게시 없음 |
| [1400](https://legendstudy.com/1400) | OBSERVED_ARCHIVE | 2019/4/3/national_mock → 2019/4/3/national_mock | AMBIGUOUS | 1401,1402,1403 | 해당 시험 영역 profile 검토 |
| [1401](https://legendstudy.com/1401) | OBSERVED_ARCHIVE | 2019/4/3/national_mock → 2019/4/3/national_mock | PARTIAL_DUPLICATE | 1400,1402,1403 | 동일 시험의 더 넓은 source 1400에 과목 부분집합; 삭제/게시 없음 |
| [1402](https://legendstudy.com/1402) | OBSERVED_ARCHIVE | 2019/4/3/national_mock → 2019/4/3/national_mock | PARTIAL_DUPLICATE | 1400,1401,1403 | 동일 시험의 더 넓은 source 1400에 과목 부분집합; 삭제/게시 없음 |
| [1403](https://legendstudy.com/1403) | OBSERVED_ARCHIVE | 2019/4/3/national_mock → 2019/4/3/national_mock | PARTIAL_DUPLICATE | 1400,1401,1402 | 동일 시험의 더 넓은 source 1400에 과목 부분집합; 삭제/게시 없음 |
| [1404](https://legendstudy.com/1404) | OBSERVED_ARCHIVE | 2019/6/3/evaluation_mock → 2019/6/3/evaluation_mock | AMBIGUOUS | 1447 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1407](https://legendstudy.com/1407) | OBSERVED_ARCHIVE | 2019/7/3/national_mock → 2019/7/3/national_mock | AMBIGUOUS | 1445,1460,1461 | 해당 시험 영역 profile 검토 |
| [1412](https://legendstudy.com/1412) | OBSERVED_ARCHIVE | 2019/6/1/national_mock → 2019/6/1/national_mock | AMBIGUOUS | 1421,1422 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토 |
| [1413](https://legendstudy.com/1413) | OBSERVED_ARCHIVE | 2019/9/1/national_mock → 2019/9/1/national_mock | AMBIGUOUS | 1425,1426 | 해당 시험 영역 profile 검토 |
| [1414](https://legendstudy.com/1414) | OBSERVED_ARCHIVE | 2019/6/2/national_mock → 2019/6/2/national_mock | AMBIGUOUS | 1423,1424 | 해당 시험 영역 profile 검토 |
| [1415](https://legendstudy.com/1415) | OBSERVED_ARCHIVE | 2019/9/2/national_mock → 2019/9/2/national_mock | AMBIGUOUS | 1427,1428,1450 | 해당 시험 영역 profile 검토 |
| [1416](https://legendstudy.com/1416) | IDENTITY_REVIEW_52 | 2019/9/3/evaluation_mock → 2019/9/3/evaluation_mock | AMBIGUOUS | 1448 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1417](https://legendstudy.com/1417) | IDENTITY_REVIEW_52 | 2019/10/3/national_mock → 2019/10/3/national_mock | AMBIGUOUS | 1446,1462,1463 | 해당 시험 영역 profile 검토; 고3 연말 추가영역 검토 |
| [1418](https://legendstudy.com/1418) | IDENTITY_REVIEW_52 | 2019/11/1/national_mock → 2019/11/1/national_mock | AMBIGUOUS | 1429,1451 | 해당 시험 영역 profile 검토 |
| [1419](https://legendstudy.com/1419) | IDENTITY_REVIEW_52 | 2019/11/2/national_mock → 2019/11/2/national_mock | AMBIGUOUS | 1430,1452 | 해당 시험 영역 profile 검토; 고2 연말 추가영역 검토 |
| [1420](https://legendstudy.com/1420) | IDENTITY_REVIEW_52 | 2019/11/3/csat → 2019/11/3/csat | AMBIGUOUS | 1449 | parser 첨부 identity/subject/kind 근거 검토; 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; 문제/답 또는 occurrence 분리 검토; 분리/누락 검토: 수학 가형 |
| [1421](https://legendstudy.com/1421) | IDENTITY_REVIEW_52 | 2019/6/1/national_mock → 2019/6/1/national_mock | PARTIAL_DUPLICATE | 1412,1422 | 동일 시험의 더 넓은 source 1412에 과목 부분집합; 삭제/게시 없음 |
| [1422](https://legendstudy.com/1422) | IDENTITY_REVIEW_52 | 2019/6/1/national_mock → 2019/6/1/national_mock | PARTIAL_DUPLICATE | 1412,1421 | 동일 시험의 더 넓은 source 1412에 과목 부분집합; 삭제/게시 없음 |
| [1423](https://legendstudy.com/1423) | IDENTITY_REVIEW_52 | 2019/6/2/national_mock → 2019/6/2/national_mock | PARTIAL_DUPLICATE | 1414,1424 | 동일 시험의 더 넓은 source 1414에 과목 부분집합; 삭제/게시 없음 |
| [1424](https://legendstudy.com/1424) | IDENTITY_REVIEW_52 | 2019/6/2/national_mock → 2019/6/2/national_mock | PARTIAL_DUPLICATE | 1414,1423 | 동일 시험의 더 넓은 source 1414에 과목 부분집합; 삭제/게시 없음 |
| [1425](https://legendstudy.com/1425) | IDENTITY_REVIEW_52 | 2019/9/1/national_mock → 2019/9/1/national_mock | PARTIAL_DUPLICATE | 1413,1426 | 동일 시험의 더 넓은 source 1413에 과목 부분집합; 삭제/게시 없음 |
| [1426](https://legendstudy.com/1426) | IDENTITY_REVIEW_52 | 2019/9/1/national_mock → 2019/9/1/national_mock | PARTIAL_DUPLICATE | 1413,1425 | 동일 시험의 더 넓은 source 1413에 과목 부분집합; 삭제/게시 없음 |
| [1427](https://legendstudy.com/1427) | IDENTITY_REVIEW_52 | 2019/9/2/national_mock → 2019/9/2/national_mock | PARTIAL_DUPLICATE | 1415,1428,1450 | 동일 시험의 더 넓은 source 1415에 과목 부분집합; 삭제/게시 없음 |
| [1428](https://legendstudy.com/1428) | IDENTITY_REVIEW_52 | 2019/9/2/national_mock → 2019/9/2/national_mock | PARTIAL_DUPLICATE | 1415,1427,1450 | 동일 시험의 더 넓은 source 1415에 과목 부분집합; 삭제/게시 없음 |
| [1429](https://legendstudy.com/1429) | IDENTITY_REVIEW_52 | 2019/11/1/national_mock → 2019/11/1/national_mock | PARTIAL_DUPLICATE | 1418,1451 | 동일 시험의 더 넓은 source 1418에 과목 부분집합; 삭제/게시 없음 |
| [1430](https://legendstudy.com/1430) | IDENTITY_REVIEW_52 | 2019/11/2/national_mock → 2019/11/2/national_mock | PARTIAL_DUPLICATE | 1419,1452 | 동일 시험의 더 넓은 source 1419에 과목 부분집합; 삭제/게시 없음 |
| [1431](https://legendstudy.com/1431) | IDENTITY_REVIEW_52 | 2020/4/3/national_mock → 2020/3/3/national_mock | AMBIGUOUS | 1474 | 명목월/시행월 충돌 |
| [1433](https://legendstudy.com/1433) | IDENTITY_REVIEW_52 | 2020/6/3/evaluation_mock → 2020/6/3/evaluation_mock | AMBIGUOUS | 1472 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1434](https://legendstudy.com/1434) | IDENTITY_REVIEW_52 | 2020/7/3/national_mock → 2020/7/3/national_mock | FULL_SET_CANONICAL | 1476 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1435](https://legendstudy.com/1435) | IDENTITY_REVIEW_52 | 2020/9/3/evaluation_mock → 2020/9/3/evaluation_mock | AMBIGUOUS | 1473 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증 |
| [1436](https://legendstudy.com/1436) | IDENTITY_REVIEW_52 | 2020/10/3/national_mock → 2020/10/3/national_mock | AMBIGUOUS | 1477 | 고3 연말 추가영역 검토 |
| [1437](https://legendstudy.com/1437) | IDENTITY_REVIEW_52 | 2020/3/1/national_mock → 2020/3/1/national_mock | FULL_SET_CANONICAL | 1464 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1438](https://legendstudy.com/1438) | IDENTITY_REVIEW_52 | 2020/3/2/national_mock → 2020/3/2/national_mock | FULL_SET_CANONICAL | 1468 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1439](https://legendstudy.com/1439) | IDENTITY_REVIEW_52 | 2020/6/1/national_mock → 2020/6/1/national_mock | FULL_SET_CANONICAL | 1465 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1440](https://legendstudy.com/1440) | IDENTITY_REVIEW_52 | 2020/6/2/national_mock → 2020/6/2/national_mock | FULL_SET_CANONICAL | 1469 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1441](https://legendstudy.com/1441) | IDENTITY_REVIEW_52 | 2020/9/1/national_mock → 2020/9/1/national_mock | FULL_SET_CANONICAL | 1466 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1442](https://legendstudy.com/1442) | IDENTITY_REVIEW_52 | 2020/9/2/national_mock → 2020/9/2/national_mock | FULL_SET_CANONICAL | 1470 | source 전과목 category + 해당 profile의 명시 과목별 문제/답 coverage; 원래 label 보존 |
| [1443](https://legendstudy.com/1443) | IDENTITY_REVIEW_52 | 2020/11/1/national_mock → 2020/11/1/national_mock | AMBIGUOUS | 1467 | parser 첨부 identity/subject/kind 근거 검토 |
| [1444](https://legendstudy.com/1444) | IDENTITY_REVIEW_52 | 2020/11/2/national_mock → 2020/11/2/national_mock | AMBIGUOUS | 1471 | parser 첨부 identity/subject/kind 근거 검토; 고2 연말 추가영역 검토; 문제/답 또는 occurrence 분리 검토; 과목 없는 문제/답 첨부; 분리/누락 검토: 정치와법 |
| [1445](https://legendstudy.com/1445) | IDENTITY_REVIEW_52 | 2019/7/3/national_mock → 2019/7/3/national_mock | PARTIAL_DUPLICATE | 1407,1460,1461 | 동일 시험의 더 넓은 source 1407에 과목 부분집합; 삭제/게시 없음 |
| [1446](https://legendstudy.com/1446) | IDENTITY_REVIEW_52 | 2019/10/3/national_mock → 2019/10/3/national_mock | PARTIAL_DUPLICATE | 1417,1462,1463 | 동일 시험의 더 넓은 source 1417에 과목 부분집합; 삭제/게시 없음 |
| [1448](https://legendstudy.com/1448) | IDENTITY_REVIEW_52 | 2019/9/3/evaluation_mock → 2019/9/3/evaluation_mock | PARTIAL_DUPLICATE | 1416 | 동일 시험의 더 넓은 source 1416에 과목 부분집합; 삭제/게시 없음 |
| [1449](https://legendstudy.com/1449) | IDENTITY_REVIEW_52 | 2019/11/3/csat → 2019/11/3/csat | AMBIGUOUS | 1420 | 해당 시험 영역 profile 검토; 직탐/제2외국어·한문 완전성 미입증; source 전과목 의도 미확인 |
| [1450](https://legendstudy.com/1450) | IDENTITY_REVIEW_52 | 2019/9/2/national_mock → 2019/9/2/national_mock | PARTIAL_DUPLICATE | 1415,1427,1428 | 동일 시험의 더 넓은 source 1415에 과목 부분집합; 삭제/게시 없음 |
| [1451](https://legendstudy.com/1451) | IDENTITY_REVIEW_52 | 2019/11/1/national_mock → 2019/11/1/national_mock | PARTIAL_DUPLICATE | 1418,1429 | 동일 시험의 더 넓은 source 1418에 과목 부분집합; 삭제/게시 없음 |
| [1452](https://legendstudy.com/1452) | IDENTITY_REVIEW_52 | 2019/11/2/national_mock → 2019/11/2/national_mock | PARTIAL_DUPLICATE | 1419,1430 | 동일 시험의 더 넓은 source 1419에 과목 부분집합; 삭제/게시 없음 |
| [1460](https://legendstudy.com/1460) | IDENTITY_REVIEW_52 | 2019/7/3/national_mock → 2019/7/3/national_mock | PARTIAL_DUPLICATE | 1407,1445,1461 | 동일 시험의 더 넓은 source 1407에 과목 부분집합; 삭제/게시 없음 |
| [1461](https://legendstudy.com/1461) | IDENTITY_REVIEW_52 | 2019/7/3/national_mock → 2019/7/3/national_mock | PARTIAL_DUPLICATE | 1407,1445,1460 | 동일 시험의 더 넓은 source 1407에 과목 부분집합; 삭제/게시 없음 |
| [1462](https://legendstudy.com/1462) | IDENTITY_REVIEW_52 | 2019/10/3/national_mock → 2019/10/3/national_mock | PARTIAL_DUPLICATE | 1417,1446,1463 | 동일 시험의 더 넓은 source 1417에 과목 부분집합; 삭제/게시 없음 |
| [1463](https://legendstudy.com/1463) | IDENTITY_REVIEW_52 | 2019/10/3/national_mock → 2019/10/3/national_mock | PARTIAL_DUPLICATE | 1417,1446,1462 | 동일 시험의 더 넓은 source 1417에 과목 부분집합; 삭제/게시 없음 |
| [1464](https://legendstudy.com/1464) | IDENTITY_REVIEW_52 | 2020/3/1/national_mock → 2020/3/1/national_mock | PARTIAL_DUPLICATE | 1437 | 동일 시험의 더 넓은 source 1437에 과목 부분집합; 삭제/게시 없음 |
| [1465](https://legendstudy.com/1465) | IDENTITY_REVIEW_52 | 2020/6/1/national_mock → 2020/6/1/national_mock | PARTIAL_DUPLICATE | 1439 | 동일 시험의 더 넓은 source 1439에 과목 부분집합; 삭제/게시 없음 |
| [1466](https://legendstudy.com/1466) | IDENTITY_REVIEW_52 | 2020/9/1/national_mock → 2020/9/1/national_mock | PARTIAL_DUPLICATE | 1441 | 동일 시험의 더 넓은 source 1441에 과목 부분집합; 삭제/게시 없음 |
| [1467](https://legendstudy.com/1467) | IDENTITY_REVIEW_52 | 2020/11/1/national_mock → 2020/11/1/national_mock | PARTIAL_DUPLICATE | 1443 | 동일 시험의 더 넓은 source 1443에 과목 부분집합; 삭제/게시 없음 |
| [1468](https://legendstudy.com/1468) | IDENTITY_REVIEW_52 | 2020/3/2/national_mock → 2020/3/2/national_mock | PARTIAL_DUPLICATE | 1438 | 동일 시험의 더 넓은 source 1438에 과목 부분집합; 삭제/게시 없음 |
| [1469](https://legendstudy.com/1469) | IDENTITY_REVIEW_52 | 2020/6/2/national_mock → 2020/6/2/national_mock | PARTIAL_DUPLICATE | 1440 | 동일 시험의 더 넓은 source 1440에 과목 부분집합; 삭제/게시 없음 |
| [1470](https://legendstudy.com/1470) | IDENTITY_REVIEW_52 | 2020/9/2/national_mock → 2020/9/2/national_mock | PARTIAL_DUPLICATE | 1442 | 동일 시험의 더 넓은 source 1442에 과목 부분집합; 삭제/게시 없음 |
| [1471](https://legendstudy.com/1471) | IDENTITY_REVIEW_52 | 2020/11/2/national_mock → 2020/11/2/national_mock | PARTIAL_DUPLICATE | 1444 | 동일 시험의 더 넓은 source 1444에 과목 부분집합; 삭제/게시 없음 |
| [1472](https://legendstudy.com/1472) | IDENTITY_REVIEW_52 | 2020/6/3/evaluation_mock → 2020/6/3/evaluation_mock | PARTIAL_DUPLICATE | 1433 | 동일 시험의 더 넓은 source 1433에 과목 부분집합; 삭제/게시 없음 |
| [1473](https://legendstudy.com/1473) | IDENTITY_REVIEW_52 | 2020/9/3/evaluation_mock → 2020/9/3/evaluation_mock | PARTIAL_DUPLICATE | 1435 | 동일 시험의 더 넓은 source 1435에 과목 부분집합; 삭제/게시 없음 |
| [1475](https://legendstudy.com/1475) | IDENTITY_REVIEW_52 | 2020/4/3/national_mock → 2020/4/3/national_mock | PARTIAL_DUPLICATE | 1432 | 동일 시험의 더 넓은 source 1432에 과목 부분집합; 삭제/게시 없음 |
| [1476](https://legendstudy.com/1476) | IDENTITY_REVIEW_52 | 2020/7/3/national_mock → 2020/7/3/national_mock | PARTIAL_DUPLICATE | 1434 | 동일 시험의 더 넓은 source 1434에 과목 부분집합; 삭제/게시 없음 |
| [1477](https://legendstudy.com/1477) | IDENTITY_REVIEW_52 | 2020/10/3/national_mock → 2020/10/3/national_mock | PARTIAL_DUPLICATE | 1436 | 동일 시험의 더 넓은 source 1436에 과목 부분집합; 삭제/게시 없음 |

## Schema, verification and stop

Fresh information_schema/pg_constraint inspection matches the policy's existing
is_active/merged pointer/quarantine/source/resource provenance capabilities.
No schema proposal is needed now. Multi-source union remains a separate controlled
writer/provenance problem if a real case requires it, not authority to merge now.

Production source_posts/content_items/exams/exam_subjects/resources/quarantine
full-row snapshots matched before/after. Queries used a read-only DB transaction;
no resolver RPC/quota write, DB mutation, deployment, activation or migration.
Accepted-state and52 manifest hashes unchanged;1710 A1 untouched. No batch selected.

Audit deterministic tests6 PASS (same/shuffled input, subject loss despite extra
resource count, protected holds, occurrence evidence, postponed-March sibling).
Flutter analyze PASS; focused72 PASS; full850 PASS/skip1/known3 failures as recorded
in [Owner QA](owner-device-qa-2026-09-27.md). No new regression at final checks.
Wiki/diff checks required before commit. Separate Commit A retains QA fixes;
Commit B contains this policy/evidence/offline tooling only. Owner iOS/untracked
and onboarding work remain untouched.

STOP: unresolved full-set evidence remains REVIEW;1431 replacement intersects52
HOLD and requires an explicit later gate. 부산대 direct App opening requires a
separate resolver-contract/deployment approval. None is silently implemented.
Next: Owner/ChatGPT review → permitted metadata/parser correction if needed →
controlled active replacement → approved full-set bounded publication → historical
expansion (possible 고3→고2→고1) → essay/class/request materials. Sequence remains
adjustable; this report grants no publication authority.
