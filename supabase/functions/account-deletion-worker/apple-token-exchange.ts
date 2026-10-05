/** Server-only Apple authorization_code -> refresh_token exchange.
 * The client sends ONLY the one-time authorizationCode from Sign in with Apple; the
 * code↔token exchange (which needs the Apple client_secret) happens here, server-side.
 * Never logs or stores the code, secret or token. Missing/failed exchange is NOT success. */

import { appleClientSecret, type AppleSigningConfig } from "./apple-client-secret.ts";

export type AppleExchangeResult = { refreshToken: string } | null;

export async function exchangeAppleAuthorizationCode(
  cfg: AppleSigningConfig,
  authorizationCode: string,
  transport: typeof fetch = fetch,
  now: number = Date.now(),
): Promise<AppleExchangeResult> {
  if (!authorizationCode || authorizationCode.length > 2048) return null;
  let secret: string;
  try {
    secret = await appleClientSecret(cfg, now);
  } catch {
    return null;
  }
  try {
    const response = await transport("https://appleid.apple.com/auth/token", {
      method: "POST",
      redirect: "error",
      signal: AbortSignal.timeout(10000),
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: cfg.clientId,
        client_secret: secret,
        grant_type: "authorization_code",
        code: authorizationCode,
      }),
    });
    if (response.status !== 200) return null;
    const data = await response.json();
    return typeof data?.refresh_token === "string" && data.refresh_token
      ? { refreshToken: data.refresh_token }
      : null;
  } catch {
    return null;
  }
}
