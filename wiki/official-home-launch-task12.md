# TASK12 — 공식 홈페이지 출시 전환 (2026-11-01)

상태: **DEPLOYED / VERIFIED** — Owner TASK12-B 명시 승인에 따라 2026-11-01 21:25 KST 운영 배포 완료. 실제 운영 URL의 Chrome PC·모바일 viewport 검증 완료. GA4 실제 수집과 모바일 실기기는 NOT_TESTED.

## 기준 및 기존 결정 재사용

- Owner TASK12: 출시 준비 안내를 정식 앱 다운로드 안내로 변경. 별도 운영 배포 승인 필요.
- [기존 홈페이지 제작·배포 기록](final-store-rc-1.md), [Analytics v1](analytics-v1-implementation-20261030.md), [TASK10 GA4 안전 수집](admin-integrated-analytics-task10.md), [장기 데이터 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 재사용한다.
- WEB: /Users/woojinchang/development/legendstudy-release-20261024 (LC3808/legendstudy-lab). 시작 1d520984c3b6cc88d1884cef7e9b8680a36609c6, 깨끗한 TASK11-F 코드에서 codex/official-home-launch-task12 분기.
- 홈페이지는 최신 LAB 트리에 없었으므로 codex/official-home-20261019의 official-home 디렉터리만 복원했다. 오래된 브랜치 전체 병합 없음.
- WEB 변경 커밋 8f5ea4229c31ea6b20438028e64d764af12d414a, 최종 442baf9 (후속 공백 정리). 원격 Push 및 LOCAL/REMOTE 일치 확인.
- APP: /Users/woojinchang/.codex/worktrees/analytics-task10/legendstudy-service-app-20261022 (LC3808/legendstudy-app). f46659dd1ecb446406d7accfbe46b2c3974de3f4에서 동일 이름 문서 브랜치. Flutter 코드·빌드 변경 없음.

## 변경 파일 및 화면

| 파일/함수 | 변경 |
|---|---|
| official-home/site/index.html | 출시 Hero, 두 스토어 CTA, 인문논술 LAB 설명, 공개 정책 안내, 환불 링크 |
| official-home/site/style.css | 기존 네이비·오렌지 유지, 다운로드 버튼 줄바꿈·모바일 정렬 |
| official-home/site/assets/ | 기존 실제 APP 화면·아이콘·Pretendard·라이선스 재사용 |
| official-home/site/analytics.js / installHomeAnalytics | 여섯 outbound 링크, 고정 목적지/위치, 중복 DOM 이벤트 방지 |
| official-home/site/bootstrap.js | 기존 GA4 runtime 연결 |
| official-home/build.mjs | 독립 dist 생성, 기존 runtime 컴파일, 홈페이지 전용 opt-in 설정·CSP |
| official-home/verify.mjs | 링크·출시 문구·사업자·자산·실제 생성 runtime import 검사 |
| src/lib/analytics/ga4.ts / createGa4Runtime | optional pageTitle만 추가. 기존 LAB 기본값 보존 |
| src/lib/analytics/official-home.test.ts | 링크·Noop·6개 클릭·PII·중복·실패 격리 회귀4개 |
| eslint.config.mjs | 생성된 official-home/dist 제외 |
| official-home/README.md / .gitignore | 빌드·설정·배포 HOLD·롤백 안내, 산출물 제외 |

Hero: “기출문제부터 학습 관리까지, 레전드스터디+”. 서브타이틀은 Owner 지정 문구 적용. 검색·PDF 열람·자료 저장·타이머·주간 기록·D-Day는 기존 APP 구현/기존 제품 문서에 맞춰 소개한다. 인문논술 LAB의 대학별 평가기준 기반 AI 첨삭 가치는 유지한다. 베타 진행 및 무료 이용 여부는 서비스 내 공지를 확인하도록 안내하며, 일일 무료권이 운영 활성화됐다고 주장하지 않는다. 수리논술은 준비 중으로 유지한다.

## 실제 연결 URL

- [App Store 다운로드](https://apps.apple.com/us/app/레전드스터디/id6820826957)
- [Google Play 다운로드](https://play.google.com/store/apps/details?id=com.legendstudy.app)
- [논술 LAB](https://lab.legendstudy.com/)
- [기존 기출자료 사이트](https://legendstudy.com/)
- [고객지원](https://lab.legendstudy.com/support/), [이용약관](https://lab.legendstudy.com/terms/), [개인정보처리방침](https://lab.legendstudy.com/privacy/), [환불 안내](https://lab.legendstudy.com/refund/), [계정 삭제](https://lab.legendstudy.com/account-deletion/)

## Analytics 상태와 보존 검토

기존 createGa4Runtime의 origin·개인정보·광고 저장 차단·수동 pageview 방식을 재사용. 기존 홈페이지에는 수집 코드가 없었다. Owner TASK11 마케팅 계약의 banner_click 이름을 사용하고, LAB 31개 이벤트/14개 허용 속성은 변경하지 않았다. 발송 속성은 platform=web, screen=official_home, source=위치:목적지의 고정값만 사용한다. 클릭을 설치·결제·첨삭 완료로 집계하지 않는다.

필요 설정: HOME_ANALYTICS_ENABLED, HOME_GA4_MEASUREMENT_ID(실제 확인된 G-... ID), HOME_GA4_PRIVACY_REVIEWED. 기본 false. 기존 LAB 환경값은 복사하지 않는다. origin은 home.legendstudy.com만 허용하며 localhost/Pages Preview는 발송하지 않는다. 잘못된 enabled 설정은 기존 dist를 지우기 전에 실패한다. 실제 ID를 만들거나 추측하지 않았다. 실제 수신/DebugView는 NOT_TESTED; 관리자 조회 권한은 수집 설정과 별개다. GA4 개인정보·동의·보존기간·자동 측정 설정 검토 후 연결 필요.

장기 보존 전략의 7개 질문:
1. 사실은 링크 클릭 시점의 이동 의도다. 학생 학습/평가 기록을 변경하지 않는다.
2. source에 당시 위치·목적지를 고정해 출처를 구분한다. 별도 원장 복제는 없다.
3. 기존 데이터 UPDATE/삭제 및 과거 이벤트 backfill 없음.
4. 학생 identity나 계정 매핑을 새로 수집하지 않는다.
5. 마케팅 행동이며 Learning/Decision/Outcome의 학습 성과나 실제 설치로 간주하지 않는다.
6. 이메일·답안·임의 URL/query/hash·결제정보를 보내지 않는다. 연결 전 개인정보 설정 검토가 필요하다.
7. 클릭 원본과 설치/전환 추정치를 혼동하지 않으며, 이번에 파생 통계를 생성하지 않는다.

## 자동 검증

Node 22 실행 기준:

| 검사 | 결과 |
|---|---|
| TypeScript --noEmit | PASS |
| 전체 ESLint | PASS: 오류0, 기존 경고5 |
| Next Production Build | PASS |
| 전체 Vitest | 1,523 PASS / 4 SKIP / 0 FAIL (212 files PASS, 3 skipped) |
| 홈페이지 build + verify | PASS |
| 잘못된 Analytics 설정 | PASS: enabled/missing ID 실패, 기존 dist 보존 |
| 생성된 runtime 실행 | PASS: import 가능, process.env 잔여 없음 |
| 수정 파일 ESLint | 오류0 |
| Flutter | NOT_TESTED: APP 코드는 변경하지 않음, TASK12 WEB 범위 |

기존 lint 경고는 Owner 검수 ref cleanup1, math hook deps2, history retry test unused args2. 테스트를 삭제하거나 SKIP를 PASS에 포함하지 않았다.

브라우저에서 생성 GA4 모듈의 환경변수 치환 정규식이 숫자4를 누락한 오류를 발견했다. A-Z0-9_로 수정하고 실제 생성 모듈 import 검사를 추가했다. 새 브라우저 탭에서 해당 오류가 없는 것을 재검증했다. 운영에는 적용되지 않은 로컬 빌드 오류였다.

## PC·모바일 및 링크 검수

Chrome 실제 브라우저로 로컬 최종 산출물을 확인했다. 가로 스크롤 없음, CTA·브랜드·법적 링크 정상. 320/390/412/768/1440px 확인, 390은 iPhone 크기, 412는 Android 크기, 768은 Tablet 크기다. 이는 Chrome viewport 검수이며 실제 iPhone/Android/Safari 실기기 PASS가 아니다.

| 검수 | 상태 |
|---|---|
| PC Hero 두 스토어 링크 클릭 → 실제 앱 페이지 | PASS |
| 모바일 하단 두 스토어 링크 클릭 → 실제 앱 페이지 | PASS |
| LAB CTA → 실제 LAB 홈 | PASS (조회만, 평가 실행 없음) |
| 기존 사이트·지원·약관·개인정보·환불·계정 삭제 화면 | PASS |
| 다운로드 내부 anchor·모바일 CTA 배치 | PASS |
| 최종 로컬 신규 탭 JS error | 없음 |
| 실제 iPhone / Android / Safari | NOT_TESTED |
| 실제 설치 또는 결제 | NOT_TESTED / 실행하지 않음 |
| 실제 GA4 수신 | NOT_TESTED |

스크린샷은 WEB의 ignored official-home/qa/task12-desktop.png 및 task12-mobile.png. 로컬 검수 URL: http://127.0.0.1:4312/ (현재 Mac 서버 실행 동안만 접근 가능). 공개 Preview는 배포하지 않았다.

## TASK12 당시 배포·백업·롤백 (이력)

Wrangler 읽기 조회로 확인한 기존 production:
- Cloudflare Pages project: legendstudy-home (LAB와 별도 static direct upload)
- deployment ID: 4104f06d-b748-4ee0-b40f-aca5ccbd909c
- source: 20cf31b / branch codex/official-home-20261019
- immutable URL: https://4104f06d.legendstudy-home.pages.dev
- TASK12 당시 home.legendstudy.com은 이전 준비 페이지였다. 이후 TASK12-B 배포는 아래 기록 참조.

승인 후에도 먼저 최신 배포 ID와 production branch를 다시 확인한다. official-home 디렉터리에서만 dist를 legendstudy-home 프로젝트로 명시 업로드한다. LAB root Functions 또는 Next out을 홈페이지로 배포하지 않는다. 배포 후 store/LAB/legal 링크 및 모바일 재검수. 이상 시 Cloudflare Pages의 기존 deployment에 Rollback한다. DNS/DB/Worker 변경 없음.

보조 복구 파일 official-home/qa/rollback-production-4104f06d.tar.gz는 20cf31b와 당시 business-info로 재빌드한 정적 산출물이다. 해시는 rollback-verification.json. 원격 raw HTTP byte 대조는403으로 불가했으며, 운영에서 직접 내려받은 완전 동일 백업이라고 주장하지 않는다. 기존 immutable 배포 보존이 주 롤백 수단이다. 롤백을 실행하지 않았다.

## TASK12-B 승인 운영 배포 — 2026-11-01

Owner가 home.legendstudy.com 하나의 운영 배포를 명시 승인했다. 신규 홈페이지 개발·LAB 재배포 없이 승인된 정적 산출물만 업로드했다.

| 항목 | 검증된 값 |
|---|---|
| 실제 운영 URL | https://home.legendstudy.com/ |
| Pages project / custom domain | legendstudy-home / home.legendstudy.com active |
| 신규 production deployment | 1b3063af-ea6f-4189-9ac5-7ad478004974 (success) |
| 배포 source SHA | 442baf9d5f0d710f7f9ac50e7b8096d96d6b6af3 |
| production branch | codex/official-home-20261019 (기존 설정 보존) |
| 배포 시각 | 2026-11-01T12:25:50.688892Z / 21:25 KST |
| 이전 production / 롤백 대상 | 4104f06d-b748-4ee0-b40f-aca5ccbd909c (success, 보존 확인) |
| LAB 배포 전후 | 9c505258-4a49-468a-83ae-2326173fb870 동일 |

시작 WEB HEAD 9f29bb8, APP Wiki HEAD edfcbf6. WEB 현재 HEAD와 442baf9의 official-home 및 빌드 입력 ga4.ts/business-info.ts diff가 비어 있음을 확인했다. 정확한 442baf9의 해당 경로만 git archive로 /tmp/task12b-source에 추출, Node22로 HOME_ANALYTICS_ENABLED=false build 및 verify 재실행 PASS. 13개 정적 파일과 _headers를 격리된 official-home 디렉터리에서 프로젝트/branch/SHA 명시하여 업로드했다. Next out·LAB Functions·API·DB는 포함하지 않았다.

Cloudflare 프로젝트·도메인·기존 배포 파일 manifest·LAB 기준 배포 설정을 /Users/woojinchang/.codex/legendstudy-backups/task12b/에 비공개 백업(디렉터리700, 설정파일600)했다. 원격 기존 immutable deployment가 주 롤백 수단이다. 배포 후 API로 home production canonical ID/source/success, custom domain active, home 설정 불변, LAB deployment/config 불변을 대조했다. 토큰·설정 원문은 Git에 저장하지 않는다.

### 운영 URL 실검증

| 항목 | 결과 / 근거 |
|---|---|
| 출시 준비 문구 제거·앱 출시 안내 | PASS: 운영 DOM 및 화면 확인 |
| App Store / Google Play CTA | PASS: PC 및 390px 실제 클릭, 각각 레전드스터디+ 상품명 렌더링 확인 |
| 논술 LAB | PASS: CTA 클릭 후 실제 LAB 홈 렌더링 |
| 고객지원·약관·개인정보·환불 | PASS: 각 링크 클릭 후 해당 제목·본문 렌더링 |
| 기존 기출자료 사이트·계정 삭제 안내 | PASS: 실제 링크 클릭 후 기존 사이트·안내 본문 확인 |
| PC | PASS: Chrome1857px Hero·브랜드 이미지 확인, scrollWidth=innerWidth |
| 모바일 | PASS: Chrome390px Hero/LAB/다운로드 레이아웃·앵커·CTA 확인 |
| 작은 화면 / Android·Tablet 폭 | PASS: 320/412/768px scrollWidth=innerWidth, 이미지 로드 확인 |
| 자산 | PASS: 운영 이미지 모두 complete/naturalWidth>0 |
| 실제 iPhone·Android·Safari | NOT_TESTED: viewport 검증과 구분 |
| 실제 설치·결제 | NOT_TESTED: 실행하지 않음 |
| 실제 GA4 수신 | NOT_TESTED: 기존 opt-in 설정 없으므로 Noop 보존 |

이번 재실행은 정적 build/verify와 운영 브라우저 검증이다. 배포 입력 코드가 TASK12 검증 버전과 동일하므로 위 TypeScript/전체 Lint/Next build/전체1523 PASS·4 SKIP 결과를 재사용했다. 새 전체 테스트 실행으로 주장하지 않는다. 배포 후 변경은 README/Wiki 기록뿐이며 배포 source SHA는 442baf9다.

스크린샷: WEB ignored official-home/qa/task12b-production-desktop.png, task12b-production-mobile.png, task12b-production-mobile-download.png. 로컬 Preview가 아닌 실제 https://home.legendstudy.com 화면이다.

### 롤백 및 영향

Cloudflare Pages → legendstudy-home → Deployments → 기존 production 4104f06d-b748-4ee0-b40f-aca5ccbd909c → Rollback to this deployment. API 대안은 해당 프로젝트 deployments/{기존ID}/rollback에 승인된 계정으로 POST. 다른 프로젝트 또는 DNS를 변경하지 않는다. 이후 canonical ID·운영 URL·스토어/정책/모바일을 다시 확인한다. 롤백 실행은 필요하지 않았으며 이번에 실행하지 않았다. 기존 배포가 success 상태로 조회됨을 확인한 준비 검증이다.

운영 변경은 home 정적 홈페이지에만 한정. legendstudy.com·LAB 배포·APP·Supabase DB·Worker·Credit·결제·Provider·스토어 제출 변경 없음. 신규 평가·결제 실행 없음.

## Owner 화면 검수 및 잔여 항목

1. https://home.legendstudy.com/ 에서 실제 출시 화면을 확인한다. 운영 배포 승인 대기 상태가 아니다.
2. 실제 모바일/Safari 검수 및 GA4 실수신은 미검증으로 유지한다. 홈페이지 배포 차단 사유가 아니다.
3. GA4 연결 시 실제 홈페이지 측정 ID와 기존 개인정보 설정 검토가 필요하다. 임의 ID/프로젝트 생성 없음.
