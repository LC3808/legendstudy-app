# 마케팅 Analytics 이벤트 명세 (§9 / §13 / §F) — 2026-11-01, Claude

역할: Claude = 이벤트 계약 설계. 구현·GA4 설정·배포는 Codex/Owner. **기존 Analytics v1 재사용·확장**( [analytics-v1-implementation-20261030.md](analytics-v1-implementation-20261030.md), 브랜치 `claude/legendstudy-analytics-v1-9a315b`). **새 분석 시스템 개발 금지. 기존 이벤트명·필드와 중복/충돌 금지(기존 계약 우선).** Codex TASK 03(기존 analytics 통합)과 충돌 회피.

## 0. 아키텍처 재확인 (불변)
- **GA4/Firebase = 행동·전환 퍼널**(이벤트 발생 ≠ 서버 완료).
- **PostgreSQL = 공식 집계**(첨삭 완료/Credit/매출). 배너 성과의 "공식 완료/매출 기준"은 GA4가 아니라 DB.
- 전송은 fire-and-forget·sanitizer allowlist 통과·세션당 중복방지(`logEventOnce`). 답안/평가/인증정보 전송 불가.

## 1. 핵심 원칙 — 기존 계약과 중복 금지
`lib/features/analytics/domain/analytics_events.dart`의 기존 상수/allowlist가 **진실원천**이다.

### 1-1. LAB 진입·첨삭 이벤트는 **신규 생성 금지, 기존 재사용**
| 지시서 요구 | 사용할 **기존** 이벤트 | 비고 |
|---|---|---|
| LAB 진입 | **`essay_lab_view`** (이미 `lab_page.dart`에 계측됨, onceKey 'lab_view') | 신규 `lab_enter` 만들지 말 것 |
| 첨삭 시작 | **`essay_submit_start`** (기존, 미계측 — 1줄 패턴으로 추가) | |
| 최초 첨삭 완료 | **`essay_completed`** + `attempt_no=1` (+ `is_free=true`) | 신규 `first_essay_done` 금지. "최초"는 파라미터로 구분 |

> "앱스토어 이동 클릭 ≠ 실제 설치 완료"와 동일하게, `essay_completed`(이벤트) ≠ 공식 완료(DB). 공식 "최초 첨삭 완료" 집계는 PostgreSQL( `credit_grants`/`run` lineage, Analytics v1 §5)로 산출.

### 1-2. 필드는 기존 키에 매핑 — `university_id`/`exam_id` 생성 금지
기존 allowlist는 `university_code`, `exam_code`를 쓴다. 지시서의 `university_id`/`exam_id`는 **기존 키와 중복/충돌**이므로 **새 키를 만들지 않고 매핑**한다:
| 지시서 요구 필드 | 실제 사용 키(기존/신규) |
|---|---|
| `platform` | `platform` (기존) |
| `university_id` | **`university_code`** (기존, 매핑) |
| `exam_id` | **`exam_code`** (기존, 매핑) |
| `source_page` | **`source`** (기존 재사용 권장) 또는 신규 `source_page` — §2-2 결정 |
| `banner_id` | **신규** |
| `banner_type` | **신규** |
| `destination_url` | **신규** |

## 2. 신규 이벤트 — 배너 노출/클릭 (기존에 없음)
배너 전용 이벤트는 기존 계약에 없으므로 **신규 2개만** 추가한다(남용 금지).

```dart
// analytics_events.dart 에 append (additive, 로직 변경 없음)
static const bannerImpression = 'banner_impression'; // 배너가 화면에 보임
static const bannerClick       = 'banner_click';      // 배너/ CTA 클릭
```

