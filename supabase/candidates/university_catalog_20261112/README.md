# 대학 Catalog 확대 — 78개 운영 적용 완료

**Owner 완료 승인 / CLOSED**: [종료 기록·보류7 사유·잔여 검증](../../../wiki/university-catalog-closure-20261112.md). 추가 적용 없음, APP 릴리스 HOLD 유지.

**APPLIED 2026-11-12 / Owner 명시 승인: 신규78행 INSERT.** 대상 LegendStudy(`stlhijzpjfgwwdgunlsd`)만.
적용 전 사용자 요청에 따라 기존 운영 Catalog53행(활성50/비활성3)을 읽기 전용 전수 확인했다.
[원본 메타데이터](../../../wiki/assets/university-catalog-audit-20261112.json), [대조표](audit.csv), [SQL 후보](candidate.sql).

## 범위와 근거

- [경기도교육청 대입 안내 목록](https://more.goe.go.kr/sei/module/cosemap/selectUnivGuidePopAjax.do)의 수시·정시 목록 합집합116개와
  [한국에너지공과대학교](https://www.kentech.ac.kr/), [한국예술종합학교](https://www.karts.ac.kr/index_karts.jsp)를 대조했다.
  118개 중 기존33, 신규 후보78, identity검토 보류7. 이는 **국내 모든 대학/전문대학을 망라한 국가 전체 목록이 아니다**.
- 한국교원대학교는 기존0, 신규 후보1. [공식 학교 검색 근거](https://www.knue.ac.kr/www/index.do)와 교육청 목록에 존재.
  공식 메인 본문 fetch403이므로 학사/입시정보 검증을 했다고 주장하지 않는다.
- 교육대10개(경인/공주/광주/대구/부산/서울/전주/진주/청주/춘천) 모두 기존 미등록.
  국립공주·군산·금오공과·목포·순천·창원·한국교통·한국해양·한밭, 한경국립·한국교원·한국체육 및 다수 사립 후보 포함.
- 과학기술 계열 KAIST/POSTECH/GIST/DGIST/UNIST는 기존 활성. 한국에너지공과대학교는 후보.
- 국립부경대학교는 기존 부경대학교 ID를 재사용하며 새 행을 만들지 않는다.
- 보류7: 국립강릉원주대학교, 국립경국대학교, 건국(글로컬), 고려(세종), 동국(WISE), 연세(미래), 한양(ERICA).
  통합/학교명 변경/캠퍼스 정체성은 추가 조사 없이 다른 대학으로 확정하지 않는다.
- 기존 비활성 서울여자대·한국항공대·합성 검증용 행은 변경하지 않는다. 앞2곳의 비활성 사유는 별도 검토 필요.
- 별칭은 CSV와 Flutter의 공통 검색 정규화에서 관리. 새 별칭 컬럼/RPC 없음.
  공백/국립 접두와 카이스트·포스텍·교대/KNUE 등 검색을 지원하되 반환 ID는 서버 원본만 쓴다.
  **앱 검색 별칭 개선만으로 미등록 대학이 검색되는 것은 아니다.**

## 운영 승인 대상과 영향

78개 Catalog 신규 행 INSERT만. 기존53행 UPDATE/DELETE0, 학생 관심/지원/프로필 변경0.
한국교원대 slug는knue, 다른 새 slug는kr-UUID파생 식별자. 기존 ID와 충돌하지 않는 UUIDv5 후보를 명시했다.
공식 기관코드라고 주장하지 않는다. 후보는 DB에서 재차 이름/slug/ID 충돌을 확인하고 충돌 시 중단한다.
관심 대학과 실제 지원은 같은 UniversityRepository/public.universities를 사용하므로 승인 적용 후 둘 다 검색된다.

LAB 지원 확대는 승인 대상이 아니다. APP 논술 목록은 별도 `essayUniversityCatalog`/SourceCatalog의42개 매핑을 사용한다.
새 Catalog 행에는 시험/문항/Registry를 생성하지 않으며 해당 ID에 essay_exams가 있으면 후보 SQL이 중단된다.
기존 대학 is_active나 LAB 관련 파일/정책은 수정하지 않았다. WEB 로컬 public-discovery.ts는 별도 essay-public-catalog.json을 사용함을 읽기 확인했다. WEB 배포본 E2E는 NOT TESTED이며 배포/코드 변경은 없다.

## 실행·검증·원복

1. Owner가78개 목록 또는 한국교원대 등 승인 부분집합을 확정한다. 미승인 자동 적용 없음.
2. 최신 운영 snapshot/종속 소비자 검토 후 `candidate.sql`을 **ROLLBACK 그대로** 리허설한다.
   이름/ID/slug충돌, 기존 전체행 보존, 새 LAB 연결0, 정확한 추가78개를 확인한다.
3. 별도 운영 승인 후 마지막 rollback을commit으로 바꾸어 적용. migration이 아닌 후보 SQL이다.
4. 적용 후 KNUE/한국교원대/서울교대 검색, 기존 ID/학생 행 불변, APP/MY 검색을 소량 읽기 검증.
   운영 사용자 데이터 쓰기는 별도 승인된 테스트만.
5. 장애 시 추가 활성화를 중단한다. 이미 학생이 새 대학을 참조했으면 DELETE 금지.
   아직 참조0임을 FK별로 확인한 경우에만 신규 후보 ID 제거를 별도 승인한다.
   참조가 있으면 기존 연결을 유지하고 검색 노출 중단·원복 영향안을 Owner와 검토한다.
   재적용은 기존 후보행을 덮어쓰지 않으며 새 행0으로 끝난다.

로컬 PostgreSQL17 격리검사: 운영 공개53행 복제 → 후보78 추가/ROLLBACK후53 PASS;
로컬commit131 PASS; 재적용추가0 PASS; 기존서울대 이름 충돌 fail-closed PASS.
후속 운영 리허설 ROLLBACK 및 승인 COMMIT 완료. 기존 전체행/보호 테이블 검증은 [적용 SQL](applied.sql), [영수증](../../../wiki/assets/university-catalog-applied-20261112.json) 참조. applied.sql은 초기53행을 요구하는 일회 실행 영수증으로 재실행하지 않는다. WEB 배포본 통합은 NOT TESTED.
기존7항 보존: 시점/원본/current projection/identity/관심≠지원≠결과/권한·retention/파생 표시 의미 유지.
