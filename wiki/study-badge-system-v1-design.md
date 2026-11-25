# 학습 배지 v1 — PHASE A 설계, 2026-11-25

상태 **DONE(설계 초안) / PLANNED(구현)**. Catalog·조건·등급은 Owner 검토 전 후보다. 운영 DB 설치·지급·이미지 제작 없음. 기존 [Achievement 결정](roadmap-academic-analytics.md#9-achievement--badge-engine), [상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md), [Study 계약](study-v1.md)을 재사용한다. 로그인/광고/합격 예측 배지는 금지한다. 공부량은 Behaviour이며 성적 성장의 증거가 아니다.

## 목적과 기존 구조

자료 이용 후 자신의 학습 기록을 이어 갈 이유를 제공한다. 배지가 리텐션을 개선했다는 효과는 아직 측정되지 않았다. 별도 경쟁·랭킹·하단 탭을 만들지 않는다.

기존 Flutter StudyController는 기기별 활성 타이머와 immutable 완료 세션/outbox를 분리한다. 서버 `public.study_sessions`는 id/user_id/mode/started_at/ended_at/active_segments/duration_seconds/include_in_study_total을 보유한다. 게스트 기록은 계정에 자동 귀속하지 않는다. active_segments의 일자별 교집합을 KST로 분할하고 기기 간 겹친 시간을 union한다. 세션 duration의 단순 합은 사용하지 않는다. 공부·모의고사 중 include_in_study_total=false는 시간 배지 제외. 현재 Home/Study는 진행 중·미동기화 기여도 표시하지만 **배지 확정은 서버에 동기화된 완료 기록만** 사용한다. UI에 동기화 대기를 구분한다. 학교 순위 참여 동의/학교 소속은 개인 배지 자격으로 복제하지 않는다.

2026-11-25 읽기 전용 확인: 서버 Study102세션/40사용자. 최초 기록2026-09-23, 최근11-23. 기존 별도 배지 저장소·지급 엔진은 확인되지 않았다. 자료 유형 ContentTypeBadge와 구분한다.

## 저장 선택 전 일곱 보존 질문

1. 사실은 완료 학습 세션과 평가 완료이며 배지는 그 파생 판정이다. achieved_at(조건 도달), evaluated_at(평가), recorded_at(지급)을 분리한다.
2. 원본 세션 UUID/정의 버전/관측 cutoff/입력 digest로 재현한다. 삭제 권리를 이유로 원본을 영구 복사하지 않는다.
3. 현재 progress는 갱신 가능하지만 award의 지급·취소·복구 사건은 append-only. 정정 전후 이유를 남긴다. 기존 Study 원본을 배지를 위해 수정하지 않는다.
4. 기존 auth.users.id 한 명에 연결한다. 학교 변경이 과거 주체나 배지 소유자를 바꾸지 않는다.
5. Study는 Learning, 완료 첨삭도 학습 행동이다. 입시 Outcome이나 미래 합격 예측과 혼합하지 않는다.
6. 자신의 배지만 조회; 관리자 정정은 서버 권한+감사. 미성년자·보관/계정삭제 정책은 기존 계약에 연결하고 학교/외부 공개·광고 전송은 별도 승인 전 금지.
7. progress/award는 versioned derived data다. 삭제·누락·늦은 동기화로 재계산 가능하며 사실 성적처럼 표현하지 않는다.

## 초기 Catalog 25개 후보

공통: 유효 완료 세션, KST 달력, union milliseconds를 먼저 집계하고 마지막에 초로 내림. 초기 시간 조건은 아래와 같으며 별도 초과 보상 없음.

|코드|이름|조건|등급 후보|
|---|---|---|---|
|start_first|첫걸음|첫 유효 완료 공부 기록(1초 이상)|Bronze|
|start_hour|학습의 시작|누적1시간|Bronze|
|total_10|작은 성취|누적10시간|Bronze|
|total_30|꾸준한 노력|누적30시간|Silver|
|total_50|성장하는 나|누적50시간|Silver|
|total_100|100시간의 기록|누적100시간|Gold|
|total_300|노력의 증명|누적300시간|Gold|
|total_500|학습 마스터|누적500시간|Platinum|
|total_1000|레전드 스터디|누적1,000시간|Legend|
|streak_3|작심삼일 돌파|3일 연속 각30분 이상|Bronze|
|streak_7|일주일의 약속|7일 연속 각30분 이상|Silver|
|streak_14|습관의 시작|14일 연속 각30분 이상|Silver|
|streak_30|한 달의 성장|30일 연속 각30분 이상|Gold|
|streak_60|꾸준함의 힘|60일 연속 각30분 이상|Platinum|
|streak_100|100일의 기적|100일 연속 각30분 이상|Legend|
|day_1|집중의 시간|한 KST일1시간|Bronze|
|day_3|오늘도 성장|한 KST일3시간|Silver|
|day_5|몰입의 하루|한 KST일5시간|Gold|
|day_8|한계 돌파|한 KST일8시간|Platinum|
|month_30|성실한 한 달|KST달력월30시간|Silver|
|month_60|성장하는 한 달|KST달력월60시간|Gold|
|month_100|빛나는 한 달|KST달력월100시간|Platinum|
|essay_first|첫 논술 도전|실제 첫 첨삭 completed|Bronze|
|essay_revision|다시 쓰는 힘|부모 결과와 연결된 실제 재첨삭 completed|Silver|
|essay_growth|논술 성장 기록|동일 시험·기준의 신뢰할 수 있는 개선 판정|HOLD|

성장하는 나/오늘도 성장이라는 후보 이름도 시간만으로 성적 향상을 암시하지 않는지 Claude·Owner 검토. 8시간·100일을 강요하는 메시지/스트릭 손실 벌칙 금지. 첫 두 배지를 한 세션에서 얻어도 알림은 하나로 묶는다. 현재 과거 기록을 인정하는 방향을 권장하되 관리자/검증 테스트 학습을 제외하는 규칙은 구현 전에 확정한다.

## 지급·정정 정책 제안

- 초기 v1은 모든 배지 **최초1회** 권장. daily/monthly의 재획득은 배지 대신 해당 기간 달성 이력으로 별도 표시할 수 있다. 대안은 period_key=KST일/월의 반복 award이나 알림·보관량·자격취소 복잡도가 증가한다. Owner가 결정한다.
- 소급 인정: 동기화된 과거 기록을 사용자별 페이지 처리, dry-run 비교 후 승인된 backfill. 정확한 조건 최초 충족 시각을 복원할 수 있으면 achieved_at, 불가능하면 null과 `historical_qualification` 표시; 지급일을 과거로 날조하지 않는다.
- 오프라인: 세션 UUID 멱등 삽입 성공 후 해당 날짜와 양옆 스트릭 연결 구간 재계산. 동기화 전 서버 획득 확정/클라이언트 단독 지급 금지.
- 삭제·정정: eligibility 재계산으로 근거가 사라지면 award RETRACTED 사건+이유; 다른 유효 근거가 있으면 유지. 대표 배지가 취소되면 선택 해제. 단순 조건 상향은 기존 award를 자동 회수하지 않고 rule version migration 정책 별도 결정.
- 비정상: 기존24시간 span/256segments/음수·겹침 검증 재사용, 미래시간/일자 역전은 검토 대기. 자기보고라는 한계를 유지하고 장시간만으로 부정행위를 확정하지 않는다. 계정 탈퇴 시 개인정보 삭제 정책을 우선하며 감사기록도 보관 근거 없이 영구 유지하지 않는다.

## Backend 모델·RPC 초안 (설치 SQL 아님)

기존 Study 저장소를 source of truth로 둔다. 아래 신규 구조는 승인 후 Migration으로 작성한다. [설치 차단된 SQL 구조 초안](../supabase/candidates/study_badges_v1/design.sql)을 제공한다. 무조건 예외 guard와 rollback이 있으며 적용용 Migration이 아니다. RPC·trigger·seed·backfill·활성화 코드는 없다.

|후보 테이블|키/필드|권한/보존|
|---|---|---|
|badge_catalog|badge_key,rule_version,kind,threshold,periodicity,title,grade,enabled,definition_json|학생 공개된 정의 조회만; 서버 관리자 변경·버전추가|
|badge_awards|id,user_id,badge_key,award_key,rule_version,achieved_at,awarded_at,state,evidence_digest,cutoff|unique(user_id,badge_key,award_key), 본인SELECT; 직접INSERT/UPDATE 금지|
|badge_award_events|event_id,award_id,event_type,reason,actor,recorded_at,source_revision|서버append-only, 공개 응답에 내부 정보 제외|
|badge_progress|user_id,metric_key,period_key,metric_version,value_ms,source_revision,computed_at|파생cache, 서버쓰기; 오래됐으면 갱신중 표시|
|badge_profile|user_id,representative_award_id|본인 RPC로 자기ACTIVE award만 선택|
|badge_recompute_jobs|user_id,dirty_from,dirty_to,source_revision,status|서버전용; 같은 사용자 작업 병합|

award_key는 최초1회 정책 `lifetime`으로 고정하며 rule_version을 unique에 포함하지 않아 버전업 중복 지급 방지. 반복정책 도입 시 명시 period_key 전환 검증. 원천 이벤트ID를 이용해 INSERT ON CONFLICT DO NOTHING 및 사용자별 트랜잭션 잠금으로 concurrent timer+backfill 중복 방지. 이벤트와 award를 한 트랜잭션에 기록한다. 공식 조정은 service/admin검증 RPC만, admin JWT client버튼 유무와 무관하게 검사한다.

후보 RPC `my_badges`, `set_representative_badge`, 서버전용 `recompute_user_badges`. 일반 사용자 supplied user_id로 타인 조회/지급 불가. 익명은 기기-local 학습만, 서버 badge 없음. WEB/APP은 같은 RPC 결과 사용. Study 세션 저장 후 안전한 dirty-job만 추가하고 학습 저장 성공을 배지 계산 실패와 결합하지 않는다. 재시도 상한·실패 큐·운영 알림은 구현 단계에서 확정.

성능: 사용자/날짜 기준 집계cache 및 dirty 범위 재계산. 최근 날짜 overlap과 역순 offline입력 때문에 단순 +duration 증분은 금지. 일별 union을 갱신하고 cumulative/month/streak 파생을 갱신한다. 화면진입은 projection조회, 전체 원본 재계산 아님. source_revision/완료revision 비교로 stale job publish 방지. backfill cursor+batch와 실행시간 상한, EXPLAIN·동시성·lock테스트가 출시 gate다.

## 화면 및 Claude 검토 명세

- 홈: 기존 D-Day 대표1+가까운2 구조 유지. 배지는 최근획득1+다음목표1의 접을 수 있는 작은 영역, 실제 데이터 없으면 홍보용 빈 카드 미노출.
- 학습 관리: 기존 누적시간/추이 아래 현재연속일·다음배지 진행률. 오늘30분미달도 어제까지 연속기록을 즉시실패 처리하지 않는다. 시간집계와 동기화대기를 설명한다.
- 타이머 종료: 저장완료 뒤 획득이 확정되면 한 번의 비차단 안내; 여러개는 “배지2개” 묶음. 동기화지연 시 종료를 막거나 반복팝업하지 않는다.
- MY: 대표1개, 획득수, 배지함. 본인 획득ACTIVE 중 선택; 개인정보 공유 기본비활성.
- 컬렉션: 카테고리, 획득/미획득, 조건·현재값·획득일. 미획득의 카탈로그 공개는 이번 Owner 요청의 설계 방향이며 과거 ‘빈 speculative 메뉴 미노출’과 구분: 승인된 실제Catalog+Backend 이후에만 노출. 아직 기능 메뉴 추가 없음.
- 메달/엠블럼, 브랜드#FFAC14 강조, 등급은 색뿐 아니라 텍스트/형태로 구분. 텍스트 대비·큰글자·스크린리더·reduce motion·44/48px 터치 검증. 학생에게 rank/성적예측 표시 금지.

## 단계·검증·승인

PHASE A 이번 설계 완료. B 시작/누적/연속+컬렉션 4~6개발일, C 일/월·대표·안내·목표 2~4일, D 논술 행동배지 2~3일. 추정치는 개발자1명 기준이며 디자인검토·Owner결정·실기기QA 대기는 별도. 성장배지는 근거계약 확정 전 일정 미정.

필수 tests: 23:50~00:20·pause·월/연도경계·윤년, 겹친두기기union, 중복UUID·동시job, 제외mock, offline역순, 계정전환, 삭제후자격재계산, ruleversion변경중복방지, 타인RPC차단, 소급날짜unknown, 대표취소, 계산실패에도세션보존, 1/30/1000시간 경계와 전체재계산대조. 운영 데이터 테스트 금지.

Owner 결정 필요: 후보25개/이름/등급, 일30분, 최초1회vs반복, 소급범위, 잘못된기록취소안내, 성장배지HOLD. Claude: 홈정보량·미획득표현·배지5등급·긴이름·접근성·알림피로. 운영 DB·backfill·출시는 각각 승인 전 금지.
