# TASK16 최종 품질 — 후속 구현 및 검증

2026-11-04. **PARTIAL / 인하 공식 해설만 운영 적용 / APP58 보존**.

[운영 연결·실제 검수](app58-expanded-production-connection-20261104.md), [학습용 5단계 Owner 정책](learning-completeness-policy-20261104.md), [APP58 산출물](app58-store-handoff-20261104.md)을 계승한다. 현재 운영 표시 소스9a8fb9f와 후속 로컬 구현을 구분한다. 기존 15대학202시험464문항을 재구축하지 않는다.

## 구현·검증 범위

| 항목 | 상태 | 근거 및 한계 |
|---|---|---|
| APP 결과 본문 | PARTIAL | Owner IMG1352–55의 재첨삭 본문·History 표시 확인. 원래 최초 결과 공백 원인은 별도이며 새 설치 검증으로 대체하지 않음 |
| 문장·소문항·수식 | PASS(로컬) | 13ef69a 경계 처리 재사용. indexed root `√[4]{u}`/`⁴√3` 표시 보완; `x⁴√3`의 지수를 루트 차수로 오인하지 않음. 실패 수식은 경고와 원문 유지 |
| 학습 완성도 | PARTIAL | 서버 검증 계약·APP/WEB 선택적 표시 구현. 실제 Provider 산출·독립 검토·영속 저장·coaching/History 연결은 아직 미구현, 운영 별점 없음 |
| 학습 변화 비교 | PARTIAL | 동일 문항/기준/정책 및 소유 lineage의 이전 평가만 비교하는 순수 계약 검사. 실제 새 평가·무료 재첨삭 UI E2E 없음 |
| 중앙대 Q2 | PARTIAL | 운영 재확인: 실제 문제2(q0)는 기존 검토 PASS. 실패했던 내부 q1은 실제 문제1이며 a2 검토 PASS·전체 completed/settled. 이번 추가 호출0. 아래 번호 정정과 한계 참조 |
| 인하 공식 해설 | PARTIAL | 공식 PDF 해시와 문항카드3쪽 예시답안 확인; 권한 변경 없는 공개 래퍼 연결·원복25+131 PASS. 승인 후 운영 RPC 공개 전/후 PASS, APP/WEB 화면은 별도 검수 |
| 인문논술 보존 | PASS(집중 회귀) | 기존 History·계정별 조회·무료 연결 회귀 포함. 새 실제 인문 Provider 호출 없음 |
| 실제 E2E | NOT_VERIFIED(이번 변경) | 과거 인하 사진 무료 재첨삭 PASS 재사용. 새 기능을 포함한 기기·WEB 전체루프는 아직 없음 |

## 기존 결과와 실제 운영 읽기 확인

운영 Inha 무료 재첨삭 `28c7e1db-8255-4474-92d8-81b4a1bdd01c`는 COMPLETED, `ANSWER_CORRECT_AND_REASONING_SUFFICIENT`, 풀이8/오류0, generated_solution 없음, considered references0이다. 따라서 참고 해설 UI 수정만으로 공식 해설을 제공할 수 없다. 기존 최초 실패/재첨삭/History/이용권은 변경하지 않았다. iPhone12ProMax available(paired)를 확인했으나 이번 코드의 설치·화면 PASS는 아니다.

## 학습 완성도 계약

WEB `src/lib/learning-completeness/contract.ts`의 후속 확장이다. 기존 엔진과 독립 검토 경계를 유지한다. 공식 기준 전체와 실제 관측 ID, 평가/문항/기준/시각을 고정하고, 신규·완료·전사 확인·전체 문항 완료 조건이 모두 맞아야 한다. 기존 평가의 검토 통과만으로 새 별점을 승인하지 않으며, 학습 판단 자체의 정확히 일치하는 독립 검토 결과가 필요하다. 공개 전 문구는 별도 검토된 안전한 note 참조만 사용한다. 이 함수 자체가 Provider의 수학적 정확성을 보장하지 않는다.

