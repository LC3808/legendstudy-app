# 대학 검색 Catalog 확장 — CLOSED

2026-11-12 Owner가 한국교원대학교 포함78개 추가 작업의 완료를 승인했다. 이 문서는 해당 Catalog 작업만 마감하며 온보딩·이메일 인증 전체 작업이나 APP 릴리스 완료를 뜻하지 않는다. **APP 릴리스 HOLD 유지**.

작업 브랜치: `codex/email-auth-stabilization-20261111`. 운영 적용·검색 검증 기록 커밋: `bffa2104`(짧은 SHA). 이번 종료 변경은 Wiki 문서만이며 한국항공/건국 논술 작업 브랜치의 커밋을 병합하거나 cherry-pick하지 않는다.

## 최종 결과

|항목|결과|
|---|---|
|전체 등록 대학|131개 (기존53 + 신규78)|
|활성 검색 대학|128개, 기존 비활성3개 유지|
|한국교원대학교|추가 완료, 기존 승인 UUID/slug knue 유지|
|관심 대학 검색|PASS — 운영 공개 API + 실제 Flutter 검색 위젯/Repository|
|실제 지원 대학 검색|PASS — 운영 공개 API + ApplicationEditor/Repository|
|기존 대학 ID·사용자 데이터|보존 확인|
|논술 LAB|변경 없음, 신규 대학 essay_exams 연결0|
|iPhone 실기기 검색|**NOT TESTED**|
|WEB 배포본 E2E|**NOT TESTED**|

이후 iPhone 물리 화면 검색과 WEB 배포본 검증은 잔여 검증으로 남긴다. 국가 전체 대학 목록 완전성 검증과 아래7개 정체성 조사는 이번 승인78개 범위 밖의 후속 검토다. 기존 비활성 대학 활성화도 별도 범위다.

## 운영 적용과 검증 근거

- [실행 SQL 영수증](../supabase/candidates/university_catalog_20261112/applied.sql), [운영 결과 JSON](assets/university-catalog-applied-20261112.json), [목록 대조표](../supabase/candidates/university_catalog_20261112/audit.csv), [원본 감사 metadata](assets/university-catalog-audit-20261112.json).
- Owner 승인 아래 ROLLBACK 리허설 후 COMMIT했다. 적용 후 독립 조회131/활성128, 신규78, 보류7 해당행0을 기록했다. 이번 종료 작업에서 추가 SQL을 실행하거나 재적용하지 않았다.
- 기존53개 대학은 시각 포함 전체 컬럼 불변. REPEATABLE READ transaction 안에서 profiles535, student_target_universities281, student_applications0, essay_exams450, essay_questions1232의 행 수·전체행 해시가 전후 같았다. 이 값은 **당시 적용 증거**이며 현재 실시간 사용자 수를 뜻하지 않는다.
- 승인된 신규78개 각각을 공개 검색 API로 조회해 UUID가 일치했고, 한국교원대/공백/KNUE 별칭도 같은 ID였다.
- 실제 검색 UI 검증은 [읽기 전용 Flutter 검사](../tool/qa/university_catalog_live_read_test.dart)와 university_search_query_test의 최종2 tests PASS, analyze PASS다. 사용자 저장 RPC를 차단한 상태에서 검색만 확인했다. 기기 검증으로 확대 해석하지 않는다.
- [상세 적용·검증 기록](onboarding-p0-ux-20261112.md#catalog-운영-반영--2026-11-12-owner-후속-승인), [운영 절차·보존·원복 근거](../supabase/candidates/university_catalog_20261112/README.md)를 그대로 보존한다. 일회 실행 applied.sql 재실행 금지.

## 보류7개와 사유

아래는 [감사 CSV](../supabase/candidates/university_catalog_20261112/audit.csv)의 `HOLD_IDENTITY_REVIEW` 대상이다. 후보 UUID는 운영 등록을 의미하지 않는다. 실제 통합/법적 지위를 여기서 새로 확정하지 않는다.

|대학|보류 사유·후속 확인|
|---|---|
|국립강릉원주대학교|통합·명칭 변경 여부와 기존 대학 ID의 연속성 검토가 미완료. 별도 신규 행인지 확정하지 않음.|
|국립경국대학교|통합·명칭 변경과 기존 기관/대학 ID의 대응 관계 검토가 미완료. 기존 행과 중복 생성하지 않도록 보류.|
|건국대학교(글로컬)|기존 건국대학교와 캠퍼스 식별 관계, 별도 검색 ID 필요 여부 미확정.|
|고려대학교(세종)|기존 고려대학교와 캠퍼스 식별 관계, 별도 검색 ID 필요 여부 미확정.|
|동국대학교(WISE)|기존 동국대학교와 캠퍼스 식별 관계, 별도 검색 ID 필요 여부 미확정.|
|연세대학교(미래)|기존 연세대학교와 캠퍼스 식별 관계, 별도 검색 ID 필요 여부 미확정.|
|한양대학교(ERICA)|기존 한양대학교와 캠퍼스 식별 관계, 별도 검색 ID 필요 여부 미확정.|

이번 마감은 보류 해제·추가 등록 승인이 아니다. 원본 목록과 기존 ID를 보존하고 후속 판단 전 적용하지 않는다.

## Git 인계와 제한

이 Catalog 작업 브랜치에 종료 문서 변경만 커밋하고 `origin`의 동일 브랜치로 Push한다. 원격 SHA는 `git ls-remote --heads origin refs/heads/codex/email-auth-stabilization-20261111`로 로컬 `git rev-parse HEAD`와 비교하며 최종 결과·SHA는 종료 응답에 보고한다. SHA를 current-status의 영구 HEAD로 고정하지 않는다.

다른 작업 브랜치 변경 포함0, main 병합0, 이번 마감 중 추가 운영 DB 변경0, WEB·APP 배포0, 스토어 제출0. 잔여 NOT TESTED를 명시한 상태로 Owner 승인 범위의 Catalog 작업을 **CLOSED** 처리한다.
