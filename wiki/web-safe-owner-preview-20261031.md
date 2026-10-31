# WEB 동일 도메인 Owner 검수 — 2026-10-31

## 범위와 현재 상태

Owner 승인: 기존 운영 화면 보존, 동일 도메인 관리자 전용 읽기 검수 경로 추가. 전체 운영 화면 교체는 별도 승인 후 진행한다. [학생 중심 결과 정책](student-centered-essay-feedback-20261031.md), [최종 피드백 UX](final-feedback-ux-refinement-20261031.md), [WEB 결과 개선](essay-web-result-refinement-20261030.md)의 후속이다. 이전 문서의 localhost 실계정 연결 미검증은 이번 동일 도메인 검수에서 해소한 범위만 아래에 기록한다.

검수 URL: https://lab.legendstudy.com/owner-review/essay/

기존 운영 로그인 세션을 재사용한다. 별도 OAuth redirect 설정, DB/RPC 설치, 평가 Worker 변경은 없다. 합성 Fixture가 아니라 로그인한 관리자 본인의 저장된 시험 기록을 조회한다. 일반 메뉴·사이트맵에는 링크하지 않는다. 정적 HTML/JS는 공개된 비민감 shell이며 실제 기록 API는 서버에서 관리자 권한을 검사한다. 응답은 no-store/noindex이며 브라우저 사용자 전환 시 기존 결과와 진행 중 요청을 무효화한다.

## 실제 배포 및 소스

| 구분 | 확인값 |
|---|---|
| WEB 저장소 | `/Users/woojinchang/development/legendstudy-release-20261024` |
| WEB 브랜치 | `codex/web-app-release-20261024` |
| 기존 실제 운영 소스 | `2f838c29fa25c38c399a6a43f9d567dd89053ffc` |
| 기존 실제 운영 배포 | `f9e0e83f-6f93-470d-a1e0-0c711607c53c` |
| 기존 불변 URL | https://f9e0e83f.legendstudy-lab.pages.dev |
| 검수 UI 기준 | `1390452dd90ca17738fd3b4b27c92e76c11d781c` |
| 검수 경로 구현 최종 소스 | `ef5c635865e7801f6086602ef2c10e0ccb7174f3` |
| 최종 추가 배포 | `94ae321b-9471-418b-b0a2-d72d21a252ef` |
| 최종 불변 URL | https://94ae321b.legendstudy-lab.pages.dev |
| 배포 완료 | 2026-10-31 12:30:59 UTC, success |
| Pages 프로젝트 | `legendstudy-lab`, production branch `main` |

이번 배포는 의도적인 혼합 산출물이다. 기존 운영 959개 asset 경로/hash 및 20개 API source/route는 이전 버전 그대로 유지한다. 검수용 정적 파일 3개와 GET API 1개만 추가한다. 배포 metadata SHA는 검수 구현 SHA이며 `commit_dirty=true`로 전체 운영 코드가 그 SHA로 교체된 것이 아님을 표시한다. 후보 브랜치 전체 `out/`를 운영 업로드하지 않았다.

최종 배포 후 기존 959개 경로/hash 일치, production 설정 전체 일치를 확인했다. `/`, `/admin/`, `/login/`, `/my/essays/`, `/my/essays/result/` 실제 응답 HTML이 기존 불변 배포와 byte 단위 일치한다. evaluation service binding `ESSAY_REVIEWED_WORKER`와 compatibility date `2026-09-20` 유지. 첨삭 Worker 버전/설정은 변경하지 않았다.

## 백업과 롤백

비공개 백업: `/Users/woojinchang/.codex/legendstudy-backups/web-safe-preview-20261031` (디렉터리 0700, 원본 설정 0600).

- 원본 `project.json`, `deployments.json`, `deployment-files.json`, `production-function-routes.json`, exact Git archive `production-source/` 보관.
- 원본 959개 asset 중 956개는 다운로드 byte/hash 검증. `/lab/index.html`, `/lab/coverage/index.html`, `/lab/how-it-works/index.html`은 redirect 응답 때문에 원본 byte를 재확보하지 못했다. 해당 3개는 원래 Cloudflare asset hash와 불변 배포로 보존했으며 다운로드한 redirect 본문은 업로드하지 않았다.
- 저장된 Secret 원문은 플랫폼에서 회수 불가. 기존 binding/배포를 유지했다. 기존 compiled function binary의 완전한 offline export는 확보하지 않았으므로 독립적인 offline 복원 완료로 주장하지 않는다.
- `post-deployment-verification.json`, `project-after.json`, `new-deployment.json`, `deployment-plan.json`, `review-manifest.json`에 최신 검증/산출물 기록. 설정 원문과 학생 데이터는 Git에 넣지 않는다.

