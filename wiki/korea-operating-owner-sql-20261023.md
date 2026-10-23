# 고려대 한 문항 운영 연결 — Owner SQL 사전 검토

상태: **LOCAL_VERIFIED / PRODUCTION_NOT_APPLIED / WORKER_V12_NOT_DEPLOYED**.
Owner는 Production SQL을 직접 실행한다고 확정했다. Worker readiness 확인 전 적용하지 않는다.
기존 [품질 검증](official-answer-quality-20261023.md), [PHASE1 보존 계약](university-evaluation-profile-phase1.md), [기존 운영5](university-profile-production-e2e-20261023.md)을 재사용한다.

## 대상과 변경

- Supabase: `stlhijzpjfgwwdgunlsd`만.
- 고려2025수시 인문2: exam `942c1c43-914f-5b99-9a30-e6474c363f6f`, question `c1f90870-3ad9-59f8-afe3-c26d665f292f`.
- 읽기 실측: review revision1/NEEDS_REVIEW, runtime policy null, 기존 run0, 원본 등록1.
- 후보: review revision2 append 및 현재 review projection 갱신. 기존 mappings/rights/checks/documents/다른 문항은 그대로, selected_questions 패키지1개와 문항 한정 runtimeApproval만 추가.
- 기존 provider_policy에 `korea-humanities-reviewed-20261023-v12` binding 하나, runtime_policy에 위 exam case 하나 추가. 기존 case 유지, baseline 다르면 transaction 거부.
- package digest(격리 PostgreSQL): `9afbeece5b9348c5402430f3bd215a9d8acf2c1ce0add6b38fffab78f7229ea4`.
- 공통 submit/reserve, Credit/Ledger, History, 다른 시험 정책, 새 테이블/71702 변경 없음. 새 고려 문항은 과거 run이 없어 기존 정책 교체용 POLICY-01 후보를 이번에 적용할 필요가 없다. POLICY-01은 기존 성공 문항의 향후 정책 교체에 여전히 미완료다.

## 전체 SQL 및 순서

전체 SQL은 공식 근거 원문을 포함하므로 공개 Git에 넣지 않는다. 비공개 기준 폴더:
`/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/official-answer-quality-20261023/`

1. `korea-operating-precheck.sql`: 읽기 전용10검사. 모두 true 필요.
2. **Worker v12 실제 배포 및 exact binding/기존 Registry79·public scope·secret 보존 확인이 먼저 필요. 현재 미배포.**
3. `korea-operating-candidate.private.sql`: 전체 적용 SQL. Owner만 실행. 함수 정의/원 review/기존 run0 사전조건을 transaction 안에서 재검사. 반복 적용은 거부하며 중복 revision 없음.
4. `korea-operating-verify.sql`: revision2/NEEDS_REVIEW, selected_questions1, v12 binding, 위 digest, 시험·문항 ID/다른 정책/submit 보존 확인.
5. `korea-operating-rollback.sql`: 신규 고려 exam case만 제거하는 긴급 실행 차단. 타 시험 case/Provider binding/revision/평가·답안·Ledger는 삭제하지 않음. 고려 재첨삭도 일시 차단되므로 과거 무료 권리 소멸로 취급하지 않고 검증된 동일 정책 복구 후 재개한다. 진행 중 평가의 종료 기록을 지우지 않는다.

## 실제 검증과 남은 gate

Production read-only precheck10개 모두 true. 시험237/문항700, ID MD5 각각 `74c42916a3fd430f5a457d0c684e288b` / `91217f81744b8e72b03f611b959e602c`. 고려 외 정책 MD5 `b980e28178196e62e7e91cfc8f228e5a`. 변경이 발견되면 기존 baseline을 임의 갱신하여 통과시키지 말고 diff 검토한다.

로컬 runtime에 v12 explicit 지원 추가. 기본 prompt/기존 binding 불변, 승인 목록에 없는 v12 binding 거부. 관련49검사 PASS. 격리 PostgreSQL8검사 PASS(단일문항, 원 body 보존, v12, submit 불변, 재적용 거부, 해당 exam rollback, revision 보존, rollback 멱등). 초기 fixture 함수 연결 세미콜론 누락은 수정 후 재검사 PASS. 실제 package→기존 loader→v12 provider 구성 및 공식 해설 전달 PASS, 네트워크 호출0.

Cloudflare API의 기존 인증 direct read401 후 Wrangler 정상 인증 경로로 deployments 조회 성공. 현재 Worker `legendstudy-essay-reviewed`, version `6b7593a4-5c0c-4b0f-9f37-f812f6a51a3d` 100%, deployment `d974bcb1-d47b-4cc8-a951-40fed252b0be`. v12 운영 미배포. 과거 stage `/private/tmp/legendstudy-profile-worker-20261023` 없음. 재구성·실제 설정 보존·배포 확인이 남았다. 코드 로더 지원을 운영 품질/E2E로 보고하지 않는다.

Provider 추가0/비용0. 기존 품질 원장57회/추산USD4.691360 유지. 기존 운영5·공개 건국2 유지, 신규 WEB/APP E2E0. 기존512상속423/잔여89 불변. 결제 worktree clean 확인, 공통 submit의 차이는 기존 POLICY-01 후보10행이며 이번에 수정/적용하지 않았다.

## 보존 검토 7항

1. 원자료/검수/적용시점 분리: 원본 및 v3 입력 보존, 새 revision과 실행 기록 별도.
2. 원본 SHA·프로필v5·패키지digest·promptv12로 재현; 이전 품질 결과 덮어쓰기 없음.
3. review current projection만 갱신하고 revision append. 학생 답안·평가·원장 UPDATE 없음.
4. 기존 canonical question/exam/student identity 유지, 새 사용자/ID 생성 없음.
5. 교육용 평가 기록이며 Admissions Outcome/합격 사실 아님.
6. 공식 근거 비공개 저장 및 기존 operator 범위 유지. 새 학생 데이터 수집·공개 승인 없음.
7. Provider 판정/내부ordinal과 대학 공식 기준·배점을 분리. 예시답안 만점 강제 없음.

## 독립 검수 진행

서강2026 기존 A 입력/평가/검수 및 공식 예시 페이지를 재사용했다. 제도 도입과 포용성 구분, 비제도적 설명의 근거 부족 지적은 원문 대조 가능하다. 다만 '각 제시문마다 긍정 적용을 먼저'라는 고정 순서를 공식 의무로 볼지 추가 검토가 필요하다. 정확한 ordinal 보정/유료 품질 최종 PASS를 선언하지 않는다.

숭실2022수시 인문2문항: 기존 복구표는 문제 전용 파생 PDF만 참조했으나 기존 보관 원본 SHA `bf0488e18d7f9c9e800df7c577c1b12a613ba7c70cc20ded147c1906d5018cf6` 14페이지에서 공식 해설/기준/예시를 찾음. 문제1 물리7–10, 문제2 물리11–14. 물리13 시각검수에서 상단4기준과 등급표의5기준 참조, 제시문 마/바/사와 세부표 바/사/아 표기 불일치 확인. 원문 오류를 조용히 정정하거나 기본체계 상속 PASS로 승격하지 않음. 후속 문항별 정밀검수 필요, 상속 수 불변.