APP/WEB은 유효한 선택적 계약만 표시하고 임의 평균·오류 수 변환·CORRECT→5를 하지 않는다. 판단 보류는0점이 아니다. 기존 결과에 필드가 없으면 표시하지 않는다. UI/계약 foundation을 실제 서버 산출 완료로 보고하지 않는다. 공식 점수/합격 가능성은 생성하지 않는다.

## 인하 공식 해설 후보

후보: `supabase/candidates/task16_final_quality_20261104/README.md`.
원본은 Owner materials의 2027 인하 모의 자연계(일반) 해설·답안 PDF이며 SHA256 `05a33c9d47d91710ea1215b535b20036f054762d2b382c967e5b932103872522`가 기존 DB artifact와 정확히 일치한다. 문항카드1–2쪽 신원·평가기준,3쪽 예시답안을 원본 이미지로 확인했다. 수식·소문항별 표시 전사이며 새 AI 풀이가 아니다. 원본 이미지/PDF는 Git에 추가하지 않았다.

공식 canonical solution1건 연결과 기존 공개 래퍼의 `disclosed=true` 응답만 보완하는 후보다. 이전 평가의 authority/considered refs는 바꾸지 않고 `SUPPLEMENTAL_AFTER_ASSESSMENT`로 표시한다. APP/WEB에 “추가 연결 공식 자료 · 평가 당시 참고자료와 구분” 및 출처 쪽수를 표시한다. 별도 정답 우회 API는 만들지 않는다. 원복은 정확한 함수 원상복구+새 solution RETIRED이며 기존 ID/공개 이력은 삭제하지 않는다.

Owner가 해당 연결만 승인하여 운영 migration20261104011942를 적용했다. 상세 postflight는 아래에 기록한다.

## 테스트

