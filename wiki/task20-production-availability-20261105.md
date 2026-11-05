# TASK20 — 운영 논술 LAB 공개 상태 복구

기준일 2026-11-05. 최종 판정 **PARTIAL**. Registry 등록과 실제 공개/실행 가능 여부를 구분한다. 운영 DB·공개 설정·평가·History·이용권·결제는 변경하지 않았다. APP58/스토어 변경 없음.

## 기존 근거와 조사 범위

[기존 확대 감사](app58-expanded-registry-audit-20261104.md), [운영 연결](app58-expanded-production-connection-20261104.md), [TASK19](task19-lab-ux-grade-cutoff-20261105.md), [데이터 보존](longitudinal-learning-admissions-data-strategy.md)을 재사용했다.

운영 Supabase stlhijzpjfgwwdgunlsd를 읽기 전용으로 조사. Registry 363시험, 26개 university row(합성 QA 포함). WEB 시험 allowlist 212, 베타 DB scope 202시험, 공개 Math leaf 72. 런타임 패키지 213건/493문항 실제 SELECT 성공. 이 수치는 서로 다른 계약의 집합이며, 212 또는 363시험 전체를 실제 공개 PASS로 해석하면 안 된다. `evaluationReady:false`는 browse 메타데이터이고 실행 판정이 아니다. 질문 is_published=false도 기존 인문 정상 경로의 상태이므로 일괄 변경하지 않는다.

[전체 시험별 공개 설정 대조 CSV](evidence/task20-20261105/public-scope-candidates.csv), [Registry 원본 스냅샷](evidence/task20-20261105/registry-policy-snapshot.json), [패키지 읽기 확인](evidence/task20-20261105/package-read-check.json), [Math 공개 문항](evidence/task20-20261105/math-public-scope.json).

## 14개 문제 원인과 상태

|문제|운영 확인·원인|판정|
|---|---|---|
|한국항공 자연·이학|공학5/10문항, 이학5/10문항 등록. 일괄 natural hold와 실행 패키지 미연결. 사회 공개 경로와 다름|PARTIAL|
|한양 자연 누락|2024 모의 자연1시험/2문항이 현재 Catalog·화면에 존재. 누락 재현 안 됨. 실행 패키지 없음|PARTIAL|
|중앙 자연 누락|2024~2026 모의3시험/12문항 등록, 화면 계열 존재. 기존 상경 혼합 경로와 별도이며 자연 패키지 없음|PARTIAL|
|숭실 자연|5시험/20문항 등록, 실행 패키지 미연결. 클라이언트 계열 일괄 hold 제거 후보 검증|PARTIAL|
|숙명 자연·2021 이후|자연/약학4시험12문항, 인문4시험10문항. 현재 노출 연도 2025모의/2026수시/2027모의. 로컬 2021~2027 자료와 등록 범위 다름|PARTIAL|
|성균관 UI|운영 SourceExamWriter 공통 컴포넌트로 사진·수식·문항 저장 존재. 별도 구형 엔진 아님. 미공개 시험의 API 실패가 주요 원인|PARTIAL|
|서울여대 자연|4시험9문항 등록, 자연 실행 패키지 미연결|PARTIAL|
|동국 자연|7시험21문항 등록, 실행 패키지 미연결|PARTIAL|
|광운 자연 누락|2022모의1시험2문항이 Catalog/계열 선택에 존재. 실행 패키지 없음|PARTIAL|
|경희 자연·의약학|자연5시험10문항(빈 시험2), 의약4시험16문항(빈 시험2). 의약 선택 시 API 조회 실패·설명 부족 재현|PARTIAL|
|건국 자연|2026자연 Q1은 기존 별도 Math leaf 공개. 시험 단위 WEB 차단이 문항 공개 경로를 가림. 나머지3문항은 미공개|PARTIAL|
|고려 자연|5시험20문항 등록, 자연 실행 패키지 미연결|PARTIAL|
|서강 자연|9시험11문항 등록, 자연 실행 패키지 미연결|PARTIAL|
|베타 인문만 안내|WEB 문구 수정·운영 종료 표시 2026-11-11 00:00 KST 확인. 지원 계열/실제 공개 시험 한정·가입3개 별도|PARTIAL|

숙명대 [기존 자료 파일 목록](evidence/task20-20261105/sookmyung-local-material-inventory.txt) 177개 파일을 대조 대상으로 보존. 원본 수정/이동/커밋 없음. PDF 보유는 문항 Registry·평가 근거 검수 완료가 아니므로 새 시험/문항을 추정 생성하지 않았다. 정확한 시험명·문항 단위 추출/기존 ID 대조 후 별도 연결 후보가 필요하다.

## WEB 수정과 검증

운영 기준 배포 51f15f6c-4403-4c19-bab9-6efca3627727 / source1037c1e. 별도 codex/task20-web-availability 브랜치 사용. 다른 관리자/Analytics 후속 변경은 포함하지 않았다.

- 자연계라는 이유로 서버 조회 자체를 생략하던 분기 제거.
- 공개 계약 실패, 정책상 미공개, 로딩, Registry 조회 오류를 구분.
- 기존 standalone Math 공개 문항 재사용. 혼합형 전체 문항 정책은 유지.
- 건국 Q1만 공개임을 명시하며 나머지 문항을 자동 공개하지 않음.
- 베타 계열/종료일/일일 갱신 문구 정정.
- 계열별 입력은 기존 공통 writer 유지. 사진/수식/문항 저장 기능 제거 없음.

