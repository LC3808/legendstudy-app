# 대학별 첨삭 프로필 PHASE 2 — 2026-10-23

## 상태: PARTIAL

Owner가 PHASE1(81e83d3)을 승인했다. 기존 엔진의 입력 조립을 로컬 구현하고 비공개 프로필 revision을 저장했다. 전체11대학 공식 프로필 검수·운영 엔진 적용 완료는 아니다. 기존 운영건국2문항·Worker·Gateway·Credit·History·UI를 변경하지 않았다.

## 구현

- `tool/essay_lab/university_profile.py`: content hash 검증, 명시 대학/시험/학년도/유형/계열/문항 scope 선택, ambiguous/missing 거부, 과거version pin선택, 동일계층충돌 차단, 문항>연도예외>프로필 criteria 우선순위, unknown≠0, immutable sidecar 생성.
- `material_runtime.load_reviewed_material(..., university_profiles=None)`: 기존 Worker loader에 선택적 연결. 미지정 시 기존 경로 그대로. 현재 배포 Worker는 미지정 상태로 보존한다. 신규입력/버전 trace는 sidecar에 보존하며 기존 History DTO에 필드를 임의추가하지 않는다.
- `bind_material`: 기존 검수된 문항기준은 그대로사용, 프로필/연도fallback으로 내용이 달라진 패키지는 `COMPILED_PACKAGE_REVIEW_REQUIRED`로 runtime 실행 차단한다. 생성 후보의 기존 digest를 신규검수 완료 digest로 간주하지 않는다. 기존 source/binding/rights/admission 검사 재사용.
- `bind_math`: 기존 physical profile ID/content hash·leaf·problem pin 대조, 기존 Math context 그대로반환. 신규숫자점수·대학scope·DBrow 없음. 실제MathWorker까지 새로운profile을배포한것은아님.
- 공통역량·피드백·감점 등의 표준필드는 저장할수있지만 현재 runtime projection은 검수된 criteria와 기존Math profile 중심이다. 모든서술필드가Provider에전달된다고주장하지않는다.

## 비공개 산출물

`~/development/legendstudy-materials/essay-validation-2026-10/university-profiles-20261023/`

- `profiles/<university>/<type>/v1.json`, `v2.json`: 30후보/60revision. v1덮어쓰기없음.
- 최신 3개는 **특정문항 한정 REVIEWED**, 27개 DRAFT. 공통적용학년도 전체를검수한3개라는뜻아님.
- DRAFT는 기존 공식자료 페이지 연결1730개를 대학별 미배정 근거inventory로재사용. 타입별공통기준으로승격하지않았다. 적용scope는비어있어선택불가.
- `compiled/`: 건국인문Q2·수리Q1, 숙명2025모의인문1-1의 입력+profile resolution 3개.
- `prepare.py`, `attach_inventory.py`: 기존 registration/review/accepted metadata 재사용. 재실행에서같은revision내용확인, 원본/PDF재업로드0.
- `report.json`, `legacy-parity.json`, `failures.json`: 건수/실제입력비교/509미연결문항의대학·연도·시험·계열·IDs·원인·근거·권장조치.

원문·평가기준 텍스트·비공개JSON은Git에포함하지않는다. Compiler/test/Wiki만Commit한다.

| 대학 | 후보 | 문항한정 REVIEWED | DRAFT | 조립 문항 |
|---|---:|---:|---:|---:|
| 가천 | 2 | 0 | 2 | 0 |
| 건국 | 3 | 2 | 1 | 2 |
| 경희 | 4 | 0 | 4 | 0 |
| 고려 | 2 | 0 | 2 | 0 |
| 동국 | 3 | 0 | 3 | 0 |
| 서강 | 3 | 0 | 3 | 0 |
| 성균관 | 2 | 0 | 2 | 0 |
| 숙명 | 3 | 1 | 2 | 1 |
| 숭실 | 3 | 0 | 3 | 0 |
| 서울여 | 2 | 0 | 2 | 0 |
| 한국항공 | 3 | 0 | 3 | 0 |
| 합계 | 30 | 3 | 27 | 3 |

## 검증 결과

- profile/material/registry/exam runtime 관련 **41 unittest PASS**, Python compile·diff check PASS. fixture 테스트이지실제운영E2E추가실행아님.
- 실제기존 건국·숙명 private package: 프로필전/후 기존 `frozen_cache` 동일PASS. 실제Math기존context동일PASS. 한양accepted 원본pin/이미지5/근거4재사용검사PASS.
- 동일입력 재실행: 기존revision/compiled bytes 동일. DRAFT/다른연도/다른계열/다른문항/모호scope/내용hash변경 차단PASS.
- 과거profile version선택, 소유권/중복요청의기존exam계약test 재사용. Production Ledger검증/무료재첨삭신규거래는실행하지않음.
- 새로운Provider 입력변경이없는3문항을불필요하게재호출하지않음. **추가Provider0회·비용US$0**. 새profile의실제평가품질PASS를주장하지않음.
- WEB/Native 코드·DTO·UI 무변경. 새프로필의실제WEB/APP/History저장E2E는미실행.