### 2-1. 공통 파라미터 (배너 이벤트)
| 키 | 값(controlled vocabulary) | 필수 | 비고 |
|---|---|---|---|
| `banner_id` | 슬러그. 자산 키와 1:1: `ios_launch` / `android_launch` / `lab_beta` / `univ_post` | ✔ | 캠페인 식별 |
| `banner_type` | enum: `app_ios` / `app_android` / `lab_beta` / `univ_post` | ✔ | 배너 종류 |
| `destination_url` | 이동 대상 **정규 URL**(아래) | ✔(click) | 100자 cap 주의(§2-3) |
| `source_page` 또는 `source` | 노출 위치: `web_main_slider` / `web_univ_post` / `app_lab_banner` / `app_home` | ✔ | §2-2 |
| `platform` | `web` / `ios` / `android` | ✔ | web은 Tistory/LAB web, ios/android는 APP |
| `university_code` | 대학 코드(§B univ_post에서만) | 조건부 | sourceUniversityId와 정합 |
| `exam_code` | 시험 코드(선택) | 선택 | |

`destination_url` 값(정규):
- `app_ios` → `https://apps.apple.com/us/app/.../id6820826957`
- `app_android` → `https://play.google.com/store/apps/details?id=com.legendstudy.app&hl=ko`
- `lab_beta` → `https://lab.legendstudy.com`
- `univ_post` → `https://lab.legendstudy.com/essay-lab/universities/{university_code}/`

### 2-2. `source_page` vs 기존 `source`
기존 allowlist에 `source`가 있다. **중복 키 생성 회피**를 위해 **두 가지 중 하나를 선택**해 Owner/Codex 합의:
- (권장 A) 기존 `source` 재사용 + 값에 노출 위치 vocabulary. → allowlist 변경 최소.
- (B) 명시성 위해 `source_page` 신규. → allowlist에 1개 추가. 본 문서 표는 둘 다 허용하되 **하나만 운영**.

### 2-3. allowlist 확장 (sanitizer)
신규 키는 `AnalyticsParamKeys.allowed`에 추가해야 전송된다(없으면 sanitizer가 drop). 추가:
```dart
static const bannerId = 'banner_id';
static const bannerType = 'banner_type';
static const destinationUrl = 'destination_url';
// (B안 채택 시) static const sourcePage = 'source_page';
// allowed 집합에 위 키 추가. forbidden/PII 규칙·100자 cap·비원시 drop 은 그대로.
```
주의: `destination_url`은 sanitizer의 **100자 cap** 대상이다. iOS 스토어 URL은 인코딩 포함 ~90자로 경계값 → **정규 URL은 100자 이내로 유지**하거나, 길면 `banner_type`로 대체 식별하고 `destination_url`은 짧은 canonical(예: 호스트+path)만 보낸다. URL에 **PII/쿼리 토큰 금지**(개인정보: URL 파라미터에 개인정보 금지 원칙과 일치).

## 3. 계측 지점 (surface별)
| 이벤트 | 위치 | 송신 경로 |
|---|---|---|
| `banner_impression` / `banner_click` (web_main_slider) | `legendstudy.com` **티스토리 스킨** 메인 슬라이더 | 티스토리 사이트 GA4(gtag `G-295EQHYTCK`, 이미 로드됨) `gtag('event', …)` |
| `banner_impression` / `banner_click` (web_univ_post) | `legendstudy.com` 대학별 자료실 게시글 삽입 배너 | 동일 티스토리 GA4 |
| `banner_click` (app_lab_banner) | APP LAB 배너 | 기존 `ref.read(analyticsServiceProvider).log(AnalyticsEvents.bannerClick, params:{…})` |
| `essay_lab_view` | LAB 진입(APP `lab_page.dart` 기존 / LAB web) | 기존 계측 재사용 |
| `essay_submit_start` / `essay_completed` | 첨삭 제출/완료 | Analytics v1 §2 미완료 목록의 1줄 패턴으로 추가(핫 컨트롤러 주의) |

> **크로스-프로퍼티 주의**: Tistory `legendstudy.com`의 GA4(G-295EQHYTCK)와 LAB/APP의 Firebase GA4는 **별개 스트림**이다. 배너 click→LAB 퍼널을 한 퍼널로 잇는 접속(join)은 **GA4 크로스도메인 측정**(legendstudy.com → lab.legendstudy.com 동일 property/도메인 연결) 설정이 선행이다. 미설정 시 두 프로퍼티의 이벤트는 분리 집계된다. 이벤트 **스키마는 동일**하게 유지해 사후 통합을 가능케 한다.

