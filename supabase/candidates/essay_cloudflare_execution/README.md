# Cloudflare execution checkpoints — APPLIED 2026-10-14

Owner A decision: Cloudflare Python Workers + Supabase; no Linux/container host.
Existing evaluator Prompt/Schema/validation remains Python; async I/O driver only.

## SQL scope

`install.sql`: one private checkpoints table, one Worker-only RPC.
FK references existing exam runs. Forced RLS; no student/direct worker table grant.
Every RPC checks account lifecycle, owner, existing immutable run lease token.
Transaction serializes on existing account/run. First begin returns true exactly
once, including concurrent same-writer calls. No pending lease takeover or TTL reset.
Write is original-writer only; checkpoint immutable. Late original write allowed;
late new dispatch denied. Provider/credit/model activation unchanged.

Account erasure already deletes exam runs. FK ON DELETE CASCADE deletes only their
new checkpoints. It cannot delete Ledger, Registry or existing history. No old
function is replaced. Installation makes no Credit or Provider request.

## Local verification

`ESSAY_ASYNC_TEST=1 PYTHONPATH=. python3 tool/test_essay_exam_credit.py --surface-only --pg-bin /opt/homebrew/opt/postgresql@17/bin`

PASS: existing canonical Ledger DDL + real lifecycle bodies/non-superuser deployer,
4 concurrent starts/one winner, wrong writer, immutable checkpoint, foreign owner,
student RPC denial, async existing ReviewedRuntimeWorker→DB checkpoints→finish→
History, replay one Provider request, first1Credit/free rewrite, erasure cascade,
nonempty rollback refusal and empty rollback. Local fixture only; fake Provider.
Local test uses no actual Provider/Credit. Production installation was subsequently
approved and applied: migration20261014044957. Postflight: forced RLS, Worker RPC
EXECUTE true, student/anon RPC and direct student table access false, runs/checkpoints0,
canonical Registry234 preserved. Exact SQL copied into migrations; do not replay.

## Rollback

`rollback.sql` refuses nonempty checkpoints, removes only new RPC/table, no CASCADE.
After use, disable queue consumption and forward-repair; retain checkpoints for
reconciliation. Never delete pending dispatch markers to force a Provider retry.

## Separate remaining gates

Cloudflare Worker+Queue deployment/bindings/Secrets; model/content transmission
policy; independent semantic reviewer; actual approved Provider/Credit E2E.
DB checkpoint install alone does not activate or complete service.