## 미완료와 다음 작업

509문항의공식기준/유형별공통성/학년도scope가미검수다. 원문존재여부와검수완료를혼동하지않는다. 27개DRAFT는표준형식과근거inventory만준비되어, 대학별내용제작완료가아니다. 현재부족한것은승인요청이아니라공식자료정밀검수·그결과의프로필작성이다.

연도/프로필fallback으로새criteria를생성한경우 기존검수package의서버digest·권리·revision·실행정책검증을거쳐야한다. 자동검수/권한승격없음. Math는로컬context대조까지이며기존physical adapter/운영Worker에새프로필적용검증은남아있다.

PHASE3 적용가능범위: 기존활성건국2문항을유지한다. 숙명신규공개0, 나머지새활성0. 이번산출물만으로일반전체공개/22대학확대를진행하지않는다. 경희·동국보강HOLD, Payment/IAP/서명키/71702변경0.


## Owner P0 후속 검수 — 2026-10-23

**PHASE2 PARTIAL 유지. 30은 최종 확정 수가 아니라 재검토 중 후보 수다.** 공통 문장이 같다는 이유로 동국 인문I/II 전체 평가체계를 병합하지 않았다. 가천 혼합 단답형, 경희 의학의 과학 과목별 차이는 추가 분리 검수 필요다. 전체 대학·학년도에 재사용 가능한 완성 프로필은 아직 확정하지 못했다.

최신 후보 상태: 공통 조항/프레임 일부 검수9, 공식 답안 형식만 검수4, 기존 문항 연결만 검수1, DRAFT16. 이14개를 완성 프로필로 세지 않는다. 숙명 인문은2025모의·2026수시·2027모의의 특정7문항에 공통3요소를 확인했고, 실제 입력 조립은2문항만 검수했다. 서강은 결과/과정 등급 구조만 확인한 부분검수다.

### 전수 대조

512문항 전수 목록/기존 연결 명세 대조. 평가 페이지 매핑430, 미확인82(원본 부재라는 뜻 아님). 부분 공통 기준 또는 기존 문항 pin 범위65, 전체 입력 검수·조립4(기존3+숙명2026수시1). 나머지508개는 입력 검수 미완료이며 조립 실패와 구분한다. 범위 밖447문항을 자동 확대하지 않았다.

| 대학 | 전체 | 기존 평가 매핑 | 부분 근거/기존 pin 범위 | 검수 조립 |
|---|---:|---:|---:|---:|
| dongguk | 48 | 30 | 9 | 0 |
| gachon | 166 | 166 | 0 | 0 |
| kau | 30 | 18 | 10 | 0 |
| konkuk | 58 | 58 | 14 | 2 |
| korea | 30 | 30 | 8 | 0 |
| kyunghee | 38 | 31 | 3 | 0 |
| skku | 27 | 21 | 2 | 0 |
| sogang | 28 | 13 | 5 | 0 |
| sookmyung | 22 | 18 | 7 | 2 |
| soongsil | 42 | 40 | 2 | 0 |
| swu | 23 | 5 | 5 | 0 |

범위65에는 형식만 확인한 문항과 기존 건국 수리v2의2026 pin도 포함한다. 전체 점수·감점·학년도 정책 검수 완료 수가 아니다. revision을 무조건 최신으로 바꾸지 않고 기존2026 pin을 보존했다.

### 확인·수정한 오류

- 공통 공식 조항을 기존 scoring evidence로 전달하되 별도 배점/감점 기준을 만들지 않음. 해당 question IDs만 적용, 문항 공식 기준 우선, 내용 변경 시 기존 package 재검수 gate 유지.
- 숙명 실제 평가에서 학생의 타당한 조건부 진술을 잘못된 부정으로 확대하는 오류 발견. 기존 scaffolding-v8 격리 후보로 최소 보완. Production v7 무변경.
- `300±30자`를 기존 분량 parser가 놓쳐 ±만 추가. 원고지 자동계수·임의 감점은 추가하지 않음.
- 경희2026인문 원본 해시 동일하지만 pypdf17페이지/PDFium18페이지. 근거9→10,16→17을 실제 렌더로 확인해 새v4에 수정. v3 원본 보존. 텍스트 추출 페이지를 실제 PDF 페이지로 단정하면 안 됨.
- 현재 부분 프로필의57개 공통 근거 연결은 PDFium 페이지 텍스트와 모두 일치. 이는 모든 문항의 수식/전체 기준 시각 검수 PASS가 아니다.
- 임시 원본 경로를 해시로 복구. 여전히1개 해시/10문항 로컬 원본 위치 미확인. 채점기준 PUA 글리프196문항은 시각 검수 필요(원본 손상으로 판정하지 않음).

