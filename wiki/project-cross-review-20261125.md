# 2026-11-25 프로젝트·운영·스토어 교차 검토

## 범위와 판정 기준

Owner 요청에 따른 읽기 전용 조사 및 후속 계획이다. 조사 시각은 2026-11-25 약 21시 이후 KST. 코드·설정·운영 데이터 변경, 학생 첨삭 재실행, 결제·환불, 배포·스토어 제출은 하지 않았다. 이 문서와 Wiki 연결만 변경한다. DB 조회는 `BEGIN READ ONLY` 안에서 수행했다. 원문 답안·회원 이메일·인증값은 보고서에 수록하지 않는다.

DONE=해당 범위 실제 확인, PARTIAL=구현/일부 검증과 남은 작업 공존, BLOCKED=접근/승인 등 구체적 차단, NOT TESTED=실행 증거 없음, READY FOR RELEASE=출시 게이트 충족, PLANNED=설계/후속 후보. 구현 완료를 운영 활성화나 스토어 출시로 바꾸어 쓰지 않는다.

## 1. Git 및 실제 운영 배포 — DONE

|대상|확인한 기준|해석|
|---|---|---|
|현재 APP/SQL/Worker 조사 checkout|`6bd46f98cd36a3147be9f7f7bd41ed16e9349ed1` / `codex/material-service-app-20261022`|11/22 복구 수정 기록; 최신 Flutter 출시 기준과 다른 branch|
|APP origin/main|`02996bed2234104e0904ec698db06cc5a8c8649c`|1.0.4+84, 실제 스토어보다 오래됨|
|APP 실제 출시 소스 연결 기준|`08345b69b1d71c9038be50767bd849a7354d2b8e` / `codex/operations-commercial-20261113`|1.0.6+88, PDF 수정 포함|
|WEB|`4e8654378abc0b181ff0f902947b72af0c6c127f`|Pages canonical `f1882082-9950-46cc-9f2c-fd35a17e9d4d`, success, 11/22 21:52 KST|
|Essay Worker|version `29f4f6cc-433f-4e8e-8da4-9ca5710f2e71`, 100%|11/22 21:52 배포; `a9bedebb` 수정 포함 실제 모듈 확인|
|Finance Worker|version `d14a757e-5b46-448c-8b66-325d181c2a9f`, 100%|11/17 배포; 자동 갱신 성공 자체의 증거는 아님|
|Supabase|`stlhijzpjfgwwdgunlsd`|운영 복구 함수·ACL·trigger postcheck PASS|

APP/WEB remote fetch 후 조사한 refs에는 11/23~25 신규 commit이 없었다. Cloudflare canonical WEB/Essay Worker 역시 11/22 배포본이다. 배포 파일 존재만으로 판정하지 않고 API의 active version/canonical deployment와 실제 Worker 다운로드를 대조했다. 기존 checkout의 미커밋 코드·문서는 이번 개발 완료물로 간주하지 않고 그대로 보존한다.

11/22 변경 흐름: `9bffbc0` Provider 진단 → `685e772` 정확 인용 위치 보정 → `5cf2f4b` fenced recovery/opt-in 품질 수정 → `a9bedeb` 운영 transport 초기화 수정 → `6bd46f9` 검증 기록. WEB `84c3f84a` 대시보드, `75397907` 복구, `4408c3e` 연결 허용 목록, `4e865437` runtime 오류 구분. 상세 근거: [런타임 수정](admin-recovery-runtime-fix-20261122.md), [대시보드](lab-dashboard-implementation-20261122.md).

## 2. Wiki와 실제 상태 불일치

