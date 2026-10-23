import { runCryptoCases } from "../crypto_cases.ts";
import { p384Cases } from "../p384_cases.ts";
Deno.serve(async () => {
  try {
    return Response.json({
      runtime: Deno.version,
      passed: [...await runCryptoCases(), ...await runCryptoCases(true), await p384Cases()],
    });
  } catch (e) {
    return Response.json({ error: e instanceof Error ? e.message : "FAILED" }, {
      status: 500,
    });
  }
});
