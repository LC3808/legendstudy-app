# APP58·WEB — 수리·상경·사회 운영 연결 확대

기준일: 2026-11-04 KST. **운영 연결·APP58 설치는 완료했으며 실제 Provider·실기기 전체 E2E 검수는 진행 중이다.** 최신 Owner 지시에 따라 기존16시험으로 범위를 제한하지 않고 기존 Registry 전체를 재조사했다. Store 업로드·심사·게시는 Owner 직접 실행이며 Codex 실행0이다.

연결 근거: [전체 Registry 감사](app58-expanded-registry-audit-20261104.md), [APP58 빌드 인계](app58-store-handoff-20261104.md), [기존 통합 보고](app-math-commerce-integration-report-20261103.md), [Owner 결정](decisions.md).

## 공개 범위와 기존 데이터 재사용

운영 Registry363시험(실제25대학+합성 fixture1)을 조사했다. 승인된 공식 runtime package213건/493문항의 digest·공식 문제·평가기준·전송권리·문항 연결을 읽기 검증했다. 데이터 READY211, NEEDS_REVIEW73, BLOCKED79. READY는 연결 근거이며 OCR·첨삭 품질 PASS가 아니다.

이번 연결 범위는 **15대학202시험464문항**: 기존 beta160시험 보존 + 신규42시험. 신규는 건국6·경희2·서강1·인하15·중앙10·한양8이다. 경로는 전체 Essay161시험355문항, 혼합26시험64문항, Math15시험45문항. Math catalog는 canonical71문항과 기존 건국 legacy1문항을 합쳐72다.

공식자료가 충분한 의예9시험은 이번 자연/상경 공개와 분리한다. 부분 승인 고려2025인문·숙명2025인문은 전체시험 확대에서 제외한다. 기존 공개 자료·IDs·review 상태는 보존한다. 대학별 미연결 사유와 전체 시험 ID는 감사 문서와 evidence JSON에 기록했다.

### 대학별 실제 연결 범위

기존 인문 제공은 이번 변경 전 beta160시험을 뜻한다. 신규 Essay1은 서강 경제경영이다. 아래 수는 활성화된 연결 범위이며 각 시험의 실제 첨삭 품질 PASS 수가 아니다.

| 대학 | 기존 인문 제공·시험 | 신규 Essay | 신규 Math | 신규 혼합 | 전체 시험 | 문항 |
|---|---:|---:|---:|---:|---:|---:|
| 건국대학교 | 예 · 8 | 0 | 0 | 6 | 14 | 28 |
| 경희대학교 | 예 · 22 | 0 | 0 | 2 | 24 | 60 |
| 고려대학교 | 예 · 4 | 0 | 0 | 0 | 4 | 8 |
| 광운대학교 | 예 · 16 | 0 | 0 | 0 | 16 | 32 |
| 동국대학교 | 예 · 6 | 0 | 0 | 0 | 6 | 18 |
| 서강대학교 | 예 · 22 | 1 | 0 | 0 | 23 | 29 |
| 서울여자대학교 | 예 · 1 | 0 | 0 | 0 | 1 | 2 |
| 성균관대학교 | 예 · 16 | 0 | 0 | 0 | 16 | 48 |
| 숙명여자대학교 | 예 · 3 | 0 | 0 | 0 | 3 | 6 |
| 숭실대학교 | 예 · 4 | 0 | 0 | 0 | 4 | 8 |
| 인하대학교 | 예 · 10 | 0 | 15 | 0 | 25 | 65 |
| 중앙대학교 | 예 · 11 | 0 | 0 | 10 | 21 | 63 |
| 한국외국어대학교 | 예 · 20 | 0 | 0 | 0 | 20 | 60 |
| 한국항공대학교 | 예 · 4 | 0 | 0 | 0 | 4 | 8 |
| 한양대학교 | 예 · 13 | 0 | 0 | 8 | 21 | 29 |
| **합계** | **160** | **1** | **15** | **26** | **202** | **464** |

