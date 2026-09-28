# Essay LAB Phase2C — shared identity E2E gate

**STATIC PASS / DIAGNOSTIC READY / OWNER_E2E_REQUIRED.** No physical iOS/Android device was connected
at preparation time; no instrumented App was installed and no actual provider login was captured.
Do not interpret harness tests as equal Production auth.users.id. Owner action comes after operator setup.

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

## Safe diagnostic

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
| Kakao | Login accepted historically; equality unverified | OWNER_E2E_REQUIRED |
| Email/password | Same backend/password flow; login accepted historically | NOT_RUN; optional existing account only |

KAKAO_APP_LOGIN / LAB_LOGIN / SAME_ACCOUNT / SAME_AUTH_USER_ID: NOT_VERIFIED in this phase.
ACCOUNT_SWITCH: diagnostic stale-response/logout tests PASS; actual device/browser A→B NOT_RUN.
Phase2B local RLS isolation remains PASS and is not relabelled Production history validation.
Production Essay tables were not created/populated to test switching.

Current device discovery found only macOS/Web targets, no physical phone. Diagnostic build installation
and live capture are NOT_RUN. This is a concrete prerequisite, not missing SQL or a request for user IDs.
Codex/operator must connect/install/arm capture first; Owner then only performs the logins.

## Minimal next Owner actions

1. Connect the iPhone to the Mac so Codex can install/run the short-lived diagnostic build.
2. Once Codex says capture is armed, log into the App with Kakao.
3. Log into LAB with the same Kakao account.

Codex handles browser diagnostic and SAME_USER comparison. Do not ask Owner for UUIDs, tokens, SQL,
Dashboard access or developer-console input. Existing account only; no signup or Apple/Google repeat.
Optional A logout→B switch may be verified afterward if another existing account is readily available.

## Gates and limits

| Gate | Status |
|---|---|
| Static shared backend | PASS |
| Kakao same user | OWNER_E2E_REQUIRED |
| App/LAB shared identity | PARTIAL (historical Apple/Google retained) |
| Migration technically ready | YES for accepted Phase2B schema/transaction correctness; separate approval still required |
| Migration promotion | READY_FOR_OWNER_REVIEW, not promoted |
| Real student data ready | NO / BLOCKED |
| Production schema/data mutation | NO |
| Production apply / Owner SQL | NO |

No real credentials/UUIDs were captured. No Production Auth/DB request was made by this preparation task.
Actual future login is the only authorized Production interaction; diagnostic GETs must remain read-only.
Identity PASS alone will not implement the remaining worker/provider/retention deployment work from Phase2B.

[Sanitized preparation result](../tool/identity_check/result.json) records test counts/source references.
Next is actual Owner Kakao E2E with this harness, then Owner/ChatGPT migration-promotion decision.
