# 1.0.5(87) 배너 제거·최종 출시 검증 — 2026-11-16

Owner 후속 지시로 종료 안내 배너도 제거한다. [86 준비 기록](app105-store-preparation-20261116.md)의 배너 유지 결정은 이번 지시로 대체된다. 기존 릴리스/데이터를 보존하며 스토어 업로드·심사 제출은 HOLD다.

## 변경 및 보존

- EssayBetaCreditEntry에서 종료된 캠페인 배너를 숨긴다. 활성 캠페인의 기존 안내, 서버 잔액 조회, 정책·Credit Ledger·결제 처리 계약은 변경하지 않는다.
- 종료 상태에서 배너가 없고 기존 workspace가 계속 표시되는 위젯 테스트로 회귀 확인.
- pubspec 1.0.5+86 → 1.0.5+87. 기존86 IPA/AAB 별도 보존. 새 기능 없음.
- 보조 Analytics 계약 검사의 오래된 v1 기대값을 현재 명시적 APP 전용14/WEB 전용7 및 WEB campaign 파라미터에 맞게 수정. 공통31 이벤트 이름/값 비교와 예기치 않은 플랫폼 확장 검출은 유지한다. 앱 바이너리에 포함되지 않는 검사 도구 변경이다.

## 검증 결과

| 항목 | 상태 | 근거 |
|---|---|---|
| Flutter 전체 | DONE | 2629 PASS /9 SKIP /0 FAIL. analyze No issues found. 관련 beta 테스트9 PASS |
| 릴리스 설정 | DONE | tool/test_store_release_config.py 3 PASS, analytics 계약45 이벤트/23 파라미터 PASS |
| IPA | DONE | signed Store export 성공, 내부 com.legendstudy.app/1.0.5/87, 최종 IPA 추출 app codesign deep/strict PASS. Store profile get-task-allow=false, 만료2027-10-19 |
| AAB | DONE | release bundle 성공, protobuf manifest package com.legendstudy.app/versionName1.0.5/versionCode87, jarsigner verified. 기존 인증서 체인/타임스탬프 경고; Play 서버 검증은 미수행 |
| iOS 업데이트 | DONE(설치) | iPhone12 Pro Max 기존86을 삭제 없이87로 업데이트, launch 성공, devicectl 설치 버전87 확인. Store IPA와 별개 development provisioning export를 사용한 QA |
| iOS 화면·검색·PDF | DONE(Owner) | 87 설치 후 배너 제거·대학 소식 비노출·자료 검색/PDF 열기 질문에 Owner ‘pass’ 회신. 직접 화면 관찰과 구분. 기존 데이터 보존은84→85 Owner 정상 보고 및 삭제 없는 후속 업데이트 근거 |
| Android 실기기 | NOT TESTED | ADB 연결0. AAB 빌드/서명을 실기기 검증으로 대체하지 않음 |
| 앱 행동 이벤트 | PARTIAL | 21:49 KST 운영 보고서 화면17509/메뉴10/기능150. 이후 실제 Owner QA 후 GA4 실시간 최근30분 menu_click5, pdf_view1 확인. 새 PDF 이벤트 서버 수신 확인. appVersion/build별 귀속·검색/bookmark/timer 전체 E2E는 NOT TESTED |
| 결제 | DONE(보존) | runtime 읽기 응답 PAUSED/LIVE/consumer_purchase=false. Finance·Toss 설정/운영SQL/실제결제/환불 변경0 |
| 스토어 제출 | HOLD | 새 IPA/AAB 업로드0, 앱 심사 제출0. Apple 개인정보 라벨 게시와 앱 버전 제출을 구분 |

로그: /tmp/app105-87-{beta-test,full-test,analyze,ios-build,android-build,aab-signature,device-export,device-install}.log. Android SDK XML/Cupertino font 및 iOS flutter_tts SPM 전환 경고는 빌드 성공과 구분하며 의존성 임의 변경 없음.

## 개인정보 신고 보완

