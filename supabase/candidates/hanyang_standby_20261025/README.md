# Hanyang STANDBY 2026-10-25

Owner 제한승인으로 SQL 적용완료. 재실행 금지.

SQL 경로(모두 적용완료, 재실행금지): `/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/hanyang-standby-20261025/`의 `registry-sql/`, `batch-a/owner-sql/`, `batch-b/owner-sql/`. 각 precheck→apply→postcheck 영수증 보존. Registry apply는 apply.sql, runtime은 apply.private.sql. [공개 명세·복구](../supabase/candidates/hanyang_standby_20261025/README.md).

복구: 한양 신규공개13 ID만 양쪽 공개scope에서 제외하고 WEB 재배포하면 기존55 공개 유지. runtime rollback은 최신 상태를 읽고 B→A 순서로 각 rollback.sql 적용; 신규case/PDF SELECT만 제거하며 기존학생결과/리뷰는 보존. Registry는 삭제하지 않는다. Worker 이전fafe9380+WEB 이전fd558454로 복구하려면 public scope도이전55로 함께 복구해야 한다(cap64). 전체설정/마스킹Secret 재전송 금지. 성균 manifest 수정만 되돌리면 누락이 재발하므로 정상수정 유지 권장. 복구실행은 이번 작업에서 수행하지 않았다.

보존7문항: (1) 원본시점과 이번연결일 분리, (2) 원본SHA와추출근거 유지, (3) 기존평가/리뷰 덮어쓰기 없음, (4) 기존auth identity 그대로, (5) 공식자료와학생Learning/Decision/Outcome 분리, (6) 정확한 문제PDF만authenticated SELECT·해설비공개, (7) STANDBY를평가성공/실력향상 사실로기록하지 않음. 오늘 범위 종료; 다음 Owner QA 오류에 최소 대응하고 다른 대학 확대하지 않는다.
