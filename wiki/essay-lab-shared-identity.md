# Essay LAB Phase2C — shared identity E2E gate

**APP_LAB_SHARED_IDENTITY: PASS — Owner acceptance, 2026-09-28.**
Owner logged into LegendStudy App and LAB with the same actual Kakao account and directly compared
both surfaces' actual Supabase auth.users.id UUIDs, confirming equality. KAKAO: OWNER_PASS — SAME
auth.users.id VERIFIED. This is Owner-reported actual identity comparison, not an inference from email,
provider labels or diagnostic unit tests. No actual UUID/email/token is recorded here.

The earlier OWNER_E2E_REQUIRED gate is closed. No repeat Kakao login, diagnostic iPhone build installation
or additional capture is required. Apple/Google historical Owner PASS is retained. Email/password NOT_RUN
does not block the current Migration Gate. Other privacy/AI provider/retention rollout gates remain separate.

[Phase2B](essay-lab-server-transactions.md) actual local JWT/PostgREST and isolation results remain PASS.
Schema, transactions and KEEP19 were not reopened. [Existing auth acceptance](auth-native-owner-acceptance.md)
records Apple/Google shared identity Owner PASS, preserved without repeat login requests.

## Static source review

| Boundary | Actual source finding |
|---|---|
| App project | AppConfig validates only HTTPS stlhijzpjfgwwdgunlsd.supabase.co, rejects alternate hosts/ports/credentials |
| LAB project | auth-config.ts validates same URL/public key; browser-auth-client.ts creates the Supabase client |
| Common identity | Supabase server user.id = auth.users.id; profiles.id references auth.users(id), no Essay identity master |
| App Kakao | SDK signInWithOAuth(kakao), PKCE/callback managed by Supabase, existing app custom-scheme return |
| LAB Kakao | State/nonce/verifier validation, token exchange, signInWithIdToken(kakao); Supabase validates issuer/audience/signature |
| Callback authority | Callback transports credentials; neither callback uses email/display name as canonical identity |
| Session scope | App and browser persist separate sessions; same backend does not itself prove same provider subject/user |

LAB source was read and its existing tests run, not edited/deployed. Hosted provider configuration was not
changed or queried. Code/config match is STATIC_BACKEND_MATCH: PASS, not a fresh provider E2E claim.

## Prepared diagnostic — retained, not required for this acceptance

[Operator harness instructions](../tool/identity_check/README.md),
[App collector](../lib/features/auth/identity_diagnostic.dart),
[LAB browser adapter](../tool/identity_check/browser.mjs),
[private comparison CLI](../tool/identity_check/check.py).

App opt-in Debug/Profile hook calls auth.getUser(); Release always disables it. Browser adapter executes
inside the actual LAB page and GETs /auth/v1/user using the existing browser session entirely in memory.
Both require a stable session through validation and compute HMAC-SHA256(one-time salt, project+user.id).
They emit only challenge hash, digest, surface, status and timestamp. No raw UUID/email/token/provider secret
is emitted. Fixed failure statuses suppress SDK/HTTP exception details. Expired/wrong-context observations
are refused; missing login is NOT_VERIFIED. A signed-out App event replaces the last observation.

Private files are outside Git, owner-only permissions. Salt expires after1hour; records after5minutes.
Expiry is not automatic disk deletion: operator removes temporary files after review. Do not commit actual
digests either. No local credential relay, Production write, SQL, DB console, new account or UI feature.
One main.dart hook is silent by default; it does not change OAuth/callback/profile handling.

Owner same-provider-account confirmation is necessary. Diagnostic equality compares server-validated
user IDs, not email or linked-provider labels. Same email alone is never PASS. If digests differ, STOP:
no auto-merge, auth.users updates or profile linking. Classify provider subject, PKCE/OIDC, duplicate users,
linking or callback/config causes for Owner review, without automatic remediation.

## Execution record

| Provider | Existing evidence | This Phase fresh E2E |
|---|---|---|
| Apple | HISTORICAL_OWNER_PASS | NOT_RUN; no repeat requested |
| Google | HISTORICAL_OWNER_PASS | NOT_RUN; no repeat requested |
| Kakao | Owner same-account App/LAB actual UUID comparison | OWNER_PASS — SAME auth.users.id VERIFIED |
| Email/password | Same backend/password flow; login accepted historically | NOT_RUN; does not block current Migration Gate |

KAKAO_APP_LOGIN / LAB_LOGIN / SAME_ACCOUNT / SAME_AUTH_USER_ID: YES, confirmed by Owner.
No fresh Codex login test or diagnostic capture was performed for this acceptance update.
ACCOUNT_SWITCH: diagnostic stale-response/logout tests PASS; actual device/browser A→B NOT_RUN.
Phase2B local RLS isolation remains PASS and is not relabelled Production history validation.
Production Essay tables were not created/populated to test switching.

At the earlier preparation checkpoint only macOS/Web targets were available; diagnostic installation
and live capture were NOT_RUN. That historical tooling state is preserved and does not invalidate the
subsequent Owner comparison. The prior device-connection/login action list is superseded: no Owner action
or repeat E2E is required for the accepted Kakao identity gate.

## Gates and limits

| Gate | Status |
|---|---|
| Static shared backend | PASS |
| Kakao same user | OWNER_PASS — SAME auth.users.id VERIFIED |
| App/LAB shared identity | PASS |
| Migration technically ready | YES for accepted Phase2B schema/transaction correctness; separate approval still required |
| Migration promotion | [PROMOTED / NOT_APPLIED](essay-lab-migration-promotion.md), Owner approved |
| Real student data identity gate | PASS |
| Overall real student rollout | Other privacy/AI provider/retention gates remain; not automatically approved |
| Production schema/data mutation | NO |
| Production apply / Owner SQL | NO |

No real credentials/UUIDs were collected or stored by Codex. This documentation update made no Production
Auth/DB request, SQL execution or mutation. Owner login/comparison is the acceptance evidence.
Identity PASS alone will not implement the remaining worker/provider/retention deployment work from Phase2B.

[Sanitized status and historical preparation result](../tool/identity_check/result.json) records test counts/source references.
Next: Owner/ChatGPT promoted package review → separately authorized Production preflight; no identity retest.
