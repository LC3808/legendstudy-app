# TASK12 — 공식 홈페이지 출시 전환 (2026-11-01)

상태: **READY FOR OWNER REVIEW / 운영 배포 HOLD**. 홈페이지 코드·로컬 검수 완료와 운영 공개를 구분한다. GA4 실제 수집은 미설정/NOT_TESTED.

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

## 배포·백업·롤백

Wrangler 읽기 조회로 확인한 기존 production:
- Cloudflare Pages project: legendstudy-home (LAB와 별도 static direct upload)
- deployment ID: 4104f06d-b748-4ee0-b40f-aca5ccbd909c
- source: 20cf31b / branch codex/official-home-20261019
- immutable URL: https://4104f06d.legendstudy-home.pages.dev
- 현재 home.legendstudy.com은 이전 준비 페이지 그대로다. TASK12 운영 배포 없음.

승인 후에도 먼저 최신 배포 ID와 production branch를 다시 확인한다. official-home 디렉터리에서만 dist를 legendstudy-home 프로젝트로 명시 업로드한다. LAB root Functions 또는 Next out을 홈페이지로 배포하지 않는다. 배포 후 store/LAB/legal 링크 및 모바일 재검수. 이상 시 Cloudflare Pages의 기존 deployment에 Rollback한다. DNS/DB/Worker 변경 없음.

보조 복구 파일 official-home/qa/rollback-production-4104f06d.tar.gz는 20cf31b와 당시 business-info로 재빌드한 정적 산출물이다. 해시는 rollback-verification.json. 원격 raw HTTP byte 대조는403으로 불가했으며, 운영에서 직접 내려받은 완전 동일 백업이라고 주장하지 않는다. 기존 immutable 배포 보존이 주 롤백 수단이다. 롤백을 실행하지 않았다.

## Owner 검수 및 잔여 항목

1. 로컬 URL에서 출시 문구, 두 스토어, LAB 정책 표현 확인.
2. 실제 모바일/Safari 검수는 별도 필요.
3. GA4 수집을 원하면 실제 홈페이지 측정 ID와 개인정보 설정 검토 필요. 미설정 Noop이어도 다운로드는 정상 동작.
4. **운영 배포는 별도 승인 대기**. 이번 Push는 production 교체가 아니다.
5. 운영 DB·Worker·Provider·Credit·결제·LAB 배포·APP 배포·스토어 제출 변경 모두 없음.
