# 이화여대 공식 기준 63문항 공개

운영 공개 DONE: 21시험·63문항(Math27 / Essay36). 신규535행,기존 Registry3문항 및 사용자데이터보존. 모의8시험24문항은공식채점기준미확보로보류. 재적용하지않는다.

- [최종 상태](final-status.json), [DB 적용 영수증](production-application-receipt.json), [DB 접근 검사](db-postflight.json)
- [실제 공개 API/배포 검증](web-production-receipt.json), [Worker 실제 모듈](worker-production-verification.json), [실제 운영 package](essay-production-package-validation.json)
- [SQL 고정 범위/SHA](production-sql-plan.json), [Math 원복](math-rollback-admission.sql), [Essay 원복](essay-rollback.sql), [PDF 접근 회수](rollback-storage.sql)
- [격리 Math 계약](math-isolated-results.json), [Essay 계약](essay-runtime-validation.json), [Essay SQL](essay-sql-validation.json), [PDF RLS](storage-isolated-results.json)
- [WEB·APP 테스트/원본 비교](pdf-web-app-verification.json), [PDF 출처/권리 조사](pdf-rights-review.json), [PDF 객체/SHA](pdf-originals.json)
- [운영 전후 보안 진단](security-advisors-comparison.json): 신규0,기존상태동일. 범위밖권한/정책변경0.
- [Owner 통합 목록](owner-integrated-review.json): 기존자연178/잔여43과이화63/모의24를분리한다.

Legacy Registry is_active/is_published=false는기존계약대로보존했다. 학생공개는운영 Math catalog/Essay whole-exam policy+Worker+WEBscope/학생PDFmanifest로검증한다. 원본58PDF와해설은수정하지않고,문제21PDF만authenticated+계정허용함수+정확SHA정책으로읽을수있다. 해설원본학생공개0.

SQL의원문/이미지payload는ignored `.local/ewha-public-20261112`와운영migration이력에보관한다. Worker/Pages원복자료는같은private디렉터리의deployment-backup. Credentials는복사하지않는다. 장애시현재deployment/hash일치확인후새공개scope를닫고이전Worker/Pages복원·신규허용목록/PDF정책회수. 원본/Registry/학생답안·결과·이력/PDF객체삭제금지. 동시배포가있으면과거전체설정덮어쓰기금지.

Provider 호출0·운영테스트답안0. 브라우저/실기기/로그인후실제제출·결과·재첨삭은NOT TESTED. AI품질검수는Owner담당.
