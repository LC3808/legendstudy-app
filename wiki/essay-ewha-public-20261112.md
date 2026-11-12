# 이화여대 63문항 운영 연결·공개 — 2026-11-12

[이화 종료·잔여43](essay-ewha-closure-20261112.md): 이화29시험87(63+24,중복0) DONE/CLOSED. 기존3 ID·실제Math공개 확인. 전체265공개43잔여; Owner AI통합검수 별도. 종료 운영쓰기/Provider0.


[성균15·이화모의24 원본 재검증](essay-skku-ewha-hold-reaudit-20261112.md): 성균은 언어형 개별승인과 자연15 Owner HOLD를 구분. 이화24 문제/예시·해설·평가설명 확보,95쪽 직접판독·원문역할 추출 보완. 자료미확보 일괄표현 정정,평가용criterion 미확정.241공개/67잔여·추가공개/운영쓰기/Provider0.


**운영 연결·사용자 공개 DONE / 실제 AI 품질 NOT TESTED.** 공식 채점기준이 확보된 21시험·63문항을 공개했다. Math 9시험·27문항, Essay 12시험·36문항이다. 운영 DB 적용은 **2026-11-12 19:07:59 KST**, WEB 공개 사후 확인은 **19:11:05 KST**다. 모의 8시험·24문항은 공식 채점기준 미확보로 보류한다. 기존 운영 모의 1시험·3문항 Registry와 기존 데이터는 보존했다.

실제 로그인 후 제출·결과·재첨삭, 브라우저 UI·iPhone·Android, AI 첨삭 품질은 **NOT TESTED**다. 이번 공개 판정은 운영 DB·배포 Worker·공개 API·권한 및 기존 계약 검증에 근거한다. Provider 호출과 운영 테스트 제출은 각각 **0건**이며 실제 품질은 Owner가 통합 검수한다.

[운영 적용 영수증](../supabase/candidates/ewha_public_20261112/production-application-receipt.json) · [DB 사후 검증](../supabase/candidates/ewha_public_20261112/db-postflight.json) · [Worker 운영 검증](../supabase/candidates/ewha_public_20261112/worker-production-verification.json) · [WEB 공개 영수증](../supabase/candidates/ewha_public_20261112/web-production-receipt.json) · [문항별 Owner 통합 목록](essay-ewha-owner-integrated-review-20261112.md).

## 적용 범위와 실제 운영 결과

| 항목 | 결과 |
|---|---|
| 신규 Registry | 21시험 + 63문항 = 84행. 기존 ID 유지, 기존 이화 3문항 전체행 일치 |
| Math | 공식 문제·기준·배점·해설·Worker 자료 403행. 기존 공개 393문항 보존, 27문항 추가로 420문항 |
| Essay | 공식 자료 documents 24 + reviews 12 + revisions 12 = 48행. 운영 package 조회 12시험·36문항 PASS |
| 합계 | 신규 데이터 **535행**, REPEATABLE READ 단일 트랜잭션 COMMITTED |
| 내부 함수 | 기존 Math 허용 목록 2개에 27 leaf 추가, 기존 Essay runtime_policy에 12시험 CASE 추가. 신규 RPC 0 |
| 문제 PDF | 원본 21파일 업로드·재다운로드 SHA 일치, 63문항 DTO 연결. 기존 Storage 객체 745개 보존 |
| Storage | 정확한 문제 PDF SHA 이름 21개·authenticated·account_service_allowed 조건의 신규 읽기 정책 1개. 해설 PDF 신규 공개 0 |
| Worker | 버전 `c56d06b8-6e11-4e19-ac09-e36c1d16dee1`, 배포 `e597663a-a7f4-4a1e-815d-c45727a32d03`. 내려받은 73모듈 중 71개 바이트 불변 |
| WEB | 배포 `f1c64b82-3feb-4b49-8775-ab6d945cd1db`, 소스 `dcda9cf36ba526f8e14d17377a267ed08f788d0a`. 신규 21시험·63문항 운영 공개 확인 |

Migration은 `20261112100444_ewha_63_official_connections_public.sql`, 결합 SQL SHA256은 `6200d40547e369ba29f72e66082a9a4903e57961bc94d236a211f8b065fda783`이다. [검증된 파일별 SQL SHA·범위](../supabase/candidates/ewha_public_20261112/production-sql-plan.json)를 사용했다. 원문 payload는 ignored `.local`에 보관하고 Git에는 메타데이터·검증·SQL 범위와 SHA를 기록한다.

