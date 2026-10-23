# 대학별 프로필 PHASE 3 — 실제 운영 E2E / 2026-10-23

판정: **대표 3문항 E2E PASS, 11개 대학 전체 PARTIAL**. 관리자 검증 계정과 iOS Simulator 범위다. 신규 3문항 일반 사용자 공개·Android/iPhone 신규 코드 E2E는 미검증이다.

## 최신 추가 — 고려 운영1문항 PASS

고려2025수시 인문2 WEB 최초·무료재첨삭→Native 결과/History/4→5비교 PASS. Credit1/0, 새Provider4회/USD0.292664. 기존5문항 보존·현재6문항. 상속 최신423/89이며 아래387/125는 당시 이력이다. [Owner 적용 후 실행 증거·표시잔여](korea-operating-owner-sql-20261023.md).

## 당시 실제 결과

| 대상 | 최초 제출 | 실제 평가·저장 | 무료 재첨삭 | Ledger 최초/재첨삭 | WEB·APP 결과/비교/History |
|---|---|---|---|---|---|
| 숙명2025모의 인문1-1 | APP | PASS | APP PASS | 1/0 | APP→WEB PASS |
| 숙명2026수시 인문1 | WEB | PASS | WEB PASS | 1/0 | WEB→APP PASS |
| 서강2026모의 경제경영1 | WEB | PASS | WEB PASS | 1/0 | WEB→APP PASS |

숙명2025 최초 `c2c83ea6-6ca7-4131-98a8-a9e362b7bd52`, 재첨삭 `fc247e8f-664f-47dc-b50b-4cd051cd5087` (04:46:14 UTC 완료). 표현4→5, 이전 오탈자 resolved, 나머지5요소 유지. 독립 검수8항목 pass. APP·WEB 실제 동일 변화 표시 확인.

숙명2026 최초 `51487646-b493-4796-8d74-c2133e2647d7`, 재첨삭 `7a61b8d8-14c8-4bbe-bec5-af6c847ce3ec`. 서강 최초 `d94e4aa1-7ac9-4a96-94aa-6af9fb36f04c`, 재첨삭 `0cd2aef9-00dd-4f6e-a905-50c78a9dfc05`. 성공한 평가를 반복하지 않고 교차 조회를 확인했다. 서강 비교는 비제도적 성장요인 항목4→5, 3항목 유지.

세 최초 평가만 각각1Credit 사용. 재첨삭·실패3건 추가 차감0, 각 decision 예약 순증0. 관리자 잔액100→97. 결제·IAP 테스트/수정 없음. 기존 건국 인문·수리 성공결과 보존.

## 장애와 최소 수정

- 실패 영수증에 없는 `output_sha256` 접근: symbolic failure 전용 checkpoint key로 수정. 기존 실패 종료·Credit 계약 재사용.
- resolved local_sentence 검증에 필요한 이전 관측 누락: 기존 저장 결과의 동일 issue sentence_feedback/evidence_ids를 scaffolding context로 전달. 검증기 완화·새 평가기준 생성 없음.
- APP 실패 확정 뒤 request key 재사용: 서버 failed와 동일 key를 확인한 경우 pending만 정리. 초안·미확정 요청 보존, 자동 Provider 재시도 없음.
- History 재작성 진입에서 PDF 연결 누락: 기존 승인 PDF를 exam/question 쌍으로 재사용, 시작페이지2 회귀검사.
- `583cbbdd-427a-47c1-afc4-210b9497072d`는 평가 영수증 이후 멈춤. 당시 Worker 로그 저장 OFF, 검수·완료 checkpoint 없음으로 원인 미확정. lease 만료 및 결과/검수/원장 거래 없음 확인 후 기존 finish로 실패 종료했다. 만료 전 복구 시도는 guard가 거부하여 변경 없었다. 동일 평가 코드의 다음 실행은 성공했지만 이 장애를 완전히 해소했다고 단정하지 않는다.
- 독립 검수 진입/오류 class만 기존 private journal에 기록하고 Queue에는 오류 class만 남긴다. 답안·키·exception 본문은 로그에 넣지 않는다. 중복 실행 방지는 그대로 유지.

## 운영 변경·보존

