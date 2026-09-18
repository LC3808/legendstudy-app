// CANDIDATE — reviewed but never deployed. See wiki/account-deletion-privacy.md.
//
// Deletes the *caller's own* account. The caller is resolved from the verified
// bearer token only; the request body is never read, so no client can name a
// target. Admin members are refused here, not merely hidden in the UI.
//
// Responses are deliberately tiny: a status, or an error code. No schema, no
// row counts, no identifiers. Nothing is logged: not the token, not the user
// id, not the provider response.

export interface AccountDeletionAdmin {
  /// Resolves the bearer token to a user id, or null when it is not valid.
  userIdFromToken(token: string): Promise<string | null>;
  /// True when the user holds an admin role.
  isAdmin(userId: string): Promise<boolean>;
  /// Deletes the auth user. Returns true when the user is gone afterwards,
  /// including when it was already gone, so a retry is safe.
  deleteUser(userId: string): Promise<boolean>;
}

const headers = {
  "Content-Type": "application/json; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
};

const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers });

export const bearerToken = (request: Request): string | null => {
  const header = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(\S+)$/i.exec(header.trim());
  return match ? match[1] : null;
};

export function createHandler(admin: AccountDeletionAdmin) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "POST") {
      return reply(405, { error: "method_not_allowed" });
    }
    const token = bearerToken(request);
    if (token === null) return reply(401, { error: "unauthorized" });

    let userId: string | null;
    try {
      userId = await admin.userIdFromToken(token);
    } catch (_) {
      return reply(500, { error: "deletion_failed" });
    }
    if (userId === null) return reply(401, { error: "unauthorized" });

    try {
      // Fail closed: an admin account is removed through an operator
      // procedure, never through the app's self-service button.
      if (await admin.isAdmin(userId)) {
        return reply(403, { error: "admin_blocked" });
      }
      // Every user-owned table cascades from auth.users, and feedback is
      // detached by ON DELETE SET NULL, so this single call is the whole
      // deletion. Repeating it on an already deleted user still answers
      // "deleted", which keeps a retry or a double tap harmless.
      const gone = await admin.deleteUser(userId);
      return gone
        ? reply(200, { status: "deleted" })
        : reply(500, { error: "deletion_failed" });
    } catch (_) {
      return reply(500, { error: "deletion_failed" });
    }
  };
}
