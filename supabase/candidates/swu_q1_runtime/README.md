# 서울여대 Q1 — Owner 적용·사후검증 PASS

Production `stlhijzpjfgwwdgunlsd`. 기존 시험 `6679b5ff-d797-53c9-8a2a-424375d7210c`, 문항 `a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6`만 연결한다.

전체 SQL과 공식자료가 포함된 패키지는 기존 비공개 증거 디렉터리에 있다:
`/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/`

Owner 실행 순서:
1. `swu-operating-precheck.sql`: 10개 true. 함수/검수 기준이 달라졌으면 중단하고 재대조.
2. `swu-operating-candidate.private.sql`: 전체 트랜잭션. revision1→2, 기존 문서 보존, 선택 Q1 패키지·runtimeApproval, runtime/provider 정책 분기 각1개.
3. `swu-operating-verify.sql`: 15개 true.
4. 실패 시 `swu-operating-rollback.sql`: 해당 시험의 신규 요청만 차단. 재첨삭 신규 요청도 중단되며 기존 결과·revision·binding·진행 중 처리 근거는 보존한다. 재개는 별도 검증 후 준비한다.

패키지 digest `35fef5c0f58e9d5489c85879277b403f3bebc8d8bed1ddfec1e4bd8ef6c9a8ab`.
Worker `80e1badb-92cd-4e56-9ca1-92999887fac1` 100% 운영 배포/실제 모듈·설정 대조 PASS.
기존81 Registry 항목 보존+서울여대1, 기존5 binding 보존+서울여대 v15 1개.
다른 설정·코드 모듈·공개 범위 불변. Worker 원복 기준 `85a7a6a5-d2d9-448b-949f-d274fded510e`.
DB 적용 후 Worker를 되돌려야 하면 먼저 위 SQL로 서울여대 신규 요청을 차단하고 진행 중 요청 처리 상태를 확인한다.

격리 PostgreSQL11검사 PASS; Production 사전검사10true. DB에는 agent가 적용하지 않았다.
기존237시험/700문항 ID·다른 정책·submit 보존. 결제/Credit/Ledger/History 코드·구조 변경 없음.
실제 서비스 Provider 제출·무료 재첨삭·WEB/APP·신규 History 자동 반영은 Owner 적용 이후 미완료다.
일반 공개 허용 목록은 건국·성균관대 기존3문항 그대로이며 이 SQL은 일반 공개 완료를 의미하지 않는다.

상세 진행/비용: [P0 Wiki](../../../wiki/essay-p0-direct-execution-20261023.md).

Owner 적용 보고 후 agent가 동일 read-only15항목을 독립 실행하여 모두true 확인했다. 원본 apply SQL을 다시 실행하지 않는다. 초기 비활성 선택 해석은 잘못되었으며 실제 선택은 가능했다. Owner는 일반계정 공개 기본을 확정했다. Worker 공개범위에는 서울여가 추가됐으나 WEB 설정 오류 후 이전 배포로 복구한 상태다. Secret 복원 및 서울여 실제 E2E는 미완료이며 상세 복구 절차는 위 P0 Wiki를 따른다.