기존 레거시 `is_active`·`is_published` 플래그를 임의로 바꾸지 않았다. 공개는 기존 Math catalog와 whole-exam runtime·WEB scope 계약을 재사용한다. 적용 직후 영수증의 Worker/WEB `pending`은 당시 시점 값이며, 이후 별도 Worker·WEB 운영 영수증의 PASS가 최종 상태다.

## 기존 데이터·권한 보존

기존 사용자 답안·결과·Credit를 포함한 20개 테이블의 기존 행을 전체행 해시로 비교했다. Math 69답안·13평가, Credit 거래 678행, 기존 Registry 450시험·1,232문항을 보존했다. whole-exam runs·checkpoint·retry 및 Math 세션·코칭 등 **private 이력 13개 테이블**도 일치했다.

기존 함수 **359개 본문 불변**, 허용 목록 3개를 포함한 **362개 함수의 identity·owner·ACL 불변**, 기존 **272개 RLS 정책 불변**, **127개 테이블 owner·RLS·ACL 불변**을 확인했다. 기존 Storage 745객체와 기존 문제 목록도 보존했다. [Security Advisor 비교](../supabase/candidates/ewha_public_20261112/security-advisors-comparison.json)는 신규 지적 0건이며 이전 지적을 해결했다고 주장하지 않는다.

WEB은 기존 공개 160시험, 비논술 정적 자산 2,195개, 설정과 Functions route를 보존했다. 공개 범위 설정은 public exams 334→355, beta exams 164→185, Math leaves 393→420이다. Worker의 기존 바인딩 13개와 엔진·prompt·SDK·Provider·Credit 정책을 보존했다. APP 릴리스·스토어 제출은 수행하지 않았다.

## 공식 PDF·평가 기준과 권한

원본 저장소의 58PDF·476쪽은 수정하거나 이동하지 않았다. 기존에 확보한 공식 문제와 해설·평가 기준을 재사용했다. 검토한 수시 문제 21PDF 및 내부 해설 21PDF에서 명시적 제한 문구는 발견되지 않았다. 이는 독립적인 법적 이용 허락 판정을 뜻하지 않는다. Owner의 63문항 연결·공개 승인 범위를 적용했고, 성균관 등 다른 대학의 RIGHTS_HOLD를 해제하지 않았다. [권한 검토 근거](../supabase/candidates/ewha_public_20261112/pdf-rights-review.json).

학생에게는 문제 원본 21PDF만 제공한다. 내부 해설·평가 기준 원본은 공개 목록에서 제외했다. 운영 DB role 조회에서 정상 계정은 21개 접근, 탈퇴 대기 3계정·알 수 없는 계정·UID 없음·anon은 0개 접근을 확인했다. 배포 후 익명 PDF 접근 42건도 차단됐다. 삭제 중 계정 경계는 격리 검증 PASS이며, 실제 삭제 중 운영 계정을 만들어 검증하지 않았다.

## 테스트와 미검증 구분

| 범위 | 실제 결과 |
|---|---|
| 운영 적용 | Registry 사전 26·사후 84, Math 사전 50·사후 116, Essay 사전 9·사후 7 PASS |
| Math 격리 | 운영 함수 본문 8개 exact, 27문항 제출·결과·재작성·재첨삭 297 계약 검사 PASS. 원복 후 기존 카탈로그·이력·결과 보존, 신규 평가 차단 PASS |
| Math 코칭 경계 | 코칭 공개 전 `coaching_required` 확인, synthetic disclosure 후 결과 계약 확인. 실제 유료 reveal NOT TESTED |
| Essay | 36문항·공식 이미지 200개, 72 mock 결과·재작성 cycle, 4종 변조 거부 PASS. 실제 운영 package 조회·배포 Worker source 대조 PASS |
| Storage | 격리 정상·탈퇴 대기·삭제 중·알 수 없는 계정·UID 없음·anon 및 권한 회수 원복 PASS. 운영 정상/탈퇴 대기 role 확인은 위 범위 |
| WEB 전체 테스트 | 1,965 PASS / 10 FAIL / 5 SKIP. 10실패는 기준 `aaeb700`에서도 동일 재현(관리자 6·Credit 4), 신규 실패 0 |
| 빌드·APP 계약 | TypeScript·Next webpack·Pages Functions PASS. APP 계약 3 PASS, 문제 PDF 21원본·63 DTO 연결 검증 |
| 운영 HTTP | `/essay-lab/`, 공개 catalog, `/login/` 200. 인증 필요 PDF manifest·service status는 비로그인 401. 공개 21시험·63문항 대조 PASS |
| NOT TESTED | 실제 인증 토큰으로 PDF manifest/뷰어 열람, 로그인 후 제출·결과·재첨삭, 브라우저 UI, iPhone, Android, AI 첨삭 품질 |

