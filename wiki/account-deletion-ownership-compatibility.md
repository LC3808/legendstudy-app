# ADR-2D ownership compatibility — isolated verified

2026-10-01. **COMPLETE locally; Production NOT_APPLIED; retry NOT_AUTHORIZED.**
Owner reported the ADR-2C apply failure42501 fully rolled back. Read-only catalog confirms
ledger23, version20261001000300 untracked and account_private/lifecycle objects absent.
Failed hash `b815b4d82ddf14c33f22be64f44a21666918787e9466f097f858c5b4b5844ff7`: **SUPERSEDED_PRE_APPLY_FAILED_ATTEMPT**.
New canonical SHA-256: `38c86fd79554225fbc6a5a30be791c860e6c89dcaa64ad7e229e3710b9a29d94`. Same unapplied migration version.
[Owner package](../supabase/verification/account_deletion/README.md),
[exact inventory](../supabase/verification/account_deletion/ownership_inventory.json),
[read-only ownership pre/postflight](../supabase/verification/account_deletion/ownership_catalog.sql).

## Root cause and final mechanism

Actual postgres: NOSUPERUSER, CREATEROLE, BYPASSRLS. Existing membership is granted by
supabase_admin to postgres for essay_executor: ADMIN=true / INHERIT=false / SET=false.
Prior isolated bootstrap postgres was SUPERUSER and masked replacement/initialization
permissions. Test bootstrap is now separate; full candidate and rollback execute after
postgres is demoted to actual capabilities. Existing function bodies come from canonical
migrations, not synthetic Essay stubs. Auth roles remain a local shim, not JWT verification.

Five existing functions use a separately approved transaction-only bridge: preserve the
supabase_admin-granted membership, add a postgres-granted SET-only row, grant CREATE on
exactly essay_private/public to essay_executor, SET LOCAL ROLE, replace only five functions,
RESET ROLE, revoke only temporary CREATE and the postgres-granted membership. Nine exact
owner/identity-argument/ACL/security/config checks fail closed on unexpected topology.
Snapshots are transaction-local tables dropped on commit. No persistent escalation helper.

New detach_finance requires BOTH SET capability and account_private CREATE (each missing
privilege separately denied in PG17). Its ownership initialization is moved after its
postgres-owned ACL setup. A separate one-function bridge assigns account_erasure_executor,
then grants private EXECUTE to postgres under the final owner so the normal non-superuser
lifecycle SECURITY DEFINER chain works. Final EXECUTE is owner+postgres, no browser roles.
Temporary CREATE/SET are removed; final owner remains account_erasure_executor.
Rollback drops that one function under its owner with a bounded SET bridge, no schema CREATE.

Exact pre/post membership and schema ACL are asserted. Pre-existing public schema ACLs
remain unchanged; original ADR-2 intentionally adds only public USAGE for its two new
executor roles. These baseline additions are distinguished from bridge privileges.
account_private finance CREATE is removed with exact ACL restoration. No permanent
SET/INHERIT/CREATE expansion, owner transfer to postgres, or unrelated membership changes.

## Complete owner-sensitive statement audit

| Statement / object | Current/creating → final owner | Required execution / bridge | Evidence |
|---|---|---|---|
| is_quality_operator, essay_private.uid, fetch_own_mock_attempt, submit_mock_attempt replacements | postgres → postgres | Normal postgres | Four replacements/security PASS |
| essay_private.owner, lock_job, credit_post_grant, credit_profile_signup, public.essay_claim_signup_credit replacements | essay_executor → same | Approved SET+CREATE bridge, exact five | Five replacements/security PASS |
| CREATE account_private schema, tables, indexes, new helpers/RPCs, triggers | postgres → postgres | Existing postgres DB/schema/table authority | Full local apply PASS |
| CREATE two NOLOGIN executor roles | New roles, postgres creator | CREATEROLE+BYPASSRLS; automatic admin-only creator membership | Non-superuser PASS; no SET/INHERIT residue |
| ALTER detach_finance OWNER | postgres → account_erasure_executor | Approved one-function SET+CREATE bridge | SET-only/CREATE-only deny; both PASS |
| Existing public RLS policies / personal-write triggers / finance triggers | postgres tables; old functions unchanged | Table owner postgres; no owner transfer | Catalog/security/rollback PASS |
| CREATE policy storage.objects | supabase_storage_admin remains owner | Existing Supabase supautils.policy_grants explicitly delegates storage.objects to postgres | Production read-only setting verified; managed extension runtime NOT_RUN locally |
| Account schema/table/function GRANT/REVOKE | postgres while ACL initialized | Owner path; finance ownership moved after ACL setup | Full local apply PASS |
| Public USAGE / account_private helper grants | Existing schema owners | Normal grant authority; no unrelated role membership | Final ACL assertions PASS |
| Five-function role membership / schema CREATE changes | Original grantor retained | Only temporary postgres-granted row and CREATE removed | S15–S17 atomic failure restoration PASS |
| Finance initialization membership/schema CREATE changes | Automatic creator membership retained | Temporary separate row removed; private schema ACL restored | F1–F4 atomic failure restoration PASS |
| Final RLS enable, grants, COMMIT | New postgres objects | No additional owner transition | Full local apply and rerun rejection PASS |
| Rollback: restore nine functions/drop new objects/roles | Original owners restored | Same exact bridges; refuse data/dependencies | Non-superuser rollback PASS |

No other ALTER OWNER / CREATE AUTHORIZATION / SET ROLE / membership bridge exists in the
candidate. No additional approval required. Managed Storage policy delegation is a platform
capability, not a newly granted bridge. Plain PG17 does not load supautils or storage.objects;
that conditional branch is not runtime-proven locally. Owner must recheck its delegation
setting and exact Storage policy postflight, without inferring live verification from tests.

## Validation and application gates

112 lifecycle SQL assertions +17 ownership/negative/failure checks PASS. Seven injected
failure checkpoints restore exact existing functions/membership/schema ACL and leave no
new lifecycle state. Non-superuser full apply/rerun rejection PASS; rollback data/dependency
refusal and exact definitions/owner/ACL/membership restoration PASS. Finance runtime chain
also tested with non-superuser postgres. Deno48 PASS; Flutter7 PASS and focused analyze clean.
QL/HQP bodies/ACLs, existing table security and economic ledger invariants preserved.

Local/schema preflight fingerprints (SHA256 sorted aclitem strings, newline joined):
- essay_private: `cd12f98486ee6502b256dc2844d50946b0cc9eab2db3598baf5877f759aae6eb`
- public: `4eb1761cc92e94c9d8b806136cd5b3230f1d9a32842d2d4733c4e3bf719c0d8c`
These are baseline-entry fingerprints; postflight excludes only the two intended new
public-USAGE grants. Exact values/algorithm are in inventory JSON; no OIDs or secrets needed.

Fresh Owner pre-apply: verify branch/HEAD/hash, ledger23/untracked/objects absent, all nine
security rows, original membership/schema ACLs, and managed Storage policy authority.
Apply only the reviewed transaction after separate authorization, then ownership/catalog/
OFF/no-data postflight, then exact-version tracking. Never broad push/repair unrelated files.
Any mismatch: STOP. No retry of failed old hash. Once actual lifecycle data exists, bounded
rollback refuses; preserve deletion obligations and use reviewed forward recovery.

ADR-2C privacy-first/no-global-hold semantics unchanged. Provider reauth/admission/revoke,
secret/worker-role provisioning, finance/Storage/backup, scheduler/notifications and UX
remain external activation gates. Owner review READY; Production retry/general activation NO.
