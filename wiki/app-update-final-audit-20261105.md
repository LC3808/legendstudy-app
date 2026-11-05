# 후속 앱 업데이트 최종 통합 감사 — 1.0.2(63)

Owner는 GA4 검증용 빌드가 출시 후보가 아님을 명시하고, APP58 보존·8개 기능 코드 대조·누락 통합·양OS 릴리스 빌드를 요청했다. 버전1.0.2(63) 사용 승인. 운영 DB/WEB/Store 변경 금지, Owner 최종 검수 후 Store 업데이트.

## 고정 기준과 포함 판정

승인 APP58 소스5b5e5a859a772f8f6af2716f1a1f3cec46a156d5. 후보 B HEAD142d0d5 및 GA4 HEAD ece362a를 시작 시 실제 Git으로 확인. TASK19 작업 트리에는 Wiki 수정/임시 캐시만 남아 있고 제품 코드 미커밋 변경은 없었다. 새 통합 브랜치 codex/app-update-final-integration-20261105는 기존 GA4 작업 공간을 재사용한다. 원본 후보 B/PDF/관리자 브랜치를 변경하지 않는다.

| 확인 대상 | APP58 | 후보 B142d0d5 | 통합 전 GA4 ece362a | 최종 앱 코드 | 실제 서비스/검수 한계 |
| --- | --- | --- | --- | --- | --- |
| TASK18 PDF 다운로드 | MISSING | MISSING | MISSING | INCLUDED | PARTIAL: 운영 정책 RPC 미설치, 파일별 권한/Edge 별도; iOS 합성 PDF Owner PASS는 과거 TASK18 근거, Android 실제 저장 미검증 |
| TASK19 등급컷 | MISSING | INCLUDED | INCLUDED | INCLUDED | PARTIAL: 운영 grade_cutoff_lookup/참조 테이블 미설치, TEST 검수만 별도 증거 |
| 논술 LAB 베타 안내 | PARTIAL(이전 문구) | INCLUDED | INCLUDED | INCLUDED | 신규 통합 빌드 Owner 검수 전 |
| 자연논술 상태 표시 | PARTIAL(이전 판정) | INCLUDED | INCLUDED | INCLUDED | 정확한 서버 연결 여부 유지, 모든 자연 문항 공개를 의미하지 않음 |
| 사회·상경·자연 최신 APP 개선 | PARTIAL | INCLUDED | INCLUDED | INCLUDED | 기존 TASK16 품질 P0/실제 평가 검증은 별도, 이번 평가 호출0 |
| 학습용5단계·History | MISSING(최신 표현/비교) | INCLUDED | INCLUDED | INCLUDED | PARTIAL: TEST 저장/비교 근거 있음, 운영 활성·품질 최종 확인은 NOT_VERIFIED |
| Firebase/GA4 | PARTIAL(기존 서비스만) | PARTIAL | INCLUDED | INCLUDED | iOS 이전 격리 DebugView PASS, 최종63/Android 수신 NOT_VERIFIED; 관리자 WEB 신규 배포 별도 |
| 문의 답변·이용권 개선 | PARTIAL(접수/기존 표시) | PARTIAL | PARTIAL | INCLUDED | support_mine/support_detail 운영 존재 확인, 최종63 실회원 답변/계정전환 Owner 검수 전 |

INCLUDED는 코드 포함 판정이며 운영 활성화·품질 승인·실기기 인수를 뜻하지 않는다. 기능 전체 최종 출시 판정은 PARTIAL / OWNER_REVIEW_PENDING.

## 실제 통합과 중복 방지

Git ancestry: APP58, math mobile d7d5bb1, 최신 수리 UI13ef69a/f53fb1d, learning9d29f3b, LABc051c4a, TASK19fc83281/9138593/6aa0b48/6ea7055 모두 시작 HEAD의 조상이다. 이들은 재병합하지 않았다.

별도 브랜치에서 필요한 앱 파일만 3-way 적용:
- PDF: 92d8110..ec6c08c의 lib/ios/android/test 및 Analytics 계약 검사. 실제 기능8f83f3f, 이벤트 보완38062bc. SQL/Edge 후보를 운영 적용하거나 기존 서버 소스를 변경하지 않았다.
- 문의: a97e966의 Native history/page 및 테스트만 적용. 원본 APP 문의ID/source로 답변 조회; 가짜WEB 문의 없음.
- 이용권: 0628028의 reason_code 표시/fixtures/tests만 적용. 원장·지급/차감·금액 계산·거래 유형 변경 없음.

