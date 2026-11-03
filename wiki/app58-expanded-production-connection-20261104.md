# APP58·WEB — 수리·상경·사회 운영 연결 확대

기준일: 2026-11-04 KST. **운영 연결·APP58 설치는 완료했으며 실제 Provider·실기기 전체 E2E 검수는 진행 중이다.** 최신 Owner 지시에 따라 기존16시험으로 범위를 제한하지 않고 기존 Registry 전체를 재조사했다. Store 업로드·심사·게시는 Owner 직접 실행이며 Codex 실행0이다.

연결 근거: [전체 Registry 감사](app58-expanded-registry-audit-20261104.md), [APP58 빌드 인계](app58-store-handoff-20261104.md), [기존 통합 보고](app-math-commerce-integration-report-20261103.md), [Owner 결정](decisions.md).

## 공개 범위와 기존 데이터 재사용

운영 Registry363시험(실제25대학+합성 fixture1)을 조사했다. 승인된 공식 runtime package213건/493문항의 digest·공식 문제·평가기준·전송권리·문항 연결을 읽기 검증했다. 데이터 READY211, NEEDS_REVIEW73, BLOCKED79. READY는 연결 근거이며 OCR·첨삭 품질 PASS가 아니다.

이번 연결 범위는 **15대학202시험464문항**: 기존 beta160시험 보존 + 신규42시험. 신규는 건국6·경희2·서강1·인하15·중앙10·한양8이다. 경로는 전체 Essay161시험355문항, 혼합26시험64문항, Math15시험45문항. Math catalog는 canonical71문항과 기존 건국 legacy1문항을 합쳐72다.

공식자료가 충분한 의예9시험은 이번 자연/상경 공개와 분리한다. 부분 승인 고려2025인문·숙명2025인문은 전체시험 확대에서 제외한다. 기존 공개 자료·IDs·review 상태는 보존한다. 대학별 미연결 사유와 전체 시험 ID는 감사 문서와 evidence JSON에 기록했다.

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

