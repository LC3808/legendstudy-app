# PDF 열람 흰 화면 P0 — 2026-11-17

## 실제 출시 결과 회수 — 2026-11-25

**양 플랫폼 RELEASED.** 아래 11/17 본문은 빌드 당시 인계 기록이며 현재 제출 대기를 뜻하지 않는다. 11/25 실제 App Store Connect/Play Console와 공개 스토어 기록을 대조한 [교차검토 §6](project-cross-review-20261125.md)을 근거로 사후 결과를 기록한다. 스토어가 Git SHA를 직접 제공한 것은 아니며 버전·빌드·산출물·소스를 연결한 기준이다.

<!-- release-record -->
```json
{
  "version": "1.0.6",
  "build": 88,
  "source": "08345b69b1d71c9038be50767bd849a7354d2b8e",
  "branch": "codex/operations-commercial-20261113",
  "last_verified": "2026-11-25",
  "evidence": "project-cross-review-20261125.md",
  "platforms": [
    {
      "platform": "ios",
      "version": "1.0.6",
      "build": 88,
      "source": "08345b69b1d71c9038be50767bd849a7354d2b8e",
      "state": "RELEASED",
      "released_on": "2026-11-18"
    },
    {
      "platform": "android",
      "version": "1.0.6",
      "build": 88,
      "source": "08345b69b1d71c9038be50767bd849a7354d2b8e",
      "state": "RELEASED",
      "released_on": "2026-11-17"
    }
  ]
}
```

|단계|iOS|Android|
|---|---|---|
|IMPLEMENTED / TESTED / BUILT|11/17 기록,2632 PASS/9 SKIP,서명 IPA|동일,서명 AAB|
|UPLOADED / SUBMITTED / APPROVED|실제 단계별 날짜 미확인|실제 단계별 날짜 미확인|
|RELEASED|1.0.6(88),11/18|1.0.6/versionCode88,11/17 10:17 콘솔 표시|

출시 결과를 확인했다고 미실시 QA를 PASS로 바꾸지 않는다. 이후 스토어 변경 가능성은 새 업로드·출시 준비 직전에 재확인한다.

### Build88 최종 포함 기능

기존 [85 포함표](app-release-105-readiness-20261115.md), [87 변경](app105-build87-release-20261116.md), [운영 기능](operations-commercial-20261113.md), [전체 Flutter 비교](project-cross-review-flutter-files-20261125.md)를 교차했다. 다음은 출시 소스에 포함된 기능이며 모든 실기기 흐름의 검증 완료를 의미하지 않는다.

|포함 기능/수정|Git 근거|
|---|---|
|PDF 빈 화면 수정: 다운로드 하단 Column 최소 높이|08345b69|
|PDF 다운로드·MY 다운로드 이력·학년도 검색|4e433f47/c0aed176|
|학습 과목·목표·주간/월간 요약|c0aed176|
|기존 학교 순위 TOP10|APP83 이전,main84와88 공통|
|수시 지원 수정·삭제·MY 요약 갱신|66ff682f|
|앱 행동 계측 코드|103c35db;전 이벤트 수신 QA와 구분|
|닉네임20graphemes·기존 공백 보존|d2d142e7/8910ae31|
|자료·저장·최근·MY·LAB 오류 안내/재시도·계정 전환 보완|d0e9a94d 및 비교 목록|
|LAB BETA 표시/만료 배너 숨김·홈 대학뉴스 보류|d0e9a94d/077d6654/a89e4863|

### 제외·미출시·알려진 문제

- 자동 입시 D-Day와 무료2 안내는88 미포함. [1.0.7+89](app-release-89-preparation-20261125.md)에 구현·빌드됐으나 실기기 QA/정책 적용/스토어 제출이 남았다.
- 학교 추가 순위 페이지·백분위는 미활성. 홈 대학뉴스는 의도적으로 숨김. 기존 수동 D-Day는 유지한다.
- 부분 재생성/신규 재시도 상한은 Backend 구현·비활성 상태이며 APP 출시 기능으로 세지 않는다.
- Android 실제 파일 저장·88→89 업데이트·세션/타이머 복구·OS별 전체 계측 수신은 미검증 범위가 남는다. 현재 진행 상태는 current-status를 따른다.