문제 발생 시 Cloudflare Pages의 기존 실제 배포 `f9e0e83f-6f93-470d-a1e0-0c711607c53c`로 rollback한다. API는 다음 경로에 인증된 POST이며 Secret을 명령행/문서에 기록하지 않는다:

`/accounts/b9d221b20fdf8b9a9a8df0971a6b2347/pages/projects/legendstudy-lab/deployments/f9e0e83f-6f93-470d-a1e0-0c711607c53c/rollback`

롤백 대상 배포 존재·success 및 원본 자산 보존을 확인했다. 실제 롤백 실행/복귀 리허설은 하지 않았다. 롤백 후 일반 로그인·기록·결과 조회와 canonical deployment를 재확인한다. DB/Worker/History/Credit rollback은 수행하지 않는다.

## 구현 및 권한

- `functions/api/owner-review/essay.ts`: `onRequest` GET만 허용. 정해진 origin·UUID query 검사 → Supabase Auth user 검증 → 기존 `admin_operator()`가 strict true일 때만 기존 `essay_exam_history(p_run)` 조회. 사용자 Bearer와 publishable key만 사용하고 service-role을 사용하지 않는다.
- `scripts/owner-review/app.tsx`: 기존 auth storage/session을 SDK로 사용. 최근 최대 50개 본인 시험 기록, 완료 run과 parent의 저장 결과 표시. 후보의 `EvaluationReport`, `EvaluationComparison`, `examReports`, `examQuestionLabel` 재사용. 제출/재처리/답안 저장 호출 없음. 계정 변경과 응답 경합은 요청 세대 번호로 차단한다.
- `scripts/owner-review/build.mjs`, `review.css`, `README.md`: 기존 서비스 public client 설정만 주입하는 검수 전용 build. 별도 로그인/새 Backend 없음.
- `cloudflare/owner-review.test.ts`: 11개 권한·입력·오류·읽기 계약 회귀.

운영 함수 정의를 SELECT로 확인: `admin_operator()`의 인증/JWT/admin_users 검증과 `essay_exam_history(uuid)`의 caller account 소유권 조건, SECURITY DEFINER/search_path 및 authenticated 실행 권한을 확인했다. 관리자라는 이유로 타인의 run을 조회할 수 없으며 기존 RPC의 소유권 검증을 그대로 사용한다.

초기 검수 전용 API에서 `READ_UNAVAILABLE` 발생: Cloudflare runtime이 fetch redirect `error` 옵션을 지원하지 않았다. `manual`로 변경하여 redirect를 따라가지 않고 non-2xx를 거절한다. 오류 응답은 개인정보/원문을 반환하지 않는다. 최종 배포에서 실제 조회 성공. 중간 검수 배포는 별도 버전으로 남으며 기존 일반 페이지는 교체하지 않았다.

## 검증

- WEB 전체: **1,420 PASS / 4 SKIP / 0 FAIL**, 196개 통과 파일/3개 skip 파일. TypeScript PASS. Lint 0 error/기존 4 warning. Next production build PASS. 최종 검수 bundle build PASS. APP 코드 변경 없음.
- API: anonymous 실제 HTTP 401, no-store/noindex 확인. 인증 실패/일반 사용자 거절/타인 run 미반환/GET 이외 거절/redirect 차단은 격리 테스트와 실제 함수 정의 검토. 일반 사용자 계정으로 실제 로그인한 E2E는 미실행.
- 기존 Chrome 관리자 실계정 세션으로 최신 검수 URL 재접속 성공, 실제 기록 15건 표시. 성균관 2026 언어형 2교시 재첨삭의 3문항 결과·parent 비교 조회 성공. run `0e9714ed-c2b3-4919-8bff-6582e499864b`, parent `b2cbc55f-edc7-423d-bfdc-f5d039b215e5`. 종합평가·작성 가이드·강점·보완·비교 내용 표시, 최종 페이지 alert 없음.
- 동일 계정 기존 운영 기록 및 결과 화면도 정상 조회. 기존 메뉴 로그인 세션과 Credit 94 표시 유지. 새 비밀번호/OAuth 로그인은 실행하지 않았고 기존 인증 세션 재사용을 검증했다.
- 현재 브라우저 계정의 목록에는 Owner 스크린샷의 최근 서울여대 기록이 없다. 해당 서울여대 run 실계정 검수는 완료로 주장하지 않는다.
- 검수 shell은 읽기 전용 결과 렌더러 검수용이며 전체 History/작성/재첨삭 업무 화면 대체물이 아니다. reserved run의 partial 결과 기능, 신규 제출, 모바일 전 너비, 실제 음성/인쇄는 이번 검수에서 별도 실행하지 않았다. 일부 오래된 문항은 registry label이 없어 기존 fallback ‘문항별 첨삭’을 유지한다.
- 운영 평가 요청/Provider 호출/재처리/Credit·History 수정 0. 전체 DB before/after audit hash를 대조한 것은 아니며, 실행한 경로가 읽기 전용임을 검증한 범위다.

