// CANDIDATE — not deployed. Wiring only; the reviewable logic is handler.ts.
import { deleteAvatarBeforeAccount } from "./avatar-cleanup.ts";
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
      const deleteAccount = async () => {
        const { error } = await client.auth.admin.deleteUser(userId);
        if (!error) return true;
        // Already gone is success: the endpoint is idempotent by contract.
        const { data, error: lookupError } = await client.auth.admin
          .getUserById(userId);
        return lookupError?.code === "user_not_found" ||
          (!lookupError && data?.user == null);
      };
      // Off until the private bucket is applied and reviewed with deletion E2E.
      if (Deno.env.get("PROFILE_PHOTO_ENABLED") !== "true") {
        return deleteAccount();
      }
      return deleteAvatarBeforeAccount(
        userId,
        (paths) => client.storage.from("profile-avatars").remove(paths),
        deleteAccount,
      );
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