|기존 기록/오해 가능 지점|교차 검증 결과|처리|
|---|---|---|
|APP84 HOLD·스토어 제출 대기|양 스토어 build88 실제 출시|이 문서의 출시 확인이 과거 제출 대기 기록을 갱신함|
|main이 최신 출시 코드라는 가정|main은 출시 commit의 조상, 28 commits 뒤처짐|main 기준 diff를 신규 기능 목록으로 사용 금지|
|복구 기능 배포=대상 요청 완료|대상은 여전히 reserved, q0만 완료|기능 DONE과 실제 복구 PARTIAL 분리|
|부분 재생성 코드 존재=운영 활성|운영 flag 없음, 기본 false|구현 완료/비활성 유지|
|DB 문항 is_published=false=공개 자료 없음|실제 공개 허용·browse·runtime policy는 별도 계약|각 범위를 아래에 따로 집계|
|11/15 analytics/학습/MY 문서의 미출시 표기|해당 코드가 08345b69에 포함되어 build88 출시|재개발 대상에서 제외, 미실시 QA만 남김|
|Finance 자동 갱신 배포=11/23 자연 갱신 성공|성공 로그는 별도 확인 필요|배포/flag만으로 성공 확정 금지|

현재 checkout의 오래된 Product state·10월 작업 중단 문구는 당시 이력이다. 최신 판단은 본 문서, 실제 운영 증거, 해당 기능의 최신 feature 문서를 우선한다. branch 간 Wiki가 분산되어 있으므로 다음 출시 준비에서 main/출시 branch 정리를 먼저 한다.

## 3. 긴급 요청 03629605 — PARTIAL

대상 `03629605-9a58-4b78-8465-c5331ac1b1c7`은 **실제 첨삭 미완료**다.

|항목|11/25 읽기 검증|
|---|---|
|상태|reserved, 최초 11/22 01:31:23 KST|
|잠금|11/22 01:46:26 KST 만료|
|완료|q0 1개; MD5 `18da60ecf6c80ead27ca16b33454db41`, 11/22 기록과 동일|
|미완료|q1 reconciling, 저장 가능한 최종 output 없음|
|복구 실행|새 attempt/복구 감사 기록 없음, 이전 제출이 정상 실행된 증거 없음|
|이용권|included_revision, 필요0, 연결 credit transaction0|
|runtime 수정|운영 `AsyncOperatingTransport` origin 보관 결함 수정본 확인|
|DB 설치|복구 함수/ACL/trigger 검사 및 기존 RPC 정의 보존 검사 PASS|

RUNTIME_UNAVAILABLE 원인은 운영 부모 transport가 `origin`을 보관하지 않아 첫 RPC 전에 발생한 AttributeError였다. 이전 WEB 허용 목록 누락과 별개다. 수정·배포·비파괴 진단은 완료됐지만 실제 q1 복구 성공은 NOT TESTED다. 현재 15분 지연 후보를 훨씬 넘고 lease도 만료됐지만 UI 처리 중 건수만으로 Provider가 지금 실행 중이라고 해석하지 않는다.

후속: Owner가 q1 1회 복구를 다시 승인하면 즉시 조건 재검증 → 기존 관리자 복구 → q0 불변·q1만 실행·attempt 소유권·결과2/2·추가 차감0·감사 기록 확인. 실패/응답 불확정 시 반복 금지. 이번 조사에서는 실행하지 않았다. [복구 배포](admin-run-recovery-deployment-20261122.md), [실패 제출](admin-recovery-q1-execution-20261122.md), [해결](admin-recovery-runtime-fix-20261122.md).

## 4. 논술 LAB 최신 운영 — DONE / 제한 명시

기간: **11/19 00:00 KST~11/25 조사 시점**, 요청 생성 cohort. 과거 11/16~22 스크린샷과 기간이 다르다.

|지표|실측|
|---|---:|
|요청 / 완료 / 실패 / reserved|12 / 11 / 0 / 1|
|완료율|91.7%|
|완료 요청 최초 요청→완료 평균|417.03초, 약 6분57초|
|중앙값|173.64초, 약 2분54초|
|재시도 사건 / 경험 요청|12 / 6|
|11/23~25 신규 요청|0|
|활성 처리 중 / 재시도 대기|1 / 0|
|논술 미처리 학생 피드백 / 보관 요청|0 / 1|

일반 서비스 feedback_submissions와 논술 피드백은 모집단이 다르다. 일반 피드백 new7을 논술 미처리7로 보고하지 않는다.