## 4. 전환 흐름 A / B / C 분석 설계
측정 가능 구간과 **측정 불가 구간을 명확히 분리**(측정 불가를 완료로 표기 금지).

### A. iOS 앱 출시 배너
`banner_impression(app_ios)` → `banner_click(app_ios, destination=App Store)` → **[App Store 이탈 — 설치는 GA4에서 측정 불가]** → (설치 후) `app_open`(Firebase, APP) → `sign_up`/`login`.
- 측정: 노출·클릭(웹), 앱 오픈·가입(앱). **클릭→설치 전환율은 GA4로 산출 불가**(스토어 콘솔/어트리뷰션 SDK 필요). 보고 시 "클릭"과 "설치/오픈"을 **별도 지표**로.

### B. Android 앱 출시 배너
A와 동일 구조(`app_android`, Google Play). 설치 전환 동일하게 측정 불가.

### C. 논술 LAB 베타 배너 (완전 측정 가능, 동일 도메인군)
`banner_impression(lab_beta)` → `banner_click(lab_beta)` → `essay_lab_view` → `university_select` → `exam_select` → `essay_submit_start` → `essay_completed(attempt_no=1,is_free=true)`.
- "최초 첨삭 완료"는 `essay_completed`의 `attempt_no=1`로 **행동 추정**, **공식 수치는 PostgreSQL**(Analytics v1 §5 funnel RPC)로 확정.

### §B 대학별 게시글 배너 (univ_post)
`banner_impression(univ_post, university_code)` → `banner_click(univ_post, university_code)` → `essay_lab_view(university_code)` → … → `essay_completed`. 대학별 성과는 `university_code`로 분해(Analytics v1 §5 "대학별" RPC 재사용).

## 5. Codex TASK 03 충돌 회피
- **추가만**: `analytics_events.dart`에 상수 2개 + allowlist 키 2~3개 추가(로직 변경 없음) → 기존 통합과 저충돌.
- 배너 click 계측은 **log() 1줄** 추가(핫 컨트롤러 아님: 배너 컴포넌트/스킨). `essay_submit_start`/`essay_completed`는 Analytics v1 §2 "미완료" 목록에 이미 1줄 패턴으로 예정 → **중복 계측 금지**(한 곳에서만).
- Supabase 집계는 기존 `analytics_admin_reporting_20261030` RPC 재사용(배너용 신규 테이블/RPC 불필요). 배너 노출/클릭은 GA4에만, 공식 전환은 기존 DB RPC.

## 6. 측정 가능/불가 명시 (과장 금지)
| 지표 | 측정 | 출처 |
|---|---|---|
| 배너 노출/클릭 | 가능 | GA4(web/app) |
| 앱스토어 이동 클릭 | 가능 | GA4 `banner_click` |
| **실제 앱 설치 완료** | **불가(GA4)** | 스토어 콘솔/어트리뷰션(별도) |
| LAB 진입·첨삭 시작/완료(행동) | 가능 | GA4 |
| **공식 첨삭 완료·Credit·매출** | 공식=DB | PostgreSQL RPC |
- "클릭"을 "설치/완료"로 치환해 보고하지 않는다. 크로스도메인 미설정 시 퍼널 단절을 명시한다.

## 7. 검수 기준 / 미완료
- [ ] 신규 이벤트는 `banner_impression`/`banner_click` 2개뿐, 기존 이벤트명과 충돌 없음.
- [ ] 필드가 `university_code`/`exam_code`/`platform`/`source(_page)` 기존 키에 매핑, 신규는 `banner_id`/`banner_type`/`destination_url`만.
- [ ] allowlist에 신규 키 추가(없으면 drop 확인), `destination_url` 100자/PII 규칙 준수.
- [ ] LAB 진입=`essay_lab_view`, 첨삭 시작=`essay_submit_start`, 최초 완료=`essay_completed(attempt_no=1)` 재사용.
- [ ] 설치 전환을 GA4 완료로 표기하지 않음.
- **미완료**: GA4 크로스도메인(legendstudy.com↔lab) 설정, Firebase 실수신 검증(Analytics v1 §15 선행), `source` vs `source_page` 최종 택1(Owner).
