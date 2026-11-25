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

마지막 PDF 수정은 **08345b69**의 `pdf_download_action.dart` Column `mainAxisSize: MainAxisSize.min`이다. [PDF hotfix 기록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/pdf-white-screen-hotfix-20261117.md), [build87 기록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/app105-build87-release-20261116.md). 당시 테스트2632 PASS/9 SKIP 및 서명 IPA/AAB 기록은 과거 증거이고 이번에 재빌드하지 않았다.

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

## 13. Wiki 및 릴리스 관리 체계 감사 — 2026-11-25

**감사 DONE / 현재 상태 체계 보완 PARTIAL(Owner 검토 전).** 기존 문서를 재사용한다. 신규 canonical 문서 체계, AGENTS 개편, Git 병합, 제품 코드·DB·배포·스토어 변경은 하지 않았다. 이 절은 앞선 11/25 조사와 구별되는 사후 감사다. 기존 기록의 충분성을 판단할 때 이 절과 7ad4be9 이후 문서를 과거 근거로 사용하지 않는다.

### 13.1 조사 범위와 시간 경계

- 현재 조사 checkout `646c5239`, 교차검토 직전 `6bd46f98`(11/22 21:57 KST), 당시 main `02996bed`(11/13 10:56), 출시 연결 source `08345b69`(11/17 09:29)를 비교했다. Git 기록 시각은 author/committer metadata이며 외부 공증 시각은 아니다.
- 로컬 heads/remotes149개를 대상으로 `git log --all --before=2026-11-25T00:00:00+09:00 -G ... -- wiki`를 검색하고 버전/빌드/출시일/Git/브랜치 키워드를 교차했다. 대표 snapshot Wiki 파일은 main362, 출시381, 조사259개. 해당 파일 수 차이는 삭제 판정이 아니라 서로 다른 branch tree다.
- 원격 `ls-remote` 확인: main02996bed, APP작업76cc4050, 조사646c5239 일치. force/reset/fetch merge 없음. 삭제되거나 접근 불가한 원격 ref·Git에 없는 사적 기록까지 누락됐다고 단정하지 않는다.
- [재현용 Git 증거](evidence/wiki-release-audit-20261125.json). 실제 스토어 출시 증거는 앞선 §6의11/25 콘솔 조회를 재사용했으며 이번 감사에서 콘솔 재접속/출시 상태 변경은 하지 않았다.
- 사후 기록의 시작: `7ad4be9`(11/25 21:43) 교차검토, `61b17c5`(22:39) 통합후속/APP89, `646c5239` 품질V1. 이들은 당시 누락을 보강한 기록이지 과거 체계 정상의 증거가 아니다.

### 13.2 11/25 이전 기록 A–F 전수 대조

아래 접근성은 **그 시점·그 branch**의 index/current-status 기준이다. ‘없음’은 조사한 tracked Wiki 증거에서 찾지 못했다는 뜻이다.

