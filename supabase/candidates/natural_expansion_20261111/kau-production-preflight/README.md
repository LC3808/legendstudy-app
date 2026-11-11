# 한국항공대 단독 비공개 적재 후보 — NOT APPLIED / NOT SERVICE READY

[최신 Owner 순서·완료 기준·HOLD](../../../../wiki/essay-natural-sequential-order-20261112.md).
기존53개 일괄 후보를 실행하지 않고 한국항공대7개만 분리했다. 기존 엔진/함수/정책은 변경하지 않는다.

- 대상:4시험7문항,Math8테이블99행+Worker7행=106행. HOLD5·후순위46·기존 운영7 제외.
- `scope.json`:기존81개 대조를 보존하며 NEW_DRAFT_ONLY7/DEFERRED_UNIVERSITY46/HOLD5/NOT READY16/기존7을 분리한다. `state`는 이전 검수표의 역사적 분류이며 SERVICE READY 확정이 아니다.
- `preflight.sql`:기존7/81 Registry·함수·RLS·권한·대상 중복 검사를 포함한 read-only116조건. 운영 적용 직전 모두true 필요.
- `verify.sql`:단독99 DRAFT+Worker7,정확한 연결·hash·비공개/권한 확인.
- `rollback-retire.sql`:신규 versioned4테이블28행만 RETIRED. 기존 기록·자료 보존. 이미ACTIVE이면1단계 범위 밖이므로 중단.
- `verify-retired.sql`:원복 확인.
- `production-functions.json`:이전00:05:50 KST 조사에서 사용한 운영 함수의 로컬 격리 복제용 스냅샷. 운영 실행 금지.
- `isolated-results.json`:정확한 단독SQL을 Unix-only PG17에서 검증한55개 검사 PASS. 실제 서비스/AI 품질 검증 아님.
- `sql-receipt.json`:SQL 및 패키지 SHA256. 정확한 apply 파일은 `/Users/woojinchang/.codex/worktrees/app-ga4-usage-20261105/legendstudy-service-app-20261022/.local/kau-production-preflight-20261112/apply-draft.private.sql` (ignored,원문/이미지 포함).
- Apply SHA256: `c4fdfeb05aa785ff7ca6afd9da3c20a0dad69c7f0294d94bf065e84ad4a3da62`.

Owner 별도 승인 후에만: 영수증 확인→운영 SELECT preflight116조건 재검사→단독 apply 한 transaction→verify→결과 기록. 오류 시 readback으로 commit 여부 확인 후 비파괴 원복. 기존 register/Worker 파일을 중복 실행하지 않는다. 기존53 일괄파일과 함께 실행하지 않는다.
DRAFT에서는 Owner도 제출할 수 없다. Owner 전용 검수 경로는 미해결이며 실제 검수/ACTIVE/RPC·배포·Provider 호출·일반 공개는 이번 승인 요청 범위 밖이다.

재현 (APP checkout):

```sh
PYTHONPATH=tool /tmp/legendstudy-task03-venv/bin/python - <<'PYCODE'
from prepare_natural_preflight import build,R
build('한국항공대학교',R/'supabase/candidates/natural_expansion_20261111/kau-production-preflight',R/'.local/kau-production-preflight-20261112')
PYCODE
NATURAL_PREFLIGHT_SCOPE=kau /tmp/legendstudy-task03-venv/bin/python tool/test_natural_preflight.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
```