최종 운영 WEB은 source `45bd519f724d11f15900f8abe60a03c0904df7b9`, Pages deployment `2a794c31-217b-42d6-81a6-d2ae79d873e7`로 배포했다. [운영 LAB](https://lab.legendstudy.com), [고정 배포](https://2a794c31.legendstudy-lab.pages.dev). 실제 배포와 현재 설정의 공개 scope212·추가 beta scope42·Math leaf72, `MATH_ENABLED=true`, `ESSAY_CONTINUOUS_CYCLES_ENABLED=true`를 확인했다. DB의 beta202시험과 자료 공개212시험은 서로 다른 범위다.

Worker는 active version `d03763e8-dcf7-4644-ac59-b7440cee87d7` 100%, deployment `2ac31b16-7a28-4053-bb97-72c0f04dcb39`에서 공개 scope212 연결을 확인했다. Worker 소스나 Provider Secret은 변경하지 않았다. Pages는 허용된5개 plaintext 설정만 변경하고, Worker는 기존13개 binding을 inherit하며 공개 scope만 수정했다. 다른 binding·Secret·Preview·비환경 설정 보존 검사를 통과했다.

공개 홈페이지200, 익명 availability의 `checked=false`, public-status/admin/Owner-review의 익명401을 확인했다. 이는 설정·익명 경계 스모크이며 인증 사용자 평가 성공을 의미하지 않는다. 실행 근거는 로컬 `/tmp/legendstudy-expanded-final-deployment-receipt.json`, `/tmp/legendstudy-expanded-final-worker-receipt.json`과 WEB Wiki의 운영 연결 보고서다.

APP58 소스·IPA·AAB는5b5e5a8 그대로 보존한다. 서버가 APP58의 고정 catalog50 요청에 승인된72개를 완전 반환하며 응답 배열 계약은 동일하다. 별도 엔진/시험 DB/APP 재빌드는 없다. 기존 서명된 Archive의 Release AOT 앱을 iPhone12ProMax에 직접 설치했고, 설치 목록에서 본앱 `com.legendstudy.app` 1.0.1(58), 별도 LS Math TEST 1.0.1(56)을 확인했다. Store IPA·AAB 해시도 기존 영수증과 동일하다. 자동 실행은 당시 기기 잠금으로 차단됐으나, 이후 Owner가 APP58에서 인하2027자연 답안 작성 화면이 “열림”을 확인했다. **설치·해당 답안 화면 진입만 실기기 PASS**이며 전체 제출/재첨삭/History PASS는 아니다.

수식 렌더러의 후속 표시 보완은 별도 검토·배포 대기 항목이다. 해당 후속 변경을 위45bd519 운영 배포에 포함된 것으로 보고하지 않는다. 평가 엔진이나 Provider 결과 변경으로 확대하지 않는다.

## 실제 검증 — 진행 중

- 새 WEB + 서버 core 적용 후 Owner의 기존 성균관2026언어2교시 재첨삭 History와3문항 결과를 실제 브라우저에서 정상 조회했다. 새 Provider 호출 없이 기존 PASS를 재사용했다.
- Owner는 현재 로그인 계정의 운영 검수를 승인했다. 일일 무료를 우선하고 추가 이용권은 최대3개만 사용한다. 테스트 기록은 실제 History/Ledger에 남기며 삭제하지 않는다.
- 대표 신규군: 서강2026모의경제경영 Essay, 인하2027자연 Math, 중앙2026경영경제 Essay+Math. 기존 공식 문제/평가자료/예시답안을 재사용한다. 공식예시답안 평가는 실제 학생 손글씨 OCR 정확도와 구분한다.
- 실제 WEB 인하2027자연 검수 시작: 대학 공식 인쇄 예시답안을 입력했고 OCR 결과10영역 중9영역이 uncertain, 잘못된 영역 좌표0건이었다. 원본 대조와 수식 표현4곳 수정을 거쳐 전사를 확정했다. 이 결과는 공식 인쇄 자료 검수이며 학생 손글씨 정확도 PASS나 수치화된 OCR 정확도 주장으로 사용하지 않는다.
- 인하 최초 평가는 일일 beta 이용권1개 출처로 요청했다. 서강2026모의경제경영 최초 Essay 평가도 다른 이용권1개 출처로 요청한 상태다. **두 요청 모두 완료 결과·실제 Provider 성공·최종 차감은 아직 확인하지 않았다.** 견적/선택 출처와 실제 차감, 요청 접수와 완료를 구분한다.
- 실제 평가 결과·사용량·이용권 원장·무료 재첨삭·History 재조회·APP↔WEB 교차 조회는 후속 확인 후 기록한다. 추가 이용권 최대3개 승인 범위는 그대로 유지한다.
- APP58 설치·인하2027자연 답안 화면 진입 Owner PASS. 동일 실제 기기의 사진 제출부터 평가·무료 재첨삭·History까지는 미완료다. 이전 A48/TEST56·Simulator PASS를 전용하지 않는다.

## 검증 범위·보안·잔여 항목

로컬 SQL은 실제 운영 함수/ACL과 합성 답안으로 전체 core DDL/rollback,72catalog,1/0 반복,무료1회,8중복요청1차감,14일/베타,힌트·정답공개,혼합부분차단·기존인문 보존을 검증했다. 로컬 PASS를 운영 Provider PASS로 대체하지 않는다.

보안 advisor는 기존 경고를 포함한다. 신규 private 이력3개는 RLS 활성·직접 접근 차단이며 정책 없음 INFO는 의도된 내부 RPC 접근 구조다. 인증 RPC SECURITY DEFINER 경고는 소유권 검사·고정 search_path·익명/legacy raw 차단과 함께 검토하며 경고0이라고 보고하지 않는다.

운영 Auth·OAuth·결제 상품/가격·Store 정책·업데이트 REQUIRED 설정은 변경하지 않는다. 기존 APP41/58 산출물 보존. 출시 전 실제 Provider 품질, 실제 기기 전체 제출, WEB↔APP 결과 조회, OCR 부호·지수·분수 정확도 등 미검증 항목을 PASS 처리하지 않는다.

공식 package42개 전체본문의 로컬 fixture 반출은 자동 승인 검토에서 proprietary payload 대량 반출을 사유로 거절했다. 반출·우회 없이 운영 pin 읽기 검증과 합성 검증을 사용했다. scope/beta 전체 target transaction은 로컬 NOT_RUN이었고, 운영 적용의 transaction guard 및 사후검사는 실제 통과했다.
