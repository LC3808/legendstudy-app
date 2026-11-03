# 온보딩/프로필 데이터 점검 — "학교 미설정" 의혹 · 2026-11-03

상태: **진단 완료 (읽기 전용 실측)**. 수정은 Codex(Flutter 앱) 영역 → 인계 대상.
담당: Claude(점검·리뷰). 대상: `profiles` 테이블(프로젝트 `stlhijzpjfgwwdgunlsd` LegendStudy).
배경: Owner가 관리자 회원목록에서 "학년만 있고 학교 없는 재학생이 많다 / 학교 설정했는데 '미설정'으로 뜨던 오류"를 보고 정상 여부 점검 요청.

## 1. 데이터 모델 (배포 브랜치 `codex/beta-store-release-task14` 기준)
- `profiles`: `id, display_name, grade_level(1~3), neis_office_code, neis_school_code, academic_status('student'|'retaker'|'other'), onboarding_completed_at`.
- 학교 = `neis_office_code`(3자)+`neis_school_code`(7자) NEIS 코드. **둘 다 null = 학교 미설정.**
- 학교명은 DB에 없음(참조 테이블 없음) → **NEIS 외부 조회로 렌더 시점에 이름 해석**. 앱 `SchoolSelection.build`는 코드가 있어도 `repository.find()`가 실패하면 `SchoolServiceException`을 던짐.
- 온보딩은 `_finish`(설정완료)와 `_skip`(건너뛰기) 모두 `markOnboardingComplete`로 끝남. **상태·학년은 마지막 `_finish`에서만 기록**, 학교는 선택 즉시 기록.

## 2. 실측 결과 (총 69 profiles, 2026-11-03 읽기 전용)
| status | users | 학교있음 | 학교없음 | 학년있음 | 온보딩미완료 |
|---|---|---|---|---|---|
| student | 33 | 14 | **19 (57.6%)** | 31 | 4 |
| retaker | 17 | 0 | 17 | 0 | 0 |
| **(null)** | **17 (24.6%)** | 1 | 16 | 2 | 5 |
| other | 2 | 0 | 2 | 0 | 0 |

정합성:
- `half_school_codes = 0` (한쪽 코드만 저장된 손상 행 없음) → **학교 저장 경로는 깨끗함**. 코드 표본 모두 형식 정상(office 3자 / school 7자).
- `nonstudent_with_school = 0`.
- `status is null AND onboarding_completed = 12` / `status null AND 미완료 = 5`.
- `has_nickname(display_name)` = **5/69** (닉네임은 대부분 미설정 — 별도 경로에서만 저장).
- edge: `student_no_grade = 2`; 학교+학년 있는데 `status=null` 1건(레거시/프로필수정 경로 추정).

## 3. 진단
1. **"학년 있고 학교 없음"(재학생 57.6%) = 버그 아님, 설계상 결과.** 온보딩 2단계 문구 "학교는 선택 사항". 학년=1탭 칩, 학교=검색+NEIS 선택(고마찰) + 전 단계 "건너뛰기". → 스킵이 자연스러움. 단 **57.6%는 과도하게 높음** → 학교기반 기능(급식·학사일정·대학매칭) 미활용. UX 개선 과제.
2. **"학교 설정했는데 미설정" = 저장 버그 아님.** DB 코드가 깨끗하고 완전. 원인은 **렌더 시 NEIS 이름 해석 실패**(앱 `SchoolSelection.build`가 에러를 던지는 설계, 또는 관리자 NEIS 조회). Owner가 이미 1차 수정. 잔존 손상 행 없음.
3. **★ status=null 17명(24.6%) = 실제 결함(데이터 손실).** 그중 **12명은 온보딩 완료했는데 상태 미기록.** 원인: **상태·학년이 마지막 `_finish`에서만 저장 → 중간에 "건너뛰기" 시 `markOnboardingComplete`만 호출돼 상태·학년 유실.** 관리자 "현재상태 빈칸" 행의 정체.

## 4. 권고 (수정 = Codex / UX = Claude)
- **P1 데이터 손실(Codex):** 온보딩 상태·학년을 **선택 즉시 저장**(학교처럼) 또는 `_skip`에서도 현재까지 고른 값 저장. 지금은 최종 단계 전 이탈 시 유실.
- **P2 학교 설정률↑(Claude UX):** '재학생' 선택 시 학교 유도 강화, 홈/MY에 "학교 설정 시 급식·학사일정" 넛지, 학교 검색 마찰 완화.
- **P3 표시 견고성(Codex):** NEIS 조회 실패 시 에러 대신 코드/조용한 폴백. 관리자도 실패 시 코드 표시.

## 5. 재현용 쿼리
`assets/.../scratchpad`가 아닌 영구 보관: 아래 3종(읽기 전용).
```sql
-- ① 상태별 분포
select coalesce(academic_status,'(null)') status, count(*) users,
  count(*) filter (where neis_school_code is not null) has_school,
  count(*) filter (where neis_school_code is null) no_school,
  count(*) filter (where grade_level is not null) has_grade,
  count(*) filter (where onboarding_completed_at is null) onboarding_incomplete
from profiles group by 1 order by users desc;
-- ② 정합성 이상치
select count(*) total,
  count(*) filter (where academic_status='student' and grade_level is null) student_no_grade,
  count(*) filter (where academic_status in ('retaker','other') and neis_school_code is not null) nonstudent_with_school,
  count(*) filter (where (neis_office_code is null) <> (neis_school_code is null)) half_school_codes,
  count(*) filter (where academic_status is null) status_null
from profiles;
-- ③ status null 세부
select
  count(*) filter (where academic_status is null and onboarding_completed_at is not null) status_null_but_onboarded,
  count(*) filter (where academic_status is null and onboarding_completed_at is null) status_null_not_onboarded
from profiles;
```
