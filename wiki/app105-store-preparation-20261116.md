# 1.0.5(86) 스토어 출시 준비 — 2026-11-16

기준 제품 Git `a89e48631a378433aa8b908134330e26af19e719`. 신규 기능/제품 코드 변경 없음. 기존 IPA/AAB 재사용. 실제 업로드·심사 제출·공개는 수행하지 않았다. [기존 84→85→86 검증 영수증](app-release-105-readiness-20261115.md)을 보존한다.

## 판정

| 항목 | 상태 | 근거 및 제한 |
|---|---|---|
| Git·산출물 일치 | DONE | 로컬/원격 작업 브랜치 a89e486 일치, clean, 제품 경로 diff 없음. IPA/AAB SHA256가 11/15 영수증과 일치 |
| 전체 Flutter 회귀 | DONE | 2629 PASS / 9 SKIP / 0 FAIL, Flutter 3.47.6 고정 wrapper, analyze No issues |
| iOS 업데이트 | PARTIAL | 11/15 삭제 없는84→85→86 설치 기록. 84→85 보존 정상은 Owner 확인. 11/16 연결된 iPhone12 Pro Max에서 com.legendstudy.app 1.0.5/86 재확인. 86 시각 확인 회신 대기 |
| Android 기본 기능 | NOT TESTED | ADB 연결0. 서명 AAB가 있어도 실기기 PASS로 대체하지 않음 |
| BETA 배지·대학 소식 | PARTIAL | 자동화 PASS. registry release-hold와 홈/편집/온보딩 필터 유지. 베타 무료 종료 정책 배너는 배지와 별개로 유지. 86 실기기 화면 회신 대기 |
| 신규 앱 이벤트 수신·저장 | PARTIAL | 21:13 KST 운영 GA4 보고서 신규 menu_click10건(LAB5/MY4/홈1, 각1이용자) 확인. 기존 이벤트31642/화면17363/기능150. 새 클릭 이벤트 서버 수신 및 보고서 조회는 확인했으나 appVersion/build 차원이 없는 집계라 특정86 QA 세션에 귀속하지 않음. 검색/PDF/저장/타이머 E2E는 NOT TESTED |
| 개인정보 신고 | PARTIAL | Play 아래 변경안 임시저장 확인, 제출0. Apple 편집 최종 단계가 즉시 게시이므로 취소하고 변경표 준비. 전체 신고 최종 확정 전 HOLD |
| 결제 | DONE(보존) | runtime 읽기 응답 PAUSED/LIVE/consumer_purchase=false. Finance·Toss·SQL·권한 변경0, 실제 결제/환불0 |
| 스토어 제출 | HOLD | Owner 실제 제출 승인 전 제출 금지. 공개 iOS/Play는1.0.4(84), 새 업로드/릴리스 생성0 |

## 산출물·검증

- `build/releases/app105-86/legendstudy-1.0.5-86.ipa`: `a9c97cfb4322fe7645687fa5b5c32da582b8a9012d5ead9cc96679c7802ce7c1`
- `build/releases/app105-86/legendstudy-1.0.5-86.aab`: `78da9d9aa6f8cc819c7149417029c3bcc81f03e104efa4b58a6f68f381203b23`
- IPA Info.plist com.legendstudy.app/1.0.5/86 확인. IDFA 수집false. codesign deep/strict는 신뢰 저장소 접근을 허용한 실행에서 exit0. sandbox 실행 CSSMERR_TP_NOT_TRUSTED를 산출물 위변조로 단정하지 않음.
- AAB jarsigner verified. 자체서명 체인·타임스탬프 없음·ZIP 읽기 방식별 manifest/debugsymbol 경고가 출력됐다. 이는 서명 실패는 아니지만 이번에 Play 서버 bundle validation/split 설치를 수행하지 않았으므로 해당 단계는 NOT TESTED.
- 최초 PATH flutter 실행은 Dart3.8 대 프로젝트^3.13.3 불일치로 의존성 해석 단계에서 종료. 프로젝트 `tool/flutterw`의3.47.6으로 재실행 PASS. SDK/lockfile 변경 없음.
- 별도 `tool/check_analytics_contract.py`는 FAIL: v1 검증기의 native_only에 앱 v2 이벤트7개가 없고 WEB 전용 schoolInvite 이벤트7개도 공통으로 비교한다. 실제 공통31개 이름/값 불일치0을 읽기 진단으로 확인. 전체 Flutter 신규 실패0과 이 보조 검사 실패를 구분한다. 스크립트/제품 코드는 이번에 변경하지 않았다.
- 증거 로그: `/tmp/app105-86-final-test-pinned-20261116.log`, `/tmp/app105-86-final-analyze-20261116.log`. Wiki handoff PASS(문서 갱신 후 재검사).

## 신고 보완표 — 제출 전 검토

실제 코드: ANALYTICS_ENABLED=true 릴리스 초기화 후 setAnalyticsCollectionEnabled(true). 사용자 옵트아웃 UI 없음. setUserId 구현은 있으나 앱 호출부 없음. iOS IDFA/Android adid 수집false. 앱 인스턴스 식별자 수집까지 꺼진 것은 아니다. 원시 검색어·답안·이메일을 새 이벤트에 보내지 않음. 기존 계정·지원·학습·구매 데이터와 분석 SDK 계약은 별개다.

