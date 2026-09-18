// CANDIDATE — not deployed. Wiring only; the reviewable logic is handler.ts.
import { createClient } from "npm:@supabase/supabase-js@2";
import { type AccountDeletionAdmin, createHandler } from "./handler.ts";

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });

export const createSupabaseAdmin = (
  url: string,
  serviceRoleKey: string,
): AccountDeletionAdmin => {
  // Service role stays server side. It is never returned, echoed or logged.
  const client = createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  return {
    async userIdFromToken(token) {
      const { data, error } = await client.auth.getUser(token);
      if (error) return null;
      return data.user?.id ?? null;
    },
    async isAdmin(userId) {
      const { data, error } = await client
        .from("admin_users")
        .select("user_id")
        .eq("user_id", userId)
        .maybeSingle();
      if (error) throw new Error("admin_check_failed");
      return data !== null;
    },
    async deleteUser(userId) {
      const { error } = await client.auth.admin.deleteUser(userId);
      if (!error) return true;
      // Already gone is success: the endpoint is idempotent by contract.
      const { data } = await client.auth.admin.getUserById(userId);
      return data?.user == null;
    },
  };
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (import.meta.main) {
  if (!supabaseUrl || !serviceRoleKey) {
    Deno.serve(() => json(503, { error: "configuration_unavailable" }));
  } else {
    Deno.serve(createHandler(createSupabaseAdmin(supabaseUrl, serviceRoleKey)));
  }
}
