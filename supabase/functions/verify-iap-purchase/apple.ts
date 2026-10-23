import { type Purchase, Rejected, type VerifiedPurchase } from "./core.ts";
import { appleApiToken, AppleFailure, boundedBytes } from "./apple-crypto.ts";
import { verifyAppleJws } from "./apple-certificates.ts";
export async function verifyApple(
  p: Purchase,
  env: (n: string) => string,
  fetcher: typeof fetch = fetch,
): Promise<VerifiedPurchase> {
  let environment: string, bundle: string, roots: string[];
  try {
    environment = env("IAP_APPLE_ENVIRONMENT");
    bundle = env("IAP_APPLE_BUNDLE_ID");
    const appId = Number(env("IAP_APPLE_APP_ID"));
    roots = JSON.parse(env("IAP_APPLE_ROOT_CERTIFICATES_BASE64"));
    if (
      !["Production", "Sandbox"].includes(environment) || !bundle ||
      !Number.isSafeInteger(appId) || appId <= 0 || !Array.isArray(roots) ||
      !roots.length || roots.length > 8 || roots.some((r) =>
        typeof r !== "string" || r.length > 20000
      )
    ) throw Error();
  } catch {
    throw new AppleFailure("CONFIG");
  }
  const token = await appleApiToken(env);
  const host = environment === "Production"
    ? "https://api.storekit.apple.com"
    : "https://api.storekit-sandbox.apple.com";
  let response: Response;
  try {
    response = await fetcher(
      `${host}/inApps/v1/transactions/${encodeURIComponent(p.transaction_id)}`,
      {
        headers: { Authorization: `Bearer ${token}` },
        redirect: "error",
        signal: AbortSignal.timeout(15000),
      },
    );
  } catch {
    throw new AppleFailure("HTTP");
  }
  if (response.status === 404) {
    await response.body?.cancel();
    throw new Rejected();
  }
  if (!response.ok) {
    await response.body?.cancel();
    throw new AppleFailure("HTTP", response.status);
  }
  let signed: string;
  try {
    const data = JSON.parse(
      new TextDecoder().decode(await boundedBytes(response)),
    );
    signed = data.signedTransactionInfo;
    if (typeof signed !== "string" || !signed) throw Error();
  } catch {
    throw new AppleFailure("RESPONSE");
  }
  const t = await verifyAppleJws(signed, roots, fetcher);
  if (
    t.bundleId !== bundle || t.environment !== environment ||
    t.type !== "Consumable" || t.quantity !== 1 ||
    t.inAppOwnershipType !== "PURCHASED" ||
    typeof t.appAccountToken !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      t.appAccountToken,
    ) ||
    typeof t.purchaseDate !== "number" || !Number.isFinite(t.purchaseDate) ||
    t.purchaseDate <= 0 ||
    typeof t.transactionId !== "string" || !t.transactionId ||
    typeof t.productId !== "string" || !t.productId
  ) throw new Rejected();
  return {
    platform: "apple",
    productId: t.productId,
    transactionId: t.transactionId,
    accountId: t.appAccountToken.toLowerCase(),
    purchasedAt: new Date(t.purchaseDate).toISOString(),
    environment: environment as "Production" | "Sandbox",
    revoked: t.revocationDate !== undefined,
  };
}