## 보존 검토와 다음 단계

일곱 preservation 검토: (1) 평가 발생/저장 시점 유지, (2) 기존 답안·parent·digest로 재현, (3) UPDATE/새 원장 없음, (4) 기존 auth identity 유지, (5) Learning 결과만 조회, (6) 본인+관리자 권한/no-store·새 수집 없음, (7) UI projection을 새 평가 사실로 저장하지 않음.

Owner가 위 URL에서 실제 계정 결과를 검수한 뒤 **전체 운영 페이지 교체를 별도 승인**해야 한다. 현재 수정본 전체는 미배포 상태이며 승인 후 최종 branch diff·운영 설정·기존 API 호환성을 다시 확인하고 교체한다. 배포 직후 로그인·기록·결과 조회 확인 실패 시 기존 실제 배포로 복귀한다. 이번에는 additive preview만 운영 반영했다. 스토어 제출·실기기 설치 없음.

WEB commit/push: `8a4d3cb` 및 `ef5c635`, LOCAL/REMOTE SHA 일치 확인. 배포 기록은 이 Unified Wiki에 별도 commit한다.


## Owner 조건부 배포 승인 후 재검증 및 롤백 (2026-10-31)

최종 재검증에서 WEB LOCAL/REMOTE `ef5c635865e7801f6086602ef2c10e0ccb7174f3` 일치, 실제 canonical `94ae321b-9471-418b-b0a2-d72d21a252ef` success 확인. 이미 배포된 동일 검수본은 중복 배포하지 않았다. 권한 회귀 11/11 PASS, 비로그인 실제 GET은 401 LOGIN_REQUIRED/no-store. 기존 관리자 세션은 실기록 15건과 3문항 parent 비교를 정상 조회했다.

Owner가 직접 다른 계정으로 신규 로그인한 뒤 기존 운영 History 49건과 서울여대 무료 재첨삭 `6fe629cb-7bfd-4907-b144-439b299cfdc3`가 확인됐다. 그러나 같은 세션의 검수 페이지는 **HTTP 403 ADMIN_REQUIRED**를 반환했다. 로그인 성공과 관리자 권한을 구분한다. 서버 권한 gate를 우회하거나 admin_users/Auth/DB를 수정하지 않았다. 이 계정의 Owner 검수 접근 조건은 FAIL이며 신규 관리자 로그인 PASS로 보고하지 않는다.

Owner 지시의 ‘문제 발생 시 기존 운영 배포로 롤백’에 따라 Cloudflare rollback 실행: API success, canonical이 **f9e0e83f-6f93-470d-a1e0-0c711607c53c**로 복귀함을 확인했다. 현재 운영 SHA는 **2f838c29fa25c38c399a6a43f9d567dd89053ffc**다. 검수 후보 ef5c635와 배포94ae321b는 보존된다. 이전 섹션의 검수 경로 배포 상태는 이 최신 롤백 기록으로 대체한다.

비공개 증빙: `owner-approval-reverification.json`, `owner-conditional-rollback.json` (기존 백업 디렉터리). 이번 변경은 Pages rollback과 Wiki 기록뿐이다. DB/평가 Worker/Credit/History 변경 및 Provider/평가 요청 없음. 일반 사용자 차단은 이번 실제 비관리자 세션 403으로도 확인됐다. 서울여대 **검수본** 결과/이전 회차는 권한 차단으로 미검증. 재배포 전에 해당 Owner 계정의 관리자 자격 확인 및 필요한 권한 변경에 대한 별도 승인이 필요하다. 기존 관리자 접근 계정으로는 다른 계정 소유 기록을 대신 조회할 수 없다.

롤백 후 브라우저 reload 검증: 기존 서울여대 결과에서 문제1·문제2와 무료 재첨삭 내용, 로그인 세션, Credit95 표시 정상/alert 없음. 검수 API는 404로 회수됨을 확인(기존 브라우저에 남은 shell은 조회 실패를 표시). Python 기본 User-Agent HTTP 재대조는403으로 완료하지 못했으나 curl anonymous401과 브라우저 정상 조회를 별도로 확인했다.
