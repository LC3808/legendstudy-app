# 11/25 통합 후속 — 운영 점검·출시89 준비·품질/배지 설계

상태 **PARTIAL**. 기준은 [교차검토](project-cross-review-20261125.md) 및 [전체 Flutter diff](project-cross-review-flutter-files-20261125.md). 이번 실제 변경은 출시88 APP의 기존 D-Day 통합/버전89/격리 테스트와 Wiki다. 운영 DB·학생 요청·원장·배포·스토어 제출 변경0. 완료된 대시보드/정확인용/문항재사용을 재구현하지 않았다.

## P0 q1 복구 준비

대상 `03629605-9a58-4b78-8465-c5331ac1b1c7`. 11/25 22:22 KST 읽기전용 diagnosis: reserved, completed1/total2, q1 reconciling/PROVIDER_NETWORK_UNKNOWN, stored result0, active_lease=false, lease11/22 01:46 KST 만료. included_revision required0, reserved/consumed/refunded/released0, ledger0, consistent=true. q0 전체 checkpoint row MD5 `18da60ecf6c80ead27ca16b33454db41`은11/22와 동일. payload MD5는 `dbcecc104af1d6fe9369ad9831eb3db9`로 **해시 대상이 다르므로 혼용하지 않는다**.

22시대 recovery `postcheck.sql`의 함수정의/ACL/기존RPC/활성fence trigger 검증 PASS. 일반 복원allowed=false RECONCILIATION_REQUIRED, 별도 uncertain_recovery.allowed=true OWNER_EXECUTION_APPROVAL_REQUIRED로 정상 구분된다. history0·신규attempt0. 이전 실행 저장 차단은 이 배포된 계약으로 유지되며 실제 늦은 학생 응답을 주입해 시험하지 않았다.

Worker 운영29f4f6cc-433f-4e8e-8da4-9ca5710f2e71(100%,11/22), WEB Pages f1882082-9950-46cc-9f2c-fd35a17e9d4d. [RUNTIME_UNAVAILABLE 수정](admin-recovery-runtime-fix-20261122.md) 이후 배포가 유지된다. 부분재생성 flag 미설정/기본false, 새 상한 비활성 유지. 이번 실제 q1실행 승인 질문을 보냈으며 응답 전에는 실행하지 않는다.

실행 순서: 새 diagnosis와 q0/ledger 기준값 → 불확정 응답 별도 승인 확인 → 기존 관리자 복구 **1회** → q1 새 attempt/독립검토/인용검증/결과저장 → 전체2문항/완료/KPI/감사/q0불변/차감0확인. 응답불확정이면 재제출 금지. UI 및 Provider 완료까지 미확인인 현재 상태를 복구완료로 보고하지 않는다.

## P0 Finance

운영 Finance Worker d14a757e-5b46-448c-8b66-325d181c2a9f(100%,11/17) 유지. Pages PAYMENT_MODE=LIVE, PAYMENT_ENABLED/PUBLIC_ENABLED/PAYMENT_FINANCE_AUTO=true 유지. 이 설정만으로 Finance의 실제 API 성공/11월23일 자연갱신을 인증하지 않는다.

기존 로그 telemetry API 재조회403, 같은 로컬 OAuth로 deployment/settings GET은 성공했다. 만료/Worker중단으로 단정할 수 없다. 확인한 OAuth 범위는 workers write/tail read 등을 포함하나 해당 observability API 접근 허용은 증명되지 않았다. 브라우저는 Cloudflare 로그인 화면(Password 단계)에 머물러 있다. **자연갱신 성공·현재 JWT exp·실제 Cron 실행·Finance API 정상은 BLOCKED/미확인**. Cron15분 설정과 런타임 로그는 다른 증거다.

`/token`뿐 아니라`/status`도 내부renewal.run 경로로 만기도래시 갱신·상태저장을 할 수 있어 실행하지 않았다. 관리자 ‘인증 상태 확인’도 누르지 않았다. 해결 순서: Owner Cloudflare 로그인 →11/23 전후 기존 finance_vault_restore/renewal success/failure/Cron로그 조회 → 만기/lastSuccess 시각대조 →403이면 최소 로그조회권한의 계정/리소스 범위확인. 재인증이나 권한확대는 원인확인 후 별도 절차. 실패가 확인된 경우 기존 rotation/runbook으로 승인된1회갱신→후속Cron확인, 기존LIVE설정 유지. 지금 인위갱신으로 자연갱신 증거를 만들지 않는다.

