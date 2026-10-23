import { runCryptoCases } from "./crypto_cases.ts";
Deno.test("Apple synthetic cryptography and fail-closed regressions", async () => {
  console.log(await runCryptoCases());
});

Deno.test('Apple RSA chain and delegated OCSP regressions',async()=>{console.log(await runCryptoCases(true))});