|요청 ID 앞8자리|최초 요청 KST|완료 소요 초|재시도|
|---|---|---:|---:|
|79e4168f|11/20 14:23|201.44|1|
|d9714b6f|11/20 22:19|173.64|1|
|b0cd5b26|11/21 03:10|100.17|0|
|56e42287|11/21 16:44|417.22|1|
|79788b36|11/22 00:14|444.29|3|
|03629605|11/22 01:31|미완료|0|
|c37166d0|11/22 02:38|95.01|0|
|4dcb49e5|11/22 09:51|183.55|1|
|741c72ae|11/22 11:29|2666.25|5|
|789c1739|11/22 16:32|94.17|0|
|b609cfcc|11/22 16:54|49.82|0|
|0777eb9b|11/22 17:53|161.79|0|

11/22 분석의 독립 검토 미승인8 + 정확 인용 거절4 =12건이며, 이번 DB 조회에서도 총12·6요청이 유지된다. 6요청 모두 현재 완료: 복구 성공6. 다만 재시도마다 AI 생성/독립 검토 호출 수는 1:1이 아니므로 12건을 추가 Provider 호출12회로 환산하지 않는다. 과거 9요청 자료의 60 receipts/입력1,114,395·출력153,581 tokens는 [품질 후속 문서](essay-quality-followup-20261122.md)의 당시 cohort 값이다. 이번 12요청 전체의 Provider 사용량·청구액은 새로 확정하지 않았다. `essay_ops_private.calls`에 해당 기간 행이 없다는 것 역시 AI 호출0의 증거가 아니다. checkpoint receipts가 따로 있다.

완료11건 모두 답안 수와 결과 문항 수 일치. 유료 완료9건은 각 필요1·settled·예약/정산 두 원장행의 순차감1/예약잔량0, 무료 재첨삭 완료2건은 필요0·원장0. 대상 미완료 무료 재첨삭도 필요0·원장0. 조사한 cohort에서 중복 차감/완료 결과 누락 증거 없음. 전 기간 모든 원장의 무결성 인증은 아니다. 과거 보관 e7af 요청의 예약 해제는 이번 범위에서 실행하지 않았고 별도 승인 대상으로 유지한다.

## 5. 대학 자료 — PARTIAL, 집계 계약 분리

|범위|대학|시험|문항|주의|
|---|---:|---:|---:|---|
|WEB 공식 대학 카탈로그|42|—|—|42개 모두 universityId 필드 존재|
|DB 전체 essay_exams/questions|26개 university ID|478|1316|합성 검증용 대학/시험1개 포함; 실제 대학25|
|stable essay_browse_catalog 결과 합계|25|448|1284|메타데이터 조회; evaluationReady=false는 이 RPC의 고정 반환값|
|운영 Pages ESSAY_PUBLIC_EXAMS 허용 목록과 DB join|16|374|956|현재 공개 scope, 모두 DB 존재; 모든 문항 실제 Provider 실행 검증을 뜻하지 않음|
|실제 Worker REGISTRY asset|24|282|722|배포된 registry 목록; 공개 scope와 다른 모집단|
|DB runtime_policy 존재|16|234|567|정책 존재; 이용자 권한·package 검증 등 추가 조건 필요|
|review.runtimeApproval APPROVED|—|233|562|승인 문항 배열 기준; VERIFIED state만 세면 오집계|

공개 허용374건을 곧바로 첨삭 가능한374건이라고 발표하면 안 된다. runtime policy/Worker registry/수학 경로/권리·package 승인 및 UI policy를 교차해야 한다. 전수 실제 제출은 이번 조사 범위가 아니므로 **최종 학생 화면 공개·첨삭 가능 교집합 전수 QA는 NOT TESTED**다.

자료 browse 0인 대학17: 강남·경기·국민·단국·덕성여·동덕여·삼육·상명·서경·서울과기·성신여·수원·신한·을지·한국공학·한국기술교육·한신. UUID 필드 누락이 아니라 자료 미등록/미연결 범위다. 기존 WEB의 준비 중 카드16개와도 정의가 다르다.