### 실제 Provider 품질

기존 엔진과 gpt-5.6-sol, 합성 답안, 격리 저장만 사용. **11호출, 사용량 기반 비용 상한 추정 US$4.117810**(청구서 확정 아님). 실패·수정 전 호출도 포함. 숙명2025모의 약한 답안/재작성 답안,2026수시 그래프 포함 답안의 최종3사례 독립 검수 PASS. 초기 오류와 재검증을 모두 보존한다. 재작성 답안 품질 비교이며 실제 History·무료재첨삭 거래 E2E 신규 PASS가 아니다. 다른10대학/수리 신규 품질 PASS로 확대하지 않음.

2026 그래프의 최초 독립 검수 harness가 base64를 텍스트로 전송해 비용이 증가했다. 그 판정을 시각 검수 근거로 사용하지 않고 기존 `SemanticReview` 이미지 adapter로 검수만1회 재실행해 PASS. 장문 context 할증을 합산한 비용으로 정정했다. 새 평가엔진 개발 없음.

### 산출물·검증·남은 일

비공개 기준 폴더: `~/development/legendstudy-materials/essay-validation-2026-10/university-profiles-20261023/`

- `question-readiness-512.json`, `readiness-summary.json`:512문항별 정확한 ID/역할/원본경로/해시/미완료 사유.
- `failures-detail.md`, `profile-review-details.md`:문항 및 유형별 보완 명세.
- `visual-reference-audit.json`, `review/`:실제 페이지 대조 및 시각 증거.
- `merge-review.json`:병합 보류 근거.
- `provider-review/usage-summary.json`,각 사례의 평가·독립 검수/원본 ledger:호출·비용·실패와 수정 근거. 원문/답안/키는Git제외.

관련43 unittest PASS. 기존 한양/건국 성공 경로·활성2문항·Production DB/Storage/Worker/Gateway/Credit/UI 변경0.

남은 핵심은16DRAFT와 부분검수13후보의 공식 공통체계·예외 확정,508문항 입력 경계/Math physical binding 검수, 대학별 대표 실제 품질 검증이다. PHASE3 신규 대학 일반 활성화 가능하다고 판정하지 않는다. 숙명 검수2문항은 후속 격리 통합 검증 후보이며 운영 등록/공개 완료가 아니다. 경희·동국 추가자료 보강 HOLD 유지.


## Owner 아키텍처 재정의 — 기본체계 우선 / 2026-10-23

이번 Owner 지시가 이전 문항 한정 프로필 제작 순서보다 우선한다. **기본 프로필을 먼저 검수하고 여러 문항이 상속한다.** 508문항을 독립 평가체계 제작 대상으로 취급하지 않는다. 이전의30후보/부분근거65/조립4는 보존된 증거이며 앞으로의 프로필 완성 KPI가 아니다.

학생 서비스는 EvaluationReport/EvaluationComparison/History/Credit와 기존 WEB/Flutter Native UI를 그대로 사용한다. 평가요소 명칭·내용만 대학·유형에 따라 달라진다. LEVEL1 대학 기본체계, LEVEL2 실제 변경이 확인된 학년도·시험 보정, LEVEL3 문항 고유 근거. 우선순위는 문항>공식 예외>대학 기본>공통 계약이다. 프로필을 매년 복제하거나 문항마다 새로 만들지 않는다.

### 구현 수정

기존 `select`가 exam_id/question_ids 필수인 구조를 보완했다. `inheritance_scopes`는 검수된 years/kinds/tracks와 source_refs로 정의하며 대학ID·버전·해시 검증을 유지한다. 기존 `scopes`의 정확 문항 pin도 그대로 지원한다. 무조건 최신버전 선택이나 다른 연도/계열 확장은 없다. 기존 공식 문항 기준 우선과 package 재검수 gate는 유지한다.

`map_profile`은 입력 패키지 생성 없이 프로필 상속을 판정한다. `PROFILE_READY`, `PROFILE_MAPPED`, `QUESTION_EVIDENCE_READY`, `EVALUATION_READY`, `E2E_PASS`를 분리하며, 검사하지 않은 후속 상태는 null이다. 상속 성공으로 Worker admission 또는 서비스 버튼을 활성화하지 않는다.

`common_evidence.applies_to_profile`는 검수된 기본 프로필 범위에서 재사용된다. 공통 지침을 새 가점·감점 항목으로 중복 추가하지 않는다. 답안 구성/표현 진단 범위와 정답 정확성 평가를 분리했다. 현재 기존 Worker 실행에 필요한 문항 근거 gate를 제거하지 않았으므로 진단 가능 범위 표기가 곧 별도 진단 서비스 배포를 뜻하지 않는다.

