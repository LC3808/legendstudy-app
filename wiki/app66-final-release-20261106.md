# APP 1.0.2 FINAL RELEASE READINESS

2026-11-06 · 빌드 66 · 소스 3fd07d2511a6e08bc727e297ff9e2a9b7ccc1a23 · RELEASE_READY = NO

## 최종 후보

APP65 소스 234368b를 기준으로 운영 Q3의 근거 부족 응답에 설명문이 생략되면 판단 보류 카드까지 숨겨지는 결함을 수정했다. 기존 결과 및 History에서 같은 카드를 사용한다. 평가 ID·버전 일치, 검토 후 제공되는 1~5단계, 미제공 시 숨김, 과거 단계 부재 시 수치 비교 생략 계약을 유지한다. Q3 신규 운영 실평가는 NOT VERIFIED. 운영 Provider 호출·DB 변경·이용권 사용·스토어 제출 0.

- 정적 분석 0건. 전체 Flutter 1,556 PASS / 7 SKIP / 0 FAIL. Q3 표시 집중 테스트 5 PASS.
- 정식 IPA 및 AAB, 각각 1.0.2(66), com.legendstudy.app. IPA 배포 서명·프로파일·Apple 로그인 권한 검증. AAB manifest versionCode 66, JAR 서명 검증 및 APP58 업로드 인증서 SHA256 일치. 양 플랫폼 바이너리에 운영 Supabase·Google 로그인·Firebase 공개 설정 포함.
- Android 첫 빌드에서 이전 integration_test 등록 파일로 Java 컴파일 실패. 표준 Flutter 의존성/플러그인 생성 절차를 포함해 재빌드 성공.
- 인계 위치는 Mac의 development/legendstudy-private-backups/app66-release-20261106. IPA SHA256 06e3111c7e09a0f41886ce63c49a7c64aa9b13555a06b6a2da3b3e718ccbdf71, AAB 0de4b7e219e3a00afc3b8a2eea461124bfdefc082c089b63ad1a228d0dd1dc8a. APP58/65의 보관 IPA·AAB 체크섬 재확인.

## 운영 기능과 실기기

- 공개 Catalog 조회 건국 2026 자연 4문항·경희 2026 자연 3문항. 기존 [WEB·APP65 실기기 검증](task20-priority-natural-connection-20261106.md)과 일치. 운영 WEB d0e0e2e.
- APP 공개키로 등급컷 RPC 11시험·2,457행의 문항 식별자·선택과목·등급·점수·출처·revision 대조 PASS.
- 다운로드 정책 RPC 운영 조회 18게시글·846 PDF 모두 PENDING, 파일 허용 0. 운영 파일 저장 성공은 미검증. 기존 합성 파일의 기기 저장 검증은 별도.
- iPhone 12 Pro Max 본앱 65 설치 조회 → 66 유지 설치 → 66 설치 조회·실행 PASS.
- iOS GA4 Data API의 1.0.2 집계에서 menu_view, material_open, exam_select, question_select 등 수신. 마케팅 버전 집계에는 빌드 번호가 없어 66 단독 증거로 사용하지 않는다.
- Android 실기기 미연결. 기존 Galaxy Play 설치본과 로컬 업로드 키는 서명이 달라 삭제 없이 교체하려면 Play 내부 테스트 트랙이 필요하다. [이전 실기기 서명 확인](task21-final-release-readiness-20261105.md).

## Owner 인계

1. iOS Transporter에서 IPA 업로드. 처리 후 App Store Connect의 1.0.2 버전에서 빌드 66 선택. 심사 제출은 Owner가 최종 검수 후 실행한다.
2. Android Play Console 내부 테스트에 AAB를 등록해 기존 Play 설치본에서 덮어 업데이트. 로그인·기존 자료 및 History·공개 7문항·등급컷·GA4 최종 빌드 이벤트를 확인한다.
3. Android 실기기 및 최종 이벤트 검증 이후 출시 차단 여부를 재판정하고 Owner가 검수한 빌드를 운영 트랙에 승격한다.

검수 시간대 GA4 실시간 API HTTP 200, iOS 1.0.2의 app_open/menu_view/screen_view/session_start/user_engagement 각 1건. 빌드 식별과 자료 Registry ID는 이 집계로 확인할 수 없다. DebugView 최초 조회는 이벤트 대기였고 Mac 잠금으로 상세 대조가 중단됐다. 66에서의 iPhone 화면별 확인과 Android 내부 트랙 및 양 플랫폼 빌드별 GA4 수신을 후속 검수한다.
