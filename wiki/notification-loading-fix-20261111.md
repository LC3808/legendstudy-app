# 알림 화면 무한 로딩 안정화 — 2026-11-11

**코드·자동 테스트·빌드 DONE / 실기기 PARTIAL**. 개인 알림 백엔드 활성화는 이번 범위가 아니다.
브랜치 `codex/task04-applications-app75`, 수정 전 소스 `efb6b59`; 기존 APP75 자동채점·학습·공지사항을 보존한다.
[공통 공지사항](notices-system.md), [홈 개인화](home-personalization-and-events.md), [04-C 기기 검수](task04c-device-verification-20261111.md)의 후속이다.

## 원인과 실제 운영 상태

운영 catalog SELECT: `public.user_notifications` 및 아래 소비 RPC4개가 모두 없다.
`user_notifications_list`, `user_notifications_unread_count`, `user_notification_mark_read`, `user_notifications_mark_all_read`.
실제 목록 API의 읽기 요청은 HTTP404/PGRST202(스키마 캐시에 함수 없음)로 실패한다.
기존 feedback_notifications/inquiry_notifications와 공지사항 RPC는 별도 계약이며 대체하거나 변경하지 않았다.

기존 Riverpod3.3.2 AsyncNotifier는 오류 시 기본 자동 재시도 최대10회,200ms부터6.4초까지 지연해 약38초의 backoff가 추가된다. 네트워크 요청 자체에는 명시적 타임아웃이 없어 더 오래 대기할 수 있었다.
따라서 ‘데이터0개라 무한 루프’가 아니라, 준비되지 않은 API 실패·자동 재시도·요청 제한시간 부재가 길게 보이는 로딩의 원인이다. 유한한 기본 재시도를 문자 그대로 무한 재시도라고 보고하지 않는다.
수정 전 회귀 테스트에서 누락 RPC 오류 이후 로딩이 남는 현상을 재현했다. 홈 배지는 공지사항 미읽음도 합산하므로 배지5가 개인 알림 RPC 정상의 증거는 아니다.

## 변경 파일과 상태 계약

- `lib/features/notifications/application/notification_providers.dart`: feed 자동 재시도 비활성화, Auth 대기와 목록 조회에 각각8초 제한. 계정 identity로 구독해 초기 인증 완료 시 중복 목록 호출 방지. 재시도 중 추가 refresh 합치기, dispose/계정 전환 후 늦은 결과 보호. 읽음 변경도 시간 제한과 사용자 동일성 검사.
- `lib/features/notifications/data/notification_repository.dart`: 목록 transport 자동 재시도 비활성화, notification-v1/목록/항목ID 응답 검증. 잘못된 payload를 빈 목록으로 변환하지 않는다. RPC 이름·인자·권한·저장 계약 유지.
- `lib/features/notifications/presentation/notifications_page.dart`: refresh/reload 중 이전 데이터 대신 Loading 표시, Empty 문구 명확화. 공지사항 메뉴는 feed 밖에 유지.
- 테스트: `test/notification_loading_test.dart`, `test/notification_repository_test.dart`, 기존 `test/notification_center_test.dart` 기대값 정정. 공지사항 테스트 그대로 유지.

| 상태 | 조건 | 표시 |
|---|---|---|
|Loading|최초/수동 조회 진행|로딩 인디케이터|
|Success|정상 DTO,1개 이상|기존 목록·읽음 동작|
|Empty|정상 DTO,0개|‘새로운 알림이 없습니다.’ / ‘새로운 소식이 도착하면\n이곳에서 확인할 수 있어요.’|
|Error|네트워크/API/Auth/시간 초과/비정상 응답|‘알림을 불러오지 못했습니다.’ / ‘다시 시도’|

Auth와 API 제한은 순차 단계별8초이므로 전체가 항상8초 이내라고 주장하지 않는다.
Future.timeout은 화면 대기와 결과 반영을 제한하며 기존 SDK의 소켓 요청을 물리적으로 취소하지 않는다. 시간이 지난 요청 결과는 화면을 덮어쓰지 않는다.
운영 RPC가 없는 현재 실제 기대 화면은 **Error**이며 Empty가 아니다. 개인 알림 정상 제공 완료나 운영 백엔드 구축 완료로 보고하지 않는다.

## 검증

- 알림·공지 관련 **46 PASS**: 0개/1개 이상, network/API401/404·인증 실패, 비정상 DTO8종, 지연/시간 초과, 중복 재시도 억제, 초기 Auth 단일 요청, 계정 전환·logout·dispose 늦은 응답, 재진입, 공지 이동·홈 배지.
- 전체 **2,532 PASS / 8 SKIP / 5 FAIL**. 기존 APP75와 동일한 D3 runner1+mobile IA4. 신규 제품 실패0. [기존 실패 상세](task04b-production-preflight-20261111.md#기존-fail5--app75-동일-조건-비교).
- `flutter analyze --no-pub`: No issues found. iOS profile/no-codesign PASS, Android debug PASS. 기존 flutter_tts SPM/Kotlin 미래 지원 경고는 남아 있다.
- 정상 main.dart를 별도 **LS04C QA 1.0.2(76)**로 서명·설치했다. 기존 iPhone APP75 및 Android 기존67 설치본은 보존한다. 릴리스 산출물·스토어 업로드가 아니다.
- Android Galaxy S8: 기존 로그인 세션에서 홈 종→오류/재시도, 재시도 후 로딩 종료, 공지사항5개 목록, 뒤로·재진입 및 완전 종료/재실행 후 오류 상태 전환 확인. [오류 화면](assets/notification-loading-20261111/android-error.png) / [공지 목록](assets/notification-loading-20261111/android-notices.png).
- iPhone: 별도 앱 업데이트·실행 DONE. 화면 동작 Owner 회신 대기, 현재 **NOT TESTED**. 미회신을 PASS로 처리하지 않는다.
- 실제 운영 0개/1개 fixture·네트워크 장애·Auth 장애는 만들지 않았다. 해당 분기는 자동 테스트 PASS이며 실기기 운영 장애 시험이 아니다. 로그아웃/재로그인 알림 전용 실기기 회귀는 NOT TESTED.

## 보존·한계

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의7항 검토:
1. 새 historical fact 수집 없음. 기존 알림 read 상태만 기존 RPC로 요청한다.
2. 기존 원본/출처/시점 변환 없음. 실패는 원본 부재로 추정하지 않는다.
3. 기존 UPDATE/이력 정책 변경 없음. 공지/학습/결과 원본을 수정하지 않는다.
4. 기존 인증 user identity 유지, 이전 계정의 늦은 결과 반영 차단.
5. Learning/Decision/Outcome와 화면 조회 상태를 혼동하지 않는다.
6. 새 권한/PII 수집/동의/retention 없음. 계정 원문·토큰을 증거에 저장하지 않는다.
7. Empty는 실제0개 응답에서만 파생, 오류/타임아웃을 데이터 사실로 저장하지 않는다.

알림 생성·푸시·DB provisioning을 재설계하지 않았다. 운영 DB/RPC/Auth/WEB 변경0, 릴리스 병합/스토어 제출0.
운영 개인 알림 제공은 별도 계약/배포 검토가 필요하며 이번 승인으로 SQL을 적용하지 않는다.
