# Essay mixed-mode foundation — 2026-10-08

Status: ANALYZED; metadata/planning contract only. No provider call, live evaluator,
content publication, existing runtime rewrite, new submission DB or Credit change.
Owner execution update permits this task despite predecessor PARTIAL. Reuse exact
006 Application **and Events**,007 Study,008 Student360/Essay;005 HELD. The new Owner
block's numbering for Events/Study is a prose mismatch, not a schema change instruction.

## ESSAY_MIXED_MODE_GAP_ANALYSIS

### Existing / reusable

- Shared public catalog: universities → essay_exams; official field_or_division,
  exam_name, academic year, source/provenance/verification already retained.
- Humanities: essay_questions/evidence/criteria → practice sessions → immutable
  attempts → evaluations/dimensions; scaffolding1.3, attempt/rewrite linkage and
  canonical Credit decision/reserve/consume/included336h authority. Text body is
  required; typed/pasted/mixed input_method is not an image artifact relation.
- Math: Store RC ca60d73 includes unchanged20261002000100/00200/00300 C/D/E.
  Activation branch codex/math-production-activation-1 at3a227be records prior
  Oct04 applied/off state; do not import its whole branch or assume current E2E.
  math_problem_sets references essay_exam_id; problems → subproblems → versioned
  evaluation profiles/criteria/solutions. Separate typed Math attempts/results.
- Math input_kind TYPED/EVIDENCE/MIXED already supports typed explanation plus
  artifacts; math_attempt_artifacts.position and extraction page/reading_order
  support ordered multiple pages. bucket math-private;20MiB artifact cap, private
  access, registration/presence/erasure state, orientation and region provenance.
  Reuse these security semantics; Humanities cannot borrow a Math user's artifact
  by UUID without an explicit owner/attempt binding.
- Runtime: math_input/extraction/evaluation/learning plusqlm_quality are existing
  authorities. Extraction confirmation and confirmed version remain explicit;
  original image/region cannot be replaced by OCR-only text for science/graphs.
- Quality: existing quality_operators/ql_* and typed qlm_*/Human Review boundaries;
  an operator does not become Admin. Existing evidence/calibration packages and
  contracts remain authoritative; synthetic routing fixtures are not AI quality.

### Missing

- Service exam category is absent; existing exam_kind is admission/mock/other,
  not Humanities/Math. No question capability classification or reviewed bridge
  between a Humanities question and a Math leaf. No mixed-operation coordinator.
- Quantitative/data interpretation are requirements, not proven new runtime
  engines. They may route through an existing evaluator only with a reviewed
  question/rubric binding; business_economics must not imply Math automatically.
- Science evaluation/rubric/golden corpus not established. NEW_CAPABILITY_REQUIRED;
  no fallback to Humanities/Math solely because a response is text or an image.
- Cross-capability completion, retry and result bindings are not implemented.
  Future overall state must remain incomplete when a required child fails;
  common billing must be one existing decision, not one charge per child retry.
- Production content: Owner current inventory confirms50 active universities,
 21 active exams,0 questions/0 published questions/0 criteria **within those21**.
  Offline representative packages do not constitute Production registration.

### Schema / runtime / UI change assessment

No Essay DB migration is needed for this phase's conservative adapter contract.
Future server catalog extension should have one verified exam-category authority
and question capability metadata with source/hash/version/review time, preserving
all official labels and immutable evaluation context. Do not seed guesses from
exam names. Existing question UUIDs and typed Math leaf identities stay unchanged.
A mixed-question bridge, runtime orchestration and common answer artifact binding
need a separately reviewed additive design; do not merge Math tables/history.

Public UI unchanged. Four service types do not mandate four empty tabs. Display
only available reviewed catalog groups; preserve university/exam/question URLs.
APP UI/client unchanged. Any future APP contract change requires a separate gate.

Migration risk: widening existing enum/dispatch or rewriting attempt/evaluation
relations is high and STOPPED. This phase's Python planning adapter performs no
DB writes/provider/billing operations and is not connected to Production routing.

## Product and planning contract

Service category: humanities_social / business_economics / math / science.
Question requirements: humanities_reasoning / data_interpretation /
quantitative_reasoning / math_solution / science_reasoning. These are a versioned
planning vocabulary, not installed DB enums or evidence that each engine exists.

A trusted server catalog adapter must resolve request university/year/exam/question
identity, question metadata version, exact rubric binding, classification version
and official evidence review. Request contains identity only; client-supplied
category/capability/evaluator/rubric is rejected. Existing evaluator bindings are
explicit humanities or math with their own resource identity and version. The
planning result cannot activate runtime or grant authorization by itself.

