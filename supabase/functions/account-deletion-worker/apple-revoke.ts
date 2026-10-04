/** Server-only Apple transport. Caller must obtain the token from a verified
 * owner/provider binding; accepting arbitrary client tokens is forbidden.
 * No material is stored or logged. Missing material is NOT a verified revoke.
 */
export type AppleRevocationMaterial = {
  clientId: string;
  clientSecret: string;
  token: string;
  tokenType: "refresh_token" | "access_token";
};
export async function revokeAppleToken(
  material: AppleRevocationMaterial | null,
  transport: typeof fetch = fetch,
): Promise<boolean> {
  if (!material || !["com.legendstudy.app", "com.legendstudy.lab"].includes(material.clientId) ||
    !material.clientSecret || !material.token ||
    !["refresh_token", "access_token"].includes(material.tokenType)) return false;
  try {
    const response = await transport("https://appleid.apple.com/auth/revoke", {
      method: "POST", redirect: "error", signal: AbortSignal.timeout(10000),
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ client_id: material.clientId,
        client_secret: material.clientSecret, token: material.token,
        token_type_hint: material.tokenType }),
    });
    // Apple uses 200 for valid requests, including previously revoked tokens.
    // This proves endpoint acceptance, not the provenance of the supplied token.
    return response.status === 200;
  } catch { return false; }
}