RIGHTS_HOLD: [자연계 공개 집계(ba2039e5 기준)](https://github.com/LC3808/legendstudy-app/blob/ba2039e5/wiki/essay-natural-publication-summary-20261112.md)는 대상221문항 중 공개178·공식HOLD6·권리HOLD15·미준비22를 기록한다. 권리HOLD15는 성균관5시험, 미준비는 경희16/서울여6, 공식HOLD는 항공5/숭실1. 이는 그 문서의 자연계 cohort이고 전체 운영 수치가 아니다. 최신 reviews JSON에 RIGHTS_HOLD 문자열0이라는 사실은 권리 해소0/전체해소 어느 쪽의 증거도 아니다. 최신 권리 증거별 재대조는 남아 있다. 후속 이화87문항 연결도 있으므로 11/12 문서의 이화0을 현재 수치로 재사용하지 않는다.

추가 우선순위: 운영 검증 일정에 남아 있는 아주 12/05, 인하 12/06 대비 현재 공개 자료의 공식 원문·권리·계열/모집단위 커버리지부터 점검. 그다음 12/18 최초합격 발표 D-Day. 날짜는 기존 VERIFIED 일정 기준이며 이번에 공식 PDF 개정 여부까지 새로 인증하지 못했다. 대학 전체 남은 시험일정 전수 우선순위는 최신 공식 공고 확인 후 확정한다. 날짜 추정·새 자료 등록은 하지 않았다.

## 6. 마지막 iOS / Android 출시 — DONE

Owner 로그인 후 실제 App Store Connect 및 Google Play Console에서 확인했다.

|플랫폼|실제 출시|출시일|확인|
|---|---|---|---|
|iOS|버전1.0.6, build88 (표시명 1.0.6(88))|2026-11-18|ASC 배포 준비됨·build88 연결 + 공개 App Store 버전 기록|
|Android|1.0.6 / versionCode88|2026-11-17 10:17, 콘솔 표시|Production, Google Play 제공됨, 100%, 178/178개국|

공개 iOS: [App Store](https://apps.apple.com/kr/app/id6820826957). ASC 앱6820826957, Play 앱4972317086113621808의 실제 배포 화면을 대조했다. iOS의 정확한 시간은 미확인. Git SHA는 스토어가 직접 제공하지 않으므로 버전/빌드·빌드 문서·소스를 연결한 기준이며 업로드 바이너리의 Git SHA를 스토어에서 독립 증명한 것은 아니다.

마지막 PDF 수정은 **08345b69**의 `pdf_viewer_page.dart` Column `mainAxisSize: MainAxisSize.min`이다. [PDF hotfix 기록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/pdf-white-screen-hotfix-20261117.md), [build87 기록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/app105-build87-release-20261116.md). 당시 테스트2632 PASS/9 SKIP 및 서명 IPA/AAB 기록은 과거 증거이고 이번에 재빌드하지 않았다.

Play Console의 결제 계정 확인 필요 경고도 관측됐다. LegendStudy 실결제 장애를 의미하는지 확인되지 않았으며 Owner가 계정 알림의 적용 범위를 확인해야 한다. 다른 앱의 정책 알림을 LegendStudy 장애로 전용하지 않았다.

## 7. 출시 이후 Flutter 전체 변경

`git merge-base --is-ancestor origin/main 08345b69` 성공. main→08345b69 28 commits. 반대 방향 `git diff 08345b69 origin/main -- lib ios android assets pubspec.yaml pubspec.lock`는 **47파일(+127/-1023), lib45 + pubspec2, ios/android/assets0**이다. 이것은 main이 오래되어 나타나는 되돌림 차이이며 신규 미출시47파일이 아니다. [전체 파일 목록](project-cross-review-flutter-files-20261125.md)에 빠짐없이 기록한다.

|기능|분류|근거/남은 범위|
|---|---|---|
|PDF 빈 화면 수정|A 이미 출시|08345b69, build88|
|PDF 다운로드·MY 다운로드 내역|A 이미 출시 / C 기기 QA 잔여|4e433f47; 양OS 실파일·권한/저장 위치 QA|
|학습 과목·목표·주간/월간 요약|A 이미 출시 / C 백그라운드 QA|c0aed176; 실제 재시작·타이머 동기화 QA|
|학교 순위 UI/기존 TOP10 조회|A 이미 출시|APP83 이전, main과88 모두 포함; 신규 기능으로 다시 등록하지 않음|
|순위 추가 페이지·개인 백분위|D 미완성|운영 student_school_ranking_page/my_study_percentile 없음; 기존 fallback 유지|
|수시 지원 요약 갱신·기존 기록 접근·삭제 UX|A 이미 출시|66ff682f|
|앱 사용 행동 계측|A 코드 출시 / C 수신 QA|103c35db; 전 이벤트 OS별 수신·중복·오프라인 QA 별도|
|자료 검색·북마크·최근·MY·LAB 결과/진행 UX|A 이미 출시|d0e9a94d 및 release 전체 diff 포함|
|닉네임20 graphemes·기존 공백 보존|A 이미 출시|d2d142e7/8910ae31|
|홈 대학 뉴스 보류·만료 베타 배너 숨김|A 이미 출시|a89e4863/077d6654; 의도된 보류를 복구할 기능으로 오인 금지|
|자동 입시 D-Day 배지·삭제/복원|B 구현 완료·미출시 / C 통합 QA|6cd4c1a7, Flutter6파일+테스트1; main/88에 없음|
|관리자 복구·대시보드·인용 보정·부분 재생성|E WEB/Backend|5cf2f4ba/a9bedebb/WEB4e865437; 자동으로 스토어 기능 변경이 되지 않음|
|미커밋 OCR/수리/카탈로그 등|D 또는 미확인|현재 dirty 작업의 완료·승인·출시 증거 없음; 이번 변경으로 합치지 않음|

전체 refs의 11/17 이후 `lib ios android assets pubspec*` 변경 commit 검색에서 PDF88과 D-Day6cd4c1a7를 확인했다. 문서·테스트만의 변화는 별도이며 새 사용자 기능으로 세지 않는다. iOS/Android 출시 baseline은 이번에는 동일88이다.

## 8. 신규 스토어 업데이트 제안 — PARTIAL, 아직 READY FOR RELEASE 아님

핵심 신규 범위는 **자동 입시 D-Day**다. 이미 출시된 학교 순위·학습·MY·PDF 개선을 새 기능으로 다시 구현하지 않는다. 운영 DB는 공식 일정15(VERIFIED 공개10/PENDING 비공개5), 연결 MATCHED12/PENDING5, preferences ACTIVE12/CANCELLED5가 확인된다. CANCELLED5를 학생이 삭제한5건으로 단정하지 않는다. WEB 운영 구현과 Flutter 미출시를 구분한다. [구현/운영 계약](admissions-dday-implementation-20261120.md).

출시 기준83... release branch를 보존하고 D-Day의 Flutter 변경만 선택적으로 통합한다. 현재 오래된 task branch 전체를 main에 덮어쓰면 build88 기능이 후퇴할 수 있다. 먼저 main을 실제 출시 소스와 정합하게 만들 계획을 검토하고, 그 위에서 D-Day provider/model/card 충돌을 해결한다. 이번에는 merge하지 않는다.

후보 버전 **1.0.7+89**: 현재 출시88 기준 제안이며 TestFlight/Play 내부 트랙의89 사용 여부를 빌드 전에 확인해야 한다. 새 기능 안내 초안: “수시 지원 기록에 맞는 확인된 입시 일정을 D-Day에서 확인할 수 있어요. 자동 일정은 숨기거나 복원할 수 있으며, 직접 등록한 일정은 그대로 유지됩니다.” 검증 후 최종 문구를 확정한다.

## 9. 출시 전 QA 및 전체 도메인 미완료

|영역|상태|남은 작업과 완료 기준|
|---|---|---|
|D-Day APP|PARTIAL|출시88 위 통합, 기존 홈 대표1+근접2/더보기 유지, KST경계·비공개5 제외·중복방지·삭제후 재동기화/날짜변경/복원·정시제외·계정전환 QA|
|iOS/Android 출시|NOT TESTED|양OS build88→후보 삭제 없는 업데이트, PDF/자료검색/다운로드/로그인/계정삭제/학습/수동일정 회귀, 스크린리더/큰글자/작은화면|
|관리자 복구|PARTIAL|설치·연결 수정 DONE, 실제 q1 복구 별도 승인 후1회 검증|
|정확 인용 보정·완료문항 재사용|DONE|11/22 운영 배포됨; 다시 구현하지 않음|
|부분 수정2+전체1·상한|PARTIAL|코드/격리시험 완료, 운영flag false. 실제 품질·시간·토큰 개선은 NOT TESTED; Owner 활성화 승인 필요|
|Evidence ID|PLANNED|기존 인용 검증 완화 없이 원문 근거 ID 설계; 전체 도입 증거 없음|
|수리/OCR/스캐폴딩|PARTIAL/BLOCKED|기존 격리 Preview·인식 공개 통제 검증과 운영 활성화를 구분; 손글씨 실기기/권리/정답 공개 QA 후 별도 승인|
|학교 순위|PARTIAL|기존 UI DONE, 페이지/백분위 RPC 설계·승인·설치 및 최소 표본/개인정보 기준 QA|
|학습 관리|DONE 구현·출시 / NOT TESTED 일부 QA|타이머 백그라운드/재시작·과목/목표 동기화 기기 QA; 기본 학습 재구현 불필요|
|수시 지원·자동 일정 WEB/DB|DONE 설치 / PARTIAL 전체 E2E|15/10/5·연결12 확인; 실제 학생 MY12카드·삭제복원 end-to-end는 학생 데이터 변경 없이 시험계정 QA 필요|
|결제·이용권|DONE 설정/최근 cohort 정합성|LIVE/public/enabled 유지; 전체 실결제·환불 회귀는 이번 NOT TESTED, 실행 승인 별도|
|Finance|PARTIAL|자동갱신 배포/flag ON; 11/23 자연갱신 성공 기존 로그 확인 필요|
|앱 분석·관리자 분석|DONE 구현/출시·WEB / PARTIAL 계측 QA|GA4 신규 이벤트 iOS/Android 수신·오프라인·옵트아웃·속성 보존 검증. SDK 배포를 실제 수신 인증으로 오인 금지|
|학업 데이터·추천/컨설팅/B2B|PLANNED|장기 전략, 역사/주체/척도/동의/테넌트 경계 검토 선행; 현재 추천 정확도/제품 출시 인증 없음|
|커뮤니티·배지·대학뉴스 확장|PLANNED/보류|기존 Owner scope 유지, 신규 업데이트에 끼워 넣지 않음|

근거: [품질 후속](essay-quality-followup-20261122.md), [재시도](essay-retry-quality-20261122.md), [수리 기술](math-technical-review-20261026.md), [인식 공개 통제](task16e-recognition-disclosure-p0-20261102.md), [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md), [운영 상용화 기록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/operations-commercial-20261113.md), [분석 구현](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/app-usage-analytics-implementation-20261115.md).

Finance 상태조회 주의: 기존 `statusOnly=true` 경로도 alarm/state 갱신 및 만기 도래 시 renewal을 수행할 수 있어 이번 읽기 전용 조사에서 관리자 ‘인증 상태 확인’을 누르지 않았다. Cloudflare 배포 API는 성공했지만 telemetry query는403이었다. Owner가 로그인 진행 의사를 알려주었으나 마지막 화면 확인 및 reload 후에도 로그인 화면이 유지되어 기존 로그에 접근하지 못했다. **11/23 자연갱신 성공은 미확인/BLOCKED**다. 배포를 재실행하거나 인위 갱신하여 자연갱신 증거를 만들지 않는다. 로그인 세션 확보 후 기존 로그만 추가 확인하면 된다.

## 10. 오늘 P0 / 빠른 P1

시간은 작업량 계획 추정이며 처리시간 개선 실측치가 아니다.

|순위|현재 상태|실행 가능한 다음 단계|예상|선행/승인|
|---|---|---|---|---|
|P0 q1 중단 요청|PARTIAL|직전 조건 재확인→관리자 복구1회→q0/원장/KPI/감사 확인|30~60분+Provider 대기|실제 재실행 Owner 승인|
|P0 Finance 자연갱신|BLOCKED 로그 접근|11/23~25 기존 success/failure/expiry 로그 확보. 실패 증거 있을 때만 원인별 조치 계획|30~60분|로그 접근; 갱신/설정 변경은 별도 범위|
|P1 앱 출시 기준 정리|PARTIAL|main/release/task branch 차이 검토,88기준 보존·D-Day만 통합|2~4시간|후속 개발 지시; 이번 merge0|
|P1 D-Day 앱 QA/출시 준비|PARTIAL|위9절 양OS QA→회귀→서명→스토어 문구|1~2일|출시 기준 정리, 시험계정/실기기; 제출 별도 승인|
|P1 Play 결제 계정 경고|미확인|Owner가 적용 계정·마감·필요 확인 항목 확인|15~30분|Owner 콘솔 조치; 결제 실행 아님|

## 11. 이번 주 P2 / P3

|순위|현재 상태|남은 일/대안|예상|선행/승인|
|---|---|---|---|---|
|P1 아주·인하 자료 커버리지|PARTIAL|12/05·06 대비 공식문서/계열/권리/공개 교집합 전수 확인, 부족분만 후보작성|0.5~1일 조사+자료량별|공식 최신 일정 확인; DB/공개 승인 별도|
|P2 품질 부분 재생성|PARTIAL 비활성|기존 재현가능 fixture로 점수·근거 정합성/거절 유지/토큰 비교, 활성화 여부 제안|1~2일|실학생 재실행 없이; flag승인|
|P2 순위 확장|PARTIAL|기존 TOP10유지, 페이지·백분위 최소 SQL/권한/표본 설계|1~2일|DB migration Owner 절차|
|P2 분석 QA|PARTIAL|양OS 각 행동→GA4→관리자 보고서 연결, 비활성/재전송 검사|0.5~1일|시험계정/기기, 개인정보 최소화|
|P2 Wiki/branch 현황 정리|PARTIAL|출시 문서 과거 HOLD와 현재 상태 연결, 다른 작업 dirty 보존|0.5일|출시 source baseline 확정|
|P3 Evidence ID·OCR·종단 분석|PLANNED/PARTIAL|작은 검증범위부터, 기존 기준/역사 보존, 신규수집/권리/비용 승인 분리|각1~3일 설계 후 재산정|Owner 제품 범위·데이터 정책|

## 12. 승인 경계 및 조사 검증

이번 조사로 새 개발·운영 조치를 승인받은 것으로 간주하지 않는다. 추가 승인 대상: q1 실제 복구, 부분 재생성/상한 활성화, 신규 DB/RPC 설치, 자료 공개/권리 처리, 새 앱 스토어 제출, 예약 해제/원장·결제 조치. 문서 Commit·Push는 이번 요청에 포함되어 있다.

이번 수행: remote fetch/Git ancestry·전체 Flutter diff, 실제 양 스토어 출시 화면, 운영 Pages/Workers 버전·설정·Worker 모듈, Supabase readonly 집계·복구 postcheck, 기존 결과 hash/원장 검증. 실학생 재실행·Provider 테스트호출·개발 코드 수정·운영 쓰기0. 과거 테스트 PASS는 해당 문서 날짜의 증거로 표기했으며 이번 신규 전체 Flutter/WEB 회귀를 실행했다고 주장하지 않는다.

보존 검토7답: (1) 이번 기록은 조사시점 스냅샷이며 과거 발생일과 분리 (2) Git SHA/배포 ID/쿼리 정의로 근거 재확인 가능하나 운영 데이터는 변할 수 있음 (3) 원본 UPDATE 없음 (4) 학생 식별체계 변경 없음 (5) Learning/Decision/Outcome 원본을 합치지 않고 운영 파생 통계만 기록 (6) 이메일·답안·비밀값 제외, 기존 권한 유지 (7) cohort/시각/집계 범위·미확인 명시. 후속 기능의 새 저장 설계는 별도 보존 검토가 필요하다.

재현 가능한 비식별 집계: [읽기 전용 DB 증거](evidence/project-review-readonly-20261125.json). `python3 tool/check_wiki_handoff.py` PASS(2,420개 내부 링크, current-status 11,372 bytes). 문서만 Commit·Push하며 기존 dirty 작업은 staging에서 제외한다.
