# 평가 근거·공식 채점기준 구조 — 2026-10-31

> 최신 판정: [숭실 v3 최종 검증](#숭실-v3-최종-검증--2026-10-31) — PDF 내용 PASS, 실제 운영 v3와 후보의 기준·digest가 달라 직접 적용 BLOCKED. 앞선 보관본 기반 적용 대기 판단을 대체한다.

Owner 10/31 지시. **APP/WEB 표시 수정 및 오프라인 정정 후보 준비. 운영 적용 아님.**
기존 [출시 전 안정화](pre-release-stabilization-20261030.md), [APP Round29](app-device-round29-20261030.md), [WEB 표시 개선](essay-web-result-refinement-20261030.md), [공식 근거 보존](essay-lab-data-foundation.md#official-evidence-archive-strategy--owner-decision-2026-09-30)을 이어간다.

## 기준과 보존 검토

- APP `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022`, `codex/essay-evaluation-stability-p0-20261029`, 시작 LOCAL/REMOTE `049d3073dc8ea0d4f8e1339acbe0f5460efdaaea`.
- WEB `/Users/woojinchang/development/legendstudy-release-20261024`, `codex/web-app-release-20261024`, 시작 LOCAL/REMOTE `93b37419105835fb9b793f285c85cf27ab649bb4`.
- APP 미추적 `.fvmrc` 보존, Analytics 통합/기본 OFF/SQL 미적용 유지. iOS30 산출물에 쓰기·새 빌드·설치 없음.
- [일곱 보존 질문](longitudinal-learning-admissions-data-strategy.md): ① 기존 평가 발생 시점과 이번 자료 정정 후보 시점 분리 ② PDF hash/page·기존 digest·원문·diff로 복원 ③ 기존 Package/결과 UPDATE 없음 ④ 학생 identity/lineage 변경 없음 ⑤ Learning 근거 표시이며 Outcome/합격 예측 아님 ⑥ 학생 답안 없는 공식 자료 Fixture만 Git, 계정별 자료는 기존 비공개 경로 유지 ⑦ 자동 탐지는 검수 후보, 정정본은 승인 대기 derived reference로 구분.

## 숭실대 원인과 추적 범위

| 단계 | 증거·판정 |
| --- | --- |
| 공식 PDF | 2026 인문, 물리 6쪽/인쇄 21쪽의 채점기준/배점 2열. 원본 이미지 직접 대조. 5행 `8~10`, `6~7`, `4~5`, `1~3`, `0` 및 별도 1점 가점 조건. |
| 추출 | pdfplumber 0.11.9 `extract_text()`가 `논\n8~10\n리적으로`, `미흡 6~7\n한 경우`를 재현. 307자 저장 criteria가 추출 결과에 그대로 포함됨. **행의 수직 위치에 따른 열 혼합이 최초 확인 지점**. 당시 도구 실행 이력까지 재현했다고 주장하지 않음. |
| Package | 보관된 v2 Package의 question/source_page_references[4].evidenceText에 동일 문자열. v1 offline compiled package/cache에도 동일 문자열. |
| 엔진 입력 | `tool/essay_lab/material_runtime.py` compile이 evidenceText를 criterion label로 복사, `live_worker.py:package()`가 label 전달. 보관된 v1 provider-input에서도 동일 문자열 확인. 새 Provider 호출 없음. |
| 저장 결과 | material_runtime의 결과 생성은 같은 cache criteria를 보존. 해당 숭실대 현재 운영 result 원본을 새로 SELECT하지 않음. **코드/보관본/Owner 화면 근거와 현재 운영 조회를 구분**. |
| API/APP | `examEvaluationReport`가 criteria.label과 dimensions.explanation을 분리해 읽음. 기존 adapter가 다시 label+feedback을 합치고 evidenceLabels도 label—feedback으로 표시하여 공식 기준/설명 중복. |
| WEB | `examReports`/`evaluation-report` 같은 매핑. 기존 WEB 중복 방지 로직 유지, 단일 표 제목/원문 disclosure 정책 일치. 현재 실제 계정 API 응답 미재조회. |

PDF SHA256 `dd97f6d0b480955f80fd2568c3b59bd8e04f2e918895ce7061e1cb2e143441ff`.
시험 `0d4fcaa4-2be0-52a0-9590-c61f65c5f199`, 문항 `5df22bef-ce93-5333-9334-023ba98468e4`, 대학 `6ae1fd3f-22da-43f4-a796-1cfe960c5fcb`.
보관 v2 digest `2b05d2d4e04ad1a39ae035feb21ac5dab8e764765e9043039e1da10d3f468fd7`.
해당 v2의 runtime deterministic 기준 ID `b05eb715-d79c-52ae-a6d9-1737cff8a547`는 **코드로 도출**, 현재 운영 cache와 신규 대조하지 않음. 승인·연결 전 실 ID/digest 재확인 필요.

## 정정 후보와 원본 관계

비공개 자료 루트 `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/rubric-structure-20261031/`:

- `prior-v2.private.json`: 기존 snapshot 그대로.
- `correction-manifest.private.json`, `candidate.diff.txt`: 공식 PDF 대조 후 지정 문항의 criteria reference 하나만 수정.
- `candidate-v3.private.json`: 별도 v3 후보, digest `092c10cd691b0ea7d49df4b7d96fbe3f602657bc97dbe05047ee7c9b6a30f6c0`.
- `structured-rubric.private.json`: 행별 배점/설명·bonus·PDF page/hash·기존 v2 digest·criterion ID·원문. `CANDIDATE_OWNER_REVIEW`.
- `source.private.json`, `bounded-quality-audit.json`: 출처와 대학별 탐지 세부 목록.

배점 위치/줄 결합 외 본문 변경 없음을 공백·배점 제거 문자열 비교로 확인. `6~7` 행의 PDF 문장부호 `상품화.`도 그대로 보존. 임의 내용 보완/점수 환산 없음. 기존 v2/평가 결과/답안은 쓰지 않음. 이 후보를 새로운 평가나 과거 결과에 연결하지 않았다.
공식자료만 담은 축소 회귀 Fixture: `test/fixtures/soongsil-rubric-source.json`.

## 대학별 제한 조사

전수 운영 검사 아님. 기존 보관 Package 6개를 대상으로 모든 role의 휴리스틱 탐지 수행. **건수는 결함 확정 수가 아니며 수학 범위/정상 줄바꿈 등 오탐 가능**. 상세 question ID·reference index·page·role은 비공개 audit에 기록.

| 대학·시험 ID | 보관 버전 | 탐지 후보 | 확인 범위/조치 |
| --- | --- | ---: | --- |
| 숭실 `0d4fcaa4-2be0-52a0-9590-c61f65c5f199` | v2 | 191 | 이번 PDF6쪽 5행 배점 열 혼합 확정, v3 후보. |
| 서울여 `6679b5ff-d797-53c9-8a2a-424375d7210c` | v3 | 387 | 기존 PDF6/14쪽 준거 삽입 대조 기록 재사용, 기존 v4 후보 유지. 이번 자동 정정 없음. |
| 경희 `51e7299e-0ae7-5e6d-9d37-a46718be76bb` | v1 | 170 | 기존 PDF3쪽 논제/배점 자료 대조 기록. 표형 채점기준으로 임의 확장 안 함. 등급/범위 경고 추가 수동검수. |
| 동국 `e75f643f-034b-5dc0-afc2-0a0ddeabc3dc` | v2 | 513 | 기존 PDF17쪽 S~F 평탄화 확인 기록; 6/12쪽 포함 전체 행 대조 미완료. 후보 자동 생성 안 함. |
| 건국 `87b73ea0-99bb-5fd3-a94d-93371b4f4a68` | v2 | 230 | 보관본 자동검사만. 이번 PDF 대조 미완료, 오류 확정/정정 등록 안 함. |
| 외대 `450b16fa-0471-5c3d-a848-a6bd47f38495` | v1 | 882 | 보관 batch 파일 검사, digest 미검증으로 명시. 이번 PDF 대조 미완료, 정정 등록 안 함. |

## 표시 변경 및 공통 읽기 모델

APP:
- `approved_result_adapter.dart`: 기준 ID/단계 그대로, `officialCriterion` 원문과 실제 `feedback` 분리. 개선·하락 요약에서 긴 원문 대신 표시명 사용.
- 단일 기준이고 표 헤더가 확인되면 `문항별 채점기준`. 기존 검수 별칭 우선. 여러 기준에는 단일표 fallback을 강제하지 않음.
- `essay_pages.dart:EssayResultView`: 설명 먼저, 없는 경우 미제공 안내. 원문은 기본 접힌 `공식 채점기준 자세히 보기`. 동일 `${원문} — ${설명}` 파생 근거만 제거, 별도 근거 보존. 원문 텍스트는 내용/순서 그대로.
- `official_rubric.dart`: 좁은 화면 배점별 세로 카드와 검증 파서 준비.

WEB:
- `criterion-display.ts:criterionDisplayName`: 기존 별칭 우선, 동일 단일표 fallback. 기준 ID 불변.
- `evaluation-report.tsx`: 결과/비교의 공식 기준 disclosure 명칭 통일. 기존 설명·근거 정확일치 중복 방지 유지.
- `official-rubric.ts`/`official-rubric.tsx`: 같은 검증 조건과 score/grade/description 2열 표 준비.

`official-rubric-read-v1` optional read model: `status`, `criterion_id`, `original_text`, `source{package_digest,package_version,page,pdf_hash}`, `rows[{score,grade,description}]`, `bonus`.
`VERIFIED` 및 **기준 ID/평가 당시 digest/원문 정확일치**와 출처 필수 필드가 갖춰져야 읽는다. 후보/불일치/불완전 행은 거부한다. 인증/소유권은 기존 결과 조회 계약 그대로다. 상태 문자열만으로 서버의 검수 권한을 증명하는 것은 아니므로 후속 producer는 승인된 자료만 제공해야 한다.

**이번 구현에서 운영 API에 새 필드가 공급되거나 기존 결과에 구조화 표가 자동 부착되지 않는다.** 현재 결과는 원문 disclosure를 유지하며, 정정 표는 검수 후보/격리 Fixture에서만 표시한다. Owner 승인 후 producer·검수자·correction ID/시점과 과거 v2의 관계를 확정해야 한다. 기존 API 호환, DB/RPC/엔진 변경 없음. 신규 Migration 필요 여부는 producer 선택 후 별도 설계.

## 자동 품질 검사

`tool/essay_lab/evidence_text_quality.py`: 문장 중간 배점·역전 점수 범위·등급 삽입 추가. 기존 준거 삽입/단어 분리/줄바꿈/중복 제목/표 평탄화/소문항 순서/필수자료 누락 검사 유지. 모든 결과 `MANUAL_PDF_REVIEW`, 자동 정정 안 함. Python 회귀 9 PASS.

## 검증 및 검수 환경

최종 수치는 아래 마감 기록 참조. 신규 테스트: 배점5행·가점·원문 보존, SWU/KHU/Dongguk 대표 손상 문자열 보존, 설명/원문 분리, 정확일치 중복 제거와 별도 근거 보존, candidate/version 불일치 거부, APP 320/360/390/430 폭. 기존 Credit·History·재첨삭 회귀는 전체 suite로 실행; 실제 Provider/계정 제출은 실행하지 않음.

WEB 로컬 검수 URL: **http://127.0.0.1:8897/**. static fixture server, 외부 Preview URL 없음. 숭실 후보 승인대기 표시 + 합성 결과/비교 화면. 실제 학생 계정/운영 조회가 아니다.
재생성 (WEB 저장소에서):

```sh
REFINEMENT_PREVIEW=/tmp/legendstudy-rubric-web-qa/index.html RUBRIC_PREVIEW_SOURCE=/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/test/fixtures/soongsil-rubric-source.json pnpm test src/components/my/refinement-preview.test.tsx
python3 -m http.server 8897 --bind 127.0.0.1 --directory /tmp/legendstudy-rubric-web-qa
```

CUA 실제 브라우저 320/375/390/768/1024px에서 document/body scrollWidth == viewport, 390px 표 시각 확인, 공식 기준 disclosure 펼침 확인. viewport 원복. 표내용은 PDF 확인본, 결과예시는 합성. APP widget 검증과 실기기 검증을 구분(실기기 NOT TESTED).
실계정 경로는 기존 WEB `/my/essays` → `/my/essays/result`. `pnpm dev --hostname 127.0.0.1 --port 3000`로 기존 환경에서 구동 가능하나 이번 작업에서 실제 로그인/사용자 결과 조회는 검증하지 않음. 로컬 후보 화면을 실제 계정 결과로 보고하지 않는다.

## 승인 대기·롤백

- 숭실 v3 후보 공식 문장·5배점·가점 Owner 검수 및 적용 여부 승인.
- 과거 v2 결과와 정정 표시 자료의 관계/출처 고지 및 검수 producer 연결 승인. 원래 평가가 정정본으로 실행됐다고 표시하지 않기.
- 다른 대학 미검수 PDF/현재 운영 API/cache 바인딩 추가 확인. 이번 자료만으로 6대학 전체 무결성을 인증하지 않음.
- 운영 DB/Worker/Auth/Credit/History/Package 교체, Provider 호출, 재실행, 설치, 스토어 제출 **0**.
- 롤백은 이번 표시/검증 커밋을 정상 revert 후 기존 절차로 별도 배포. 운영은 이번에 미변경이므로 운영 rollback 불필요. 후보 파일은 미적용 상태 유지. 기존30번 빌드 그대로 사용 가능.

## 검증 마감

- APP 구현 commit `2419808`; WEB 구현 commit `e809969` (각 위 기준 브랜치). Wiki 마감은 별도 문서 commit.
- Flutter 3.47.6 Analyze **0 issues**, 전체 **1267 PASS / 0 FAIL / 7 SKIP**. 숭실/대표 문자열·표/별도 근거 widget 테스트 포함. SKIP은 실환경 의존 기존 항목이며 PASS에 포함하지 않음.
- WEB Node22.23.2 전체 **1395 PASS / 0 FAIL / 4 SKIP**, TypeScript PASS, Production Build PASS. Lint **0 errors / 기존 4 warnings** (`exam-session-submit.tsx` hooks2, `essay-session-retry.test.tsx` unused2). 초기 Node24 경고를 피하고 명시적 Node22 바이너리로 마지막 검증 수행.
- 기존 disclosure 문구를 검사하던 WEB 테스트 1건은 승인된 새 문구로 수정 후 전체 재통과. 신규 APP UI 테스트는 원문과 제목이 같던 합성 Fixture를 실제 숭실 공식자료 Fixture로 교체하여 접힘/펼침 검증. 검증 완화·테스트 삭제·신규 SKIP 없음.
- Python 품질/정정 후보 테스트 **9 PASS**. Wiki handoff PASS, current-status 11,809 bytes (<12KB), 내부 링크 검사 통과.
- 로그: `/tmp/rubric-app-analyze-final.log`, `/tmp/rubric-app-final.log`, `/tmp/rubric-web-{final,typecheck-final,lint-final,build-final}.log`, `/tmp/rubric-wiki-check.log`.
- 로컬 표/펼침/5너비 검증 PASS. 새 iOS 빌드/실기기/실계정 API·로그인/운영 배포·GA4 수신 NOT TESTED. 원본 표 정정 후보는 미적용이므로 운영 표 구조 복원 완료로 보고하지 않음.


## 숭실 v3 최종 검증 — 2026-10-31

**결론: PDF 내용 PASS / 기존 후보 그대로 운영 적용 BLOCKED.** 아래 실제 운영 조회가 앞선 보관본 기반 기록보다 우선한다. 이번 검증은 운영 SELECT만 사용했고 Package/Worker/Credit/History 변경과 Provider 호출은 없다.

### 공식 PDF·내용 검증

2026학년도 숭실대학교 수시 논술 인문계열 문제 1(1-1). PDF 첫 페이지의 문항 식별과 운영 `essay_exams` 식별 일치. 시험 `0d4fcaa4-2be0-52a0-9590-c61f65c5f199`, 문항 `5df22bef-ce93-5333-9334-023ba98468e4`.
PDF 물리 6쪽 / 인쇄 21쪽, SHA256 `dd97f6d0b480955f80fd2568c3b59bd8e04f2e918895ce7061e1cb2e143441ff`.
원본은 위 비공개 산출물 폴더의 `source.private.json`에 정확한 절대 경로 보관. 페이지 렌더 시각 확인 + 독립적인 좌표별 좌측 설명/우측 배점 추출로 대조했다.

| 행 | 배점 | 대조 |
|---|---|---|
| 1 | 8~10 | 설명 전체 문자 순서·행 연결 일치 |
| 2 | 6~7 | 설명 일치; PDF의 `상품화.` 마침표도 보존 |
| 3 | 4~5 | 설명 일치 |
| 4 | 1~3 | 설명 일치 |
| 5 | 0 | 설명 일치 |

가점 `※ 글쓰기 능력이 뛰어난 답안의 경우 1점 가점 부여 가능` 별도 보존. 누락·중복·설명 중간 배점 없음. 공백/줄바꿈만 무시한 셀 문자 비교이며 문장 의미를 추론해 수정하지 않았다. 문제·예시답안·다른 근거는 후보에서 동일하다.
재현 도구: [`tool/verify_soongsil_rubric_candidate.py`](../tool/verify_soongsil_rubric_candidate.py), `--pdf <source.private.json의 path> --artifacts <위 비공개 산출물 폴더>`; pdfplumber 설치된 Python 사용. 네트워크/DB 접근과 파일 수정 없음.

### 실제 Package 상태와 후보 차이

Package에 별도 UUID ID 필드는 없다. 식별자는 exam ID + package_version + digest이며 DB revision과 함께 기록한다.

| 구분 | 버전 / revision | digest |
|---|---|---|
| 후보가 기초로 삼은 보관본 | v2 / 2 | `2b05d2d4e04ad1a39ae035feb21ac5dab8e764765e9043039e1da10d3f468fd7` |
| 로컬 정정 후보 | v3 / DB 미등록 | `092c10cd691b0ea7d49df4b7d96fbe3f602657bc97dbe05047ee7c9b6a30f6c0` |
| **현재 운영본** | **v3 / 3** | **`d5f609e1e11cc11c77b356c0aada574ce4fd24bba618faee3e20ef33d60306a5`** |

운영 `reviews`는 `NEEDS_REVIEW`, scoped runtimeApproval APPROVED 경로를 사용한다. `runtime_policy`도 현재 운영 v3 digest를 선택하며, v2와 v3 모두 DB jsonb digest 재계산 일치. 최신 운영 v3는 q1/q2 **두 문항**, 후보는 **q1만 포함**한다. 기존 공식 이미지·근거 구성·권리 purpose도 보관 v2와 달라 단순 교체는 최신 변경을 되돌릴 위험이 있다. 현재 q1 criteria는 reference index 2이며 보관 v2의 index 4가 아니다. 현재 운영 q1에도 원래 배점 혼합 문자열이 남아 있다.

보관 v2→로컬 후보의 정확한 변경 필드:
- `questions[0].source_page_references[4].evidenceText`
- 같은 reference의 `verification` → CANDIDATE_OWNER_REVIEW
- 최상위 `verification_status`, `package_version`, `package_digest`

그 외 필드는 recursive 비교 동일. 후보 ID는 위 exam/v3/local digest이며 운영 revision 번호를 할당하지 않았다.

**기존 평가 엔진에 바로 투입 불가:** 후보는 의도적으로 CANDIDATE_OWNER_REVIEW라 runtime의 VERIFIED_MANIFEST/VERIFIED 검사를 통과하지 않는다. 또한 후보 digest는 sorted compact JSON 산출물 체크섬으로 운영 `jsonb::text` digest가 아니다. 같은 후보를 SELECT로만 계산한 PostgreSQL digest는 `b2cb46b3b9421f3e816ea73457c1fe2980daed2ed09c6a6be21e3a933135329a`. 승인 상태/버전/기준 Package를 바꾸면 digest도 다시 계산해야 한다. 원래 평가 엔진 검증은 완화하지 않는다.

### 기존 결과·Credit·History 보존

대상 시험으로 제한한 시작/종료 SELECT 비교: **run 4건, checkpoint 40건, 관련 credit_transactions 4건 모두 동일**. run 전체 행, snapshot(학생 답안 포함), result(평가 단계/설명/근거 포함), checkpoint 전체 행, Credit 전체 행의 해시를 비교했다. 새 run 없음. History 원천 run/result/parent도 불변이다. 별도 과거 시점의 무변경을 소급 인증하는 검사는 아니다.

| run | 상태 | 평가 당시 digest |
|---|---|---|
| 03b6e579-dee5-477c-9add-6f932c7ae367 | completed | 보관 v2 |
| 244aed57-d1d2-4095-9c90-18f9fffa07da | completed | 보관 v2 |
| 2d7a4abf-a787-4b15-a716-a939ccfde8bf | completed | **현재 운영 v3** |
| ec9879cb-01b9-4794-a792-20b741d373f4 | failed | 보관 v2 |

비공개 검증 원장: 같은 산출물 폴더의 `production-preservation-final.private.json`(답안 없이 해시), `production-material-final.private.json`(Package/승인/읽기 함수 스냅샷). 기존 결과에 정정본 연결 없음. 공개·계정 UI를 직접 호출한 검증은 아니다.

### APP·WEB Fixture 및 자동 검증

- APP: 설명 우선, 원문 접힘, 별도 배점 5행/가점, candidate/다른 digest 차단, 원문 보존. 전체 **1267 PASS / 7 SKIP / 0 FAIL**, Flutter Analyze **0 issues** (3.47.6).
- WEB: 같은 숭실 source Fixture로 5행/가점 표시; 전체 **1395 PASS / 4 SKIP / 0 FAIL**. TypeScript PASS, Production Build PASS, Lint **0 errors / 기존 4 warnings**.
- Python 품질/후보 회귀 **9 PASS**, 새 PDF 좌표 대조 PASS.
- 실제 로컬 브라우저 320/375/390/768/1024px에서 document/body 폭=viewport; 390px 표·줄바꿈 시각 확인. 실제 학생 결과가 아닌 합성 평가와 공식 표 Fixture.
- 새 iOS 빌드/실기기/실계정 APP·WEB 결과 UI는 NOT TESTED. 운영 producer가 구조화 모델을 제공하지 않으므로 **운영 구조화 표 활성화는 미완료**. candidate를 VERIFIED로 바꾸는 일은 Fixture에서만 하며 운영 활성화로 간주하지 않는다.
- 로그 `/tmp/ssu-final-{analyze,app-tests,web-tests,ts,lint,build,pdf-audit}.log`. 테스트 SKIP을 PASS로 집계하지 않음.

### Owner 승인용 적용 절차 — 실행 SQL 아님

1. **현재 후보의 직접 적용은 금지.** 현재 운영 v3 전체를 기준으로 신규 정정 후보를 별도로 준비한다. 다음 사용 가능한 버전은 재조회하여 결정(현재 기준 v4). q2/공식 이미지/rights/문제/답안/기타 근거 모두 보존하고 q1의 정확한 sourceHash/page/role/before hash로 수정 범위를 고정한다. 인덱스만으로 변경하지 않는다.
2. 신규 후보를 공식 PDF와 다시 대조하고 Owner에게 전체 diff·두 문항 보존·최종 digest·반영 범위 승인을 받는다. 이번 작업에서는 신규 v4를 생성하거나 승인 상태를 바꾸지 않았다.
3. 승인 후 실행 직전 `reviews.revision=3`, digest=`d5f609…`, runtime_policy/RPC 정의·rights·두 문항 집합·진행 중 run 유무를 재확인한다. 불일치 시 중단한다. 현재 review body/runtime policy/역사 revisions를 비공개 백업한다.
4. 기존 운영 등록 계약으로 **새 revision 추가**와 현재 review 포인터/승인/pin을 한 트랜잭션에서 변경하는 한정 SQL을 준비한다. digest는 승인된 최종 body에서 PostgreSQL 방식으로 계산한다. v2/v3 revisions를 UPDATE/DELETE하지 않는다. Worker·평가 규칙·Registry·Credit 변경은 포함하지 않는다.
5. 현재 `essay_material_runtime_package`는 숭실의 역사적 fallback을 **revision2/v2 digest만 명시 허용**한다. 새 버전 적용 시 지금의 v3도 역사본으로 조회 가능하도록 정확한 v2/v3 digest 허용을 보존하는 RPC 변경안이 필요하다. 이는 **별도 운영 RPC 승인 대상**이다. 이 조건 없이 활성화하지 않는다.
6. 적용 후 SELECT로 신/구 Package digest, 두 문항, rights/approval, 신규 pin, v2/v3 과거 읽기 가능 여부와 run/checkpoint/Credit 해시를 검증한다. Provider 호출 없이 검증하고 실제 평가는 별도 승인 없이는 실행하지 않는다.
7. 신규 요청만 새 pin을 사용한다. 기존 요청/재처리는 snapshot의 당시 digest 유지. 과거 결과의 단계·설명·근거를 재작성하지 않는다. 정정 원문 표시가 필요하면 별도 출처/정정 버전임을 명시하는 읽기모델 및 producer 승인 후 연결한다. 새 자료가 예전 평가에 사용된 것처럼 표시하지 않는다.

### 롤백 절차

이번에는 운영 변경이 없어 운영 롤백이 필요하지 않다. 향후 승인 적용 시: 신규 요청 pin을 배포 직전 실제 운영 v3 digest로 되돌리되 기존 v2/v3와 새 버전으로 이미 접수된 요청의 역사본 읽기를 계속 보존한다. 새 revision 삭제 금지. 아직 새 요청이 없을 때만 백업 review/policy/RPC 복원 조건을 사용할 수 있고, 이미 새 digest run이 생겼다면 역사 fallback을 제거하는 무조건 복원은 금지한다. 모든 롤백은 적용 digest/현재 상태 guard 및 Owner 승인 하에 실행한다. run/Credit/History 수동 변경 없음.

승인 필요: 최신 운영 v3 기반 재정정 후보 준비·검수 → 한정 적용 SQL 및 역사 fallback RPC 검토 → 별도 운영 적용 승인. **현재 판정은 자료 내용 검증 완료이며, 현 후보의 배포 승인 권고가 아니다.**
