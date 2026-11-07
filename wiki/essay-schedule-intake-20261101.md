# 대학별 논술 일정 데이터 정비 — 입력 양식·검증 체계 (§7 / §12 / §E) — 2026-11-01, Claude

역할: Claude = 입력 양식·검증 체계 설계. **Owner가 공식 자료(요강 PDF/캡처/입학처 공지/URL)를 순차 제공**한다. 자료 제공 전 일정 값 **임의 생성 금지** — 양식·검증만 선행 준비하고, 미제공 대학은 추출 **대기** 상태로 둔다. **운영 DB 직접 반영 금지(Owner 승인 후).**

## 1. 기존 스키마 확인 결과
- **전용 "논술 일정" 테이블/엔진 없음.** APP에는 국가단위 모의고사/수능 카운트다운용 `lib/features/home/domain/day_event.dart`, `day_target.dart`, `study/notifications/mock_notification.dart`가 있고, `ExamMetadata`(`exam_metadata.dart`)에 `examDate/examMonth/year/academicYear/examRound/examType` 필드가 있으나 이는 **모의고사·수능 메타**이지 대학별 논술 일정이 아니다.
- WEB 대학 상세(`/essay-lab/universities/{id}/`)에 "2027학년도 논술 일정" 링크가 있으나, 현재는 정적 안내 수준으로 보인다(일정 DB 조회 UI 아님, 2026-11-01 실측).
- 결론: **대학별 논술 일정은 신규 staging 구조가 필요**하다. 본 문서는 운영 DB에 바로 넣지 않는 **중간 데이터(CSV/JSON) + 검증기**를 정의한다. 운영 테이블 설계·적용은 Owner 승인 후 별도 트랙.

## 2. 입력 양식 (staging) — 파일
저장소 포함(이 브랜치):
- `assets/essay-schedule/schedule-template.csv` — 헤더 + EXAMPLE 2행(모두 UNKNOWN / REVIEW_REQUIRED: 자료 미제공 상태의 올바른 기본값 예시).
- `assets/essay-schedule/schedule.schema.json` — JSON Schema(draft-07) 필드·타입·enum·패턴 정의.
- `assets/essay-schedule/validate.py` — CSV ↔ 스키마 + 교차필드 검증기(네트워크/DB 없음, read-only).

## 3. 필수 필드 (지시서 §7)
| 컬럼 | 의미 | 규칙 |
|---|---|---|
| `university_id` | sourceUniversityId(sogang 등) | `university_catalog.dart`에 존재해야 함 |
| `university_name` | 공식 대학명 | 요강 표기 |
| `academic_year` | **학년도**(입학 학년도) | 예: 2026학년도 수시논술 → 2026 |
| `conduct_year` | **시행연도**(실제 시행 연도) | **학년도≠시행연도**. 수시는 보통 학년도−1. 다르면 notes 사유 |
| `admission_type` | 전형명 | 수시논술/모의논술/정시 등 요강 명칭 그대로 |
| `track` | 계열/모집단위 | WEB 등록 계열과 정합(예: 인문계열(경제경영), 통합) |
| `exam_date` | 날짜 | `YYYY-MM-DD`(KST) 또는 `UNKNOWN` |
| `start_time` / `end_time` | 시작·종료 시각 | `HH:MM`(24h KST) 또는 `UNKNOWN`; 둘 다 known이면 start<end |
| `venue` | 장소(고사장) | 또는 `UNKNOWN` |
| `official_source_url` | 공식 출처 | 입학처 공지/요강 PDF. **임의 URL 금지** |
| `announcement_date` | 발표일 | `YYYY-MM-DD` 또는 `UNKNOWN` |
| `confirmed` | 확정 여부 | `CONFIRMED` / `TENTATIVE` / `UNKNOWN` |
| `review_status` | 검토 상태 | `REVIEW_REQUIRED` / `REVIEWED` / `REJECTED` |
| `source_evidence` | 근거 | 요강 파일명+페이지/캡처 식별자/공지 제목·일자 |
| `extracted_by` / `extracted_at` | 추출자·추출일 | 감사용 |
| `notes` | 비고 | 학년도≠시행연도 사유, 복수 교시 등 |

## 4. 검증 규칙 (validate.py가 강제)
- `university_id` ∈ 카탈로그 sourceUniversityId(카탈로그가 있는 브랜치에서 실행 시).
- 날짜/시각 포맷 또는 `UNKNOWN`. 미확인=UNKNOWN(절대 임의 생성 금지).
- enum: confirmed / review_status.
- 교차검증: exam_date·start·end 모두 known이면 start<end.
- **공식 근거 없으면 REVIEWED 불가**: `official_source_url` 비거나 `source_evidence` 비면 `review_status=REVIEWED` 거절(운영 승인 후보 차단) → 임의 데이터가 승인 단계로 올라가는 것을 막음.
- 경고: 학년도==시행연도(수시 특이), 학년도≠시행연도인데 notes 없음, confirmed=CONFIRMED인데 exam_date=UNKNOWN.
- 실행: `python3 -I assets/essay-schedule/validate.py <csv>` (exit 0=valid, 1=error 존재).

## 5. 작업 흐름 (Owner 자료 순차 제공 대응)
1. **지금(자료 전)**: 42개 대학에 대해 `university_id`/`university_name`/`official_source_url`(카탈로그 보유분)만 채운 행을 만들고 나머지는 `UNKNOWN`, `review_status=REVIEW_REQUIRED`로 **대기 행** 생성 가능(선택). 날짜·시각은 **입력 금지**.
2. **자료 제공 시(대학 단위)**: 해당 대학 요강/공지에서 날짜·시각·장소·발표일 추출 → 행 갱신, `source_evidence`·`official_source_url` 기재, `confirmed` 판정, `review_status=REVIEW_REQUIRED`→(검토 후)`REVIEWED`.
3. **검증**: validate.py 통과(0 errors) 필수.
4. **Owner 승인**: REVIEWED 행만 운영 반영 후보. 운영 테이블 설계·마이그레이션은 별도 트랙(아래 §6).
5. **미제공 대학**: 계속 대기(REVIEW_REQUIRED, UNKNOWN). 보고 시 "추출 대기"로 명시.

## 6. 운영 반영(향후, Owner 승인 후 — 본 작업 범위 밖)
- staging(REVIEWED) → 운영 테이블로의 승격은 신규 마이그레이션 설계가 필요하며, 기존 Supabase 정책(AGENTS.md §4: Owner가 직접 SQL 적용)을 따른다. 본 문서는 **테이블을 만들지 않는다.**
- 매핑 제안(설계용, 미적용): `university_id`→기존 university UUID(catalog의 `universityId`), `track`→Registry 계열, 날짜/시각→timestamptz(KST), `confirmed`/`review_status`→운영 가시성 게이트. 실제 컬럼·RLS는 Owner 승인 후 확정.

## 7. 검수 기준 / 미완료
- [ ] validate.py가 템플릿에서 0 errors(확인: 2 rows, 0 invalid).
- [ ] 자료 제공 대학만 날짜 입력, 미제공은 UNKNOWN 유지.
- [ ] REVIEWED 행은 모두 official_source_url + source_evidence 보유.
- **미완료(대기)**: 모든 대학의 실제 일정 값 — Owner 공식 자료 **순차 제공 대기**. 운영 테이블 설계·적용은 Owner 승인 후.
