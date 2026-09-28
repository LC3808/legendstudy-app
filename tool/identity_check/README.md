# Private shared-identity diagnostic (Phase2C)

**Owner acceptance update:** Kakao App/LAB actual auth.users.id equality is Owner-verified.
No repeat login, phone connection or diagnostic build installation is required. The procedures below
are retained tooling reference, not current Owner instructions. See
[canonical acceptance](../../wiki/essay-lab-shared-identity.md).

Operator tooling, not product UI, account linking, or a deployed service. Default App builds do not
run it; Release is always disabled. Never store real UUIDs/tokens/emails in Git or diagnostic output.
A salted digest is still private pseudonymous data. Challenge/observations live only in a chmod700
new `/private/tmp/` directory, files600, maximum1hour; observations older than5minutes are refused.
Delete the private directory after review; expiry prevents acceptance, not filesystem auto-deletion.

## Operator preparation — not Owner work

1. Connect an actual device and use the established local public build configuration; do not print it.
   Run `python3 tool/identity_check/check.py init --directory /private/tmp/ls-identity-<unique>`.
   This creates challenge.json and defines.json privately. Never reuse a challenge across review rounds.
2. Codex/operator builds/runs Debug or Profile using the existing configuration plus
   `--dart-define-from-file=/private/tmp/ls-identity-<unique>/defines.json`.
   Pipe process output directly (without tee/raw log file) into
   `python3 tool/identity_check/check.py app-log --directory /private/tmp/ls-identity-<unique>`.
   Only LS_IDENTITY_CHECK records are retained; unrelated output is discarded. The App code itself
   never prints credentials/IDs. Do not enable SDK debug or HTTP trace logging. Operator handles build,
   signing, install, and collection; Owner never runs terminal commands.
3. Prepare the existing LAB browser tab on https://lab.legendstudy.com. After Owner login, execute
   `probeLabIdentity` from browser.mjs in that page's browser automation context with the same salt,
   expiry and verified public publishable key. This is operator browser automation, NOT an instruction
   for Owner to paste JavaScript into a developer console. Do not navigate to callback URLs containing
   credentials, export localStorage, inspect network headers, or return the session from the page.
   The function reads the existing LAB `legendstudy-lab-auth` session only in browser memory, GETs
   the exact project's /auth/v1/user, checks identity and unchanged session, then returns digest only.
   It never refreshes/signs in/updates a profile or transfers credentials to a local server.
4. Send only the returned diagnostic object into
   `python3 tool/identity_check/check.py lab-input --directory /private/tmp/ls-identity-<unique>`.
   The strict collector rejects unexpected fields, another project/challenge, stale results or invalid
   digests. Browser failures return fixed status, not raw exceptions. Do not save raw browser/tool dumps.
5. After Owner confirms these were the SAME Kakao account (not merely identical email), run
   `python3 tool/identity_check/check.py compare --directory /private/tmp/ls-identity-<unique> --same-provider-account-confirmed`.
   Output only SAME_AUTH_USER_ID and RESULT. `NO / STOP_IDENTITY_CONFLICT` means STOP immediately;
   never merge users/update profiles. Classify subject/PKCE-OIDC/linking/callback causes separately.

## Owner steps once operator has armed both captures

1. Sign into the diagnostic App with Kakao.
2. Sign into LAB with the same Kakao account.

No UUID copy, SQL, DB console, token transfer or new account. The current task prepared/tested tooling;
no physical phone was connected, no diagnostic build was installed, no actual login was captured.
Operator must arm it before asking Owner to perform the two logins. Apple/Google are historical Owner
PASS; no repeat requested. Email is optional with an existing account, no new signup requested.

## Session switch / stale-result boundaries

App auth events invalidate pending GET results, emit signed_out, and revalidate the new session.
Browser probe must run after logout (signed_out), then after B login (new verified digest). Operator
checks A/B digests differ and repeats App/LAB comparison for B with explicit same-account confirmation.
Keep any transient A baseline private; do not commit a digest. A disconnected App collector is not proof
of logout, and a prior observation must not be reused. Identity equivalence does not prove database RLS;
reuse Phase2B actual local isolation evidence. Do not create Production Essay/history fixtures.

Diagnostics are not remotely attested identity proofs: their trust boundary includes the controlled
client code and operator. Fresh server GET, unchanged local session and challenge binding avoid reliance
on display name/email or unvalidated local UUID. Owner confirmation is needed to establish which provider
account was used; a list of linked providers is not proof of the current login provider.

Tests: Flutter identity/shared/native/Kakao; Node browser.test.mjs; Python test_check.py.
All tests use synthetic IDs and mocked Auth responses; none establishes actual Kakao same-user E2E.
