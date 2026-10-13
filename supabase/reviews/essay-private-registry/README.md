# Private Registry read — Owner application gate

Production **APPLIED** with explicit Owner approval on 2026-10-13 KST.
Hosted migration version: `20261012215054`. Read-back confirms essay_worker-only
EXECUTE and 234 unpublished questions across 76 exams. Authenticated, anon and
service_role EXECUTE remain denied. End-to-end gateway JWT verification is pending the prerequisites below. The earlier
assumption that an operational worker credential already existed was not verified.

SQL: `../../migrations/20261012215054_essay_private_registry_read.sql`
Rollback: `rollback.sql` (drops only the new RPC; no data deletion).

`essay_registered_questions(uuid)` returns only the exact approved 234 question IDs,
source keys, metadata versions, exam IDs, university IDs, academic years and kinds.
It returns no PDF/text, answers, identities, evaluations, credentials or Credit data.
The existing `essay_worker` role alone receives EXECUTE. Anonymous, authenticated,
service_role and Math worker roles cannot call it. No table grants or RLS changes.
The existing account lifecycle guard checks the gateway's verified subject.

WEB POST `/api/essay/catalog` verifies Auth online and the existing MATH allowlist
before the RPC. It accepts only bearer authentication and returns private/no-store.
Native calls the same endpoint. GET remains anonymous published-metadata only.
Neither metadata identity nor private registration grants Draft or evaluation access.

Deployment prerequisite: a separately issued, unexpired `essay_worker` credential
and reviewed API role membership. Neither is currently provisioned. Do not use service_role, a Math
worker credential, a browser key, or generate credentials with unapproved signing access.
Missing configuration or RPC fails closed; existing source-only drafting continues.

Validation: `tool/test_essay_private_registry.py` uses disposable PostgreSQL17 with
actual canonical Math/account lifecycle migrations: exact234 IDs, minimal fields,
all other roles denied, missing/restricted account denied, RLS/Credit unchanged,
rollback/data preservation and reinstall. Seven checks PASS; existing Math setup
finalization/HQ read regression PASS. This is not live JWT or Provider E2E.

Apply only this exact SQL after approval. Read-back must confirm function ACL,
no anonymous/student EXECUTE, exact234 IDs via worker + approved Auth subject,
unpublished records unchanged. Re-run of an existing function intentionally aborts
rather than overwriting an operational definition. Inspect deployment history first.


## Owner action — Worker authentication correction (2026-10-13)

This section supersedes earlier “paste the existing JWT” guidance. Production
read-only SQL confirms `essay_worker` exists and can execute the registry RPC,
but `pg_has_role('authenticator','essay_worker','MEMBER')` is false. Other API
roles (anon/authenticated/service_role) cannot execute this RPC. Database owner
read-back of234 rows is NOT proof of working JWT/Data API access.

Cloudflare Production/Preview currently have no ESSAY Secret. Scoped local
credential locations yielded no existing worker credential; this is not a claim
that all Owner secret stores were searched. Existing worker Wiki describes an
undeployed credential broker, not an operational issuer.

### 1. Services and existing credential check

- Supabase project `stlhijzpjfgwwdgunlsd` → SQL Editor: read-only membership/ACL
  queries below. No migration is performed by checking these.
- Supabase → Settings → JWT Signing Keys: check trusted signing-key IDs/algorithms
  and the existing issuer's private-key custody. Do not rotate/import/revoke keys
  as a troubleshooting shortcut. Managed asymmetric private keys cannot be
  downloaded. JWKS is public verification material, not a signing credential.
- Cloudflare → Workers & Pages → `legendstudy-lab` → Settings → Variables and
  Secrets → Production (and Preview separately): check the NAME only. Encrypted
  Secret values cannot be recovered from the dashboard after saving.
- Check only the project's approved secret manager/issuer with its operator.
  A database role, Supabase login, PAT or API key does not establish a JWT issuer.

```sql
select r.rolname,
 pg_has_role('authenticator', r.oid, 'MEMBER') as api_role_membership,
 has_function_privilege(r.oid,
   'public.essay_registered_questions(uuid)', 'EXECUTE') as registry_execute
from pg_roles r
where r.rolname in ('essay_worker','anon','authenticated','service_role');
select p.proname
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
 and has_function_privilege('essay_worker',p.oid,'EXECUTE')
 and not has_function_privilege('anon',p.oid,'EXECUTE')
order by p.proname;
```