|항목|A 존재 / B 경로 / C 기록 시점|D 당시 실제 내용|E 공식 경로 접근|F 누락·차이|
|---|---|---|---|---|
|APP1.0.6|있음: `pdf-white-screen-hotfix-20261117.md`,08345b69,11/17|신규1.0.6 준비·산출물 검증|출시 branch index/current 최상단 직접 링크|조사6bd/main029에는 없음; 실제 RELEASED 표시는 아님|
|Build88|같은 문서/commit|IPA1.0.6/88,AAB versionCode88,두 SHA256·서명 PASS|동일|빌드 기록은 충분, 배포 결과 미회수|
|iOS11/18 출시|이전 기록 발견 못함|88문서는 업로드/심사제출0·Owner 업데이트 전 PARTIAL|어느 대표snapshot에서도 복원 불가|11/25 §6에서 처음 실제 출시 확인을 연결|
|Android11/17 출시|이전 기록 발견 못함|87은100% 확인,88은 빌드/인계|동일|11/25 §6에서 versionCode88·100%·출시시각 확인|
|출시 기준08345b69|간접 존재: 해당 commit에 코드·Wiki·pubspec 결합|본문은 이전기준077d6654와 ‘본 문서 포함 최종HEAD 참조’|Git을 읽으면 해석 가능; 문서만으로 최종SHA 고정 불가|출시 바이너리→source의 명시적인 사후 연결은7ad4be9|
|출시된 기능 전체 목록|부분: `operations-commercial-20261113.md`(c0aed176),`app-release-105-readiness-20261115.md`(d0e9a94d),87문서(077d6654),88문서|기능별 변경/보존/QA와85→87→88 delta가 있음|출시 index에서 직접 또는상세1단계. 조사branch에는 최신파일 미포함|누적 ‘88 RELEASED 기능’ 단일목록 없음. 구현 PARTIAL/미배포 문구 잔류|
|미출시 Flutter 기능|부분: 기능별 문서|부분 QA와 미출시가 같은 PARTIAL에 섞임|branch별로 다름|전체 release대비 inventory 없음;11/25 전체diff에서 보완|
|자동 입시D-Day 미출시|있음: `admissions-dday-implementation-20261120.md`,6cd4c1a7/13cd1f3a,11/20|Flutter59검사·APP 실기기/스토어 NOT TESTED/NOT DEPLOYED,WEB/DB와 분리|조사branch index/current 직접 연결|이 항목은 누락 아님.88/main에 코드 없음도Git확인|
|main과 출시branch 관계|부분:105준비문서11/15 main02996be/작업66c3ba7·main변경0;operations PHASE6 통합잔여|task branch 유지·main통합 미실행 명시|출시branch 상세문서에서 접근|최종28차이/88출시 이후통합 책임·완료상태는 미기록|
|다음 개발 기준branch|부분:105/88은operations-commercial 명시;D-Day는material-service 명시|각 작업 기준은 명확|각branch 내 접근 가능|프로젝트 공통 APP다음기준이 하나로 연결되지 않음|
|다음 스토어 후보|부분:당시85/87/88 후보·추가 QA 기록,D-Day APP별도|88 이후후보버전/범위 통합표 없음|분산|89 제안은11/25 사후, 기존기록으로 역산하지 않음|

