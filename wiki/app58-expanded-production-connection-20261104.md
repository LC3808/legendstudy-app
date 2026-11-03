# APP58·WEB — 수리·상경·사회 운영 연결 확대

기준일: 2026-11-04 KST. **운영 연결·APP58 설치 완료. 서강 Essay와 인하 Math 사진 무료 재첨삭은 실제 검증했으며, 혼합형·전체 해설·APP 결과 조회에는 P0가 남아 있다.** 최신 Owner 지시에 따라 기존16시험으로 범위를 제한하지 않고 기존 Registry 전체를 재조사했다. Store 업로드·심사·게시는 Owner 직접 실행이며 Codex 실행0이다.

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

수식 렌더러 후속 표시 보완은 별도 source `691ba728e65f7d9fa446baa8974a29428d37bf08`, Pages `f11d97ab-248d-49fd-aa5e-ddaf0f36c004`로 운영 배포했다. [당시 고정 배포](https://f11d97ab.legendstudy-lab.pages.dev). 원본 전사 수정 없이4제곱근과 선행 문항번호 표시를 보완했으며, API bundle은45bd519와 byte-identical이고 Pages 전체 설정·실제 배포 환경 binding도 동일하다. 로컬 전체1,721PASS/기존4SKIP·집중24PASS 및 실제 renderer asset/HTTP 확인을 통과했다. 이 배포의 Provider 호출·DB변경0이며, 아래 인하 평가 입력 전달/모순 방어 수정은 이 표시 배포와 별도로 배포했다. 근거: `/tmp/legendstudy-inha-root-deployment-receipt.json`.

## 실제 검증 — 진행 중

- 새 WEB + 서버 core 적용 후 Owner의 기존 성균관2026언어2교시 재첨삭 History와3문항 결과를 실제 브라우저에서 정상 조회했다. 새 Provider 호출 없이 기존 PASS를 재사용했다.
- Owner는 현재 로그인 계정의 운영 검수를 승인했다. 일일 무료를 우선하고 추가 이용권은 최대3개만 사용한다. 테스트 기록은 실제 History/Ledger에 남기며 삭제하지 않는다.
- 대표 신규군: 서강2026모의경제경영 Essay, 인하2027자연 Math, 중앙2026경영경제 Essay+Math. 기존 공식 문제/평가자료/예시답안을 재사용한다. 공식예시답안 평가는 실제 학생 손글씨 OCR 정확도와 구분한다.
- 실제 WEB 인하2027자연 검수 시작: 대학 공식 인쇄 예시답안을 입력했고 OCR 결과10영역 중9영역이 uncertain, 잘못된 영역 좌표0건이었다. 원본 대조와 수식 표현4곳 수정을 거쳐 전사를 확정했다. 이 결과는 공식 인쇄 자료 검수이며 학생 손글씨 정확도 PASS나 수치화된 OCR 정확도 주장으로 사용하지 않는다.
- 인하2027자연 Q1: session `a8147d8a-ab21-4345-8a9a-2a077b85313f`, evaluation `4539b56f-63b7-471b-acb7-6bf34cdac25b`가 completed/COMPLETED로 저장됐다. beta 출처 reserve1건·consume1건, billing settled·이용권1개 사용을 확인했다. **기술적 완료·차감 확인과 첨삭 품질은 다르다.** 확정 전사10영역/1,364자가 존재하지만 결과는 `NOT_ATTEMPTED`, 풀이단계0개이며 제출 풀이가 없다는 진단을 반환했다. 이 최초 사례의 첨삭 품질은 FAIL이며, 후속 입력 전달/모순 방어 수정과 재첨삭 결과는 아래에 구분한다. 최초 결과·Ledger를 덮어쓰거나 삭제하지 않는다. 해설 공개 이력0, 토큰 사용량은 현재 DB에 없어 UNKNOWN이며0으로 보고하지 않는다.
- 서강2026모의경제경영: run `c00bdc9d-2fdc-443b-b492-3f7d110fb024` completed, admin_grant 출처 reserve1건·consume1건, billing settled·이용권1개 사용을 확인했다. 실제 WEB 결과의 종합 요약·잘한 점3개·보완할 점2개 표시를 확인했다. 이 확인은 결과 생성·표시와 차감 범위이며 모든 첨삭 품질 PASS를 뜻하지 않는다. 평가+독립 검토 receipt 합계는 입력16,765/출력4,722/전체21,487토큰, 비용 금액은NULL로 미확인이다(0원 아님).
- 안전한 결과/원장 영수증: `/tmp/legendstudy-expanded-actual-e2e-safe-receipt-20261104.json`. 이 기록은 기존 실제 실행을 읽기 검증한 결과이며 검증자가 추가 Provider를 호출하지 않았다. 이 시점의 최초 평가 영수증과 이후 무료 재첨삭·WEB History 검증은 아래에 구분한다. APP↔WEB 동일내용 교차 확인은 아직 후속 검증 대상이다. 추가 이용권 최대3개 승인 범위를 유지한다.
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


## 사진 평가 입력 보완·실제 무료 재첨삭 후속

확정 사진 전사를 Provider의 student_answer에 명시하는 투영과, 비어 있지 않은 확정 답안에 NOT_ATTEMPTED와 근거 있는 평가 부재가 함께 나타나는 허위 미제출 판정을 차단하는 수정이 WEB source `0cc53505ed3aac856a19089af9c6bafe2d31ba08`, Pages `98c8e200-b8e2-41c0-83b3-8c96f42d36fe`로 배포됐다. [고정 배포](https://98c8e200.legendstudy-lab.pages.dev). API bundle은 이 입력 연결을 위해 재컴파일했고 Pages 전체 설정·배포 환경 binding은 그대로다. 전체1,734PASS/기존4SKIP 및 TS/lint/build/Functions/boundaries PASS. 기존 평가 원문·결제 판단·서버 공개 계약을 변경하는 새 엔진은 아니다. 무관하거나 불완전한 답안도 근거 있는 INVALID/NOT_ASSESSABLE 평가는 허용한다.

같이 적용한 History/rewrite 보완은 고정 catalog에 없는 시험을 정확한 Registry ID로 해석한다. 실제 인하2027 WEB History 조회, 같은 시험의 무료 재첨삭 진입, 확정 전사 불러오기 PASS. History의 학교/2027 표기와 최초·재첨삭2개 기록 보존도 실제 확인했으며, 이전 고정 catalog 기준의 잘못된 제목을 수정했다. APP의 별도 title-only 증상을 이 WEB 수정으로 해결했다고 보고하지 않는다. 배포 자체는 Provider·DB변경0, 실제 검수에 따른 기록/차감은 별도다. 배포 영수증: `/tmp/legendstudy-photo-history-deployment-receipt.json`.

### 인하2027자연 Q1 — 공식 인쇄 답안 사진 재첨삭

- attempt `a486306e-5326-4cce-8327-3b8cb81598a3`, session `db53f246-75ba-4099-8b50-550c8e8d7f33`, evaluation `28c7e1db-8255-4474-92d8-81b4a1bdd01c`. 최초 session/evaluation을 parent/predecessor로 연결하며 최초 보류 결과는 그대로 남아 있다.
- 실제 사진 입력 → OCR10영역(uncertain9/잘못된 좌표0) → 학생 전사 확인 → prompt4 재첨삭 → 결과 저장·History 연결 PASS. 확정 전사10영역은 불확실0이다. 이는 공식 인쇄 예시답안의 사진 검사이며 실제 손글씨 정확도 전체 PASS는 아니다.
- 실제 응답은 ATTEMPTED, CORRECT, ANSWER_CORRECT_AND_REASONING_SUFFICIENT, 풀이8단계·오류0. 이 대표 정답 사례를 올바른 풀이로 인정하는 검증을 통과했다. 대안 풀이·다수 오류·전체 시험의 평가 품질까지 일반화하지 않는다.
- billing `26c8ea0f-264f-4c11-b765-1e2c23488123`: included_revision, settled, required0, 추가 Ledger0. 최초 beta 차감과 연결된 무료 재첨삭이며 중복 차감 없음.
- 전체 해설 명시 공개 이력1건은 저장됐으나, 공식 해설 payload0·생성 해설 없음이다. 공개 이력 저장 PASS와 전체 해설 제공 PARTIAL을 구분한다. 없는 해설을 생성해 보충하거나 완전 제공으로 표시하지 않는다.
- bounded Provider 로그 시각 대조상 OCR3,579 + 재첨삭11,160 =14,739토큰. 기존 로그에 request ID가 없어 시각 기반 연결은 추론이며 정확한 ID join으로 표현하지 않는다. 비용은 UNKNOWN,0원 아님.

### 중앙2026경영경제 — 혼합형 중간 결과

회차 `7b3b724a-6c90-4bcd-95c0-9f894d934c44`, billing `6ce59fa8-8ca6-4649-9ad0-370c3b3d2e63`. 공식 예시답안3문항을 제출했다. 최초 처리에서 Q1 Essay·Q3 Math는 completed, Q2 Essay는 INDEPENDENT_REVIEW_NOT_ACCEPTED로 실패했다. 내용 오류를 단순 설명 부족으로 분류한 평가에 대해 독립 검토가 거절했다. 이 시점에는 전체 run reserved, 이용권 reserve1·consume0으로 전체 완료/전체 차감을 처리하지 않았다.

첫5회 Provider receipt 합계 입력114,833/출력11,473/총126,306토큰이며 비용 필드가NULL이므로 미확인이다. root가 기존 UI의 “실패한 문항 다시 처리 · 추가 이용권 없음”으로 Q2만1회 재시도했으나 독립 검토 grounding fail로 다시 실패했다. 성공 Q1/Q3 checkpoint는 보존했고 최종 전체 run/billing은 reserved, Ledger는 최초 reserve1만 존재하며 consume0·추가 reserve0이다. 명시 재시도1회에서 평가+독립 검토2호출 합계46,345토큰(입력41,762/출력4,583), 중앙 누적172,651토큰이며 비용은 미확인이다. 추가 자동 Provider 실행은 없고 동일 예약의 명시 재처리 대기 상태다. 혼합형 전체 E2E는 PARTIAL이며 오늘 추가 재시도는 하지 않는다. 추가 유료 승인3개 중 서강 사용1·중앙 예약1로2개만 사용/예약했고 인하 무료 재첨삭은0개다.

위 실제 결과의 안전한 영수증은 `/tmp/legendstudy-expanded-postfix-e2e-safe-receipt-20261104.json`이다. 새 Provider 호출로 과거 PASS를 반복하지 않았으며 기존 원본·최초 실패·History·Ledger를 삭제하지 않는다.

## 다음 재개 시 P0 순서

1. 중앙 혼합형 Q2의 두 독립 검토 거절 사유를 확인하고 품질 보완 범위를 정한다. 기존 run/billing reserved1·consume0을 보존하며 새 제출로 중복 예약하지 않는다. 재시도는 명시 결정 이후에만 실행한다.
2. APP58의 같은 계정·같은 평가 ID·진입 화면을 확인해 제목만 표시되는 현상을 재현한다. 아직 원인이 확인되지 않아 APP59나 임의 서버 호환 수정은 만들지 않았다.
3. 전체 해설의 공식/생성 payload 미제공을 별도 품질 차단 요소로 해소한다. 공개 이벤트만으로 제공 완료를 판단하지 않는다.
4. 현재 범위의 실제 기기 전체 루프와 APP↔WEB 원본/확정전사/결과/History 교차 검수를 완료한다. 공식 인쇄답안 성공을 실제 손글씨 OCR 전반의 성공으로 대신하지 않는다.
5. Store 업로드·심사·게시는 Owner 직접 실행이며 Codex0이다. APP58의 현재 파일을 그대로 사용하고 운영 업데이트 안내·REQUIRED는 별도 승인과 스토어 공개 확인 전 활성화하지 않는다.


## 최종 WEB 표시 배포·작업 종료

최종 운영 표시 source `9a8fb9fdacb8efe95df1d74a73037ebf753158b9`, Pages `bfb80aef-8d88-4bbe-91c0-03b376fc856f` 배포·확인을 마쳤다. [운영 LAB](https://lab.legendstudy.com), [고정 배포](https://bfb80aef.legendstudy-lab.pages.dev). artifact SHA256 `a980cff580c90617a70161d11d572806e5ce1fa8bf73c41e3a059c1a96c58dca`. API bundle은 입력보완0cc5350과 byte-identical, 전체 Pages 설정·46개 환경 binding 동일, 실제 renderer hash 일치·홈200/보호API401을 확인했다. 이전 통합1,734PASS/기존4SKIP를 재사용했고 최종 renderer 집중25PASS·TS/lint/build/boundaries PASS. 앞선 입력 보완124PASS와 History31PASS는 별도 집중 검사이며25개에 합쳐 보고하지 않는다. 이 표시 배포의 추가 Provider·DB변경0이며 최종 영수증은 `/tmp/legendstudy-superscript-root-deployment-receipt.json`이다.

최종 판정은 **CONDITIONAL_READY: 운영 연결은 완료했으나 전체 품질/실기기 검수 완료는 아니다.** 인하 무료 사진 재첨삭과 서강 Essay의 확인된 범위는 PASS, 중앙 혼합형·전체 해설·APP58 본문 조회는 PARTIAL이다. 이 판정을 스토어 심사 제출 승인이나 모든 대학 평가 품질 보증으로 해석하지 않는다.

APP58 source5b5e5a8·버전58·IPA/AAB는 그대로다. 이번 마감은 Wiki만 수정하고 앱 코드·재빌드·Store 작업0이다. 로컬 앱 검사 프로세스는 모두 종료했고 flutter/dart/xcodebuild/gradle/wrangler 실행이 없음을 프로세스 이름만 읽어 확인했다. 기존 미추적 `.wrangler/`, `tool/__pycache__/`는 임의 삭제하지 않았다. 중앙 reserved1은 처리 중인 로컬 작업이 아니라 실패 결과를 보존한 서버 회차이며, 자동 Provider를 재호출하지 않는다. 다음 날에는 위 P0 재개 순서부터 진행한다.