## APP 브랜치와 출시 준비

양 스토어 실제 최신1.0.6+88을 ASC TestFlight와 Play 최신버전/번들에서 다시 확인했다.89등록 없음(확인시점). iOS 출시11/18, Android11/17, 기준08345b69. remote fetch 후 origin/main02996bed...08345b69는0/28, fast-forward 가능·충돌없음. main→88에 workflow 변경없고 기존 materials workflow는schedule/dispatch다.

main fast-forward+push는 자동 승인 검토가 기본 브랜치 변경의 후속 영향과 정확한 승인 부족을 이유로 차단하여 **실행0**. Owner에게 `02996bed →08345b69` 정확한 범위 승인을 요청했다. reset/force/cherry-pick중복 없음. 별도 개발브랜치에서 출시88의 기능을 보존하여 작업했다.

출시 브랜치 `codex/operations-commercial-20261113`의34d2ee9(무료2문구)에 기존 D-Day6cd4c1a7의lib/test7파일만 적용,patch check 충돌0. 신규 기능 재작성·DB재설치 없음. 버전1.0.7+89, APP commit `76cc405`. 구체 테스트/실기기 gate는 [출시89](app-release-89-preparation-20261125.md).

## 첨삭 전수 검토 및 UX

[별도 품질/UX 보고서](essay-lab-student-experience-review-20261125.md): 전체70요청은관리자17/심사review30/학생후보23. 후보완료20요청38문항,실패2/미완료1. 과거 후보계정의 실제학생확정은 Owner분류확인 필요. 기준50/50 현재공식package텍스트일치,dimension binding미등록0,답안인용20/20 exact-offset. 완료무료재첨삭5건required0/ledger0. 실제교육적점수최종승인은별도.

우선: 서비스가능조회 일시실패 진단, Owner 대표결과검수, APP가이드 번호/체크행, 잘한점 소제목 계약, 공식점수vs내부레벨 설명. 평가엔진/학생결과UI 수정0. WEB 학생용 화면을 Owner계정으로 확인한 범위와 실학생E2E 미검증을 분리했다.

## 무료2개 정책

[기존 완료 패키지](signup-credit-policy-two-20261125.md) 재사용: SQL/Wiki30844e7,WEB712ff3a,APP34d2ee9. private helper가 신규지급2개의 단일 기준, 기존`essay_signup_3_v1`중복방지 표식과 기존잔여유지. SQL24/G1회귀84/WEB288+101/Flutter21 PASS는 앞선정책작업 기록이며 이번 재실행으로 중복집계하지 않는다.

운영DB 아직3개,WEB새안내 미배포. 먼저 Owner SQL승인→precheck→install→postcheck/원장불변→WEB안내배포→APP89출시. DB변경전2개가현재지급된다고 광고하지 않는다. 구88의3개문구는베타고정문구로현노출제한이있지만binary는바뀌지않으므로서버공지/FAQ와업데이트로해소. 이번ASC확인에서심사노트에도three complimentary credits·과거베타기간문구가남아있어89제출전안내수정필요. 실제스토어메타데이터는변경하지않았다.

## 아주대·인하대

공식 PDF를11/25 다시 내려받고 일정페이지를 렌더링해 표의 행/계열을 검증했다. 아주 PDF8쪽(인쇄6쪽), 인하 PDF25쪽(인쇄36쪽).