| 플랫폼·항목 | 변경안 | 저장 상태 |
|---|---|---|
| Play 앱 상호작용 | 기존 앱 기능·맞춤설정 유지 + 애널리틱스 추가, 선택 수집→필수(옵트아웃 없음), 비임시/수집됨 유지 | 임시저장 DONE |
| Play 기기 또는 기타 ID | 앱 인스턴스 ID: 수집됨/비임시/필수/애널리틱스 | 임시저장 DONE |
| Play 대략적인 위치 | SDK의 IP 파생 위치: 수집됨/비임시/필수/애널리틱스. GPS/정확한 위치 아님 | 임시저장 DONE |
| Apple 제품 상호작용 | 앱 기능+분석. 계정/기기 연결 여부를 Apple 정의에 맞게 보완(앱 인스턴스 ID 존재하므로 userId 미호출만으로 비연결 단정 금지) | 게시하지 않음 |
| Apple 기기 ID·대략적 위치 | 분석 목적 수집 항목 추가, 연결 여부와 추적 여부 각각 검토 | 미게시 변경안 |
| 양쪽 구매 내역 | Firebase 자동 구매 이벤트와 기존 구매 원장 구분, 분석 목적 추가 여부 확인 | 최종 검토 필요 |
| 양쪽 기존 사용자ID/답안·사진/학습 데이터 | 계정 UUID와 연결되는 기존 저장 계약이 비연결 신고와 맞는지 항목별 대조 | 최종 검토 필요 |

Play 공유 안 함 초안은 서비스 제공자 처리 예외 전제이며 Google Signals/Ads 연결/Google 제품 데이터 공유 설정은 이번에 확인하지 못했다. 이를 최종 확정된 신고로 간주하지 않는다. Apple에서도 추적 미사용 확정은 IDFA=false만으로 하지 않는다. 현재 초안은 수집을 새로 활성화하지 않고 신고 내용만 보완한 것이다.

공식 근거(11/16 확인): [Firebase Apple 가이드](https://firebase.google.com/docs/ios/app-store-data-collection), [Analytics Apple 신고](https://support.google.com/analytics/answer/10285841), [Analytics Play 신고](https://support.google.com/analytics/answer/11582702). 기본 앱 인스턴스 ID, IP 파생 위치, 구매/화면 이벤트 및 설정별 차이를 참고했다.

Apple 현재 신고 7종/제품 상호작용 앱 기능만/기기ID·위치 없음 재확인. 편집 마지막 버튼이 '게시'이며 즉시 반영 안내가 있어 변경안 확인 후 취소했다. Play는 '임시저장' 후 '변경사항이 저장되었습니다' 확인; 최종 미리보기/심사 전송은 하지 않았다. 증거 `/tmp/legendstudy-play-privacy-draft-20261116.png`.

## 86용 제출 문안 (미게시)

### 양쪽 스토어 업데이트 설명

논술 LAB과 MY 화면의 사용성을 개선했습니다.
- 논술 LAB의 BETA 배지를 정리하고 조회 실패 시 안내와 재시도를 개선했습니다.
- 지원 정보를 수정하거나 삭제한 뒤 MY 요약이 갱신되도록 개선했습니다.
- 닉네임 입력 안내와 계정 전환 후 화면 안정성을 개선했습니다.
- 홈 화면의 대학 소식 카드는 사용성 개선을 위해 잠시 표시하지 않습니다.
기존 학습 기록과 저장한 자료는 그대로 유지됩니다.

### 심사 메모 추가 문안

Version 1.0.5 (86) improves Essay LAB catalog recovery, profile/application summaries, nickname validation, and account-switch navigation. The university news home card is temporarily hidden. The Essay LAB BETA badge is removed; the existing notice about the end of the free beta remains. Historical records and existing signup/purchased credit policies are unchanged. Existing in-app purchase and review-access flows are retained. No new payment method is introduced. Existing Firebase Analytics measures allowlisted app interactions; declarations must be finalized before submission. Preserve existing review credentials without copying them into this document.

기존85 초안의 '대학 소식 연결' 문구는86 제출 시 사용하지 않는다. 기존 공개1.0.4 심사 메모의 과거1.0.1 beta 설명도 새 버전 작성 시 위 문안과 정합화한다. 계정 자격증명·스토어 결제 설정은 변경하지 않는다.

## 최종 게이트

1. 86 iPhone 화면 확인 및 신규 이벤트별 발생/전송/수신 대조. iPhone12 설치 버전 확인과 iPhone17 미러링 화면을 혼동하지 않는다.
2. 개인정보 신고 연결/추적/공유 및 구매 분석 용도 최종 확인 → Apple 게시·Play 최종 신고 완료. 현 단계 PARTIAL.
3. Android 실기기 미검증을 Owner에게 명시.
4. 기존86 IPA/AAB 사용. 제품 코드 변경이 필요하면 새 번호로 재빌드.
5. Owner의 별도 스토어 제출 승인 이후에만 업로드·심사 제출 절차 진행. 현재 제출 가능 판정은 HOLD.