집중 회귀 92/92 PASS, TypeScript/변경 파일 ESLint PASS, 운영 NEXT_PUBLIC 설정으로 webpack 163페이지 빌드 PASS, Wrangler4.136.1 함수 빌드 PASS. 전체 회귀는1774PASS/7FAIL/5SKIP+unhandled1: 관리자 analytics 7실패와 unhandled는 변경 전 운영 소스1037c1e에서도 동일 재현. 전체 PASS로 보고하지 않는다.

운영 화면 검증은 로그인된 Owner의 학생용 경로를 사용했다. 별도 일반 사용자 계정 실기능 검증은 NOT_VERIFIED. Provider 호출/새 답안 저장/실제 차감은 하지 않았다. 기존 인문·History·결제 실제 회귀 완료로 주장하지 않는다.

## 보존 검토 7항

1. 변경 대상은 표시 및 공개 조회 계약이다.
2. 기존 학생 답안·평가 사실을 수정하지 않는다.
3. 시험·문항·사용자 식별자를 보존한다.
4. 기존 History/원장 UPDATE나 재계산 없음.
5. 신규 PII 수집 없음.
6. 감사 CSV는 시점별 파생 스냅샷이며 원본 사실을 대체하지 않는다.
7. 운영 신규 자료 연결은 별도 검수·승인·원복 절차 후 적용한다.

## 공개 확대 차단 요소 및 승인 경계

미연결 자연 시험을 일괄 활성화하지 않는다. 필요한 순서는 기존 공식문제/출제의도/채점기준 → 문항 ID와 Evidence Package 대조 → 기존 Math/Essay 계약 연결 → TEST 검증 → 정확한 시험/문항 scope와 migration·rollback 작성 → Owner 운영 승인이다. 현재 자료만으로 검수 완료 상태를 올리는 SQL은 작성/적용하지 않았다.

WEB 배포는 논술 LAB route + 고정 오류 분류 API만 overlay한다. 기존 다른 route hash, 함수 routing, 프로젝트 설정을 검증하여 보존. 원복 대상 최초 배포51f15f6c. Secret 값은 보고서/로그/Git에 기록하지 않는다.

## 배너 제작 인계

[전체 후보 목록](evidence/task20-20261105/public-scope-candidates.csv)은 Registry·allowlist 대조용이며 광고 확정 목록이 아니다. 초기 조회 장애는 운영자 공개 범위 판정으로 해소했다. 해당 장애 해소 후 AVAILABLE로 실제 확인된 시험/문항만 추려 전달한다. 모든 대학 자연계 공개를 암시하는 배너는 만들지 않는다.

## 최종 운영 postflight

최종 배포 **858e369c-2efa-44f6-8d5a-840eae49f0e8**, WEB Git **23a03b0a232d49dd41f6edf841e07fe8537d337f**. 상태 success. 최초 기준 대비 다른 경로1460개 hash 동일, production/preview 설정 객체 동일. API후속 변경57회귀 PASS, 최종 TypeScript/린트 PASS. UI빌드3151f71 이후 변경은 API 및 진단뿐이다.

운영자 allowlist 우회 경로가 미공개 시험의 없는 패키지를 조회해 Worker BACKEND_UNAVAILABLE를 반환하는 원인을 확인했다. 일반 사용자와 마찬가지로 기존 공개 시험 allowlist를 먼저 판정하도록 보완했다. 공개 설정 자체를 확장하거나 인증을 우회하지 않았다. 로그는 고정 오류 코드·연결 유효성 boolean만 기록한다.

- 건국2026자연 Q1: 부분 공개 안내 및 기존 Math 사진 답안 진입 **PASS**. 전체4문항 공개는 **PARTIAL**.
- 경희2027의약학: 오류 대신 미공개 사유·비활성 요청 표시 **PASS**. 자연/의약 평가 활성화는 미실시.
- 한양2027인문: 텍스트 입력·저장 버튼·기존 첨삭 요청 경로 **PASS**(실제 저장/새평가 미실행).
- 한양2027상경: Q1/Q2 모두 요구하는 통합 첨삭 경로 **PASS**(새평가 미실행).
- 인하2027자연: 이전 시험 기록 안내·새 로컬 초안 선택·사진/수식 입력·기존 Math 추출 진입 **PASS**. 새 답안 저장·OCR·평가 미실행.
- 베타 종료 시각 운영 표시 **PASS**. 안내 모달 계열 문구는 코드/검사 PASS, 숨김 처리된 로그인 세션에서 모달 재노출 직접 검증은 NOT_VERIFIED.
- 기존 이용권92/오늘무료1 표시 유지. 실제 원장/History 전수 해시 회귀는 이번에 미수행; 쓰기 호출 없음.

[Claude 배너 인계와 공개 설정 전체 목록](task20-banner-handoff-20261105.md). 스크린샷은 비공개 로컬 /private/tmp/task20-{konkuk,kyunghee,hanyang-humanities,hanyang-mixed,inha}-production.jpg에 저장했다. 운영자 이용권 표시가 있어 Git에 추가하지 않는다.

잔여 P0: 미연결 자연 시험 평가 패키지/공식 근거/Math 계약 연결, 숙명2021이후 파일→Registry 문항 매핑, 일반 로그인 사용자 별도 검증, 전체 공개 설정202시험 개별 admission/화면 확인, 기존 History·인문 실평가·결제 회귀, 베타 모달 재노출 확인. 신규 DB 적용은 이 근거를 갖춘 migration/원복안을 작성한 뒤 Owner 승인 대상으로 둔다. 이번 결과는 전체 대학 자연계 공개 완료가 아니다.
