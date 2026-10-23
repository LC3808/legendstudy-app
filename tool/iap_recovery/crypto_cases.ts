// Ephemeral synthetic PKI only; no store requests, credentials or Production writes.
import js from "npm:jsrsasign@11.1.5";
import {
  appleApiToken,
  AppleFailure,
  base64url,
  decode64,
  unhex,
  utf8,
} from "../../supabase/functions/verify-iap-purchase/apple-crypto.ts";
import { verifyApple } from "../../supabase/functions/verify-iap-purchase/apple.ts";
import {
  handler,
  Rejected,
} from "../../supabase/functions/verify-iap-purchase/core.ts";
import { verifyAppleJws } from "../../supabase/functions/verify-iap-purchase/apple-certificates.ts";
const { KJUR, KEYUTIL } = js;
const assert = (v: unknown, m: string) => {
  if (!v) throw Error(m);
};
const stamp = (n: number) =>
  new Date(n).toISOString().replace(/[-:]/g, "").slice(0, 15).replace("T", "") +
  "Z";
export async function runCryptoCases(rsaRoot = false): Promise<string[]> {
  const passed: string[] = [];
  const now = Date.now(),
    before = stamp(now - 60000),
    after = stamp(now + 3600000);
  const keys = Array.from(
    { length: 3 },
    () => KEYUTIL.generateKeypair("EC", "secp256r1"),
  );
  if (rsaRoot) keys[0] = KEYUTIL.generateKeypair("RSA", 2048);
  const signatureAlgorithm = (n: number) => rsaRoot && n === 0 ? "SHA256withRSA" : "SHA256withECDSA";
  const names = [
    "/CN=Synthetic root",
    "/CN=Synthetic intermediate",
    "/CN=Synthetic leaf",
  ];
  const certs = keys.map((key: any, n: number) =>
    KJUR.asn1.x509.X509Util.newCertPEM({
      serial: { int: n + 1 },
      sigalg: signatureAlgorithm(Math.max(0,n-1)),
      issuer: { str: names[Math.max(0, n - 1)] },
      subject: { str: names[n] },
      notbefore: { str: before },
      notafter: { str: after },
      sbjpubkey: key.pubKeyObj,
      cakey: keys[Math.max(0, n - 1)].prvKeyObj,
      ext: [
        { extname: "basicConstraints", cA: n < 2, critical: true },
        {
          extname: "authorityInfoAccess",
          array: [{ ocsp: `http://ocsp.apple.com/synthetic-${n}` }],
        },
        ...(n === 1
          ? [{ extname: "1.2.840.113635.100.6.2.1", extn: "0500" }]
          : n === 2
          ? [{ extname: "1.2.840.113635.100.6.11.1", extn: "0500" }]
          : []),
      ],
    })
  );
  const responderKey = KEYUTIL.generateKeypair("EC", "secp256r1");
  const responders = [0, 1].map(n => KJUR.asn1.x509.X509Util.newCertPEM({
    serial:{int:20+n},sigalg:signatureAlgorithm(n),issuer:{str:names[n]},subject:{str:"/CN=Synthetic responder"},
    notbefore:{str:before},notafter:{str:after},sbjpubkey:responderKey.pubKeyObj,cakey:keys[n].prvKeyObj,
    ext:[{extname:"extKeyUsage",array:["ocspSigning"]}]
  }));
  const der = (p: string) => p.replace(/-----[^-]+-----|\s/g, "");
  const sign = (payload: unknown, certificates = certs) =>
    KJUR.jws.JWS.sign(
      "ES256",
      JSON.stringify({
        alg: "ES256",
        x5c: [...certificates].reverse().map(der),
      }),
      JSON.stringify(payload),
      keys[2].prvKeyObj,
    );
  const payload = {
    transactionId: "synthetic",
    quantity: 1,
    bundleId: "com.legendstudy.app",
    environment: "Production",
    type: "Consumable",
    inAppOwnershipType: "PURCHASED",
    appAccountToken: "11111111-1111-4111-8111-111111111111",
    purchaseDate: now,
    productId: "com.legendstudy.essay.credit1",
  };
  const signed = sign(payload);
  let mode = "good";
  const fetcher: typeof fetch = async (input) => {
    const n = Number(String(input).split("-").at(-1));
    if (mode === "outage") return new Response("", { status: 503 });
    const issuer = Math.max(0, n - 1);
    const id = new KJUR.asn1.ocsp.CertID().getParamByCerts(
      certs[issuer],
      certs[n],
      "sha256",
    );
    if (mode === "wrong-cert") id.sbjsn = "7777";
    const response = new KJUR.asn1.ocsp.OCSPResponse({
      resstatus: "successful",
      restype: "ocspBasic",
      respid: mode === 'delegated' ? { name: {str:'/CN=Synthetic responder'}} : mode === 'by-key' ? {key: KJUR.crypto.Util.hashHex(new js.X509(certs[issuer]).getSPKIValue(), 'sha1')} : { name: { str: names[issuer] } },
      ...(mode === 'delegated' ? {certs:[responders[issuer]]} : {}),
      prodat: { str: before },
      array: [{
        certid: id,
        status: { status: mode === "unknown" ? "unknown" : "good" },
        thisupdate: { str: before },
        nextupdate: { str: mode === "stale" ? before : after },
      }],
      sigalg: mode === 'delegated' ? 'SHA256withECDSA' : signatureAlgorithm(mode === 'wrong-signer' ? 2 : issuer),
      reskey: mode === 'delegated' ? responderKey.prvKeyObj : keys[mode === "wrong-signer" ? 2 : issuer].prvKeyObj,
    });
    return new Response(unhex(response.tohex()));
  };
  assert(
    (await verifyAppleJws(signed, [der(certs[0])], fetcher, now))
      .transactionId === "synthetic",
    "valid signed chain + online status",
  );
  passed.push("valid chain, JWS and both OCSP responses");
  async function rejects(
    label: string,
    work: () => Promise<unknown>,
    stage: string,
  ) {
    try {
      await work();
    } catch (e) {
      assert(
        e instanceof AppleFailure && e.stage === stage,
        label + " error stage",
      );
      passed.push(label);
      return;
    }
    throw Error(label + " accepted");
  }
  for (mode of ["unknown", "stale", "wrong-cert", "wrong-signer", "outage"]) {
    await rejects(
      "OCSP " + mode,
      () => verifyAppleJws(signed, [der(certs[0])], fetcher, now),
      "OCSP",
    );
  }
  for (mode of ['delegated', 'by-key']) {
    assert((await verifyAppleJws(signed,[der(certs[0])],fetcher,now)).transactionId === 'synthetic','OCSP '+mode);
    passed.push('OCSP '+mode+' verified');
  }
  mode = "good";
  await rejects('malformed chain length',()=>verifyAppleJws(sign(payload,certs.slice(1)),[der(certs[0])],fetcher,now),'CHAIN');
  await rejects('reordered chain',()=>verifyAppleJws(sign(payload,[certs[0],certs[2],certs[1]]),[der(certs[0])],fetcher,now),'CHAIN');
  await rejects('malformed compact JWS',()=>verifyAppleJws(signed+'.extra',[der(certs[0])],fetcher,now),'CHAIN');
  await rejects('not-yet-valid chain',()=>verifyAppleJws(signed,[der(certs[0])],fetcher,now-120000),'CHAIN');
  await rejects(
    "untrusted root",
    () => verifyAppleJws(signed, [der(certs[1])], fetcher, now),
    "CHAIN",
  );
  await rejects(
    "expired chain",
    () => verifyAppleJws(signed, [der(certs[0])], fetcher, now + 7200000),
    "CHAIN",
  );
  const parts = signed.split(".");
  parts[1] = base64url(utf8(JSON.stringify({ transactionId: "tampered" })));
  await rejects(
    "tampered payload",
    () => verifyAppleJws(parts.join("."), [der(certs[0])], fetcher, now),
    "JWS",
  );
  const web = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  );
  const raw = new Uint8Array(
    await crypto.subtle.exportKey("pkcs8", web.privateKey),
  );
  const b64 = btoa(String.fromCharCode(...raw));
  const pem = "-----BEGIN PRIVATE KEY-----\n" + b64 +
    "\n-----END PRIVATE KEY-----";
  for (const value of [pem, pem.replace(/\n/g, "\\n"), b64, base64url(raw)]) {
    const token = await appleApiToken(
      (n) => n === "IAP_APPLE_PRIVATE_KEY" ? value : "synthetic",
      now,
    );
    const a = token.split(".");
    const claims = JSON.parse(new TextDecoder().decode(decode64(a[1])));
    assert(
      claims.exp - claims.iat === 1200 && claims.aud === "appstoreconnect-v1" &&
        claims.bid === "synthetic",
      "JWT claims",
    );
    assert(
      decode64(a[2]).length === 64 &&
        await crypto.subtle.verify(
          { name: "ECDSA", hash: "SHA-256" },
          web.publicKey,
          decode64(a[2]),
          utf8(a[0] + "." + a[1]),
        ),
      "JWT signature",
    );
  }
  passed.push("PKCS8 PEM, escaped PEM, base64, base64url JWT signatures");

  const settings: Record<string, string> = {
    IAP_APPLE_PRIVATE_KEY: pem,
    IAP_APPLE_ENVIRONMENT: "Production",
    IAP_APPLE_BUNDLE_ID: "com.legendstudy.app",
    IAP_APPLE_APP_ID: "1",
    IAP_APPLE_ROOT_CERTIFICATES_BASE64: JSON.stringify([der(certs[0])]),
    IAP_APPLE_KEY_ID: "synthetic",
    IAP_APPLE_ISSUER_ID: "synthetic",
  };
  const env = (n: string) => settings[n];
  const purchase = {
    platform: "apple" as const,
    transaction_id: payload.transactionId,
    product_id: payload.productId,
    verification_data: "synthetic",
  };
  let responseStatus = 200,
    responseClaims: Record<string, unknown> = { ...payload };
  const api: typeof fetch = async (input, init) => {
    if (String(input).includes("ocsp.apple.com")) {
      return await fetcher(input, init);
    }
    assert(
      String(input) ===
        "https://api.storekit.apple.com/inApps/v1/transactions/synthetic",
      "current Apple host",
    );
    assert(init?.redirect === "error", "credential redirect blocked");
    return responseStatus === 200
      ? Response.json({ signedTransactionInfo: sign(responseClaims) })
      : new Response(null, { status: responseStatus });
  };
  assert(
    (await verifyApple(purchase, env, api)).accountId ===
      payload.appAccountToken,
    "verified transaction",
  );
  passed.push("Apple HTTP + signed transaction projection");
  for (responseStatus of [400, 401, 410, 429, 500]) {
    await rejects(
      "HTTP " + responseStatus + " retryable",
      () => verifyApple(purchase, env, api),
      "HTTP",
    );
  }
  responseStatus = 404;
  try {
    await verifyApple(purchase, env, api);
    throw Error("404 accepted");
  } catch (e) {
    assert(e instanceof Rejected, "404 rejection");
  }
  passed.push("HTTP 404 rejected");
  responseStatus = 200;
  let grants = 0;
  const service = handler({
    authenticate: async () => payload.appAccountToken,
    verify: (p) => verifyApple(p, env, api),
    grant: async () => {
      grants++;
      return "granted";
    },
  }, true);
  const request = () =>
    new Request("https://synthetic.invalid", {
      method: "POST",
      headers: { Authorization: "Bearer synthetic" },
      body: JSON.stringify(purchase),
    });
  for (
    const change of [
      { bundleId: "wrong" },
      { environment: "Sandbox" },
      { type: "Non-Consumable" },
      { quantity: 2 },
      { inAppOwnershipType: "FAMILY_SHARED" },
      { appAccountToken: "22222222-2222-4222-8222-222222222222" },
      { transactionId: "other" },
      { productId: "com.legendstudy.essay.credit3" },
      { revocationDate: now },
      { purchaseDate: now + 3600000 },
    ]
  ) {
    responseClaims = { ...payload, ...change };
    assert(
      (await service(request())).status === 422,
      "invalid signed claims rejected",
    );
    assert(grants === 0, "invalid claims no grant");
  }
  passed.push(
    "10 signed claim/account/transaction/revocation gates: zero grants",
  );
  responseClaims = { ...payload };
  assert(
    (await (await service(request())).json()).status === "granted" &&
      grants === 1,
    "valid path reaches mock grant exactly once",
  );
  passed.push("valid complete verifier reaches mock grant");
  passed.push(rsaRoot ? 'RSA root/intermediate certificate + RSA OCSP' : 'EC certificate + ECDSA OCSP');
  return passed;
}