- 임시 Unix-only PostgreSQL17: 공식 해설25검사 + 기존 runtime131회귀 PASS. 공개 전 응답, 다른 소유자·익명 거절, 최대5과제, 공개 멱등성, evaluation/pin/credit 불변, 정확한 원복·solution ID 보존 포함.
- APP 전체1,489 PASS / 기존7 SKIP, 집중30검사 PASS; Flutter Analyze0.
- WEB 계약/표시/공개 제어28검사 PASS; TypeScript 검사 PASS.
- 중앙 Q2 retry/session 집중9검사 PASS. 고정 Wrangler4.150.0/workers-py1.17.7 dry-run PASS(70 modules/530.64KiB); 운영 Worker 실제 version d03763e8와14개 binding 이름/유형을 읽기 확인. 배포/재호출 없음. 빌드 방식은 [Cloudflare Python 패키징 문서](https://developers.cloudflare.com/workers/languages/python/packages/)를 확인했다.
- 실제 Provider 호출0, 운영 DB 쓰기0, 원장/History 수정0, Store 작업0. 자동 검사는 실제 기기 또는 Provider 품질 PASS가 아니다.

## 후속 P0 및 빌드

1. 인하 운영 RPC 연결·postflight 완료. 후속 APP/WEB 실제 화면 검수는 남음.
2. 중앙 문항 번호 혼동을 정정했다. 저장된 독립 검토 통과 결과를 재사용하고 혼합형 APP/무료 재첨삭 및 해설 UI 검증을 이어간다. 이미 완료된 회차를 재호출하지 않는다.
3. 학습 완성도 신규 Provider 산출·판단 자체 검토·저장·RPC/History 계약 및 실제 사례 검증. 기존 결과 backfill 금지.
4. 최초/재첨삭/History 본문·전체 해설의 실제 iPhone/WEB 교차 검수.
5. APP58과 별개 후속 빌드가 필요하다. 최종 통합/빌드번호 확정 전 스토어 제출 후보로 취급하지 않는다. 기본 store config가 이 checkout에 없어 검증된 기존 설정 경로를 연결해야 한다. 누락 설정으로 빌드하지 않는다.

완료 판정은 PARTIAL이다. 운영 연결 완료, 로컬 코드 완료, 서비스 품질 검증을 구분한다.

## Owner 승인 후 공식 해설 운영 적용

승인 범위는 인하 Q1 공식 해설1건뿐이다. 자동 승인 검토가 내부 함수 교체를 위한 임시 public CREATE 권한 부여를 거절하여 해당안은 미적용했다. 권한을 전혀 변경하지 않는 공개 래퍼 보완으로 수정하고25+131 로컬 검사를 재통과한 뒤 적용했다. 내부 함수·공개 ACL·소유자·인증 구조는 그대로다.

Hosted migration `20261104011942`. 공개 wrapper MD5 `e05c492620a5e7120050fcd1e995691c`→`8d758a455bd76391f4c0537ad3a3c7f4`; 내부 hash `4bab7b41ef9e1f68b275d62ca4edd496` 불변. 원본 최초 결과의 authenticated read는 full_solution 없음, 기존 공개 요청된 무료 재첨삭 read는 공식 reference1건/본문894자/추가 연결 표시를 반환한다. 검증은 DB의 실제 RPC를 기존 Owner identity·authenticated 역할로 읽고 rollback한 것이며, 브라우저/iPhone 화면 E2E는 아니다.

평가·답안·참조·공개이력·Credit transactions 전체 hash가 변경 전후 동일하다. 새 Provider 호출·공개 이벤트·이용권 사용0. 운영 solution1건 및 wrapper1개만 변경했으며 APP58/WEB/Worker 재배포0. `supabase/candidates/task16_final_quality_20261104/production-receipt.json`에 안전한 영수증을 저장했다. 초기 보고의 운영 쓰기0은 승인 전 단계 기록이며 이번 한정 적용으로 대체한다.

보안 advisor는 조회했으며 기존 RLS/no-policy·authenticated definer·extension/Auth 관련 안내가 있다. 이번 함수는 익명 실행 거절·기존 소유권검사 유지이며 프로젝트 전체 보안 PASS로 확대 보고하지 않는다. [Supabase definer 점검 설명](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).


## FINAL CLOSEOUT 운영 재확인 — 2026-11-04

새 지시의 미완료 목록을 실제 운영 상태와 대조했다. 이번 세션은 읽기 검증이며 Provider 호출0, DB 변경0, 이용권/History 변경0이다.

### 중앙 문항 번호 정정 및 기존 성공 결과 재사용

기존 보고서의 “Q2 실패”는 내부 배열 인덱스 `q1`을 문제 번호로 해석한 오류였다. 현재 Registry·저장 결과·WEB을 교차 대조하면 다음과 같다. Registry ID와 원래 결과를 수정하지 않았다.

| 실제 문항 | Registry ID | 내부 키 | 현재 검증 |
|---|---|---|---|
| 문제1 Essay | 82ce8195-821c-5a3e-be9e-d6c7cefa4da5 | q1 / q1-retry-2 | a2 독립 검토8항목 true, evaluation44a8f9bd-815c-5e8b-a614-b007e8b9f1c2 |
| 문제2 Essay | 6dd7b23e-7ffc-562e-8bc0-2c19c76391b1 | q0 | a0 독립 검토8항목 true, evaluationff325f59-b5f1-5e93-a4b2-d66a95f0e282 |
| 문제3 Math | fb4072f0-054a-5ae0-bbdc-f21cf71bf865 | q2 | 저장된 Math 결과 및 WEB 종합 진단 표시 |

기존 run7b3b724a-6c90-4bcd-95c0-9f894d934c44는 2026-11-04 06:38:34 KST completed. 같은 billing6ce59fa8-8ca6-4649-9ad0-370c3b3d2e63은 settled/paid_cycle/required1, reserve1·consume1이다. 별도 새 회차를 만들거나 추가 차감하지 않았다. WEB은 문제1·2 본문과 문제3 Math 결과를 모두 표시한다. 문제1의 내용상 오류를 표현 문제로 혼동하지 않고 (나)의 반항 이유만 수정하도록 한 결과가 검토 통과했다. 실제 문제2는 개념→사례 적용 및 대안의 근거를 인정하고 불필요한 재작성 과제를 만들지 않았다.

현재 receipt8건의 평가/검토 토큰181,368 + 별도 Math usage37,315 = 누적218,683토큰이다. q1-a2 평가25,089·검토20,943토큰은 이미 저장된 기록이며 이번 호출이 아니다. 비용 필드는 NULL이라 금액 미확인이다. 해당 작업의 실행 주체/배포 원인을 추정하지 않는다. 이전 예약 상태 기록은 당시 상태로 보존하고 현재 완료 상태와 구분한다. 실제 무료 재첨삭/APP 통합 결과는 아직 별도 검증 대상이므로 혼합형 전체 PASS로 확대하지 않는다.

### 인하 공식 해설 WEB 실화면

기존 무료 재첨삭 db53f246-75ba-4099-8b50-550c8e8d7f33 → evaluation28c7e1db-8255-4474-92d8-81b4a1bdd01c를 실제 로그인 WEB에서 조회했다. 기존 공개 상태의 ‘공식 예시답안’을 펼쳐 (1-1)/(1-2), 접선, 분수, 4제곱근, 최솟값8/9 표시를 확인했다. 새 공개 요청이나 SQL 재적용은 없다. 현재 운영 UI에는 후속 소스의 ‘추가 연결 공식 자료’ 구분 문구가 아직 없어 배포/화면 검증이 남는다.

WEB의 MathDocument가 인라인 수식 전후의 prose chunk를 block으로 감싸 불필요한 개행을 만들던 원인을 수정했다. 명시적 줄바꿈·빈 문단·display math·표는 보존하고 인라인 수식 주변 문장은 이어 표시한다. 원문 값/DB/평가를 변경하지 않는다. 회귀16 PASS, tsc --noEmit --incremental false PASS. 최초 일반 typecheck는 tsbuildinfo 쓰기 권한 오류였으며 코드 타입 오류가 아니었다. 이 수정은 아직 운영 미배포다.

### 기기·빌드 및 남은 차단

CoreDevice 읽기에서 iPhone12ProMax available(paired)를 확인했다. Mac 미러링은 별도17ProMax를 대상으로 하여 실제12ProMax 화면 증거로 사용하지 않았다. Owner에게 최초 첨삭/재첨삭을 구분한 재조회 확인을 요청했다. 원래 빈 화면은 아직 원인 확정/PASS 아님.

App Store Connect 읽기에서 iOS1.0.1(58) 심사 대기 중을 확인했다. 심사 취소/빌드 교체/업로드/게시를 하지 않았다. 계정의 Apple Developer Program 계약 검토 안내가 표시되어 필요 시 Owner가 직접 처리해야 한다. Android 최신 업로드 번호는 확인 중이며 후속 버전을 임의로 확정하지 않는다. APP58 산출물 보존. 학습5단계 Provider 생성·독립 검토·신규 저장/RPC/비교는 여전히 미연결이며 운영 DB 후보 승인 전에 활성화하지 않는다.

### 최초 첨삭 답안 조회 보완 — Owner 10:58 화면 확인

- Owner 실제 화면: 최초 첨삭은 빈 위젯이 아니라 판정 보류·강점 없음·과제 없음 상태이며, 재첨삭은 답안 근거가 표시된다. 최초 결과를 정상 평가로 소급 변경하지 않는다.
- APP은 기존 `math_coaching.attempt_id`로 본인 소유 `math_input/read_input`을 조회하고, 동결된 동일 제출의 답안을 평가 근거와 별도 표시한다. 조회 실패가 기존 피드백을 숨기지 않는다. 확정 전사의 설명문 보존을 위해 기존 인식 화면처럼 raw_text를 우선한다. 기존 평가·이용권·History 변경 없음, 추가 Provider 호출 없음.
- 관련 Flutter 테스트 22개 PASS. 실기기 반영은 후속 빌드 검수 전이므로 미완료. Owner 확인: 양쪽 스토어 최고 빌드 58, 후속 후보는 59.
- WEB `aef2fe9`: 인라인 수식/문장 경계 개선 및 학습 완성도 독립 검토 오케스트레이션 후보. 관련 42개 검사·타입 검사 PASS. 실제 Worker 연결·신규 저장·운영 적용은 아직 미완료이며 별점 완료로 판정하지 않는다.
