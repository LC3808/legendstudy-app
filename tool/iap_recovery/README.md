# IAP recovery verification (draft, not deployed)

Synthetic fixtures are generated in memory. No Production secret, store API,
purchase replay, ledger RPC or payment is used. The mock grant in the last case
only increments a local counter; it does not prove DB idempotency.

From the repository root:

```sh
deno check --lock=supabase/functions/verify-iap-purchase/deno.lock supabase/functions/verify-iap-purchase/index.ts
deno test supabase/functions/verify-iap-purchase/core_test.ts tool/iap_recovery/crypto_test.ts
```

Edge comparison (use a free localhost port and the absolute checkout path):

```sh
docker run --rm --name legendstudy-iap-recovery-tests \
  -p 127.0.0.1:19092:9000 \
  -v "$PWD:/workspace:ro" \
  public.ecr.aws/supabase/edge-runtime:v1.74.3 \
  start --main-service /workspace/tool/iap_recovery/edge
curl --fail http://127.0.0.1:19092
docker stop legendstudy-iap-recovery-tests
```

This tests a pinned local Edge runtime, not an assertion of the deployed runtime
version. `probe/` separately reproduces Node API limitations with ephemeral keys
and a public synthetic certificate. No fixture key is a store credential.

RSA/delegated OCSP and malformed-chain coverage now pass. Source rollback v20 is
in rollback/. Build both review packages with python3 tool/iap_recovery/build_package.py.
Both preserve the deployed Production entrypoint. Review dependency resolution and
obtain Owner approval for the exact package before any deployment.
The existing deployment helper currently packages only the old three source files;
do not run it for this draft. Actual Apple JWS/Google order verification and device
balance checks remain separate acceptance gates. See the canonical investigation
at `wiki/iap-production-read-only-20261023.md`.