Report/Growth reuse original typed result references. Humanities1..5 dimension
comparisons require same question/criterion/rubric definition/metadata/regime/
contract/evidence and student-request context. Math dimensions/results remain typed;
no100-point conversion, universal trend, average across unrelated components, or
Application-required Essay history. Student360008 remains unchanged; future additive
summary may carry nullable reviewed category/classification version and references,
not answer bodies or invented performance. Report/PDF engine NOT_IMPLEMENTED.

## Seven preservation answers

1. Classification source/review/version separate from student occurred/recorded facts.
2. Keep official/raw label, question and existing result IDs; no guessed backfill.
3. Future corrected classification gets a new version; never reinterpret old scores.
4. No new student identity; shared auth.users/profile remains authority.
5. Catalog metadata is neither learning fact nor Application/Outcome.
6. Private artifacts/answers remain owner/operator-scoped with existing deletion.
7. Taxonomy/routing plan is derived metadata, not evaluation or verified learning gain.

## Golden QA / next approval

Humanities: evidence/rubric matching, strong-answer CORE0, real flaws, rewrite/history.
Economics: one synthetic exam with prose, data interpretation and Math questions;
include prose-only business exam to reject “business always Math”.
Math: formula/proof, partial/incorrect/correct-without-steps, rotated/poor images,
multiple pages and extraction correction using existing Math quality workflow.
Science: physics/chemical equations/reactions/graphs/biology/calculation samples;
require new capability and rubric review before real evaluation.
All require grounding, identity mismatch rejection, hallucination/stability, image
loss, partial failure/retry, same billing decision, included rewrite policy and
history. No provider invocation is authorized by passing synthetic contract tests.

Next Owner gate: content/rubric publication, reviewed mixed bridge/orchestration,
science capability, real provider cost/model QA and hosted private artifact E2E.
Payment/Toss/Signup/IAP/Manus visual/Claude APP UI unchanged.

## Read-only mapping of21 active exams

Source: Owner SQL inventory plus public REST catalog read2026-10-08. Every row below
is year2025, published questions0/criteria0. Classification is a **label-derived
proposal**, not a verified question-capability assignment or Production backfill.