기존 Worker adapter가 공식 출제 의도·채점표 이미지를 거부하던 2조건만 보완했다. Worker 변경 모듈은 `registry_asset.py`와 `essay_lab/material_runtime.py` 두 개이며 기존 첨삭 엔진을 새로 만들거나 결과 품질을 대신 판정하지 않았다. [검증 상세](../supabase/candidates/ewha_public_20261112/pdf-web-app-verification.json).

## 비파괴 원복

적용 실패는 단일 트랜잭션 전체 ROLLBACK으로 처리하도록 준비했고 실제 실패·운영 원복은 없었다. 사후 장애가 있으면 신규 WEB scope를 닫고 직전 Pages 배포 `844798cb-e04b-4f2c-82ec-16fc45cc200a` 복원 가능성을 현재 배포 상태와 대조한다. Worker는 직전 버전 `d03763e8-dcf7-4644-ac59-b7440cee87d7`이 복구 기준이다.

DB는 신규 Math 27 leaf·Essay 12시험 허용 목록과 신규 PDF 정책만 회수한다. [Math 원복](../supabase/candidates/ewha_public_20261112/math-rollback-admission.sql) · [Essay 원복](../supabase/candidates/ewha_public_20261112/essay-rollback.sql) · [Storage 원복](../supabase/candidates/ewha_public_20261112/rollback-storage.sql). Registry·자료·학생 답안·결과·이력·PDF 객체는 삭제하지 않는다. 다른 배포나 허용 목록 변경이 끼어 있으면 옛 전체 함수 본문 복원을 강행하지 않고 최신 상태에서 정확한 신규 scope만 닫도록 다시 검증한다.

## 통합 검수와 잔여 범위

[문항별 Owner 통합 목록](essay-ewha-owner-integrated-review-20261112.md)은 기존 자연 확장 221문항과 별도 이화 87문항, 총 **308문항**을 식별자로 구분한다. 기존 자연 **178 공개·43 잔여**, 이화 **63 공개·24 보류**로 총 **241 공개·67 잔여**다. 공개 대상은 10개 대학·93시험에 속하며 일부 시험은 부분 공개다. 전체 확장은 PARTIAL이고 실제 AI 품질은 모두 Owner 검수 대기다.

자연 잔여 43문항은 공식 HOLD6(한국항공5·숭실1), 성균관 PDF RIGHTS_HOLD15, NOT READY22(경희16·서울여6)를 유지한다. 이화 모의 24문항은 공식 채점기준 확보가 필요하며, 예시답안에서 기준을 생성하거나 Math/Essay로 강제 연결하지 않는다. 기존 한양·중앙·고려·인하와 이전 운영 추가 문항은 이 분모 밖에서 보존한다. 중앙대 과학11 HOLD도 별도로 유지한다.

## Git·보존 원칙

입력 기준 APP `3caadae` / WEB `aaeb700`, 실제 WEB 배포 소스는 위 `dcda9cf...`다. APP 최종 문서·검증 커밋은 본 문서를 포함하는 Git 커밋으로 추적하며 최종 보고에서 별도로 명시한다. 배포 사실은 HEAD나 로컬 파일 존재가 아니라 운영 영수증으로 판정한다.

시험학년도·자료 기록일·정정일을 구분하고 원본 SHA와 기존 이력을 보존한다. 기존 학생 식별자·답안·결과 계보를 유지한다. 학습 사실·평가·진학 결과를 섞지 않으며 공식 원문과 모델 출력을 분리한다. 개인정보 수집·접근 목적·보존 기간·Credit 정책 변경은 없다. [기존 공식 원본 보존 결정](decisions.md#2026-09-30--archive-first-official-essay-evidence)과 [최신 대학별 공개 기준](essay-natural-sequential-order-20261112.md)을 계승한다.