### 최초 실제 상속 프로필

숙명 인문v5: 기본3요소(논제 충족·논리 구성·명확한 자기 언어)를 공식2025모의 인문1/2 및2026수시·2027모의에서 확인. 기본 채점 방향은 요구 충족과 논리·문장 완성도, 문항별 등급표는 LEVEL3. 감점 임계값/정답/제시문 논점/등급별 구체조건은 공통 프로필에 넣지 않았다. 점수·가중치는 임의로 만들지 않았다.

적용범위는2025모의·2026수시·2027모의 인문이며 **문항ID를 열거하지 않고10개 기존문항 상속 PASS**. PROFILE_READY는 이 범위의 기본 진단체계를 뜻하며 모든 문항의 정확성/배점 평가 준비완료가 아니다. 이전v1~v4와 성공 입력/운영 정책 보존.

512문항에 새 상태 분류를 실행해 검증된 기본 프로필 상속10개를 구분했다. 나머지502개는 개별 프로필 제작 대기가 아니라 해당 대학·유형의 기본체계 검수 대기다. 기존4조립·65부분근거를 취소하거나 같은 자료를 재등록하지 않았다.

### 대학별 다음 기본체계 검수 단위

| 대학 | 기본체계 단위 및 다음 확인 |
|---|---|
| 가천 | 언어 단답/수리 약술. 같은 시험 안 혼합 유형 분류와 정답 허용 원칙을 기본화 |
| 건국 | 인문/수리/상경통합 차이. 기존 성공 문항 정책 보존, 공통 등급 구조와 문항별 점수 구분 |
| 경희 | 인문/사회/수리/의학 후보. 의학의 과학 과목 차이부터 확인; 일부 문장 동일만으로 병합하지 않음 |
| 고려 | 인문/수리의 논리·근거 평가와 공식 부분점수 구조. 면접/학생부 기준 혼용 금지 |
| 동국 | 인문I/II 공통 기본체계 병합 여부를 전체 등급 체계로 판단, 실제 차이는 시험 보정. 수리 별도 |
| 서강 | 인문/상경 결과·과정 평가 공통체계 우선, 내용 고유 논점 분리. 수리 별도 |
| 성균 | 언어 분류·자료해석·논증 체계, 수리 풀이 체계. PDF 공개 HOLD와 프로필 검수 별도 |
| 숙명 | 인문 기본v5 READY/10상속. 자연/약학의 실제 채점체계 동일성 확인 후 분리·병합 |
| 숭실 | 인문 이해·구성 등급체계, 상경/수리 차이. 문항별 점수 단위를 기본 프로필 점수로 일반화하지 않음 |
| 서울여 | 인문/자연 기본체계. 자수 제한 없음은 형식 근거이며 평가체계 완성으로 세지 않음 |
| 항공 | 공학/이학/사회. 공학·이학의 공통 풀이 평가와 문항별 부분점수 예외 비교 |

최종 프로필 수 미확정. 현재 기본 진단체계 READY1, 나머지 후보는 전환 검수 중이다. 30개 목표 고정 없음. 학년도 동일성은 공식자료로 확인하고 변경이 있을 때만 보정한다.

### 검증과 보존

47관련 unit tests PASS: 같은 프로필이 새 문항에도 상속, 다른 대학/연도/유형 차단, 미검수 근거 차단, 상속과 평가 가능 상태 분리, 기존 문항 기준·실행 gate 보존. 실제 숙명 기본 범위10/512 자동 분류 및58공통 근거 페이지 텍스트 대조PASS. 전체11대학 프로필 완성/운영 E2E PASS는 아니다. 이전Provider 품질3사례와기존건국운영성공을재사용,이번추가Provider0·Credit거래0.

원본: 비공개 `university-profiles-20261023/profiles/sookmyung/humanities/v5.json`, `inheritance-mapping-sookmyung.json`, `base-inheritance-status-512.json`. 이전 실패명세의 문항 고유 자료 문제는 예외 큐로 보존하며 모든 프로필 제작을 막는 전제조건으로 사용하지 않는다.

장기데이터 보존 검토: 새 개인정보 수집 없음; 기존 사용자 목적/동의 범위 불변; 원본·기존 profile revision 불변; 새 version은 추가만; 학생 답안/History/Ledger UPDATE 없음; 식별자·참조 불변; 결과 재현용 버전·해시 sidecar 유지, 운영 DTO/저장구조 변경 없음.

PHASE2 진행 중. 다음은 위 대학·유형별 기본체계 검수 → 상속 일괄 적용 → 예외/근거 상태 확인 → 기존 입력 조립 → 유형 대표 품질 검증 순서다. Production/Worker/UI/APP/신규테이블/Migration 변경0. PHASE3 전체활성화 없음.
