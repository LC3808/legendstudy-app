# Historical Exam Expected Coverage Registry

Status: **Phase3 offline foundation implemented — 2026-09-27.**
[Policy](exam-full-set-canonical-policy.md) · [Phase3 results](exam-canonical-audit-phase3-2026-09-27.md) · [Phase2 baseline](exam-canonical-audit-phase2-2026-09-27.md)

## Scope and authority

SOURCE ARCHIVE != APP CATALOG. One exam → one canonical full-set experience.
The primary input is 57 existing writer-ready posts / 57 distinct nominal exam
identities, actually calendar2021–2024. Two regression identities add2020 March
and reference-only2019 June: **59 entries,55 VERIFIED,3 PARTIALLY_VERIFIED,1 UNVERIFIED**.
This is a reusable2020→current foundation, **not an exhaustive registry of every
2020–2026 session**. Unrepresented2020/2025/2026 exams and Wave2/3 always miss;
no inferred year expansion. Phase2's2026 G1 reference remains preserved in its
artifact but is not silently promoted to a complete2026 calendar here.

Independent authority defines EXPECTED; LegendStudy snapshot defines OBSERVED.
Five annual education-office spreadsheets supply exact year/grade/session paper
inventories. Calendar revisions are separate evidence; an older annual plan does
not override later actual-date evidence. No binary source documents are committed.

## Files and reproducibility

- `tool/ingestion/reference/exam-expected-coverage.json`: reviewable registry,
  compact metadata/citations, official attachment SHA256 and sheet/cell locators.
- `tool/ingestion/exam_coverage_registry.py`: exact lookup, independent identity
  checks, ExpectedCoverage adapter and stricter Phase3 sibling rule.
- `tool/audit_exam_canonical_phase3.py`: fixed57 input, baseline sibling scan,
  source/registry comparison, no network/DB/writer imports.
- `tool/ingestion/samples/exam-canonical-phase3-audit.json`: deterministic result,
  input hashes and per-post reasons, actual paper/kind maps, next actions.
