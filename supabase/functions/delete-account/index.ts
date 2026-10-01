// NOT DEPLOYED. Public client key + caller JWT only. No immediate delete route.
import { createHandler } from "./handler.ts";
const url = Deno.env.get("SUPABASE_URL");
const key = Deno.env.get("SUPABASE_ANON_KEY");
const enabled = Deno.env.get("ACCOUNT_LIFECYCLE_ENABLED") === "true";
Deno.serve(
  !enabled || !url || !key
    ? () => new Response("unavailable", { status: 503 })
    : createHandler({
      async call(token, operation) {
        const response = await fetch(
          `${url}/rest/v1/rpc/account_deletion_${operation}`,
          {
            method: "POST",
            headers: {
              apikey: key,
              authorization: `Bearer ${token}`,
              "content-type": "application/json",
            },
            body: "{}",
            signal: AbortSignal.timeout(10000),
          },
        );
        if (!response.ok) throw Error("DENIED");
        return await response.json();
      },
    }),
);