과거 원문은 [88 PDF 기록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/pdf-white-screen-hotfix-20261117.md), [85 통합목록](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/app-release-105-readiness-20261115.md), [87 인계](https://github.com/LC3808/legendstudy-app/blob/08345b69/wiki/app105-build87-release-20261116.md)에 보존되어 있다. 11/25 이후 모든 참조는 별도 시점 증거다.

### 13.3 원인 분류와 책임 범위

|분류|판정·근거|해결책|
|---|---|---|
|A 기록 자체 누락|확인:88 실제 출시일/플랫폼별최종상태·누적포함목록·사후source연결 부재|기존88인계에 실제 결과와 확인시각을 추기; 과거 제출0은 당시값으로 보존|
|B 정보 분산|확인:출시381개/조사259개 Wiki tree와 별도source계보|현재상태에서 플랫폼별 canonical 릴리스문서의 고정Git링크를 안내|
|C current 갱신|부분갱신:출시branch는88 BUILT까지 갱신, 조사branch는 최신운영만 추가. 실제RELEASED/과거gate폐기 미반영|현재요약은 현재판정만, 과거상태는 기존history에 보존|
|D index 연결|출시branch내 연결누락 아님(최상단 링크 존재). branch간 최신 릴리스 연결이 빠짐|필수 RELEASE route에 실제 릴리스 인계 연결 추가(제안)|
|E 빌드/출시 혼동|88원문은 명확히 구분했으므로 원문에서 ‘빌드=출시’ 오류는 없음. 뒤늦은독자가 미출시·QA미완료를동일시할 위험|구현/QA/배포를별도 열로; PARTIAL의 대상 명시|
|F Git기준|최종source가Git객체로존재하나버전→출시source 명시연결·main차이최신표 없음|release source와docs HEAD 구분, ancestry검사 및양플랫폼receipt|
|G 에이전트 필수읽기 누락|어느 파일을 실제 읽지 않았는지 입증할실행로그 없음. 단정불가. 다만11/25 전 여러branch 증거를 통합한 상태가 없었고초기계획에반영되지않음|범위판정 전 main/release/task의linked Wiki 교차, 기능을 구현/배포/QA로분리해 재개발여부 결정|
|H Wiki/운영 불일치|확인:current Store BLOCKED·AI/student/worker OFF vs출시88·실운영요청. 이후WEB배포에도 ‘교차검토가최신’문구 잔류|해당문장 과거표기 및최신배포근거로한정, 무기한최신선언 금지|
|I 인계 회수절차|관측:Owner가업로드담당,88인계 후최종결과갱신 없음. 누가왜미기록했는지는 미확인|빌드 인계 후 업로드/심사/출시회신을기록하는 종료조건과담당 지정|

스토어 접속 목적은 두 가지였다. **버전·빌드·소스 준비 기록의 검증**과 동시에 **기록에 없던 실제 RELEASED/출시일 복원**이었다. 따라서 콘솔 접속 전체가 불필요한 재조사는 아니다. 반대로, 구현 목록은 기존 Wiki·Git에서 먼저 복원할 수 있었다. 실제 출시 확인을 위한 접속과, 이미 구현된 기능을 재개발 후보로 분류하는 오류는 구분해야 한다.

### 13.4 현재 상태 문서가 충족하는 범위

감사 시작 시 current-status는 11,964 bytes였고 구조 검사는 PASS였다. 11/25 사후 문서 덕분에 아래 정보는 대부분 상세 링크 한 단계로 복원되지만, 본문 모순이 남았다.

|필수항목|현재 복원 결과 / 공백|
|---|---|
|APP 버전·빌드·플랫폼·출시source·기능|§6–7에서88양OS·08345b69·기능목록가능. 본문Store BLOCKED와충돌|
|미출시|[89 준비](app-release-89-preparation-20261125.md):D-Day/무료2문구,실기기QA·정책DB·제출잔여. BUILT≠RELEASED|
|WEB|[품질V1](quality-console-v1-20261125.md)ecac36e5/Pages6e4b8189가최신확인;본§1의4e865437는앞선시점|
|Worker|§1 Essay29f4f6cc/Finance d14a757e,11/25확인. 새운영조치전active version재조회|
|Supabase Migration|D-Day/복구각설치문서로추적가능;모든Migration의단일전수적용목록은없음. 파일존재로APPLIED판정금지|
|개발기준|APP operations-commercial76cc4050,운영/SQL material-service646c5239,WEB lab-admin-operations c64bfc7. 공통‘하나의최신HEAD’없음|
|진행·미완료·BLOCKED·승인·다음|통합후속/품질V1링크로가능하나과거‘mid-Oct Store launch’와혼재. q1/Finance/APP89/무료2/Q15 상태별분리필요|

위 운영 버전은 앞선 조사 시점의 증거다. 이번 감사에서 현재 운영을 다시 조회한 것은 아니다. 스토어는 11/25 조회, q1은 11/25 22:22 진단, 품질 모집단은 22:44 집계다. 후속 배포·실행·업로드 직전에 재확인한다. Finance의 11/23 자연 갱신은 성공 미확인 상태다.

### 13.5 기존 릴리스 기록 필드 감사

기존 `app-release-closeout.md`는 10/4 BLOCKED 보고이며 현재 통합 릴리스 대장이 아니다(0570099c). 이를 새 대장으로 대체하기보다 기존 83/84/85/87/88 인계 문서를 각 릴리스의 증거로 재사용한다.

|필드|88 이전 기록|최소 보완|
|---|---|---|
|버전·빌드·플랫폼|양OS1.0.6/88 명시|유지|
|source·branch|branch/이전기준077d6654·최종문서HEAD참조|사후08345b69연결,산출물SHA와별도표시|
|포함·수정·제외|PDF수정명확;기존기능은85/87/operations에분산|기존포함표+delta링크,대학뉴스홈보류/백분위미활성/D-Day미포함 명시|
|테스트·산출물·빌드일|2632PASS/9SKIP,서명IPA/AAB SHA,11/17기록|정확빌드완료시각은아티팩트receipt추가확인;commit시각으로대체금지|
|업로드·심사제출·승인·출시|88문서agent실행0,실제Owner후속날짜미기록|업로드/제출/승인일 UNKNOWN;11/25확인한실제출시일만기입|
|알려진문제·다음후보|실기기/업데이트/플랫폼QA잔여존재;88이후통합후보없음|현재89준비를후속링크,실기기QA미완료를미출시기능으로바꾸지않음|

기존 표에 상태를 구분하는 방안을 제안한다: IMPLEMENTED(코드), TESTED(시험 범위·결과), BUILT(산출물), UPLOADED(스토어 수락), SUBMITTED(심사 접수), APPROVED(승인), RELEASED(실제 노출), UNRELEASED(미출시). 플랫폼별로 별도 행을 사용하고, 중간 단계 날짜를 모르면 UNKNOWN으로 남긴다. RELEASED라는 사실로 이전 QA가 모두 PASS였다고 역추론하지 않는다.

### 13.6 Git 28 commits의 정확한 의미

`main02996bed...08345b69`는 left0/right28이며 main은 출시 소스의 조상이다. 충돌 28개가 아니라, 11/13 APP84 main 반영 후 11/17 PDF88까지 작업 브랜치에서 추가된 커밋이다. lib45개와 pubspec2개에 차이가 있다. 28개 커밋에는 문서·운영 RPC·검증도 포함되므로 전부 새 기능으로 세면 안 된다. 전체 목록은 증거 JSON에 기록했다.

11/13 APP83/84는 명시적 승인 후 main을 FF/Push했다. 11/15 준비 문서는 작업 브랜치 유지·main 변경0, 11/17은 스토어 업데이트를 Owner 담당으로 구분했다. **작업 브랜치 분리는 의도됐지만, 출시 후 main 정합화와 최종 인계 회수가 완료됐다는 증거는 없다.** 영구적인 release/main 분리 정책도 찾지 못했다. 특정 담당자의 실수로 단정할 수는 없으나, 인계 절차상 미완료가 남았다는 것은 확인된다.

조사 브랜치 6bd46f98와 출시08345b69는 공통 조상8a149835, left39/right322로 main의 28커밋 지연과는 다른 관계다. 조사 브랜치 전체를 APP에 덮어쓰면 회귀 위험이 있다. 11/25 후속 작업에서는 이미 출시88 위에 D-Day를 선택 통합한76cc4050을 만들었다. 다시 구현할 대상이 아니다.

권장: Owner검토후main02996bed→08345b69의정확FF를재확인하고,후보89(무료2안내·D-Day)는별도QA/승인한다. 현재branchHEAD76cc4050전체를88동기화승인으로간주하지않는다. 이전자동승인검토가main push를차단한기록은[통합후속](integrated-followup-20261125.md)에있으며이번에는재시도하지않았다. release ancestry와제품diff/기능보존검사를다음빌드의입구로사용한다. source SHA와빌드후문서커밋을구분한다.

현재기존미커밋: .gitignore,ios project,essay math_gateway/source_catalog/student_pdf_catalog,test/math_gateway,중앙Wiki/과거작업문서및미추적자료. 미완료기능이나출시기능으로승격하지않고보존했다. 다른release checkout은76cc4050의기존상태를사용하며이번감사로reset/삭제/병합하지않았다.

### 13.7 AGENTS와 검사기의 실제 보장

AGENTS는08345b69와 현재 HEAD 간 차이가 없다. §2의 시작 순서·실제 상태 우선·전체 Wiki 검색·종료 시 링크 검사, §6의 current/log 분리, §7의 구현·시험·실제 상태·미완료 기록은 충분한 일반 규칙이다. 같은 규칙을 중복 추가할 필요는 없다. 다만 플랫폼별 스토어 단계·배포 ID·source·branch와 인계 후 결과 회수는 필수 필드로 명시되지 않았다. 대규모 AGENTS 개편 대신 기존 릴리스 인계 표에 해당 필드를 추가하는 안을 제안한다.

`tool/check_wiki_handoff.py`가검사하는것: Markdown링크파일/anchor존재,10도메인라우팅의문자열, current-status12000bytes. RELEASE라우팅은privacy/auth/current/community/research만요구하며실제릴리스문서·version·build·commit·stage·branch는검사하지않는다. 현재PASS는**구조적연결성과크기만PASS**이며기록의진실성/최신성/출시완료를보증하지않는다. 모순문구가존재해도PASS인것을이번직접실행으로재현했다.

|자동화 가능한 보완(제안,미구현)|사람/외부확인 필요|
|---|---|
|current의APP/WEB/Worker/DB/branch/다음/승인요약·참조존재|내용이실제운영과맞는지|
|RELEASED행의플랫폼/version/build/source/확인시각/근거필수|스토어실제공개·단계별시각·업로드binary와source동일성|
|Git commit실재,release→candidate ancestry,미통합 diff경고|의도한제외기능·회귀QA·개발기준승인|
|동일platform/version/build의서로다른source·현재상태충돌탐지|과거snapshot인지실제오류인지|
|미완료의범위/다음행동/승인·BLOCKED사유필수|해소여부·Owner결정|

검사출력도 STRUCTURE_PASS와RELEASE_METADATA_PASS를분리하고‘운영사실미검증’을명시하는안이적절하다. 새대장파일을만들기전에기존인계표를기준으로parser/test를준비한다. 본감사에서는검사코드변경없음.

### 13.8 새 에이전트 재현(이전 채팅 제외)

별도 에이전트에 대화 이력을 전달하지 않고 공식 시작 문서 3개와 그 링크만 읽도록 했다. 파일·운영 변경은 없었다. 현재 10개 질문은 대부분 상세 링크 한 단계에서 답할 수 있지만, 충돌하는 표현을 해석해야 하므로 무조건 PASS로 판정할 수 없다.

|질문|현재Wiki에서의답 / 한계|
|---|---|
|1버전·2빌드·3Git|1.0.6/88/08345b69,§6. binary독립SHA증명과구분|
|4출시기능|§7목록;상세QA잔여분리|
|5구현미출시|APP89:D-Day/무료2문구,실기기·정책·제출잔여|
|6WEB/Worker|품질V1ecac36e5/6e4b8189;Worker29f4f6cc. §1만따르면오래된WEB로오답|
|7미해결|q1미완료,Finance자연갱신미확인/로그차단,서비스조회일시실패진단|
|8다음|통합후속P0/P1+품질V1미완료. 과거10월우선순위와혼재|
|9branch|APPoperations-commercial,운영/SQLmaterial-service,WEB lab-admin. 현재로컬HEAD는Git재확인|
|10승인|q1,무료2DB,정확mainFF,스토어,품질DB/Owner역할등구체범위별|

추가로사후문서를제외한3snapshot을각각재현했다. `6bd46f98`는88정보불가(10/25후보·Store BLOCKED),`02996bed`는84준비/83출시까지만,`08345b69`는88 BUILT/기능후보는가능하나실제RELEASED불가였다. **세snapshot모두양OS88실제출시를Wiki만으로복원하지못했다.** 11/25보완이실제로정보를추가했음을확인했으며이를과거체계정상근거로사용하지않는다.

현재 재현 결과: 읽기 전용 진단과 QA 준비는 조건부로 시작 가능하다. 운영 실행에는 승인과 상태 재확인이 필요하다. 과거 Store BLOCKED/AI OFF와 무기한 ‘최신’ 표현을 정리하면 오독 위험을 줄일 수 있다.

### 13.9 Owner에게 제안하는 최소 수정 순서

1. 기존88인계에양플랫폼RELEASED와11/25확인근거·source·누적기능참조를추기(과거빌드/제출0이력보존). 새릴리스문서증식없음.
2. current-status의한정된요약을플랫폼/컴포넌트별현재상태+공식상세참조로정리. 오래된StoreBLOCKED/AI OFF/10월다음순서는기존history로옮기되원문보존. index의10/26‘최신마감’·9/25‘Latest’도역사표기.
3. 기존RELEASE라우팅/검사에위메타데이터와ancestry검증추가. 정상/누락source/상이build/모순RELEASED/구branch후퇴fixture를통과시킨다. 외부사실은마지막확인시각과재확인조건으로남긴다.
4. Owner검토후정확mainFF와APP89QA는별도개발작업으로수행. Wiki정정이Git병합·스토어출시승인이아님.

1–3은문서/검사보완약2–4시간,Git/릴리스재검증은별도이며작업량추정이다. 이번에는감사와근거기록·발견된오타정정만수행했다. 구조개편/AGENTS수정/새자동검사/실제main갱신은미실행이다.

## 14. 승인 후 Wiki·Git·릴리스 정상화 — 2026-11-25

공식 Wiki 기준은 **LC3808/legendstudy-app origin/main:wiki/**다. main의 제품 코드는 출시88까지 FF하고, 이후 변경은 문서/검사 도구로 한정했다. 후보89는 operations-commercial 브랜치에 남겼다. 과거의‘main28커밋 지연’은 §13 감사 시점의 사실이며 정상화 후 현재 상태가 아니다.

### 실행과 보존

- 깨끗한 기존 main checkout에서02996bed→08345b69 fast-forward. 충돌/force/reset 없음. `git diff 08345b69 -- lib ios android assets pubspec.yaml pubspec.lock` 비어 있음. 출시source는 후보76cc4050의 ancestor다.
- main에 없던 운영 branch의 tracked Wiki83개를 선택 반영했다. 기존 main의 feature 문서를 덮어쓰지 않았다. main에 없는 SQL/Worker 소스 참조36개는 원본fee6af5의 검증된 Git 링크로 연결했으며 제품 코드/운영 migration을 가져오지 않았다.
- 기존88 문서에 실제 양OS RELEASED, 출시일,source,포함/제외/미출시/QA/다음89를 추기했다. 과거11/17 업로드0 기록은 역사로 유지한다.
- current-status는 구성요소별 마지막 확인 상태와 상세 참조로 교체했다. 이전 main/운영branch current는 기존history에 원문 보존했다. index의 과거‘최신’ 표현과 RELEASE 경로를 정리했다.
- AGENTS는 공식main 읽기·작업branch/출시source 확인·공식게시 완료·플랫폼별 출시 결과 회수만 보완했다. 기존 일반규칙과 데이터보호 규칙은 유지한다.
- 실제 학생 요청·답안·결과·운영DB·이용권·Toss·Finance·WEB/Worker·스토어 변경0. 기존 작업checkout의 dirty 파일은 수정/삭제/통합하지 않았다.

### 공식 문서 반영 절차

어느 branch에서 시작하든 먼저 APP 원격main의 AGENTS/index/current를 읽는다. 공식 문서 URL은 `https://github.com/LC3808/legendstudy-app/blob/main/wiki/current-status.md`. 접근 불가하면 마지막 확인값과 freshness NOT_TESTED를 보고한다. 오래된 branch가 스스로‘공식’이라고 선언할 수 없다.

작업별 코드 branch는 유지한다. 종료 시 문서 변경만 검토해 공식main에 반영하고 push한다. 새 운영코드나 미출시APP 전체 병합을 문서승인으로 대신하지 않는다. 기존 활동branch에는 동일 AGENTS 안내를 반영하며, 더 오래된 보관branch는 원격main 문서를 읽는 시작 절차를 따른다. 웹 저장소도 APP main Wiki를 프로젝트 상태의 기준으로 사용한다.

### 검사 계약과 실패 테스트

`python3 tool/check_wiki_handoff.py`: 기존 링크/anchor/10라우팅/12KB를 유지하고 구조화된 current 및 기존88문서의 JSON 기록을 읽는다. 구조화 값은 별도 대장이 아니라 같은 공식 문서의 검사 입력이다. release source의 pubspec/version/build,양플랫폼 receipt 일치,증거링크,후보stage/branch,release→후보 및main ancestry를 검사한다.

`python3 tool/check_wiki_handoff.py --official`: 추가로 원격main을읽고 추적ref 최신성,공식 Wiki/AGENTS/검사기와working tree 동일성,미게시Wiki 파일 유무를 확인한다. 원격 접근 실패나미게시 상태를PASS로바꾸지 않는다. 모든항목과공식반영이통과해야HANDOFF_READINESS PASS다.

14개 격리 테스트: 정상,필수항목누락,상이build,중복platform,근거누락,BUILT를RELEASED로사용,후보branch누락,pubspec불일치,commit부재,ancestry실패,미게시변경,오래된remote,중복구조화record, 과거 APP82/HOLD 현재형 라우팅 재발. `python3 tool/test_release_handoff.py` PASS. 실제Git commit/ancestry도 별도로 검사했다.

PASS는 구조·기록 일관성·Git·공식게시의 판정이며 외부 Store/DB/운영의 진실성을 자동 보증하지 않는다. 기록된 마지막 확인상태는 콘솔 재접속 없이 복원할 수 있다. 새 릴리스/복구/DB/배포 실행 직전에는 외부 최신성을 재확인한다. 독립 인수인계 결과와 최종 공식게시 확인은 아래에 기록한다.

### 최종 독립 인수인계 및 게시 검증

독립 검토자는 대화 이력 없이 작업branch AGENTS에서 공식main으로 이동했다. 첫 검토에서 index의 ‘최신 APP82’와 현재형‘APP 릴리스 HOLD’가 발견돼 FAIL이었다. a1cc96b에서 역사 링크로 분리하고 회귀 검사를 추가했다. 수정본을 다시 읽은 결과 **11/11 엄격 PASS**: 실제 버전/양OS빌드/source/출시기능/미출시/WEB·Worker/DB/장애/다음/branch/승인을 콘솔 재접속 없이 복원했다.

공식main의 `--official` 검사는 WIKI_STRUCTURE / RELEASE_CONSISTENCY / GIT_BASELINE / OFFICIAL_WIKI / HANDOFF_READINESS 모두 PASS. current6650bytes,내부링크3824개(최종기록 추가 전). 14테스트 PASS. 이 결과는 운영 상태를 새로 검증했다는 뜻이 아니다. 마지막 확인시점과 재확인조건을 함께 복원했다.

활동branch 안내도 게시: 운영cf9cfc6,APP후보ef956bf,WEB683085a의 AGENTS에 공식main 참조를 반영했다(후속 명료화 문서commit은 각HEAD참조). 임의의 과거branch 전체를 강제로 수정하지 않으며, 보관branch 재개 시 공식main AGENTS부터 읽는다.

남은 운영문제는 정상화 작업의 미완료가 아닌 기존 후속 과제다: q1 실제복구 승인,Finance 로그 접근,APP89 기기QA/스토어승인,무료2DB승인,품질Q15후속. 새로운 문서체계나 제품배포 없이 정상화를 마쳤다.
