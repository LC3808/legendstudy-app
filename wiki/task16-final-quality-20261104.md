# TASK16 최종 품질 — 후속 구현 및 검증

2026-11-04. **PARTIAL / 운영 미반영 / APP58 보존**.

[운영 연결·실제 검수](app58-expanded-production-connection-20261104.md), [학습용 5단계 Owner 정책](learning-completeness-policy-20261104.md), [APP58 산출물](app58-store-handoff-20261104.md)을 계승한다. 현재 운영 표시 소스9a8fb9f와 후속 로컬 구현을 구분한다. 기존 15대학202시험464문항을 재구축하지 않는다.

## 구현·검증 범위

| 항목 | 상태 | 근거 및 한계 |
|---|---|---|
| APP 결과 본문 | PARTIAL | Owner IMG1352–55의 재첨삭 본문·History 표시 확인. 원래 최초 결과 공백 원인은 별도이며 새 설치 검증으로 대체하지 않음 |
| 문장·소문항·수식 | PASS(로컬) | 13ef69a 경계 처리 재사용. indexed root `√[4]{u}`/`⁴√3` 표시 보완; `x⁴√3`의 지수를 루트 차수로 오인하지 않음. 실패 수식은 경고와 원문 유지 |
| 학습 완성도 | PARTIAL | 서버 검증 계약·APP/WEB 선택적 표시 구현. 실제 Provider 산출·독립 검토·영속 저장·coaching/History 연결은 아직 미구현, 운영 별점 없음 |
| 학습 변화 비교 | PARTIAL | 동일 문항/기준/정책 및 소유 lineage의 이전 평가만 비교하는 순수 계약 검사. 실제 새 평가·무료 재첨삭 UI E2E 없음 |
| 중앙대 Q2 | PARTIAL | Q2는 Essay, Q3가 Math. 기존 independent review 실패의 재시도 안내 보완은13ef69a. Worker 배포·새 실제 재시도 아직 미실행. 기존 예약/성공 Q1·Q3 보존 |
| 인하 공식 해설 | PARTIAL | 공식 PDF 해시와 문항카드3쪽 예시답안 확인; 연결 SQL·원복 로컬 PASS. 운영 적용 승인 대기 |
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

공식 canonical solution1건 연결과 기존 `if disclosed` 분기만 변경하는 후보다. 이전 평가의 authority/considered refs는 바꾸지 않고 `SUPPLEMENTAL_AFTER_ASSESSMENT`로 표시한다. APP/WEB에 “추가 연결 공식 자료 · 평가 당시 참고자료와 구분” 및 출처 쪽수를 표시한다. 별도 정답 우회 API는 만들지 않는다. 원복은 정확한 함수 원상복구+새 solution RETIRED이며 기존 ID/공개 이력은 삭제하지 않는다.

운영 적용은 최종 지시10항에 따라 Owner에게 이 구체적 후보 범위로 요청했다. 승인 전 적용하지 않는다.

## 테스트

- 임시 Unix-only PostgreSQL17: 공식 해설23검사 + 기존 runtime131회귀 PASS. 공개 전 응답, 다른 소유자·익명 거절, 최대5과제, 공개 멱등성, evaluation/pin/credit 불변, 정확한 원복·solution ID 보존 포함.
- APP 전체1,489 PASS / 기존7 SKIP, 집중30검사 PASS; Flutter Analyze0.
- WEB 계약/표시/공개 제어28검사 PASS; TypeScript 검사 PASS.
- 중앙 Q2 retry/session 집중9검사 PASS. 고정 Wrangler4.150.0/workers-py1.17.7 dry-run PASS(70 modules/530.64KiB); 운영 Worker 실제 version d03763e8와14개 binding 이름/유형을 읽기 확인. 배포/재호출 없음. 빌드 방식은 [Cloudflare Python 패키징 문서](https://developers.cloudflare.com/workers/languages/python/packages/)를 확인했다.
- 실제 Provider 호출0, 운영 DB 쓰기0, 원장/History 수정0, Store 작업0. 자동 검사는 실제 기기 또는 Provider 품질 PASS가 아니다.

## 후속 P0 및 빌드

1. 승인 후 인하 후보 preflight→적용→공개 전/후 실제 응답·원장 보존 postflight.
2. 중앙 Q2 재시도 안내의 Worker 패키징/배포와 기존 예약을 이용한 최소 재검증. 독립 검토 거절을 우회하지 않는다.
3. 학습 완성도 신규 Provider 산출·판단 자체 검토·저장·RPC/History 계약 및 실제 사례 검증. 기존 결과 backfill 금지.
4. 최초/재첨삭/History 본문·전체 해설의 실제 iPhone/WEB 교차 검수.
5. APP58과 별개 후속 빌드가 필요하다. 최종 통합/빌드번호 확정 전 스토어 제출 후보로 취급하지 않는다. 기본 store config가 이 checkout에 없어 검증된 기존 설정 경로를 연결해야 한다. 누락 설정으로 빌드하지 않는다.

완료 판정은 PARTIAL이다. 운영 연결 완료, 로컬 코드 완료, 서비스 품질 검증을 구분한다.