### 11/17 빌드 당시 원문 (역사)


## 범위·Owner 지시

1.0.5(87) 출시 후 다운로드 가능 자료의 앱 내 PDF가 흰 화면이고 다운로드는 성공한다는 보고. Owner 지정 자료는 **2026학년도 수능**이다. 11/17 후속 지시로 QuickTime/실기기 화면 확인을 중단하고 수정·테스트·빌드를 우선한다. 스토어 업로드/업데이트는 Owner 담당. 결제 PAUSED, Finance, Credit Ledger, 회원 권한, 학습·이용권·평가 기록 변경 없음.

기준 앱 Git `077d66543dbc3a71b397c37872049e34b8370983`, 브랜치 `codex/operations-commercial-20261113`. App Store Connect TestFlight의 최신 표시 빌드87 및 배포 준비됨, Google Play production **87(1.0.5),100%**를 직접 읽음. 신규1.0.6(88) 준비. 스토어 제출/운영SQL/서버 배포 없음.

## 재현·확정된 코드 결함

다운로드 도입 `4e433f47a4e7a1290c5c586c3f3b0ab75e29e027`에서 `PdfDownloadAction`을 `PdfViewerPage.Scaffold.bottomNavigationBar`에 연결했다. 해당 action의 `Column`은 기본 `mainAxisSize.max`여서 하단 영역이 화면 전체 높이를 점유한다. `ALLOWED`에서만 이 Column을 표시하고 `VIEW_ONLY/PENDING`에서는 축소 위젯을 반환한다.

- 수정 전 위젯 테스트: **ALLOWED PDF 본문 높이0**, VIEW_ONLY/PENDING 정상. 기존 오류 패널 존재 여부 검사는 통과했지만 실제 화면 공간은 확인하지 못했다.
- 수정 전 Android API36 에뮬레이터: 동일한 합성3페이지 PDF의 문서 로딩 성공. VIEW_ONLY PASS, ALLOWED 뷰어 높이0으로 FAIL. 파일 로딩 실패와 화면 공간 소실을 분리하여 재현했다.
- 최소 제품 수정: `pdf_download_action.dart` Column에 **`mainAxisSize: MainAxisSize.min` 한 줄**. 다운로드 준비/취소/완료 안내를 포함한 내용만큼 높이를 사용한다.
- 실제 iPhone 스토어 화면 직접 관찰은 NOT TESTED. 미러링 대상이 다른 기기였고 USB QuickTime 확인 중 Owner가 중단 지시했다. 실제 기기 결과를 에뮬레이터로 대체 주장하지 않는다.

## 운영 파일 A/B 읽기 검증

운영 데이터 쓰기 없이 public policy와 resolver/download endpoint를 읽었다. 인증값·서명URL 전체는 출력/기록하지 않았다. GET은 리다이렉트 비허용. 아래 값은 조회 당시 응답이다.

|자료|resource ID|정책|열람 GET|다운로드 GET|
|---|---|---|---|---|
|2026학년도 수능 물리학1 문제|2d1088aa-fa58-5cab-9257-994a842ed8cf|ALLOWED|200 /1,584,531바이트/%PDF-|200/동일 크기·동일 SHA256|
|2026년5월 고3 물리학1 문제|7d58444c-5efe-535e-88f3-45bcdec9362b|PENDING|200/648,970바이트/%PDF-|정책상403|

두 열람 응답 모두 host blog.kakaocdn.net, Content-Type application/octet-stream, Content-Disposition attachment, Content-Range 없음. JSON/HTML이 아닌 PDF magic 확인. 첫 자료의 열람·다운로드 SHA256은 `7316cea95d7850f94d9f4aa7bbc200a2dae16308235bf47ebeb618681a23ff78`로 일치한다. URI 동일성을 가정하지 않고 각각 resolver/resource-download로 발급받아 별도 요청했다. HEAD/Range 요청, 장기 URL 만료·네트워크 변경은 NOT TESTED.

