/** Web Crypto only: no Node key objects, PEM signing or X509.verify. */
export const utf8 = (s: string) => new TextEncoder().encode(s);
export function base64(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s);
}
export const base64url = (b: Uint8Array) =>
  base64(b).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
export function decode64(s: string): Uint8Array<ArrayBuffer> {
  return Uint8Array.from(
    atob(s.replace(/-/g, "+").replace(/_/g, "/")),
    (c) => c.charCodeAt(0),
  );
}
export const hex = (b: ArrayBuffer | Uint8Array) =>
  Array.from(new Uint8Array(b), (x) => x.toString(16).padStart(2, "0")).join(
    "",
  );
export function unhex(h: string): Uint8Array<ArrayBuffer> {
  if (!/^(?:[0-9a-f]{2})+$/i.test(h)) throw Error("INVALID_HEX");
  return Uint8Array.from(h.match(/../g)!, (x) => parseInt(x, 16));
}
export function pkcs8(raw: string): Uint8Array<ArrayBuffer> {
  return decode64(
    raw.replace(/\\[rn]/g, "").replace(
      /-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----/g,
      "",
    ).replace(/\s/g, ""),
  );
}
export type AppleStage =
  | "CONFIG"
  | "KEY_IMPORT"
  | "JWT_SIGN"
  | "HTTP"
  | "RESPONSE"
  | "CHAIN"
  | "JWS"
  | "OCSP"
  | "CLAIMS";
export class AppleFailure extends Error {
  constructor(
    readonly stage: AppleStage,
    readonly httpStatus: number | null = null,
  ) {
    super("APPLE_UNAVAILABLE");
  }
}
export async function appleApiToken(
  env: (n: string) => string,
  now = Date.now(),
): Promise<string> {
  let key: CryptoKey;
  try {
    key = await crypto.subtle.importKey(
      "pkcs8",
      pkcs8(env("IAP_APPLE_PRIVATE_KEY")),
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    );
  } catch {
    throw new AppleFailure("KEY_IMPORT");
  }
  try {
    const iat = Math.floor(now / 1000);
    const input = base64url(
      utf8(
        JSON.stringify({
          alg: "ES256",
          kid: env("IAP_APPLE_KEY_ID"),
          typ: "JWT",
        }),
      ),
    ) + "." +
      base64url(
        utf8(
          JSON.stringify({
            iss: env("IAP_APPLE_ISSUER_ID"),
            iat,
            exp: iat + 1200,
            aud: "appstoreconnect-v1",
            bid: env("IAP_APPLE_BUNDLE_ID"),
          }),
        ),
      );
    const signature = new Uint8Array(
      await crypto.subtle.sign(
        { name: "ECDSA", hash: "SHA-256" },
        key,
        utf8(input),
      ),
    );
    if (signature.length !== 64) throw Error();
    return input + "." + base64url(signature);
  } catch {
    throw new AppleFailure("JWT_SIGN");
  }
}
/** Bound all remote payloads; do not follow redirects with credentials. */
export async function boundedBytes(
  r: Response,
  limit = 262144,
): Promise<Uint8Array<ArrayBuffer>> {
  const reader = r.body?.getReader();
  if (!reader) throw Error("EMPTY_RESPONSE");
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const part = await reader.read();
    if (part.done) break;
    size += part.value.length;
    if (size > limit) {
      await reader.cancel();
      throw Error("RESPONSE_TOO_LARGE");
    }
    chunks.push(part.value);
  }
  const result = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}
