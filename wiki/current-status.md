# Current Status

공식 기준은 **LC3808/legendstudy-app origin/main의 wiki/**다. 작업 브랜치의 사본은 공식 상태를 대신하지 않는다. 아래는 **2026-11-26 마지막 확인 상태**이며 외부 운영을 실시간 보증하지 않는다. [index](index.md) · [정상화 절차/검사 한계](project-cross-review-20261125.md).

## P0 논술 LAB 운영 장애 — 2026-11-26 22:43 KST Owner 보고

- **DONE — Owner 정상 작동 확인.** `ESSAY_REGISTRY_WORKER_JWT` 저장 후 23:39:58 KST Production `6ac93a1b` 재배포 성공. 정적3207경로·Functions 라우팅·Production/Preview 설정 동일. 이후 Owner가 “확인 완료, 정상 작동.”으로 복구를 확인했다. [배포·Owner 확인](finance-auth-renewal-20261117.md#owner-정상-작동-확인--2026-11-26).
- 기존 원인은 Pages Registry JWT 만료에 따른 discovery/availability503이다. Finance 설정 변경 없음. 이번 주 신규 요청0·마지막 정상 요청11/22 17:53 KST는 당시 Owner 보고이며 장애 시작/영향 건수 산정 근거로 확대하지 않는다.
- Owner 확인에 기기·계정·실제 제출 여부의 개별 명시는 없다. 별도 학생 API HTTP200 계측, 양OS 실기기 전수 검증, 실제 첨삭 제출/완료까지 PASS로 확대하지 않는다. 에이전트의 실제 제출·기존 요청 재실행·이용권/원장 변경0.
- 로그 기반 영향 분석과 Registry 자동 갱신·감시는 후속 과제다. 이번 정상 복구 확인은 신규 기능·운영 자동화·기존 학생 요청 재실행의 추가 승인이 아니다.

## APP 실제 출시와 다음 후보

**iOS/Android 1.0.6, Build88 RELEASED.** iOS11/18,Android11/17 출시. 출시 소스 `08345b69b1d71c9038be50767bd849a7354d2b8e`. 최종 포함 기능·제외·QA 한계의 단일 참조는 [88 릴리스 기록](pdf-white-screen-hotfix-20261117.md)이다. PDF/학습/기존 학교TOP10/MY 개선을 재개발 대상으로 등록하지 않는다.

[1.0.7+89](app-release-89-preparation-20261125.md)는 출시88을 포함한 `76cc4050` 후보로 D-Day 및 무료2 안내가 BUILT/UNRELEASED다. 양OS 빌드·자동검증 완료와 실기기88→89 업데이트·스토어 출시를 구분한다. 업로드·제출은 아직0이며 승인 필요. 무료2 DB 미적용 상태에서 정책 적용 완료로 안내하지 않는다.

## 운영 상태와 DB

- WEB: 동일 소스 `513e641f`/Pages `6ac93a1b` Secret 저장 후 재배포, 기존 품질V1 및 정적3207경로 보존. [배포·검증](quality-console-v1-20261125.md). 후속 문서 HEAD를 배포 소스와 혼동하지 않는다.
- Essay Worker: `29f4f6cc-433f-4e8e-8da4-9ca5710f2e71`,11/22 배포·11/25 확인. 관리자 복구/정확 인용 보정 운영, 부분 재생성·신규 상한은 비활성. [런타임](admin-recovery-runtime-fix-20261122.md).
- DB: 프로젝트 stlhijzpjfgwwdgunlsd. [D-Day 설치](admissions-dday-implementation-20261120.md)와 [복구 설치](admin-run-recovery-deployment-20261122.md) 확인. [무료2 SQL](signup-credit-policy-two-20261125.md)은 승인 대기. 모든 migration이 적용됐다는 뜻은 아니다.
- 결제: Toss LIVE 유지. Finance Worker `d14a757e-5b46-448c-8b66-325d181c2a9f` **11/23 10:30:35 자연주기 갱신 성공**,active 만료11/30 10:30:35 KST를 기존 로그에서 확인. [P0 교차검증](finance-auth-renewal-20261117.md). 별도 Pages Registry JWT 만료 장애는 Secret 저장·보존 재배포 후 **Owner 정상 작동 확인으로 복구 DONE**.

## 진행·미완료·승인·다음 작업

1. q1 요청03629605…는 reserved,완료1/2. 복구 연결 수정과 실제 완료는 다르다. Owner 승인 후 직전 잠금·완료문항 해시·이용권0 재확인→기존 복구1회. 이번 실행 없음.
2. **Registry 장애 복구 DONE(Owner 확인)**. 후속: 영향 로그 분석·자격증명 만료 감시/자동 갱신 검토. 운영 적용은 별도 승인.
3. APP89 실기기 업데이트·PDF/로그인/학습/수동 및 자동 D-Day 회귀. 스토어 제출 별도 승인.
4. 무료2 신규 지급 정책은 [준비된 SQL/검증/원복](signup-credit-policy-two-20261125.md) Owner 승인·적용 후 확인. 기존 지급분/원장 보존.
5. [품질V1](quality-console-v1-20261125.md) PARTIAL:70요청118문항 대조,내용20요청38문항 검토. Q15 개별 저장·Owner 집계·나머지 내용/Claude 검토 미완료. 새 DB는 exact SQL 준비 후 별도 승인.
6. 아주·인하 자료의 부족 범위와 [통합 후속](integrated-followup-20261125.md) QA. 배지·OCR·수리 확장·Evidence ID는 구현/설계/활성화를 각각 구분한다.

## 개발 기준과 인수인계

- 공식 문서와 출시된 APP 기준: `origin/main`. main은 출시88을 포함한다. 이후 Wiki 커밋은 버전 증가나 운영 배포가 아니다.
- APP 후보89: `codex/operations-commercial-20261113`; 운영/SQL/Worker: `codex/material-service-app-20261022`; WEB 별도 저장소: `codex/lab-admin-operations-20261114`.
- 작업 전 원격 main의 AGENTS/index/current를 읽고 실제 branch/HEAD와 출시 ancestry를 확인한다. 오래된 작업 branch 전체를 APP에 덮어쓰지 않는다.
- 종료 시 작업 결과를 공식 main Wiki에 선택 통합하고 원격 일치 검사를 한다. 다른 기능의 미커밋 변경을 섞지 않는다.

## Daily Sync status

기존 자료 운영/자동 동기화 범위는 [Materials closeout](materials-final-closeout-2026-09-27.md)과 [Daily Sync 이력](history/status-checkpoints.md)을 참조한다. 이번 작업에서 재수집·운영 실행 없음.

## 과거 상태

과거 Store BLOCKED/AI OFF/10월 우선순위는 [정상화 전 상태 원문](history/status-checkpoints.md#pre-normalization-release-branch-status--2026-11-25)에 보존했다. 현재 판정으로 사용하지 않는다. 제품 정책은 [decisions](decisions.md), 실제 과거 작업은 [log](log.md)를 따른다.

## 검사 입력 (동일 문서의 구조화된 요약)

자동 검사는 필수값·Git·구조화된 충돌만 검사한다. 스토어/DB/운영 사실 자체는 보증하지 않는다. 외부 상태는 실행·배포·업로드 직전에 재확인한다.

<!-- handoff-status -->
```json
{
  "wiki_branch": "main",
  "last_verified": "2026-11-26",
  "release_record": "pdf-white-screen-hotfix-20261117.md",
  "candidate": {
    "version": "1.0.7",
    "build": 89,
    "source": "76cc405028308ceddcc76dca77285e6795346640",
    "branch": "codex/operations-commercial-20261113",
    "state": "BUILT",
    "release_state": "UNRELEASED",
    "evidence": "app-release-89-preparation-20261125.md"
  },
  "unreleased": [
    "자동 입시 D-Day APP",
    "무료2 안내 APP/운영 DB 정책 승인 대기"
  ],
  "web": {
    "source": "513e641fe3bec9f33906ca37a5e828f64702ac09",
    "deployment": "6ac93a1b-15a8-488a-99c0-b306213683f1",
    "state": "DEPLOYED",
    "evidence": "finance-auth-renewal-20261117.md"
  },
  "worker": {
    "essay_version": "29f4f6cc-433f-4e8e-8da4-9ca5710f2e71",
    "finance_version": "d14a757e-5b46-448c-8b66-325d181c2a9f",
    "evidence": "project-cross-review-20261125.md"
  },
  "db": "D-Day/관리자 복구 APPLIED; 무료2 APPROVAL_PENDING; 전체 migration 전수 인증 아님",
  "payment": "Toss LIVE 유지,이번 변경0",
  "finance": "11/23 10:30:35 갱신 성공;active 만료11/30 10:30:35 KST",
  "development": {
    "app": "codex/operations-commercial-20261113",
    "backend": "codex/material-service-app-20261022",
    "web": "codex/lab-admin-operations-20261114"
  },
  "work": [
    "APP89 QA",
    "품질 콘솔 Q15/Owner 집계 미완료"
  ],
  "blocked": [
    "None"
  ],
  "approval": [
    "q1 실제 복구",
    "무료2 운영DB",
    "스토어 제출",
    "부분 재생성/상한 활성화",
    "Q15 DB/Owner 역할 계약"
  ],
  "next": [
    "Registry 재발 방지 및 영향 분석 후속 검토(운영 적용 별도 승인)",
    "q1 승인 후 직전 조건 재확인",
    "APP89 실기기 회귀",
    "무료2 DB 승인 패키지 검토"
  ]
}
```
