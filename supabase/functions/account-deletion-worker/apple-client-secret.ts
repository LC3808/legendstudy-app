/** Server-only Apple client_secret (ES256 JWT) generation.
 * The Apple signing key (.p8 PKCS8 PEM), Key ID, Team ID and Services/client ID are
 * provided by Owner secrets at runtime. Nothing here is stored or logged. The client
 * (app/web) never sees this material. */

export type AppleSigningConfig = {
  teamId: string;
  keyId: string;
  /** Services ID / client_id used for Sign in with Apple (e.g. com.legendstudy.app). */
  clientId: string;
  /** PKCS8 PEM contents of the Apple .p8 private key. */
  privateKeyPem: string;
};

function b64url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlJson(value: unknown): string {
  return b64url(new TextEncoder().encode(JSON.stringify(value)));
}

function pkcs8FromPem(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [A-Z ]+-----/g, "")
    .replace(/-----END [A-Z ]+-----/g, "")
    .replace(/\s+/g, "");
  if (!body) throw Error("APPLE_SIGNING_UNAVAILABLE");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

/** Build a short-lived Apple client_secret JWT (ES256). `exp` stays well under Apple's
 * 6-month maximum; a fresh secret is minted per call. */
export async function appleClientSecret(
  cfg: AppleSigningConfig,
  now: number = Date.now(),
): Promise<string> {
  if (!cfg.teamId || !cfg.keyId || !cfg.clientId || !cfg.privateKeyPem) {
    throw Error("APPLE_SIGNING_UNAVAILABLE");
  }
  const iat = Math.floor(now / 1000);
  const header = { alg: "ES256", kid: cfg.keyId, typ: "JWT" };
  const payload = {
    iss: cfg.teamId,
    iat,
    exp: iat + 300,
    aud: "https://appleid.apple.com",
    sub: cfg.clientId,
  };
  const signingInput = `${b64urlJson(header)}.${b64urlJson(payload)}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pkcs8FromPem(cfg.privateKeyPem) as BufferSource,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      new TextEncoder().encode(signingInput),
    ),
  );
  // Web Crypto returns the raw r||s concatenation, which is exactly the JWS ES256 form.
  return `${signingInput}.${b64url(signature)}`;
}
