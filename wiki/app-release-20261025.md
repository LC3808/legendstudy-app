# 2026-10-25 Native APP 통합 업데이트

상태: MY UI 복원·자동 검증·Release 빌드 완료. 실기기 상세 검수/스토어 제출·출시는 미완료.

## Authority / 보존 검토

Owner 2026-10-25 APP release 1~40과 추가 Credit 표시 지시가 현재 범위. [기존 Credit 정책](payment-app-foundation.md#2026-10-25-사용자-크레딧-내역-표시-정책), [MY 공유 기반](my-shared-foundation.md), [데이터 전략](longitudinal-learning-admissions-data-strategy.md), [기존 실기기 성공](essay-p0-direct-execution-20261023.md) 재사용. Unified `LC3808/legendstudy-docs`의 10/25 인수인계·10/24 서비스 원칙·관리자 구매 조사 참조. 오래된 출시 차단 상태보다 실제 Store/DB 확인 우선.

7개 보존 질문: (1) 지원 이벤트의 발생/기록 시각은 기존 RPC가 소유; (2) 대학/문항/평가/구매 ID와 provenance 유지; (3) 지원 상태는 기존 append-only event, 정보 수정은 revision 계약, 삭제는 기존 RPC; (4) 동일 auth UID 공유; (5) 관심 목표/지원 Decision/학습 Learning/결과 Outcome 혼합 금지; (6) 동일 사용자 권한/기존 삭제·보존 정책, 새 수집 없음; (7) 그래프·카운트·파일은 기존 결과의 표시/파생물이며 원본 업데이트 없음. DB DDL·Ledger 경제·상품 ID·Secret 변경 없음.

## 기존 상태와 범위

- 기존 APP: 로그인/IAP/잔액/예약 반영, customer Credit projection, 문항 작성·PDF·인문 회차, 단일 Math 입력/판독/학습, shared History, 학교·학습시간.
- WEB에서 이식 유지: 결과 성장 세로막대·공유, Math 회차/실패 재처리, 사용자 Credit 내역 표시 통일. MY 재설계는 아래 Owner 후속 결정에 따라 철회.
- Backend 신규 변경 없음. 기존 Owner 적용 Math 회차/Essay retry/admin report SQL 재실행 없음.
- 관리자 APP 메뉴 제거. Flutter Native 유지. 기존 단일 Worker API/IAP Edge 코드 미수정.

## 구현

Owner가 iPhone 12 Pro Max 새 앱을 확인한 후 “마이페이지는 수정한 것이 UI/UX가 더 이상한 것 같다. 기존으로 되돌리자” 요청. MY 구성·프로필 편집·목표·학습·LAB 카드와 관련 저장 UI를 c3e93d9 이전 화면으로 복원. 새 MY 전용 미사용 컴포넌트/저장 어댑터/테스트 제거. 관리자 콘솔 WEB 전용 원칙에 따라 APP 관리자 메뉴 제거는 유지. Credit 내역 중복 표시 개선·실제 만료 수량과 결과 화면 성장/공유는 유지. 새 MY 지원 현황 UI 등을 이번 출시 완료 기능으로 보고하지 않는다.

Credit reserve/release 숨김·consume decision합산 기존 구현 재사용. expiry는 실제 grant ledger에서 남은 수량만 표시, 조회/범위초과는 불명 오류로 표시. 구매/지급/환불/관리자 원장·계산 불변.

Math: 기존 문항 drafts와 사진→immutable attempt→upload/extraction→학생 확인→math_session_submit 한 번. 기존 parent free policy 적용. durable round/attempt/retry keys; lost response 재사용. completed는 evaluate 재호출 안 함. History math_session_history를 legacy attempt와 중복 없이 회차로 표시. 인문 essay_exam_session_status/retry 같은 계약 사용.

성장: 같은 평가 계약만 strict 비교, 원래 기준명/단계 보존, 세로막대, 비교 상위 접힘. 대표 음성 종합평가 영역. 일반 사용자 내부 evidence count/생성 예시 노출 제거(저장 원본 유지). PNG는 별도 Canvas allowlist(카운트·기준명·단계·LAB주소); PDF도 로컬 요약/피드백, 계정·답안 원문·내부 ID 제외. Android 문서 저장/iOS 공유 시트, 공개 URL 생성 없음.

## 운영 사실

WEB Production `e9f1d4a1def74beb85e643f386bc5622b3aedb97`, deployment `e6af7b54-5199-4af9-94f1-1ee8fd909420`, canonical API success. 실제 로그인 고객 내역에 확정사용 -1크레딧, reserve/release 숨김. 관리자 원장 예약+1/확정잔액-1·예약-1 5개 페이지 유지 확인.
Rollback WEB `8261d17d1d379feff16e247267583ea4a165f86b` / `7ff387f2-4625-40e2-b557-61b71c1dbd64`.
Essay Worker `17b3bd65-8d90-4e8e-8ff6-a696e9575588` 유지. Math는 WEB Pages Functions. IAP Edge v23 ACTIVE WebCrypto 구현 확인; 이 checkout의 오래된 IAP Edge source 재배포 금지.
모바일 실제 검증 기록: Google1건1지급, Apple2건4지급, 총3건5지급·사용1→구매 잔액4. 거래 건수/상품 수량/잔액 구분. native amount/currency/environment 미저장으로 매출 추정 금지.

## 검증과 남은 게이트

- 기존 APP customerCredit15 / WEB80 PASS(2skip) 보존. WEB Typecheck/Lint/boundary/build PASS 후 위 배포.
- APP 새 Math partial consent/응답유실/remount 같은 key/성공 재실행 방지 PASS; expiry 예약 반영·원기준 그래프·PNG/PDF 생성 PASS. 실제 한국어 PDF 렌더 확인. 지원 수정 lost response 같은 key/ID/revision 유지 PASS.
- MY 복원 후 전체 Flutter test **1123 PASS / 7 skip / 0 FAIL**. Analyze **No issues**. 기존 catalog 표시순서와 삭제된 원문 버튼을 전제한 테스트는 현재 ID 보존/첨부 재시도 동작에 맞게 수정. 새 크레딧 구매 문구 기대값 수정.
- MY 복원 후 Android AAB/APK 1.0.1(2026102501), iOS IPA 1.0.1(20) Release 빌드 PASS. iPhone·Android 복원본 데이터 보존 재설치·실행 PASS. Owner의 iPhone 조회 “확인 완료”는 복원 전 후보의 확인이며 새 빌드 구매 성공으로 확대하지 않음. Device Hub 화면 공유는 iOS27 이상 요구/기기26.6.1이라 직접 UI 검증 BLOCKED.
- Android 연결 기기 기존 versionCode2026102401(스토어18보다 큼), 데이터 보존 설치를 위해 새 candidate2026102501. iOS store19, candidate20. iPhone12 Pro Max Owner 지정. 서명/ID 유지.
- 앱의 인문 이미지 제출은 기존 인문 API가 text-only라 지원되지 않음. Math text+image 혼합/다문항은 기존 Math 회차 경로. 별도 인문 이미지 평가·교차 엔진 회차를 구현한 것으로 보고하지 않음.
- Native 초안 사진은 기존 기기 저장 계약; 제출 후 canonical 평가/History 공유. 제출 전 사진의 타기기 draft 동기화는 기존 계약에 없음.
- 실기기 로그인·IAP·WEB↔APP 변경 동기화·재작성·성장/저장·키보드/PDF/타이머·회차 실제 정산은 실제 확인만 PASS, 나머지 NOT TESTED/BLOCKED 구분 필요.
- Google Play 개발자 지급계정 주의 알림은 Owner 조치 항목(계정/결제 설정 변경하지 않음).
- 스토어 업데이트는 새 빌드·검증 보고 후 Owner 최종 승인 전 제출 금지. 이전 수정전 Android20 artifact 사용금지, iOS 중단본 업로드 없음.

APP rollback: 기존 출시 Android18(1.0.0)/iOS19(1.0.0) 유지, 신규 store submission 없음. 코드 baseline c3e93d9(customerCredit). 데이터/서버 변경 없는 UI/API client rollback.

## 최종 artifact 식별 (MY 복원본)

- `build/app/outputs/bundle/release/app-release.aab` SHA256 `8ce453d30fc231dea468b8feece67543e7d9617eea2197e0cbbc4c23dc44833a`
- `build/app/outputs/flutter-apk/app-release.apk` SHA256 `97f216fcd265f06f2c016a408634d734175879be3465acaa4eaed7db08819860`
- `build/ios/ipa/legendstudy_app.ipa` SHA256 `0063d184aee48f77800031eca80b09604c5108d785657a61a1710921d35728b5`

빌드 로그: `/tmp/app-ios-restored.log`, `/tmp/app-android-restored.log`, `/tmp/app-android-restored-apk.log`. 자동 검증 `/tmp/app-restored-analyze.log`, `/tmp/app-restored-tests.log`. Kotlin/SDK metadata/Flutter TTS SPM/Cupertino font 경고는 빌드 실패 아님; 도구/의존성 정책 변경 안 함.
