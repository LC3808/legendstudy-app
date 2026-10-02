# MATH-2D — Runtime consumer surface

**IMPLEMENTED / ISOLATED_VERIFIED; Production NOT_APPLIED.** Base [MATH-2C](math-essay-persistence-implementation.md) remains unchanged. This is a bounded integration implementation, not Math activation or LAB work.

[Canonical physical consumer contract](../supabase/verification/math_essay/runtime/README.md) provides named PostgREST arguments, exact version/action/payload/return contracts, authority, physical relation mapping, bounds, cursor and error semantics. [Owner package](../supabase/verification/math_essay/runtime/application.md) records installation/rollback. No canonical SDK-generation workflow was found; [physical catalog](../supabase/verification/math_essay/runtime/physical_catalog.json) is generated from isolated PG17, not Production or an invented SDK.

## Changes

Four postgres-owned bounded wrappers: math_input(jsonb), math_extraction(jsonb), math_evaluation(jsonb), qlm_quality(jsonb). Their named parameter is p_request. Student, extraction worker, evaluation worker and Quality authority remain separate; exact EXECUTE only, empty search_path, no browser table CRUD or executor membership.

Six existing Math functions now serialize evidence/confirmation/extraction/evaluation request on the attempt after lifecycle locks. Evidence registration retries by position are deterministic. One confirmation per candidate is enforced; exact retry returns the same version, changed/stale confirmation rejects. New candidates invalidate older readiness. Request freezes latest confirmed extraction and billing atomically. Typed SHORT_ANSWER needs no artificial Vision run. Worker claim returns pinned input context; student read/history never exposes a worker lease or object path.

READY_FOR_EVALUATION is a derived server projection, not a client-writable field. Confirmation creates an immutable derived extraction run with original candidate provenance. It never creates re-solve or charges Credit. Existing MATH-4/5/6/7 meanings, initial+one eligible same-lineage reevaluation within336h, HQ E1/E2, ql-read-v1/hq-read-v1 and financial economics remain intact. No price/refund formula or second wallet.

## Preservation review

Occurrence and confirmation timestamps remain distinct; original evidence/candidate content is preserved; corrections create versions rather than overwrite submitted facts; Auth identity is reused; student learning, Quality judgment and finance remain separate; private content stays owner/operator gated and erasable; readiness is derived rather than a new raw fact. No analytics retention is implemented.

## Executed verification

[C01–C30](../supabase/verification/math_essay/runtime/validation.json) PASS, including concurrent confirmation and lifecycle lock race; new-candidate/confirmation race also executed. [Math regression](../supabase/verification/math_essay/runtime/regression.json):131 checks PASS. [Humanities/HQP](../supabase/verification/math_essay/runtime/legacy_validation.json):102 assertions PASS. [Runtime install/failure/rollback](../supabase/verification/math_essay/runtime/ownership_validation.json):8 checks PASS;14 base installation checks also rerun. Non-superuser PG17, synthetic auth/Storage fixtures only; no Production JWT or Storage runtime claim.

Migration: [20261002000200_math_runtime_surface.sql](../supabase/migrations/20261002000200_math_runtime_surface.sql), SHA-256 `b40bf7224a84658308ff1640b639acb857e379998211131d97a688a9711fe049`. MATH-2C migration bytes/hash unchanged. No new role/table, no unrelated migration edit. Rollback restores exact MATH-2C definitions/security on empty install.

## Handoff and activation gates

READY_FOR_CLAUDE_MATH_3B_BINDING: YES — contract/local integration only. Claude remains responsible for LAB implementation; this task does not modify LAB. R21 remains PRODUCTION_ACTIVATION_GATE / actual Storage NOT_ASSESSABLE. Evidence metadata registration returns upload_available=false. Future trusted admission and resumable byte cleanup must verify absence before metadata deletion; no bucket or Storage runtime was activated.

Lifecycle helper fails closed without ADR-2. Math erasure hook, worker credential admission, real gateway verification and all deployment remain separately gated. Production writes0, provider calls0, no remote tracking, Edge/scheduler deployment or AI activation. Next: Owner/ChatGPT review → MATH-3B physical binding → separately authorized provider bake-off / MATH-4B.
