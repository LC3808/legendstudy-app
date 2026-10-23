# 서울여대 Q1 보완 + Q2 묶음 (Owner 적용 대기)

프로젝트 `stlhijzpjfgwwdgunlsd`; 시험 `6679b5ff-d797-53c9-8a2a-424375d7210c`.
Q1 `a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6`, Q2 `d0862954-4d0d-5811-9b48-5dc8e319634d`.

Q1의 소문항 누락을 구분하는 공식기준 분리 및 Q2 공식자료 연결. 기존 profilev6 재사용.
v17후보 Q1부분/공식/재작성·Q2공식/부분/오답 6개 각각 계약·독립8검수 PASS.
기존Worker정책은 유지하며 v17기능만 추가했다. 신규정책은 Owner SQL 이후 선택된다.

전체 SQL(공식자료 포함, Git 제외):
`/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/swu-batch-revision3/`

1. precheck.sql — 7개 true
2. apply.private.sql — 전체 트랜잭션, revision2→3/Q1+Q2, v17정책 추가
3. postcheck.sql — 10개 true
4. 실패 시 rollback.sql — 이전 Q1 실행정책으로 복귀; revision·binding·기존결과 보존

기존237시험/700문항ID·다른정책·두Q1결과 hash·submit 보존. Credit/Ledger/History/RLS/grant 수정 없음.
현재 reader는 최신 패키지만 읽어 단순정책 롤백이 실패함을 격리 검사에서 확인했다.
`historical-reader.sql`은 전체 apply에 포함되어 있으므로 별도 실행하지 않는다.
정확한 SWU revision2 digest에 한해 현재 승인·권리와 과거 승인 모두 검사하고 조회한다.
다른 대학 과거패키지 조회 권한은 넓히지 않는다. 잘못된 digest·현재 승인/권리취소 시 거절한다.
격리 history는 합성2행; 실제 운영 precheck/postcheck는 기존실행2개 hash를 대조한다.
Worker:3922d417-2685-41aa-ae0d-327944c7ffb8; 기존615f4825 보존.
SQL원복 후에만 Worker원복을 고려하고 진행중 요청을 먼저 확인한다.

[최신 증거](../../../wiki/essay-p0-direct-execution-20261023.md#service-token-recovery-and-swu-operating-runs).

예상 package digest: `dffdb94b185ba6e316bae052db1d5c1a92259c5cc974476ecc3c86877877a233`. 운영 SQL은 아직 실행하지 않았다.
