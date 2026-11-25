# APP 1.0.7+89 출시 준비 — 2026-11-25

**PARTIAL / 스토어 제출 전 QA 필요.** 양 스토어 최신1.0.6+88을 실제 콘솔에서 확인,89미등록. 기준08345b69의 PDF수정·기존출시기능을 보존했다. main을강제reset하거나운영DB를변경하지않았다.

## 변경 범위

- 출시 브랜치 `codex/operations-commercial-20261113`, 시작34d2ee9(무료2안내). 기존D-Day6cd4c1a7의lib/test7파일만적용: SupabaseDayEventRepository,providers,AdmissionDayEvent,DayEvent,repository계약,DayTargetCard,테스트. 새동기화시스템없음.
- pubspec1.0.7+89. 자동일정배지·숨김·복원·KST·기존수동일정·대표1/가까운2 UI 재사용.
- `integration_test/admission_day_event_smoke_test.dart`는기존MockClient/fake저장소테스트를native런타임에재사용. 실제학생계정/운영DB연결없음.
- 다른출시후Flutter개선은[기존 전체diff](project-cross-review-flutter-files-20261125.md)에따라구분하며이번에미검증대규모변경을끼워넣지않았다. 논술결과UI/엔진은검토만수행.

## 이번 검증

|검증|결과|
|---|---|
|D-Day관련집중테스트4파일|59PASS|
|전체Flutter test|2655PASS/9SKIP/0FAIL|
|Flutter analyze|No issues|
|iOS Simulator build|PASS|
|iOS 합성Home/Study Native UI|8PASS|
|iOS 자동D-Day Native 계약/화면(1x/2x)|23PASS|
|Android 자동D-Day Native 계약/화면(1x/2x)|23PASS|
|Android production signed AAB|PASS,1.0.7+89,101997636 bytes|
|iOS production signed Archive/IPA|PASS,IPA Info.plist1.0.7/89,34496265 bytes|
|실제스토어설치88→89업데이트|NOT TESTED|
|실학생WEB↔APP동기화·RLS E2E|NOT TESTED;Mock계약검증과구분|

기존 출시용 ignored config를 값 노출 없이 `tool/store-release --config .../app-release-rc-20261113/legendstudy-app/config/store-rc.local.json`로 재사용. APP_ENV production,기존publicdefines유지,필수3releaseflags true. 실제결제/로그인/환불/Finance갱신호출0.

AAB SHA256 `ec01a477de470036da208352dfd0b140b324c1d442ed6c06148bfb6a05c87567`.
IPA SHA256 `28bf4601491e0f5f0f35785e2240960a9fd10f970b1d643cc13e80cbe0c68e5d`.
산출물은해당checkout `build/app/outputs/bundle/release/app-release.aab`, `build/ios/ipa/legendstudy_app.ipa`;Git에넣지않음. 추후제품코드변경시재빌드/해시갱신필수.

빌드경고:기존Kotlin2.2.20지원예고/SDK XML도구버전,CupertinoIcons font참조,flutter_tts SwiftPackageManager미지원. 현재빌드실패는아니지만아이콘누락/플랫폼회귀를실기기QA에포함한다. 무관패키지전체업그레이드하지않음.

## 출시 전 반드시 확인

1. Owner 무료2 SQL적용/pre/postcheck→WEB공지동시반영. 미적용현재3개를새정책적용완료로표시하지않음.
2. 동일실기기에서스토어88설치후89업데이트:로그인유지/수동D-Day·draft·타이머outbox·PDF다운로드보존. 삭제재설치로대체검증하지않음.
3. iOS/Android 소셜로그인,PDF열람/다운로드,자료검색/저장,타이머백그라운드/복원,학교랭킹,KST,MY,이용권잔액,논술기존결과/오류안내. 실제결제실행없이구매화면·정책표시확인;TossLIVE승인결제금지.
4. 자동일정:검증된본인일정표시→삭제→재진입/날짜변경에도유지→직접복원,수동D-Day보존,계정A/B격리. 운영학생일정으로테스트하지말고승인된QA계정사용.
5. Android15이상edge-to-edge/insets,작은화면·큰글자,VoiceOver/TalkBack,긴문항결과.이번build성공만으로QA완료라하지않음.
6. ASC심사노트의three complimentary credits와만료된베타기간을신규정책에맞춰수정할초안검토.89번호가여전히미사용인지업로드직전재확인.개인정보/서명/아이콘/스크린샷기존정책검토.

## 업데이트 안내 초안 (아직 게시 안 함)

“지원한 대학의 공식 입시 일정을 D-Day에서 확인할 수 있습니다. 자동으로 표시된 일정은 숨기거나 다시 복원할 수 있습니다. 논술 LAB 무료 첨삭권 안내를 최신 정책에 맞게 정리했습니다.”

정책적용전에는무료2개가현재지급된다는문구를게시하지않는다. 심사설명은‘New eligible users receive two complimentary essay credits after the policy rollout; existing balances remain unchanged. Official admissions events can be dismissed and restored.’로제안하며실제적용상태에맞춰최종검토.

업로드·TestFlight배포·Play트랙등록·심사제출모두0. Owner승인전금지. 실기기QA0.5~1일+발견결함수정,스토어심사시간은보장하지않는다.