Existing role additionally executes claim/finalize_success/finalize_failure/
reconcile/timeout. Enabling its API membership therefore exposes more capability
than metadata read. A membership change must be separately reviewed/approved;
the registry RPC approval is not approval for that broader access. No executable
permission migration is offered as ready: choose reviewed worker access or a
narrow read role first, with exact grant/rollback/authorization tests. A read-role
alternative also requires the server credential-role expectation to be updated.

### 2. Obtain the value (issuer/operator prerequisite)

The value is a signed JWT with `role=essay_worker` and a finite `exp`, signed by a
key currently trusted by THIS project. No test-user impersonation is necessary.
Reusing a valid existing trusted signer is preferred. If none is available,
issuer provisioning/key trust is separate approval work; Owner cannot currently
copy a ready value from API Keys. Legacy shared-secret signing is only possible
if that legacy key is still accepted; never place that secret in Cloudflare as
this JWT value.

Installed CLI supports `supabase gen bearer-jwt --role ... --valid-for ...`.
It signs LOCALLY: it does not fetch a project's signing key. Blank interactive
key input uses a development key and is invalid for this production setup.
Key entry can echo to terminal, so do not paste private JWKs into a recorded CLI.

After the approved issuer has configured a protected, outside-Git CLI workspace
with `[auth].signing_keys_path` pointing to the existing trusted private JWK file
(and verified the selected kid against the project), the operator can issue a
short validation token without printing it:

```sh
umask 077
essay_token_file=$(mktemp -t legendstudy-essay-worker)
supabase gen bearer-jwt --role essay_worker --valid-for 1h > "$essay_token_file"
# Only after successful issuance and signature/role/expiry verification:
pbcopy < "$essay_token_file"
```

This is a conditional operator procedure, NOT a command already run and NOT a
permanent one-hour production credential strategy. Do not continue if prompted
for an unconfigured signing key. Do not use a public JWT website. Do not put any
key/token in chat, Git, command arguments, debug output or screenshots. The issuer
must validate the signature using the project's trusted key, role and expiry,
then remove the temporary file and clear the clipboard after entry. Renewal must
be in place before continuous service: no automatic broker/rotation is deployed.

### 3. Cloudflare Secret entry

Workers & Pages → `legendstudy-lab` → Settings → Variables and Secrets →
Production → Add. Name `ESSAY_REGISTRY_WORKER_JWT`; paste ONLY the signed JWT,
without `Bearer ` or quotes; choose Secret/Encrypt, Save, then redeploy the reviewed
commit via the existing Pages procedure. Do not copy the signing private key.
Preview is a separate decision; do not provision production credentials there
implicitly. Preserve MATH_* settings, allowlist and evaluation switches.

### 4. Verification after setting

- Verify Production deployment success and its commit SHA; saving a Secret alone
  does not prove the running deployment uses it.
- The server rejects malformed, wrong-role, expired/near-expiry configuration;
  this is a preflight, not signature verification. Supabase verifies signature
  and database role/function ACL when the RPC actually executes.
- Sign in with the existing approved test account. WEB and APP authenticated
  POST `/api/essay/catalog` must succeed; compare the registered canonical ID set
  (76 exams/234 questions), not the public source selection77/237 that retains
  quarantined research entries. Private response must be `private, no-store`.
- Signed-out/private POST must be denied; another authenticated unallowlisted
  account must not reach the RPC. Public GET remains unchanged.
- Confirm published/evaluation activation remains OFF and allowlist unchanged.
  This read check needs no Provider or Credit transaction.
- Report only HTTP status/counts/set match and verification outcome, never headers,
  raw JWTs, browser localStorage, HAR or student content. Revoke/renew according to
  the approved issuer procedure; never disable signature/role checking to pass.

Test-account JWT authenticates the student to the gateway only. Publishable/anon
API keys belong in the separate apikey header. Secret/service_role keys and Math
worker credentials are not substitutes. Authenticator membership and issuer are
still prerequisites, and fixing them alone does not finish exam Credit/Draft/QA.

References: [Supabase signing keys](https://supabase.com/docs/guides/auth/signing-keys),
[PostgREST role switching](https://docs.postgrest.org/en/stable/references/auth.html),
[Cloudflare Pages Secrets](https://developers.cloudflare.com/pages/functions/bindings/#secrets).