실제 충돌3파일:
1. lib/features/analytics/domain/analytics_events.dart — PDF4종·등급컷·GA4메뉴/자료 이벤트와 허용 키 모두 합집합 보존. 기존PII 필터 유지.
2. lib/features/credits/credit_history.dart — 기존 KST시각/이용권 용어 유지, reason_code 기반 label만 통합. reserve/release 숨김·consume decision별 합산 보존.
3. test/credit_history_test.dart — 최신이용권 문구와 새원인분류 기대값 통합, 잔액/중복차감 방지 기대값 유지.

전체 관리자 브랜치 병합은 불필요한 서버/문서 충돌을 만들므로 시행하지 않았다. 유효한 원본 Wiki는 각 source SHA에 보존하고 이 감사 문서에 포함 근거/미완료를 연결한다.

## 읽기 전용 운영 확인

2026-11-05 Supabase stlhijzpjfgwwdgunlsd의 pg_proc/information_schema SELECT만 실행:
- support_mine(p jsonb), support_detail(p jsonb): 존재, stable.
- resource_download_policy, grade_cutoff_lookup: 없음.
- grade_cutoff_references: 없음, 기존 grade_cutoff_versions 존재.
- math_coaching/math_session_history/essay_math_coaching의 wrapper에는 learning_completeness/comparison 리터럴이 없음. wrapper만으로 내부 projection 미설치를 단정하지 않음; 운영 최신5단계 제공은 NOT_VERIFIED.

새 SQL/RPC/Edge/WEB 배포0. 실제 문의/평가/답변/이용권/결제/환불 실행0. Auth/RLS 변경0. PDF는 서버 오류/미설치 시버튼숨김, 등급컷은 패널 오류/재시도로 기존 자료 열람 보호. 기능 공개를 위해 별도 서버 승인·연결이 필요하다.

## 검증

통합 집중62PASS, 전체 Flutter1,546PASS/기존7SKIP/0FAIL. Analyze0. Analytics APP/WEB 공유 계약 + Native확장38이벤트/23키 검사PASS. git diff --check PASS. 신규 다운로드 native채널은 기존 export채널과 별도로 보존.

기존 운영 설정을 복사한 ignored 로컬 설정에 플랫폼별 Firebase만 병합. 기존 Google/Apple/Kakao/Auth/Supabase/평가 플래그 보존 확인. device-qa/store-release 사전검사PASS. 개인키/keystore/비밀값 Git 미추가. 최종 build source SHA·서명·해시는 별도 receipt로 고정한다.

## APP58 보존

원본 /Users/woojinchang/development/legendstudy-private-backups/app-review-integration-20261103/candidate-b/release58/:
- IPA88ecaf7e91dd9fe05b79113e5e0119295bb9dbeac2f043a2592a87261a28a01e
- AAB5ac0a0448a9f65c49d90f69cf4c0b393e9cd655ee2514d77e424fc6d1e5c7987

작업 전 실제 재계산 일치. 새63 산출물은 별도 경로이며58 재생성/덮어쓰기/기기 설치/Store 교체 없음.

## 보존 검토7

1. 기존 문의·평가·원장 발생시각/정정 이력 유지, GA이벤트시각 별도.
2. 기존원본/Registry/ID/원장 재사용, 출처SHA로 통합재현.
3. 데이터 UPDATE 없음, 표시계층만 통합.
4. auth canonical 학생ID/원본 문의ID 보존, GA사용자와 회원수 구분.
5. 학습 판단·지원/결과·서비스행동을 혼동하지 않음.
6. 기존RLS/본인조회/PII필터/다운로드권한 보존, 신규권한 확대 없음.
7. 표시라벨·GA랭킹·학습단계는 원본거래/공식점수로 취급하지 않음.

## Owner 검수

63에서 로그인4종/복귀 → 자료·PDF기존열람 → 자료/학습 등급컷 미연결안내 → LAB베타문구/자연상태 → 기존수리·상경 결과/History → MY문의답변·이용권원인표시. 실제 평가/금융작업은 별도 승인 없이는 실행하지 않는다. 서버 연결 이후 PDF OS저장·등급컷실조회와 최종63 GA4(Android포함) 수신을 검증한다. 학습5단계는 기존 품질P0를 해결했다고 주장하지 않는다. Store 제출은 Owner 검수 후 별도다.