| Exam ID | Official exam label | Proposed service category | Basis / limit |
|---|---|---|---|
| `0b3faf34-a53d-5a9e-8ffd-c270783f4d26` | [2025학년도 경희대학교 논술 사회계 11월 17일 오후](https://iphak.khu.ac.kr/detail.do?board_seq=13928&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | UNRESOLVED | social/natural/medical label insufficient; source question review needed |
| `d190bb2e-711c-5bfb-9f79-19729e03bf8e` | [2025학년도 경희대학교 논술 의·약학계 11월 16일 오후](https://iphak.khu.ac.kr/detail.do?board_seq=13928&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | UNRESOLVED | social/natural/medical label insufficient; source question review needed |
| `04119637-2d7b-52b4-8e84-4cbd76d0275c` | [2025학년도 경희대학교 논술 인문·체육계 11월 16일 오전](https://iphak.khu.ac.kr/detail.do?board_seq=13928&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | humanities_social | explicit humanities/language label; mixed components unverified |
| `de947c5e-7c9d-5190-a025-aeefb0631bcd` | [2025학년도 경희대학교 논술 자연계 11월 17일 오전](https://iphak.khu.ac.kr/detail.do?board_seq=13928&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | UNRESOLVED | social/natural/medical label insufficient; source question review needed |
| `2919c142-21d7-539d-952a-5382d16dbdf7` | [2025학년도 경희대학교 모의논술 사회계 온라인](https://iphak.khu.ac.kr/detail.do?board_seq=12260&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | UNRESOLVED | social/natural/medical label insufficient; source question review needed |
| `a5ce6865-b88d-57ef-9aa5-605ebc4e806c` | [2025학년도 경희대학교 모의논술 의·약학계 온라인](https://iphak.khu.ac.kr/detail.do?board_seq=12260&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | UNRESOLVED | social/natural/medical label insufficient; source question review needed |
| `071a6834-4bc1-586b-bacd-33d89d1d39cd` | [2025학년도 경희대학교 모의논술 인문·체육계 온라인](https://iphak.khu.ac.kr/detail.do?board_seq=12260&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | humanities_social | explicit humanities/language label; mixed components unverified |
| `2946d60b-cc6b-586b-b769-1f21718b4df7` | [2025학년도 경희대학교 모의논술 자연계 온라인](https://iphak.khu.ac.kr/detail.do?board_seq=12260&menuurl=89BGs%2Bk748ajyySWoWlQPw%3D%3D) | UNRESOLVED | social/natural/medical label insufficient; source question review needed |
| `e3b1b7b2-26ef-5a4f-8c5a-749aa0b5d949` | [2025학년도 성균관대학교 논술 수리형 1교시](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290) | math | explicit math label; question capability unverified |
| `56a562f2-992e-5302-af54-1508b6a4c1c8` | [2025학년도 성균관대학교 논술 수리형 2교시](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290) | math | explicit math label; question capability unverified |
| `405fa544-7f65-5e56-88e6-a2959d32dd30` | [2025학년도 성균관대학교 논술 수리형 3교시](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290) | math | explicit math label; question capability unverified |
| `e15a43a8-5a50-501a-8a60-a632316240e8` | [2025학년도 성균관대학교 논술 언어형 1교시](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290) | humanities_social | explicit humanities/language label; mixed components unverified |
| `306ac6e2-572a-59f1-bf2f-cb0394ec04f1` | [2025학년도 성균관대학교 논술 언어형 2교시](https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290) | humanities_social | explicit humanities/language label; mixed components unverified |
| `df2ca870-5d5b-56c6-8257-0bd997b1bdc4` | [2025학년도 성균관대학교 모의논술 수리 논술](https://admission.skku.edu/admission/html/rolling/questionView.html?idx=59182) | math | explicit math label; question capability unverified |
| `ef67de3d-7c9f-505a-90dd-339a8658dc3a` | [2025학년도 성균관대학교 모의논술 언어 논술](https://admission.skku.edu/admission/html/rolling/questionView.html?idx=59182) | humanities_social | explicit humanities/language label; mixed components unverified |
| `a6667288-75ad-50d4-b237-d2a08e2bff8b` | [2025학년도 숙명여자대학교 모의논술 인문계열](https://admission.sookmyung.ac.kr/admission/html/rolling/previousView.asp?p_board_idx=52111&p_mode=modify) | humanities_social | explicit humanities/language label; mixed components unverified |
| `96153040-bcac-5006-82a4-147a98d0b553` | [2025학년도 연세대학교 논술 인문계열](https://admission.yonsei.ac.kr/seoul/admission/html/counsel/dataView.asp?BBS_NO=3356) | humanities_social | explicit humanities/language label; mixed components unverified |
| `1825b3d9-3e15-519f-947c-8867cfbdaa67` | [2025학년도 연세대학교 논술 자연계열(수학)](https://admission.yonsei.ac.kr/seoul/admission/html/counsel/dataView.asp?BBS_NO=3356) | math | explicit math label; question capability unverified |
| `3cf7c549-32bc-5cdb-b1f5-4e8b24958559` | [2025학년도 연세대학교 논술 자연계열(수학) 추가시험](https://admission.yonsei.ac.kr/seoul/admission/html/counsel/dataView.asp?BBS_NO=3356) | math | explicit math label; question capability unverified |
| `f95339d5-ffe8-59ff-960a-31ba637cf37b` | [2025학년도 연세대학교 모의논술 자연계열(수학)](https://admission.yonsei.ac.kr/seoul/admission/html/rolling/noticeView.asp?BBS_NO=3236) | math | explicit math label; question capability unverified |
| `66ad79a8-7ea9-525d-a8f7-dc8c0e92b3e5` | [2025학년도 한양대학교 모의논술 인문계열](https://go.hanyang.ac.kr/web/pds/pds_view.do?bn=14860&m_type=SUSI&ct02=ns02) | humanities_social | explicit humanities/language label; mixed components unverified |

Label proposals: {"UNRESOLVED": 6, "humanities_social": 8, "math": 7}. No positively verified business/science classification
from these labels alone. Official source URLs are preserved; this report does not
claim a new PDF content review or permission to redistribute source PDFs.


## Current Production Math verification

Owner current read-only inventory confirms20261002000100/00200/00300 and20261004000200
recorded, math_problem_sets/problems/subproblems/evaluation_profiles installed, and
math-private public=false. All five returned postgres-owned function body MD5s match
Store RC SQL exactly: math_input554c5bf6e77c346e5c7e7c17d68adaca,
math_extraction5dbf4ad6fdd9e3bd5bdec8ac8a94f97b,
math_evaluation2da499ae490c6a456f4f6561b17b1d75,
math_learning66299b1baf05170990e4b8d7e7351c67,
qlm_qualityfe233264d8452be8616684e2574389b3.
This verifies deployed definitions/private-bucket setting, not current gateway
provider readiness, artifact byte/URL/erase E2E or Math content row counts.

## Implemented foundation and tests

`tool/essay_platform_contract.py` is an offline server-adapter planning contract;
no Production endpoint or runtime is connected. Trusted loader supplies reviewed
question metadata. Identity-only requests reject client capability/evaluator/rubric
fields. Context and rubric/typed subject/exam mismatch fail closed; unsupported
science cannot silently use Humanities. Plans retain missing requirements and
runtime_enabled=false/Credit actionNONE. No AI quality success implied.
8 synthetic tests cover Humanities, Math, mixed Economics exam, prose-only business,
missing requirements, spoofing, cross-question/exam/year/rubric mismatch and Science.
Existing isolated Math learning/C-D regression, Humanities legacy102 and Math
installation regression pass. Actual provider/evaluation E2E NOT_RUN.
