# 작업03-C — 자동채점 운영 적용·검증

2026-11-11 · 승인 기준 `0a6864b` · **운영 적용 PASS / 실기기 최종 검수 진행**.
Owner가 정답표443·문항11,170·참고등급컷1,029의 적재/공개와 검증을 승인했다.
미검증 과목, Registry/권한 정책 변경, 스토어 제출은 승인 범위에 포함되지 않는다.

[03-B 검수 근거](task03b-ready-candidate-20261111.md) ·
[승인 SQL·원복](../supabase/candidates/task03b_ready_20261111/README.md) ·
[운영 영수증·TEST 기록 식별자](../data/mock_expansion/task03c/production_receipt.json).

## 적용과 공개 범위

LegendStudy `stlhijzpjfgwwdgunlsd`에만 적용했다.
Migration: `20261111041154_task03c_verified_mixed_scoring_engine`.
[실제 적용 SQL](../supabase/migrations/20261111041154_task03c_verified_mixed_scoring_engine.sql)은 승인01_engine과 바이트가 같다.
CLI로 만든 파일명을 실제 운영 migration 버전에 맞춰 보존했으며, 새 migration을 중복 적용하지 않았다.

|항목|적용 전|적용 후|
|---|---:|---:|
|정답표|0|443 published/current/READY|
|문항 항목|0|11,170|
|READY Registry 과목|0 공개|396 공개|
|READY 과목이 있는 시험|0|17|
|참고 등급컷|2,457|3,486 (신규1,029)|
|자동 등급 계산 버전|0|0|
|채점 기록|0|review 검수11건만 별도 저장|

원래417과목 중 PARTIAL12·NOT_READY9는 키 미생성/공개 제외.
353과목은1표,39과목은2표,4과목은3표: `353 + 39×2 + 4×3 = 443`.
홀짝형·선택과목 variant에 따른 차이며 중복 삭제나 임의 병합을 하지 않았다.
11,170은 선택과목 공통문항/홀짝형을 포함한 키별 항목 수이며 고유 원문 문항 수와 다르다.

## 순서·전송·검증

1. 운영 함수/ACL/제약 fingerprint preflight PASS. 기존417Registry ID/부모/과목코드/학년도/월 일치.
2. 기존 함수정의/권한/정책/참고2,457행/Registry를 비공개 `.local/task03c/before-snapshot.json`에 백업.
3. 승인 mixed-v2 엔진 적용. 기존 계정 lock/allowed, fetch-own, 소유자 RLS 유지.
4. draft443키/11,170문항/1,029참고행을 한 트랜잭션에 적재. exact bidirectional 검사 PASS.
5. anon 조회에서 draft 키/문항/available0 확인. 기존 참고행 해시 보존 후 공개.
6. exact 공개 후 검사, 운영 APP Repository 실제 HTTP 조회·비로그인 채점, DB RPC 검증.

원본5MB 요청은 MCP/CLI Management API에서413으로 거절됐고 쓰기0을 확인했다.
[전송 전용 도구](../tool/task03c_compact_transport.py)는 반복 JSON 값만 dictionary/상수로 표현한다.
원래 JSON 전체를 복원해 equality를 assert하고 같은 승인 SQL의 임시 staging에 넣는다.
검증/잠금/트랜잭션/공개 조건은 그대로다. 약1.14MB 전송 SQL로 전체 적재/검증/공개 성공.
전송형도 격리PG에서1,329제출·재실행·충돌·원복 검사를 통과했다. 실제 전송 SHA는 영수증 참조.

## 운영 채점 및 앱 연결

- 실제 운영 RPC, review 계정 DB-role context로443표×만점/오답/미응답=**1,329건** 저장·재조회 검증 PASS.
  한 트랜잭션을 ROLLBACK하여 이 대량 검증 기록은0건 남겼다.
- Owner가 지정한 review 계정에 객관식/단답형/전원정답 대표 각3건=9건을 별도 COMMIT.
  동시 같은ID2요청은1건·같은결과, 새ID 재제출1건으로 **검수 기록11건**을 보존했다.
  `study_session_id=null`: 기존 공부시간/타이머/이용권에 연결하거나 차감하지 않았다.
- 변경 답안 같은ID는23505 ATTEMPT_CONFLICT. 없는 키는23514 KEY_UNAVAILABLE.
- 다른 기존 eligible 계정의 authenticated DB role에서 TEST attempt/answer/본인RPC 접근 불가.
  이는 DB 권한 검증이며 **별도 두 실제 JWT 로그인 E2E와 구분**한다.