이번 전체시험 서비스 범위에 포함하지 않은161시험은 공식자료가 준비된 의예9, 부분 승인2, 승인 package가 없는150(검토 필요71/차단79, 합성 검증용1 포함)로 구분한다. 기존 공개 PDF/metadata를 삭제한 수가 아니다. 가천·가톨릭·경북·부산·서울시립·세종·아주·연세·이화·홍익10개 대학은 이번202시험 연결 범위가 없다. 가천17시험은 검토 필요이고 나머지는 승인 runtime package/review 미확보로 차단되어 있다. 이미 서비스가 있는15대학 안에도 별도 미활성 시험이 남아 있으며, 정확한 시험별 사유는 [전체363시험 evidence](evidence/app58-expanded-registry-20261104.json)와 [감사 보고서](app58-expanded-registry-audit-20261104.md)에 보존했다.

## 운영 SQL 적용과 보존 검사

대상은 LegendStudy 운영 `stlhijzpjfgwwdgunlsd`다. 검토·로컬 PostgreSQL17·독립 리뷰를 거친 다음 증분을 root가 순차 적용했다.

1. 공통 coaching·힌트/전체해설 공개 이력·반복 첨삭 core.
2. 전체 문항 및 승인 package pin을 확인하는 expanded scope와 APP58 catalog50 호환.
3. 기존160 scope 행을 그대로 두고42개를 추가하는 beta 연결.
4. 신규 혼합26시험의 전체 문항 제출을 이용권 예약 전에 강제하는 guard.

적용 후 함수20개 원문·owner·ACL·search_path 일치, raw RPC 권한 누출0, 임시권한 복원, private disclosure3테이블 보호 PASS. 혼합 reserve는 기존 SECURITY INVOKER·postgres-only EXECUTE를 유지한다. 기존 idempotency 재조회·History·인문 선택 문항 제출을 보존한다.

적용 직전/직후 보호14테이블 count·행집합hash를 비교했다. 기존 계정144·grant154·거래243·billing72·결제events36/operations9/orders18·Math bindings11/evaluations11·Essay runs54 등13종은 동일하다. 유일한 변경은 승인된 beta scope160→202. 기존160행 및 캠페인 행 hash도 동일하다. 기존 학생 원문·Ledger·History를 갱신하거나 삭제하지 않았다.

사후검사에서 eligible의 예상 fixture ACL=null과 실제 postgres-only ACL이 달랐다. 실제 운영 정의·owner·권한은 기존 안전한 값 그대로였으며, 잘못된 로컬 기대값만 수정하고20함수 사후검사를 다시 통과했다. 운영 ACL을 완화하지 않았다.

기존 공개 제어를 보존한다. 전체 해설은 명시 요청 전 서버에서 제외하며, 원본 AI 응답을 수정하지 않는다. 하루1회/KST00/이월없음/2026-11-11 00KST 종료 및 유료1+무료1/14일·베타 더 이른 제한은 동일하다.

## WEB 전환 및 APP58

호환 WEB을 먼저 Math HOLD로 배포했다: deployment `d8b0d2de-72aa-4ba0-ac76-a9a8fc2ddb84`, source `172c5e153b541f87689fef1918678974f8ff535a`. 이 단계는 MATH_ENABLED=false만 변경하고 기존 public211/Math99/cyclesfalse 및 모든 Secret·다른 설정을 유지했다. 홈페이지200, 인증 API의 익명401, 기존 관리 route 보존을 확인했다.