실제 GA4 속성562560908 관리 UI 읽기 확인: Google 신호 데이터 비활성, Google Ads 연결0, 계정 Google 제품 및 서비스 공유 꺼짐. 집계·익명화 참여 모델링 켜짐, 기술 지원 꺼짐, 비즈니스 추천 켜짐. 설정은 변경하지 않았다. 계정의 별도 GDPR 처리 약관 미수락 표시도 있었으며 새 약관에 임의 동의하지 않았다.

- Apple **게시 완료**: 수집 유형7→9(대략적 위치·기기ID 추가), 두 유형 분석/연결됨/추적안함. 제품 상호작용과 구입 내역은 앱기능+분석/연결됨/추적안함. 사용자ID·사진/비디오·기타 사용자콘텐츠·기타데이터는 기존 앱기능 목적을 유지하고 실제 계정 저장에 맞춰 연결됨으로 정정. 이메일 기존 연결됨 유지. 최종9종과 모든 연결 상태, 추가설정필요 없음 확인. 이는 개인정보 라벨 보완이며 실제 앱 심사 제출이 아니다.
- Play **초안 저장 완료**: 앞서 저장한 앱 상호작용 분석/필수, 기기ID와 대략위치 분석/필수/수집됨/비임시에 구매 내역 분석 목적 추가. 기존 앱기능·기타 설정 보존. 최종 공개/심사 전송은 하지 않았다. 스토어 제출 승인 후 초안 반영 절차 필요.
- GPS/정확한 위치, 광고ID 신규 수집 또는 Analytics 활성화 설정 변경 없음. 기존 앱 instance ID/IP 파생 위치/자동 구매 및 화면 이벤트를 신고에 반영했다. 원시 검색어·답안·이메일을 신규 이벤트로 보내지 않는 기존 allowlist 유지.
- 증거: /tmp/legendstudy-apple-privacy-87.png. 공식 근거: [Firebase Apple](https://firebase.google.com/docs/ios/app-store-data-collection), [Analytics Apple](https://support.google.com/analytics/answer/10285841), [Analytics Play](https://support.google.com/analytics/answer/11582702).

## 산출물

- build/releases/app105-87/legendstudy-1.0.5-87.ipa — SHA256 `514f2563b6388e700d157a071952b7c3839af23920d5eac106b051088aca2919`
- build/releases/app105-87/legendstudy-1.0.5-87.aab — SHA256 `21080289a52244bb8521f87594849baf4c03c4e9f78a6c882bd3c2b4e46423ca`
- 기존86의 공개 production define을 보존. iOS Generated.xcconfig에서 재구성하고 Android86 AAB의 Firebase 공개 appID/key를 대조하여 플랫폼 설정 유지. Secret 출력/커밋 없음. Flutter3.47.6 tool/flutterw 사용, lockfile 변경 없음.

## 87 제출 문안 — 아직 미제출

논술 LAB과 MY 화면의 사용성을 개선했습니다. 논술 LAB의 BETA 배지와 종료 안내 배너를 정리하고, 조회 실패 시 안내와 재시도를 개선했습니다. 지원 정보 수정·삭제 후 MY 요약 갱신, 닉네임 입력 안내와 계정 전환 안정성을 개선했습니다. 홈 대학 소식은 사용성 개선을 위해 잠시 표시하지 않습니다. 기존 학습 기록과 저장 자료·이용권 정책은 유지됩니다.

심사 메모: Version 1.0.5 (87) removes the Essay LAB BETA badge and expired-beta banner, improves catalog recovery, profile/application summaries and nickname validation, and temporarily hides the university-news home card. Existing learning records, signup/purchased-credit policies and in-app purchase flows are unchanged. No new payment method is introduced. Privacy disclosures have been reconciled with existing Firebase Analytics collection. Preserve existing review credentials; do not copy them to Wiki.

## 남은 게이트

Android 실기기·Play 생성 split 설치, 검색/저장/타이머 이벤트 각각의 서버 수신과 빌드별 대조는 미검증이다. iOS 사용성은 Owner PASS이며 제출용 산출물 준비 완료. Play 신고 초안 반영 및 실제 스토어 업로드/심사 제출은 Owner 별도 승인 후에만 수행한다. 현재 전체 상태 PARTIAL / 제출 HOLD.