- `tool/test_exam_coverage_registry.py`: real historical + boundary fixtures.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tool/audit_exam_canonical_phase3.py --output /tmp/phase3.json
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tool -p test_exam_coverage_registry.py
```

## Contract

Lookup key extends existing identity with organizer: calendar exam_year,
nominal_month,grade,exam_family,organizer. Academic year is explicit; actual date,
administered month and distribution events are consistency guards, not a new DB
identity. `reference_date` may be an official planned date; `date_status` tells
whether actual event evidence was acquired. Source dates are never overwritten.
Unknown organizer may be supplied by one independently cited exact calendar
entry; an existing different organizer produces REVIEW. Missing source evidence
cannot become high confidence merely because a registry row exists.

Each entry records required named papers, domain/subject groups, Korean/math
variants, conditional offered/not-offered papers, evidence and confidence/status.
Named social/science papers must all be covered; a single elective never proves
a domain complete. Conditional means optional for a student, not optional for a
catalogue advertised as the whole exam. Grade2 late and grade3 October profiles
include vocational6 + foreign/Hanmun7; KICE June/September columns list vocational6
+ foreign/Hanmun9. These are exact2021–2024 cell findings, not an all-years rule.
Grade3 March excludes scienceII where explicitly marked not offered.2020 math
가/나 and grade1 integrated subjects stay distinct from modern grade3 choices.

FACT = directly checked official cell/date assertion. DERIVED = deterministic
named-set normalization of those facts. INFERENCE/UNKNOWN cannot certify a
required coverage field. VERIFIED needs nonempty named inventory and scoped
verified fact citations. PARTIALLY_VERIFIED CSAT notices establish selected facts
but not a complete named inventory. UNVERIFIED2019 case has no usable profile.
Registry miss, duplicate key, malformed provenance or unsupported year never
falls back to a generic profile.

FULL_SET requires independent verified expectation + consistent source identity
+ required question/answer pairs + complete subject/choice mapping. Explanation
is not universally required: `answer_explanation` satisfies answer, plain answer
also works. The existing offline QA pairing contract is App usability policy,
not a claim that authorities provide explanations. Combined documents are not
split or relabeled; uncertain coverage of such files stays REVIEW until file
content evidence establishes the relationship. Filename counts are insufficient.

Phase3 PARTIAL_DUPLICATE additionally requires a unique actually FULL_SET sibling,
strict observed subset and no unknown attachment subject/kind/identity. A broader
REVIEW sibling is not enough. Complete ties and a subset of tied candidates stay
REVIEW. Phase2 code/output remain unchanged as historical evidence. Coverage
classification is separate from publication_hold:1431 can satisfy coverage while
remaining protected by IDENTITY_REVIEW_52. No hold is released by this tool.

## Research provenance

The following source scopes are deliberately narrow. Official planned coverage
is sufficient evidence of the expected inventory, not proof of source file
contents or HTTP usability. File-level links/content need a fresh preflight
before any later publication approval.

| Reference | Authority / original source | Proves |
|---|---|---|
| ice_2020_coverage | Incheon Metropolitan City Office of Education: [2020학년도 전국연합학력평가 연간 출제 범위](https://www.ice.go.kr/upload/board/1414/2020/08/1597136600777.xlsx) | expected_papers, offered_and_not_offered_domains, named_electives |
| ice_2021_coverage | Incheon Metropolitan City Office of Education: [2021학년도 전국연합학력평가 연간 출제 범위](https://www.ice.go.kr/upload/board/1414/2021/03/1616486316189.xlsx) | expected_papers, offered_and_not_offered_domains, named_electives |
| ice_2022_coverage | Incheon Metropolitan City Office of Education: [2022학년도 전국연합학력평가 연간 출제 범위](https://www.ice.go.kr/upload/board/1414/2022/05/1653543426893.xlsx) | expected_papers, offered_and_not_offered_domains, named_electives |
| ice_2022_calendar | Incheon Metropolitan City Office of Education: [2022 시행 일정 및 주관 교육청](https://www.ice.go.kr/upload/board/1414/2022/05/1653543426876.hwpx) | planned_dates, organizer, nominal_admin_month_relation |
| ice_2023_coverage | Incheon Metropolitan City Office of Education: [2023학년도 전국연합학력평가 연간 출제 범위](https://www.ice.go.kr/upload/board/1414/2023/06/9922ba604859354c2246ab234ece6306.xlsx) | expected_papers, offered_and_not_offered_domains, named_electives |
| ice_2023_calendar | Incheon Metropolitan City Office of Education: [2023 시행 일정 및 주관 교육청](https://www.ice.go.kr/upload/board/1414/2023/06/70df30f19e6a20e81be5e6315445eeda.hwpx) | planned_dates, organizer, nominal_admin_month_relation |
| ice_2024_coverage | Incheon Metropolitan City Office of Education: [2024학년도 전국연합학력평가 연간 출제 범위](https://www.ice.go.kr/upload/ice/na/bbs_570/2024/08/90ed44a7c1ef36df9e918a999ceb40ea.xlsx) | expected_papers, offered_and_not_offered_domains, named_electives |
| ice_2024_calendar | Incheon Metropolitan City Office of Education: [2024 시행 일정 및 주관 교육청](https://www.ice.go.kr/upload/ice/na/bbs_570/2024/08/4e524a33dacfb9f2b67c49532749faea.hwpx) | planned_dates, organizer, nominal_admin_month_relation |
| moe_2021_calendar | Ministry of Education: [2021 planned exam calendar](https://www.moe.go.kr/upload/brochureBoard/1/2021/02/1612743646339_28214575761487136.pdf) | planned_dates, organizer |
| school_2021_march | Daejeon Dongsan High School: [2021 March school calendar](https://djdongsanhs.djsch.kr/scheduleH/list.do?schdYear=2021&section=1) | 2021_march_grade_specific_dates, 2021_G1_G2_September_actual_date_2021-08-31 |
| moe_2022_september | Ministry of Education / KICE: [2023학년도 9월 모의평가 실시](https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=92402&lev=0&m=020402&opType=N&page=1&s=moe&statusYN=W) | 2022_G3_September_actual_date_2022-08-31 |
| ice_2022_actual | Incheon Education Office / student reporter: [2022 전국연합학력평가 시행 현장](https://www.ice.go.kr/news/na/ntt/selectNttInfo.do?mi=&nttSn=2462331) | 2022_G1_G2_September_actual_date_2022-08-31 |
| ebs_2023_late | EBS: [2023-12-18 학력평가 풀서비스 안내](https://about.ebs.co.kr/board/bbs?boardId=31&boardTypeId=1&cmd=view&postId=30002817866) | 2023_G1_G2_late_actual_date_2023-12-19, organizer |
| busan_2021_results | Busan Education Office (original report reproduced by Uway): [2021 고2 6월 채점 결과 분석](https://info.uway.com/info/desk/index2.htm?CMS_SEQ=160457&CTG_SEQ=6&ROW_NUMBER=96&UPPER_CTG_SEQ=1&ctrl=read&page=13) | 2021_G2_June_actual_date_2021-06-02 |
| school_2020_distribution | Daein High School: [2020-04-24 학력평가 문제 배부 자료](https://daein.icehs.kr/boardCnts/list.do?boardID=218713&m=0302&page=21&type=main) | 2020_G3_paper_distribution_date |
| moe_2021_csat | Ministry of Education / KICE: [2022학년도 수능 채점 결과](https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=89967&lev=0&m=020402&opType=N&s=moe&statusYN=W) | 2021_CSAT_date, domain_presence_not_complete_named_paper_inventory |
| moe_2022_csat | Ministry of Education / KICE: [2023학년도 수능 시행세부계획](https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=91915&lev=0&m=020402&opType=N&s=moe&statusYN=W) | 2022_CSAT_date, domain_presence_not_complete_named_paper_inventory |
| moe_2023_csat | Ministry of Education / KICE: [2024학년도 수능 시행 기본계획 브리핑](https://www.korea.kr/briefing/policyBriefingView.do?newsId=156559554) | 2023_CSAT_planned_date_not_complete_named_paper_inventory |

The Busan2021 result is the original education-office report reproduced by Uway;
its host is explicitly not the authority. School calendars and the education-office
student-reporter event account are supporting institution evidence, not KICE
coverage authority. All sources accessed2026-09-27. Annual attachments are retained
only temporarily outside Git; cell locators/hashes make later review possible.

## Gates and extension

DISCOVERY → PARSE → NORMALIZE → existing EXAM IDENTITY → exact EXPECTED COVERAGE
→ observed resource/subject mapping → SIBLING comparison → offline classification
→ Owner review → separate controlled publication gate. Writer, scheduler and
Production gate integration: **NO**. A future importer may propose registry rows;
it must not label inferred profiles VERIFIED. Add exact-year sources before
expanding2015–2019 or2010–2014. Current schema is sufficient for this reference
layer and single-target `merged_into_content_item_id`; no migration or new
canonical DB architecture is proposed. Runtime redirect/reference handling is
still required before active replacement.