활성화 단계 운영 WEB은 source `45bd519f724d11f15900f8abe60a03c0904df7b9`, Pages deployment `2a794c31-217b-42d6-81a6-d2ae79d873e7`로 배포했다. [운영 LAB](https://lab.legendstudy.com), [고정 배포](https://2a794c31.legendstudy-lab.pages.dev). 실제 배포와 현재 설정의 공개 scope212·추가 beta scope42·Math leaf72, `MATH_ENABLED=true`, `ESSAY_CONTINUOUS_CYCLES_ENABLED=true`를 확인했다. DB의 beta202시험과 자료 공개212시험은 서로 다른 범위다.

Worker는 active version `d03763e8-dcf7-4644-ac59-b7440cee87d7` 100%, deployment `2ac31b16-7a28-4053-bb97-72c0f04dcb39`에서 공개 scope212 연결을 확인했다. Worker 소스나 Provider Secret은 변경하지 않았다. Pages는 허용된5개 plaintext 설정만 변경하고, Worker는 기존13개 binding을 inherit하며 공개 scope만 수정했다. 다른 binding·Secret·Preview·비환경 설정 보존 검사를 통과했다.

공개 홈페이지200, 익명 availability의 `checked=false`, public-status/admin/Owner-review의 익명401을 확인했다. 이는 설정·익명 경계 스모크이며 인증 사용자 평가 성공을 의미하지 않는다. 실행 근거는 로컬 `/tmp/legendstudy-expanded-final-deployment-receipt.json`, `/tmp/legendstudy-expanded-final-worker-receipt.json`과 WEB Wiki의 운영 연결 보고서다.

APP58 소스·IPA·AAB는5b5e5a8 그대로 보존한다. 서버가 APP58의 고정 catalog50 요청에 승인된72개를 완전 반환하며 응답 배열 계약은 동일하다. 별도 엔진/시험 DB/APP 재빌드는 없다. 기존 서명된 Archive의 Release AOT 앱을 iPhone12ProMax에 직접 설치했고, 설치 목록에서 본앱 `com.legendstudy.app` 1.0.1(58), 별도 LS Math TEST 1.0.1(56)을 확인했다. Store IPA·AAB 해시도 기존 영수증과 동일하다. 자동 실행은 당시 기기 잠금으로 차단됐으나, 이후 Owner가 APP58에서 인하2027자연 답안 작성 화면이 “열림”을 확인했다. **설치·해당 답안 화면 진입만 실기기 PASS**이며 전체 제출/재첨삭/History PASS는 아니다.

수식 렌더러 후속 표시 보완은 별도 source `691ba728e65f7d9fa446baa8974a29428d37bf08`, Pages `f11d97ab-248d-49fd-aa5e-ddaf0f36c004`로 운영 배포했다. [현재 고정 배포](https://f11d97ab.legendstudy-lab.pages.dev). 원본 전사 수정 없이4제곱근과 선행 문항번호 표시를 보완했으며, API bundle은45bd519와 byte-identical이고 Pages 전체 설정·실제 배포 환경 binding도 동일하다. 로컬 전체1,721PASS/기존4SKIP·집중24PASS 및 실제 renderer asset/HTTP 확인을 통과했다. 이 배포의 Provider 호출·DB변경0이며, 아래 인하 평가 입력 전달/모순 방어 수정은 이 표시 배포와 별도 진행 중이다. 근거: `/tmp/legendstudy-inha-root-deployment-receipt.json`.

## 실제 검증 — 진행 중

- 새 WEB + 서버 core 적용 후 Owner의 기존 성균관2026언어2교시 재첨삭 History와3문항 결과를 실제 브라우저에서 정상 조회했다. 새 Provider 호출 없이 기존 PASS를 재사용했다.
- Owner는 현재 로그인 계정의 운영 검수를 승인했다. 일일 무료를 우선하고 추가 이용권은 최대3개만 사용한다. 테스트 기록은 실제 History/Ledger에 남기며 삭제하지 않는다.
- 대표 신규군: 서강2026모의경제경영 Essay, 인하2027자연 Math, 중앙2026경영경제 Essay+Math. 기존 공식 문제/평가자료/예시답안을 재사용한다. 공식예시답안 평가는 실제 학생 손글씨 OCR 정확도와 구분한다.
- 실제 WEB 인하2027자연 검수 시작: 대학 공식 인쇄 예시답안을 입력했고 OCR 결과10영역 중9영역이 uncertain, 잘못된 영역 좌표0건이었다. 원본 대조와 수식 표현4곳 수정을 거쳐 전사를 확정했다. 이 결과는 공식 인쇄 자료 검수이며 학생 손글씨 정확도 PASS나 수치화된 OCR 정확도 주장으로 사용하지 않는다.
- 인하2027자연 Q1: session `a8147d8a-ab21-4345-8a9a-2a077b85313f`, evaluation `4539b56f-63b7-471b-acb7-6bf34cdac25b`가 completed/COMPLETED로 저장됐다. beta 출처 reserve1건·consume1건, billing settled·이용권1개 사용을 확인했다. **기술적 완료·차감 확인과 첨삭 품질은 다르다.** 확정 전사10영역/1,364자가 존재하지만 결과는 `NOT_ATTEMPTED`, 풀이단계0개이며 제출 풀이가 없다는 진단을 반환했다. 이 사례의 첨삭 품질은 FAIL이며 입력 전달/모순 방어를 보완 중이다. 최초 결과·Ledger를 덮어쓰거나 삭제하지 않는다. 해설 공개 이력0, 토큰 사용량은 현재 DB에 없어 UNKNOWN이며0으로 보고하지 않는다.
- 서강2026모의경제경영: run `c00bdc9d-2fdc-443b-b492-3f7d110fb024` completed, admin_grant 출처 reserve1건·consume1건, billing settled·이용권1개 사용을 확인했다. 실제 WEB 결과의 종합 요약·잘한 점3개·보완할 점2개 표시를 확인했다. 이 확인은 결과 생성·표시와 차감 범위이며 모든 첨삭 품질 PASS를 뜻하지 않는다. 평가+독립 검토 receipt 합계는 입력16,765/출력4,722/전체21,487토큰, 비용 금액은NULL로 미확인이다(0원 아님).
- 안전한 결과/원장 영수증: `/tmp/legendstudy-expanded-actual-e2e-safe-receipt-20261104.json`. 이 기록은 기존 실제 실행을 읽기 검증한 결과이며 검증자가 추가 Provider를 호출하지 않았다. 무료 재첨삭·전체 History 재조회·APP↔WEB 동일내용 교차 확인은 아직 후속 검증 대상이다. 추가 이용권 최대3개 승인 범위를 유지한다.
- APP58 설치·인하2027자연 답안 화면 진입 Owner PASS. 동일 실제 기기의 사진 제출부터 평가·무료 재첨삭·History까지는 미완료다. 이전 A48/TEST56·Simulator PASS를 전용하지 않는다.

## 검증 범위·보안·잔여 항목

로컬 SQL은 실제 운영 함수/ACL과 합성 답안으로 전체 core DDL/rollback,72catalog,1/0 반복,무료1회,8중복요청1차감,14일/베타,힌트·정답공개,혼합부분차단·기존인문 보존을 검증했다. 로컬 PASS를 운영 Provider PASS로 대체하지 않는다.

보안 advisor는 기존 경고를 포함한다. 신규 private 이력3개는 RLS 활성·직접 접근 차단이며 정책 없음 INFO는 의도된 내부 RPC 접근 구조다. 인증 RPC SECURITY DEFINER 경고는 소유권 검사·고정 search_path·익명/legacy raw 차단과 함께 검토하며 경고0이라고 보고하지 않는다.

운영 Auth·OAuth·결제 상품/가격·Store 정책·업데이트 REQUIRED 설정은 변경하지 않는다. 기존 APP41/58 산출물 보존. 출시 전 실제 Provider 품질, 실제 기기 전체 제출, WEB↔APP 결과 조회, OCR 부호·지수·분수 정확도 등 미검증 항목을 PASS 처리하지 않는다.

공식 package42개 전체본문의 로컬 fixture 반출은 자동 승인 검토에서 proprietary payload 대량 반출을 사유로 거절했다. 반출·우회 없이 운영 pin 읽기 검증과 합성 검증을 사용했다. scope/beta 전체 target transaction은 로컬 NOT_RUN이었고, 운영 적용의 transaction guard 및 사후검사는 실제 통과했다.


## APP58 History 실기기 후속 — PARTIAL

Owner는 APP58에서 “기록은 있으나, 내용은 없음”, 이어 “제목만 있고 내용이 비어 있음”을 보고했다. 이 증상은 미해결이며 APP↔WEB 동일 결과 조회 PASS로 처리하지 않는다. 당시 APP 로그인 계정과 브라우저 검수 계정의 동일성, 선택한 History 항목·evaluation ID·실제 진입 화면은 아직 대조하지 못했다. Owner가 휴식에 들어가 추가 질문이나 기기 조작을 진행하지 않았다.

정확한 APP58 소스5b5e5a8과 현재 `lib/` 차이는0이다. 읽기 점검에서 [History 모델](../lib/features/essay/shared_history.dart)은 순수 Math session의 evaluation_id를 [History 화면](../lib/features/essay/shared_history_page.dart)의 MathCoachingPage로 전달한다. [coaching 페이지](../lib/features/essay/math_mobile/math_coaching_page.dart)는 `math_coaching/read`의 math-coaching-v1 응답을 읽고 실패 시 오류 안내를 표시한다. [결과 화면](../lib/features/essay/math_mobile/math_coaching_screen.dart)은 tasks/strengths가 비어도 종합 진단, 근거 없음 안내, 수정·해설 버튼을 렌더링한다. 배포 SQL의 coaching_projection은 NOT_DETERMINABLE 결과에 문자열 판정보류 진단을 반환한다. 따라서 인하 결과의 풀이단계0만으로 제목만 표시된 실기기 현상을 단정할 수 없다. 실제 APP 응답을 인증 우회나 다른 계정 impersonation으로 조회하지 않았으며, 확인되지 않은 원인에 대한 서버/APP 수정도 하지 않았다.

기존 Flutter3.47.6 로컬 회귀3개 PASS: `math_coaching_history_sources_test.dart`의 원본 조회 중 gateway 수명, `math_coaching_history_refresh_test.dart`의 공개 후 History 갱신, `task16f_mobile_test.dart`의 빈 tasks/strengths 및 명시 공개·실패 차단 단일 사례. Mock/Widget 검사이며 실제 기기 재현 성공을 뜻하지 않는다. 다음 검수에서는 동일 계정·History 항목·화면명을 먼저 대조한 뒤 해당 읽기 응답과 UI를 확인한다. 새 평가나 이용권 차감은 이 원인 확인에 필요하지 않다.

최종 읽기 해시 재확인: 기존 release58 IPA SHA256 `88ecaf7e91dd9fe05b79113e5e0119295bb9dbeac2f043a2592a87261a28a01e`, AAB SHA256 `5ac0a0448a9f65c49d90f69cf4c0b393e9cd655ee2514d77e424fc6d1e5c7987`. 기존 영수증과 일치하며 추가 빌드·스토어 작업은 없다.

## 평가 입력 보완의 seven preservation review

[기존 장기 학습자료 보존 정책](longitudinal-learning-admissions-data-strategy.md)의 검토를 인하 입력 연결 보완에 적용한다. 이는 별도 배포 완료 주장이 아니며, 실제 배포·후속 평가 결과는 WEB 보고서와 실행 영수증에서 확인한다.

1. 최초 실패/보류 평가와 발생·기록 시각을 유지하고 후속 검증은 별도 재첨삭으로 남긴다.
2. student_answer는 확정 OCR 또는 typed 원문에서 재현 가능한 투영으로 만들며 원문을 임의 보충하지 않는다.
3. 기존 결과·원본·Ledger의 UPDATE 또는 삭제를 수행하지 않는다.
4. 동일 Auth identity 및 기존 소유권 RPC 계약을 유지한다.
5. Learning 평가 입력의 연결만 보완하며 결제 판단과 분리한다.
6. 기존 허용 Provider·전송 권한·retention 범위를 유지하고 신규 개인정보 수집을 추가하지 않는다.
7. student_answer는 원문을 명시하는 파생 투영이며 새로운 학생 사실로 취급하지 않는다. prompt_version 후보4는 후속 새 평가에만 기록한다. 새 평가 엔진·스키마를 만들지 않고 APP58을 보존한다.