- [아주 공식 모집요강](https://www.iajou.ac.kr/_common/new_download_file.php?menu=boardfile&file_no=4601):12/05토 공과/자연/자유전공자연09시,첨단ICT/소프트웨어14시,의과19시.12/06일 경영/인문/사회/자유전공인문09시,약학14시. 기계공학의12/05연결은공과대학조건과일치.
- [인하 공식 모집요강](https://admission.inha.ac.kr/ajaxfile/CMN_SVC/FileView.do?GBN=X04_1&TEMP_CODE=IPSI_A&CONFIG_CD=C1405&CONFIG_SEQ=6&SITE_NO=2&SUB_SEQ=8):12/05인문,12/06자연. 기계공학12/06연결일치. 두대학논술최초합격12/18. 추후유의사항공지가최종우선하므로시험전공고변경재확인필요;이번자료다운로드가모든후속공지변경없음의증명은아니다.

|범위|아주|인하|
|---|---:|---:|
|DB 등록시험/문항|6/12|35/95|
|운영 WEB 공개 allowlist 교집합|0/0|34/92|
|운영 Worker registry 포함|6/12|35/95|
|DB runtime policy 존재시험|0|34|
|runtime policy 없음|6시험|2021수시자연오후1시험3문항|

registry존재만으로실제AI가능이라하지않는다. 아주는6개기존모의자료의공식기준/권리검수·runtime연결이우선이다. 신규중복수집하지않는다. 인하34개는현재package의Owner Inha STANDBY providerTransmission APPROVED기록이있다. 아주review없음/인하미연결1개는권리확인완료로간주하지않는다. 두대학확정RIGHTS_HOLD개수는별도권리명세전수검증미완료이므로UNKNOWN;다른대학기존15건을이대학으로전용하지않는다. 실제AI제출은0,학생계열별최종게이트전수E2E는NOT TESTED.

작업안: 아주6시험12문항의기존파일→공식출처·채점기준·권리manifest대조→소규모정확성검증→승인된공개/runtime연결(1~2일+검수). 인하미연결3문항은원인/권리확인0.5일;나머지92문항재등록금지. 남은12/5·6의계열별가용성QA를우선한다.

## 수능 전후 실제 수집 지표

동일6일 비교:11/13~18 KST와11/19~24 KST(수능일포함).11/25미완결제외. auth.users는현재존재하는가입기록이므로삭제회원은복원하지않았다.

|관측지표|전6일|후6일|해석|
|---|---:|---:|---|
|신규가입|252|110|-56.3%, 기간동일·계절인과확정불가|
|서버 Study사용자|8|3|소표본;앱DAU/WAU아님|
|완료Study세션|30|4|집계포함29→4;게스트/미동기화제외|
|비관리자논술요청|1|12|후기간완료11/미완료1|
|비관리자논술사용자|1|6|논술사용은같이감소하지않음|

해당기간 payment_orders는LIVE CANCELLED1,성공구매0. 정책별청구전환cohort/무료권소진분모가없으므로‘무료→유료전환율0%’로계산하지않는다. 신규가입자와타기간구매자의기간상관을전환율로취급하지않는다.

DAU/WAU·자료검색·열람횟수·재방문율·무료권사용자cohort: **NOT TESTED/추가Analytics export필요**. recent_views는마지막열람projection,bookmarks는현재저장행이므로일별event처럼집계하면편향된다. Study사용자를전체활성이용자로대체하지않는다. 앱이벤트계측의출시범위도[Flutter교차검토](project-cross-review-flutter-files-20261125.md)참조.

해결안: 같은GA4property/timezone에서13~18/19~24의activeUsers,newUsers,returningUsers,search/view/study/essay event를출시버전·platform별추출→미수집구간표시→가입cohort7/14일리텐션은관측완료후계산. 현재감소를제품실패나수능효과로단정하지않는다. 겨울방학은고1/2자료→저장/타이머→주간기록의기존기능유입을먼저측정하고,배지출시후옵트인·반복방문·학습기록일수를비교한다. 논술은남은시험기출/재작성가치,학습은비경쟁습관의역할로구분. 신규추적수집·광고메시지는이번에추가하지않는다.

## 배지 설계와 후속 우선순위

[배지PHASE A](study-badge-system-v1-design.md) 25개후보·일30분·KST union·소급·중복방지·정정·권한·성능·Native화면명세작성. 운영설치/지급0. 과거획득조건을새로확정한것이아니며Owner정책·Claude디자인검토대기.

P0:q1명시승인후1회복구,Finance로그접근확보(각0.5일내진단,외부대기별도),대학목록상태조회실패분리진단. P1:main정확한FF승인,89실기기회귀0.5~1일,무료2SQL적용승인,아주·인하부족범위. P2:품질보고서Owner검수후최소개선·Analytics동일기간export. 배지B는Owner정책확정뒤4~6일예상.

승인필요: q1실행,무료2운영DB,main정확한FF push(자동검토차단),스토어업로드/제출,배지정책·후속DB/backfill. 로그인필요:Cloudflare기존로그. 이번미승인작업:부분재생성/새상한/EvidenceID확장/전체대학연결/배지지급/정시예측모두비활성.