열람은 기존 resolver → 메모리 PDF 바이트 → pdfrx2.6.5 경로, 다운로드는 별도 권한확인 → PDF magic/해시 확인 → 네이티브 저장 경로다. 다운로드 가능 여부가 열람 URL/파일 경로를 바꾸지 않는다. 파일은 정상 로딩되지만 하단 레이아웃이 본문을 없애므로 다운로드만 성공할 수 있다.

서버 응답/헤더를 바꿔도 이미 설치된 Flutter의 Column 높이를 고칠 수 없다. 정책 비활성화는 다운로드 기능을 없애므로 채택하지 않았다. **다운로드 유지 복구에는 앱 업데이트가 필요하다.** 서버 변경 없음.

## 검증 기록

- 수정 전 로그: `/private/tmp/pdf-policy-viewport-red.log`, `/private/tmp/pdf-native-red.log`.
- 관련 위젯/다운로드/신뢰 resolver 테스트40 PASS(추가 보강 전1차).
- 수정 후 Android API36 네이티브 최종2 PASS: 열람 전용/허용 각각3페이지 파싱·첫/중간/마지막 페이지 render,실제 뷰어 높이,다운로드 바이트 전달·완료 안내 후 본문 공간,화면 폐기 후 재열람. `/private/tmp/pdf-native-final.log`. 실제 저장 UI는 mock이며 실기기 화면 관찰과 구분한다.
- 다운로드 saver는 자동화에서 test double이며 실제 Android 파일 저장 UI 검증과 구분한다.
- 실제 iOS/Android 사용자 흐름, 기존 앱 업데이트 설치·세션/저장/최근/학습 보존, 로그인별·오프라인·네트워크 전환·확대축소 회귀는 NOT TESTED. 제품 로직·데이터 경로 미변경과 실제 실행 검증을 구분한다.
- 최종 테스트/서명 산출물 결과는 아래에 갱신한다.

## 스토어 문안

일부 학습자료의 PDF가 빈 화면으로 표시되는 문제를 수정했습니다. PDF 열람과 다운로드를 함께 이용할 수 있습니다.

Apple 긴급 버그 수정은 신속 심사 요청 대상이 될 수 있으나 승인/소요시간 보장은 없다. Owner 제출 시 재현 단계(다운로드 허용 수능자료→PDF 열기→빈 화면)와 최소 수정 설명을 첨부한다. [Apple App Review](https://developer.apple.com/distribute/app-review/). 실제 요청은 하지 않았다.

## 산출물·최종 검사

- iOS Store IPA: `build/releases/app106-88/legendstudy-1.0.6-88.ipa`,1.0.6/88/com.legendstudy.app 확인. codesign deep/strict PASS, get-task-allow=false,프로파일 만료2027-10-19. SHA256 `8923142907070624e92313eea11a2de2b5d9de0819dc00b072e924fc86b0554b`.
- 정적 분석: No issues found. Wiki handoff PASS. 기존87산출물 보존.
- 제품 코드 변경은 Column 한 줄과 pubspec 버전만. 추가 수정 없이 서버·결제 설정 보존.
- 전체 Flutter 회귀: **2632 PASS /9 SKIP /0 FAIL**, `/private/tmp/pdf-hotfix-full-test.log`. 기존2629에서 정책별 공간 테스트3개 추가. 신규 실패0.
- Android AAB: `build/releases/app106-88/legendstudy-1.0.6-88.aab`, protobuf manifest versionName1.0.6/versionCode88 확인,jarsigner verified. SHA256 `8dbdbd8ede598830dc0cb6742ecd72221c9a56e8674f879088320df4aee05215`.
- 상태: 수정/자동화/서명 빌드 DONE, 실제 기기 최종 검증 NOT TESTED, 운영 복구는 Owner 스토어 업데이트 전까지 PARTIAL. 업로드/심사 제출0. SDK/Kotlin/기존 Cupertino font 경고는 빌드 실패와 구분하며 이번 긴급 수정에서 의존성 변경 없음.
- 산출물 폴더의 RELEASE-NOTES.txt 및 SHA256SUMS 제공. 최종 Git HEAD는 본 문서를 포함하는 커밋과 인계 보고를 참조한다.