- 기존 private review에 selected question 1개씩만 연결: 숙명2025 revision2, 숙명2026 revision3, 서강 revision2. 시험 전체 NEEDS_REVIEW는 유지하고 문항 한정 runtimeApproval만 APPROVED. 같은 시험 다른 문항 보존.
- 기존 Registry79시험, 정책 `university-profile-reviewed-20261023-v1`, 공식 문항 기준 우선. 숙명2026 도표는 기존 image transport 크기 한도에 맞춰 보존 압축했다.
- 최종 Worker `6b7593a4-5c0c-4b0f-9f37-f812f6a51a3d`; 직전 평가 수정 `6b259208-f537-4bcf-94eb-845a1e08b20c`. 설정·기존 secrets는 keep-vars로 보존.
- 관리자 계정만 기존 검수 scope에 추가. Pages `17244d3b-4be3-4eda-8814-432582c86e9e`, WEB source `ad6ffec28b7ae17d385f3917630cf4da420713a2`. 기존 일반 공개 범위 확대 없음. 신규3문항은 운영 검수 계정에서 PASS이며 일반 공개 PASS가 아니다.
- 기존237시험/700문항 ID 해시 일치. 133 RLS **정책** 유지(테이블 수와 구분). PDF/학생답안/기존 History 삭제 없음,71702 미적용.
- Simulator 앱1.0.0(2026102201), `com.legendstudy.app`, 삭제 없이 업데이트. 로그인·답안 보존. Android/실기기/스토어 빌드는 이번 수정으로 교체하지 않음.

## 검증·Provider 사용량

Worker/material/staging34개 검사, Flutter catalog/widget/history17개 검사, 변경3 Dart파일 analyze, iOS Simulator build PASS. Mock 검사와 위 실제 운영 실행은 구분한다. 신규 진단 코드는 후속 실제 운영에서 검수 진입·완료로 확인.

이번 대표문항 운영 구간의 확인 영수증15개(평가9/독립검수6), input183,690/output30,709 tokens. 이전 테스트 계획 단가(input4/output20 USD per1M)를 그대로 적용한 **기록분 추산** USD1.34894. 최신 단가/캐시 할인/실청구 검증 아님. 미확정583c 실행의 검수 호출 여부·비용은 영수증이 없어 미확정이므로 15회를 전체 청구 호출 수라고 단정하지 않는다. 성공한 기존 건국/한양 평가 재실행 없음.

## 11개 대학 확대 상태

기본체계28/상속387/512 및 원본 평가페이지 연결430은 재사용한다. 상속과 공식 문항 입력·Math leaf 검수는 다르다. 아래 E2E 수는 실제 증거가 있는 문항이며 일반 사용자 공개 수가 아니다.

| 대학 | 등록 | 프로필 상속 | 운영 E2E 확인 | 남은 연결 |
|---|---:|---:|---:|---|
| 가천 |166|166|0|국어/수학 특수 유형 공식 문항표·실행 계약 검수|
| 건국 |58|29|2 기존|나머지 공식 문항 근거·복합형 leaf|
| 경희 |38|29|0|인문/수리/과학 문항 근거·leaf; 추가자료 HOLD|
| 고려 |30|30|0|문항 공식 기준 package pin·대표 E2E|
| 동국 |48|24|0|문항 공식 기준·leaf; 추가자료 HOLD|
| 서강 |28|9|1 신규|나머지 문항 기준·Math leaf|
| 성균 |27|15|0|문항 근거·PDF 권리 HOLD|
| 숙명 |22|22|2 신규|나머지 문항 근거·Math leaf|
| 숭실 |42|40|0|학년도 환산표 예외·문항 근거|
| 서울여 |23|5|0|범위·문항 근거 검수|
| 한국항공 |30|18|0|과정/답 배점·문항 근거·leaf|

미상속125(참조78/범위47)는 기존 명세 유지. 512개 별도 프로필을 만들지 않는다. 검증된 공통 프로필은 상속하고 공식 정답·문항별 배점만 보완한다. 아직 검수되지 않은 문항을 일괄 공개하지 않음.

## 증거·복구·다음 실행

비공개 자료 루트 `essay-validation-2026-10/profile-service-20261023/`: `rewrite-failure-spec.md`, `provider-usage-summary.json`, 운영 전후 invariants, 정책 rollback SQL, 실제 UI 증거. 원본/답안/Secret은 Git 미포함. 미상속 상세는 기존 `university-profiles-20261023/final-completion/scope-failures-125.md` 유지.

회귀 시 기존 Worker 버전·Pages 직전 배포로 복구하고 문항 한정 policy rollback을 적용한다. 결과/History/Ledger를 삭제하거나 과거 평가 pin을 덮어쓰지 않는다. 다음은 신규3문항 일반계정 공개 범위/운영 장애 관측 확인, 나머지 대학의 공식 문항 근거·기존 Math physical binding 준비다. 현재 전체 서비스는 PARTIAL.
