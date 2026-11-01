# 공통 공지사항 — TASK 01


2026-11-01 TASK14-B: Production 설치·검증 완료. 공지2건 게시, 베타 campaign은 미활성(운영 WEB에 이전 2회 안내 잔존). [설치·권한·백업·잔여 차단 근거](final-store-rc-1.md#task14-b--scoped-backend-installation-and-owner-ux-defects).

2026-10-31 Owner 요청. **구현·격리 검증 완료 / 운영 SQL·WEB·APP 릴리스 미적용**.
기존 [홈/개인화](home-personalization-and-events.md), [MY](core-app-improvements.md),
[관리자 권한](admin-member-directory.md), [데이터 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 확장한다.
기존 개인 알림함과 문의 알림 큐는 대체하지 않는다. 푸시는 범위 밖이다.

## 확인한 실제 상태

- APP 기준 `ea0c0b1`, `codex/essay-evaluation-stability-p0-20261029`; 기존 untracked `.fvmrc` 보존.
- WEB 기준 `ef5c635`, `codex/web-app-release-20261024`, `/Users/woojinchang/development/legendstudy-release-20261024`.
- LegendStudy Supabase `stlhijzpjfgwwdgunlsd` SELECT: `notice_private` 없음. 기존 `admin_operator()`와 `account_private.allowed(uuid)` 존재.
- 기존 admin guard는 JWT 사용자·role·만료 및 admin_users를 검증한다. account guard는 auth.users 존재 및 DELETION_PENDING/ERASING 배제. 이 함수들을 변경하지 않는다.
- 기존 WEB 검수 배포 롤백 이력은 [별도 기록](web-safe-owner-preview-20261031.md). Git 상태를 운영 배포로 간주하지 않는다.

## 데이터와 API

단일 Supabase `notice_private` 도메인, 새 콘텐츠/읽음/변경 이력 3개 테이블. APP/WEB 별도 콘텐츠 복제 없음.

| 테이블 | 계약 |
|---|---|
| notices | notice_id UUID, title(1–200), content(1–50,000), category, status, is_pinned, published_at, expires_at, created_at, updated_at, created_by. 추가 is_public/show_app/show_web |
| reads | (user_id, notice_id) PK, read_at. 본인만 RPC로 기록; 계정 삭제 시 cascade |
| revisions | 매 저장 당시 snapshot + actor + recorded_at. 수정/보관도 보존. 계정 삭제 시 actor/created_by set null; snapshot에서 created_by 제외 |

카테고리 general/일반 공지, update/서비스 업데이트, beta/베타 테스트, maintenance/서비스 점검, policy/이용 정책, event/이벤트.
상태 draft/published/archived. 삭제 대신 보관을 제공한다.
`published` + 서버시간 `published_at <= now()` + `expires_at > now()`(또는 없음) + 채널을 만족할 때만 노출한다.
별도 Cron/Worker 없이 예약·종료가 판정된다. 종료 시 신규 조회에서 제외되며 이미 내려받은 화면을 강제로 회수하는 기능은 아니다.
비로그인도 is_public 공지를 볼 수 있다. 회원 전용은 활성 계정만 허용한다.
본문은 일반 텍스트로 저장/렌더링하며 HTML 실행이나 Markdown 외부 리소스 로딩을 하지 않는다.

| public RPC | 인자 | 권한 |
|---|---|---|
| notice_list | p_channel, p_offset=0, p_limit=20(최대50) | anon/authenticated: 공개 범위 적용 |
| notice_detail | p_notice_id, p_channel | anon/authenticated: 숨김/기간외/타깃외 NULL |
| notice_mark_read | p_notice_id, p_channel, p_updated_at | authenticated 활성 계정, 보이는 해당 버전만 |
| notice_admin_list | p_offset=0 | authenticated + admin_operator + 활성 계정 |
| notice_admin_save | p JSON | 동일 관리자 검증, 필드 화이트리스트·서버 작성자·수정 충돌 검사 |

모두 SECURITY DEFINER, search_path='', 스키마·테이블 완전 수식.
세 테이블 RLS ON, 클라이언트 직접 권한 없음. service_role에도 RPC 실행권한 없음.
UI에서 관리자 메뉴를 감추는 것과 별도로 DB 함수에서 강제한다.
기존 관리자 자격 없는 Owner 계정에는 자동 권한을 주지 않는다.

읽음은 user_id를 요청에서 받지 않고 auth.uid()로 강제한다. 같은 공지 ID를 APP/WEB에서 공유한다.
수정 후 updated_at이 read_at보다 크면 다시 NEW로 표시한다. 과거 버전을 보고 보낸 읽음은 최신 수정을 지우지 못한다.
서로 다른 관리자가 수정하면 expected updated_at 불일치로 NOTICE_CONFLICT. 초안은 화면에 유지하고 목록을 재조회한다.
읽음 실패 시 내용은 유지하고 서버 확정 전 읽음으로 간주하지 않는다.

## 보존 검토 — 7개 질문

1. 수집 사실: 운영자가 작성한 서비스 공지와 사용자 확인 시각이다. 학습 능력·평가 사실이 아니다.
2. 식별/연결: 안정적인 notice_id, 기존 auth.users ID 사용; 계정·Credit identity를 새로 만들지 않는다.
3. UPDATE 의미: 운영 콘텐츠 최신본은 편집 가능하되 모든 성공 저장본은 revisions에 남긴다. 읽음은 최신 버전 확인 상태의 projection이며 클릭 이벤트 원장이 아니다.
4. 동일 사용자: APP/WEB 기존 인증 UUID로 연결하며 게스트를 추적용 가상 계정으로 만들지 않는다.
5. Learning/Decision/Outcome: 서비스 커뮤니케이션이다. 성장/입시/추천 데이터로 재해석하지 않는다.
6. 권한/삭제: 관리자만 편집, 읽음은 본인; 계정 삭제 시 개인 읽음 삭제·작성자 연결 해제. 공지는 보관 방식으로 보존한다.
7. 파생값: unread는 실제 게시 조건과 updated_at/read_at에서 계산한다. 비로그인 미읽음은 0이며 허위 NEW 이력을 생성하지 않는다.

## 화면·파일·함수

APP (Flutter Native):
- `lib/features/notices/notices.dart`: Notice/NoticeFeed, NoticeApi, noticeFeedProvider/noticeDetailProvider/noticeUnreadProvider, NoticesPage/NoticeDetailPage.
- `lib/app/router.dart`: `/notices`, `/notices/:id`.
- `lib/features/profile/presentation/profile_page.dart`: MY 공지사항, 게스트도 접근.
- `lib/features/notifications/presentation/notification_bell.dart`: 기존 개인 알림 + 공지 미읽음 합산. 로그인은 기존 알림함, 게스트는 공지 목록.
- `lib/features/notifications/presentation/notifications_page.dart`: 기존 알림함 상단 공지 진입 유지. 개인 알림 목록/전체 읽음 기능 보존.
- 목록 20개 이전/다음, 고정/카테고리/NEW. 상세는 일반 텍스트. 목록 60초/복귀/수동 새로고침, 읽음 성공 시 캐시 무효화.

WEB (동일 저장소의 기존 UI/Supabase/Auth 사용):
- `src/lib/notices/client.ts`: noticesClient, RPC 계약.
- `src/components/notices.tsx`: Notices/NoticeDetail/NoticeNavLink. 계정 변경 시 콘텐츠/미읽음 초기화, 늦게 도착한 이전 응답 무시.
- `/notices/`, `/notices/detail/?id=<notice_id>`: static export에 맞춘 query 상세 경로, 20개 페이지.
- `src/components/admin/admin-notices.tsx`: AdminNotices/Editor/save. `/admin/notices/`, 기존 AdminSurface 서버 자격 확인 사용.
- `src/components/admin/admin-surface.tsx`, `src/components/site-nav.tsx`: 기존 메뉴 확장.
- 관리자 제목/본문/분류/상태/고정/공개·회원/APP·WEB 노출/게시 시작·종료, 즉시 시작 시각 설정. 날짜 입력은 관리자 기기 현지시간, DB는 timestamptz.
- 목록/미읽음은 60초 및 브라우저 focus/수동 새로고침으로 재조회. Realtime/푸시가 아니므로 다른 기기의 읽음 배지는 즉시성 보장이 아닌 다음 조회에 동기화된다.

## SQL 승인·적용·롤백

정확한 후보: [install](../supabase/candidates/notices_v1/install.sql), [verify](../supabase/candidates/notices_v1/verify.sql), [rollback](../supabase/candidates/notices_v1/rollback.sql).

1. Owner가 대상 프로젝트와 관리자 자격, 기존 admin/account guard 존재, notice_private 미존재 확인.
2. 승인 후 SQL Editor에서 install.sql **한 번** 실행. 트랜잭션이며 기존 스키마가 있으면 중단한다. 부분 설치/재설치는 먼저 상태 확인한다.
3. verify.sql 확인: 5 public 함수 security definer/search_path 고정, 읽기2 anon+auth, 쓰기3 auth만, service_role false, 테이블3 RLS true.
4. 검수 공지 작성이 별도 허용된 환경에서 실제 admin/일반/guest 로그인으로 아래 E2E 수행. 일반/게스트 admin 호출 거절, 공개·회원·기간·채널 확인.
5. DB 검증 후 WEB/APP 릴리스. **이번 작업은 SQL 적용·운영 배포·실기기 설치를 하지 않았다.**

rollback.sql은 일상 검증 절차가 아니다. 문제가 있을 때 클라이언트 공지 진입을 이전 코드로 되돌린 뒤 실행권한만 회수한다.
콘텐츠/수정 이력/읽음은 삭제하지 않는다. 기존 개인 알림은 유지된다.
롤백 뒤 install.sql 재실행 금지. 원인 검토/Owner 승인 후 정의를 재검증하고 원래 install 마지막 GRANT만 복구한다.
APP/WEB 코드 롤백은 이번 공지 커밋 revert 또는 기존 빌드 재배포로 수행한다. 강제 reset/기존 작업 삭제 없음.

## 검증 및 한계

- PostgreSQL 17, 독립 로컬 빈 DB: [local_test.sql](../supabase/candidates/notices_v1/local_test.sql) PASS. auth/admin/account fixture 사용, 실제 SET ROLE anon/authenticated 및 실행권한 검증.
- 공개/회원/초안/예약/종료/채널/보관, 다른 사용자 읽음 격리, APP→WEB 공유 읽음, 반복 읽음 idempotency, 수정 후 NEW/오래된 읽음 차단, optimistic conflict, 관리자 변경 snapshot, 비활성 계정/직접 테이블 차단, 롤백 후 데이터 보존 PASS.
- local_test.sql은 **격리 전용**이며 운영에서 실행 금지. 빈 PG cluster에서 `psql -v ON_ERROR_STOP=1 -f local_test.sql`; auth/admin stub을 만든다. 운영 인증의 대체 검증이 아니다.
- Flutter 3.47.6 Analyze: 0 issues. 전체 1,297 PASS / 7 SKIP. 최종 경계 처리 후 공지+기존 알림 24 PASS.
- WEB Node22: TypeScript/Production Build PASS; Lint 0 errors / 5 기존 warnings. 전체 1,429 PASS / 4 SKIP. 새 공지 테스트 9 PASS.
- Flutter 좁은 320dp/큰 글자 빈 목록, 로그인·비로그인 상세, 읽음 실패 내용 유지, 홈 종 합산/게스트 진입 검증.
- WEB 목록/상세/HTML 문자열 비실행/숨김/guest/읽음 실패/로그아웃 배지 제거/관리자 저장 실패 검증. 기존 메뉴 테스트는 공지 링크를 포함하도록 갱신.
- 자동 UI fixture + 실제 격리 SQL 검증이며 **운영 admin 작성→실제 APP·WEB 표시, 실계정 권한, 실기기, 운영 읽음 동기화는 NOT TESTED**.
- 전체 평가/Credit/History/OCR/PDF/Analytics 기존 회귀 포함. 이 영역 코드/운영 데이터를 수정하지 않았다. FCM/APNs 없음.

## 남은 작업

Owner SQL 승인·적용, 실제 관리자 계정 E2E, WEB 배포/APP 검수 빌드 및 실기기 검수.
코드 구현을 운영 사용 가능으로 보고하지 않는다. 새 공지 실제 작성·운영 평가/Provider 호출은 수행하지 않았다.

## 코드 식별

APP 구현 `3d562dc`, WEB 구현 `fb7f7df`. 문서 커밋은 별도이며 최종 LOCAL/REMOTE 확인 결과는 완료 보고에 기재한다.
