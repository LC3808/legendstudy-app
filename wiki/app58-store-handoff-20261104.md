# APP58 Store 인계 — 2026-11-04

## Owner 역할 정정

Owner 최신 결정에 따라 App Store Connect와 Google Play Console의 업로드·심사 제출·게시를 Owner가 직접 진행한다. Codex는 코드 통합, IPA/AAB 빌드, 서명·인증 설정 검증, Backend 연결, 산출물과 절차 인계를 담당한다. 별도 명시 요청 없이 스토어 작업을 실행하지 않는다. 이전 업로드 승인은 이 역할 정정으로 대체한다.

이번 조사 중 **IPA 업로드 0 / AAB 업로드 0 / 심사 제출 0 / 게시 0**이다. Transporter의 기존 계정 및 Console 접근 상태만 확인했다. 기존 APP41과 APP58 산출물은 보존했다. 이후 Owner 승인 실기기 검수에서 기존 서명된 APP58 Archive를 iPhone12ProMax 본앱에 설치했으며 추가 재빌드는 없다. 별도 LS Math TEST56은 그대로다.

## 최종 빌드 산출물

실제 빌드 소스: `5b5e5a859a772f8f6af2716f1a1f3cec46a156d5`. 이후 문서/TEST 정책 적용 기록 커밋과 빌드 소스를 구분한다. 버전 `1.0.1`, 빌드 `58`, 앱 ID `com.legendstudy.app`.

산출물 폴더:
`/Users/woojinchang/development/legendstudy-private-backups/app-review-integration-20261103/candidate-b/release58/`

| 산출물 | 크기 | SHA-256 |
|---|---:|---|
| `legendstudy-1.0.1-58.ipa` | 33,981,223 bytes | `88ecaf7e91dd9fe05b79113e5e0119295bb9dbeac2f043a2592a87261a28a01e` |
| `legendstudy-1.0.1-58.aab` | 99,632,168 bytes | `5ac0a0448a9f65c49d90f69cf4c0b393e9cd655ee2514d77e424fc6d1e5c7987` |

`Runner.xcarchive`와 기존 빌드 receipt도 같은 폴더에 보존한다. 원본 파일을 다른 소스로 교체하거나 번호만 재기록하지 않는다.

## 검증 결과

| 검사 | 결과와 한계 |
|---|---|
| iOS 서명/배포 | codesign strict/deep PASS, App Store provisioning, debug 권한 꺼짐, Apple 로그인 entitlement 확인 |
| iOS 실제 바이너리 | 1.0.1/58, Supabase URL/공개키·Google 서버/iOS ID 포함, 운영 설정/TEST 꺼짐 PASS |
| Android 실제 AAB | protobuf manifest versionName 1.0.1 / versionCode 58, jarsigner PASS, Supabase·Google 설정 포함 |
| Android 설정 | minSdk24/targetSdk36, debug 꺼짐, Billing 포함, AD_ID 없음 |
| 수리/상경 미활성 표시 | 실제 빌드 소스와 동일한 코드의 집중33검사 PASS: 준비중/서버 미승인/목록 실패에서 잘못된 평가 실행·렌더 예외 방어 |
| 전체 빌드 기준 회귀 | Flutter 1,480 PASS / 기존7 SKIP, Analyze0. 이 수치는 이후 실제 운영 활성화 E2E의 증거가 아님 |
| 신규58 실기기 인증 | 이번 인계에서 재실행하지 않음. 기존 A48 로그인4종 및 B56 UI Owner PASS를 별도 근거로 재사용 |
| Store 처리 | 미업로드, 미처리. Owner 업로드 후 서버 처리 결과 확인 필요 |

감사 산출물: 로컬 `/tmp/legendstudy-app58-artifact-audit-result.json`, `/tmp/legendstudy-app58-hold-preflight.json`. 비공개 키·서명 파일 내용은 문서나 Git에 포함하지 않는다. APP40 인증 설정 누락과 APP41 외부 브라우저 Design 심사 거절은 서로 다른 이력이다.

## Owner 업로드 절차

### iOS

1. Transporter에서 기존 LegendStudy 개발자 계정/공급자를 확인한다.
2. 위 `legendstudy-1.0.1-58.ipa`를 추가하고 검증 후 전송한다.
3. [App Store Connect](https://appstoreconnect.apple.com/apps/6820826957/distribution)에서 처리 완료된 1.0.1(58)을 확인한다.
4. 기존 1.0.1 심사 화면의 빌드 선택·수출 규정·로그인 검수 안내를 확인한다. Guideline4 수정은 시스템 인증창 사용과 실제 Kakao 취소/복귀 검수 근거를 전달한다.
5. 심사 제출 및 출시 방식은 Owner가 결정한다. 조사 시 기존 화면에 승인 후 자동 출시가 선택되어 있었으므로 실제 제출 전에 원하는 게시 방식인지 확인한다. Codex는 이 설정을 변경하지 않았다.

업로드는 심사 제출·게시와 다르다. 기존 화면의 저장되지 않은 Owner 편집은 임의 저장하거나 덮어쓰지 않는다. [Apple 공식 업로드 안내](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).

### Android

1. [Google Play Console](https://play.google.com/console/)의 기존 LegendStudy 앱과 개발자 계정을 선택한다.
2. Owner가 선택한 테스트 또는 정식 트랙의 출시 초안에 위 `legendstudy-1.0.1-58.aab`를 업로드한다.
3. package/versionCode58·서명·Console 검사를 확인하고 릴리스 노트 및 필요한 검수 정보를 검토한다.
4. 저장, 검토 요청, 게시를 각각 Owner가 진행한다. 테스트 배포 성공을 정식 서비스 게시로 보고하지 않는다. [Google 공식 출시 준비 안내](https://support.google.com/googleplay/android-developer/answer/9859348?hl=en).

## 서비스 연결 경계

수리·상경 운영 연결과 공개 범위 확대는 [통합 보고서](app-math-commerce-integration-report-20261103.md) 및 [현재 상태](current-status.md)의 별도 작업이다. Store 산출물 PASS가 운영 RPC·Provider·공개 설정·실제 E2E 완료를 뜻하지 않는다. Owner 지시에 따라 전체363시험을 조사해15대학202시험464문항을 기존 Registry와 평가 엔진에 연결했다. [최신 운영 연결·실제 검증·남은 P0](app58-expanded-production-connection-20261104.md)를 제출 전 확인한다. 서강 Essay와 인하 사진 무료 재첨삭은 실제 결과가 있으나, APP58 History 본문 공백·혼합형 전체 완료·전체 해설 payload는 검수 차단 요소다. 산출물 빌드 PASS가 이 품질 문제의 해결을 뜻하지 않는다.

업데이트 안내 정책은 격리 TEST disabled 적용 완료, 운영 미적용/비활성이다. 스토어 출시 확인 전58을 최신 공개 버전으로 안내하거나 REQUIRED를 켜지 않는다. [업데이트 정책](app-update-check-20261104.md).