- 공개자료에는 복수 허용답 배열>1 사례가 없어, 복수정답은 운영 순수 엔진 함수의 합성 입력으로 확인.
  합성 정답표를 공개하거나 미검증 데이터를 적재하지 않았다. 실제 전원정답은 공개 검수 자료로 확인.
- [실제 Flutter Repository 검사](../test/task03c_live_scoring_test.dart): 운영HTTP 목록443/과목396/시험17,
  답안 입력 준비, 객관식/숫자/전원정답의 만점·오답·미응답 Guest 채점 PASS.
  새 Grade 버전 없이 원점수/문항별 정오/획득점수, **등급 산출 불가** 유지.
- 이 테스트는 명시적 `TASK03C_LIVE_READS=true`일 때만 실행한다. 평소 테스트에서는 skip.
  APP 코드로 실제 API를 호출하지만 설치 앱 손가락 조작이나 authenticated HTTP 제출 검증은 아니다.
- 기존 학습/타이머/복구/학교·초대 회귀100 PASS. 03-B 공식522/학습120의 기존 증거도 보존.

## 등급컷·권한·기존 자료 보존

기존2,457행 ID/전체행 해시 `6e2db2a78ea3ca5a6856afb4f816b616` 적용 전후 동일.
참고 raw/standard/percentile 및 confirmed/unspecified 분리. 없는160셀 null, 미만/미배정117사실 제외 유지.
참고값으로 공식등급/표준점수/백분위를 역산하지 않는다. grade_cutoff_lookup는 변경하지 않았다.

채점/참고6테이블 RLS 활성. 기존 정책 정의 전체 동일. anon 제출불가, authenticated 제출허용+본인검사.
기존 Auth/account lifecycle·Registry·학습·평가·Credit/Ledger/결제 변경 SQL은 실행하지 않았다.
계정/원장 전체를 덤프해 모든 행 해시를 대조했다는 뜻은 아니며, 대상SQL 범위와 기존 대상행 보존을 검증했다.
보안 Advisor 전후 finding identity 비교: **신규0**. 기존 권고 수는 동일하다:
RLS/no-policy56, public extension1, anon SECURITY DEFINER9, authenticated SECURITY DEFINER151,
leaked-password protection1. 이번 작업에서 관련 없는 정책·Auth 설정을 변경하지 않았다.
[기존 보안 권고 설명](https://supabase.com/docs/guides/database/database-linter).

## 원복·남은 검수

[05_rollback_visibility.sql](../supabase/candidates/task03b_ready_20261111/05_rollback_visibility.sql)은
이번 batch만 withdrawn/current=false로 바꾼다. 답안·점수·정답 evidence/참고행은 삭제하지 않는다.
운영 원복은 실행하지 않았고 격리 원복으로 보존을 검증했다. 재공개는 신규 검수 절차 필요.

- 실제 학생 JWT 로그인→입력→제출→앱 재시작 후 결과 재조회: 실기기 검수 진행.
- Android 실기기/새릴리스/스토어: NOT TESTED/미실행.
- PARTIAL12 generic 직접진입·9과목 taxonomy·공식등급 환산은 후속. 이번에 임의 해소하지 않았다.
- APP67/APP71 보존. 내부 APP72 빌드/설치 결과는 아래 후속 기록에 추가한다.

## 보존 검토

[03-B 일곱 질문](task03b-ready-candidate-20261111.md#장기-데이터-보존7질문)을 그대로 적용한다.
이번에는 새 불변 key/question/evidence를 승인 범위로 추가하고 공개 상태만 전환했다.
공식 사실과 파생 연습점수 구분, 동일 사용자·기존권한, 당시 source/version과 결과 snapshot을 유지한다.
TEST11건의 별도 식별자를 보존하며 기존 학생 기록처럼 검증을 꾸미지 않는다.

## 내부 APP72 설치 — 2026-11-11

Owner가 iPhone 연결을 확인하여 APP71을 삭제 없이1.0.2(72)로 업그레이드 설치·실행했다.
기존APP71 Framework SHA 동일한 복사본을 `.local/task03c/app71-preserved/Runner.app`에 보존했다.
기존 production/Firebase/관찰/소셜로그인 define 유지. APP 코드 자체는 승인기준0a6864b와 동일하며
이번 커밋은 적용증거·migration·검증도구·Wiki다. codesign deep/strict PASS, iOS release build PASS.
정적분석 PASS. APP67 원본 및 스토어 상태는 변경하지 않았다. IPA/AAB/스토어 업로드는 진행하지 않았다.
Owner에게 review TEST 계정의 숫자입력/채점/등급산출불가/저장·재열기/타이머 확인을 요청했다.
기기 조작 결과 회신 전에는 설치·실행 PASS와 기능검수 PASS를 구분한다.
