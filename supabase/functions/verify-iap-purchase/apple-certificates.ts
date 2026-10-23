import "npm:reflect-metadata@0.2.2";
import {
  BasicConstraintsExtension,
  X509Certificate,
} from "npm:@peculiar/x509@2.2.0";
// ASN.1/OCSP parsing only. All signature and certificate verification uses Web Crypto.
import js from "npm:jsrsasign@11.1.5";
import { p384 } from "npm:@noble/curves@2.0.1/nist.js";
import {
  AppleFailure,
  boundedBytes,
  decode64,
  hex,
  unhex,
  utf8,
} from "./apple-crypto.ts";
const { X509, KJUR, ASN1HEX } = js;
// jsrsasign's ambient declarations omit OCSPParser/getParamByCerts. The parsed
// values remain untrusted and are checked below before any entitlement is used.
const ocsp = KJUR.asn1.ocsp as unknown as {
  OCSPRequest: new (value: unknown) => { getEncodedHex(): string };
  OCSPParser: new () => { getOCSPResponse(raw: string): any };
  CertID: new () => { getParamByCerts(issuer: string, subject: string, algorithm: string): Record<string,string> };
};
const parsed = (c: X509Certificate) => {
  const x = new X509();
  x.readCertPEM(c.toString("pem"));
  return x;
};
const dates = (c: X509Certificate, now: number) =>
  Number.isFinite(c.notBefore.getTime()) &&
  Number.isFinite(c.notAfter.getTime()) && c.notBefore.getTime() <= now &&
  now <= c.notAfter.getTime();
function time(s: string): number {
  if (!/^\d{14}Z?$/.test(s)) throw Error("OCSP_DATE");
  const d = Date.UTC(
    +s.slice(0, 4),
    +s.slice(4, 6) - 1,
    +s.slice(6, 8),
    +s.slice(8, 10),
    +s.slice(10, 12),
    +s.slice(12, 14),
  );
  if (
    !Number.isFinite(d) ||
    new Date(d).toISOString().replace(/[-:T]/g, "").slice(0, 14) !==
      s.slice(0, 14)
  ) throw Error("OCSP_DATE");
  return d;
}
/** Edge v1.74 cannot verify ECDSA P-384/SHA-256 (Apple delegated OCSP
 * certificates use this valid pairing). Verify that exact pairing with pinned
 * noble; all other certificate signatures stay on Web Crypto. No trust bypass. */
export async function verifyCertificateSignature(
  certificate: X509Certificate, issuer: X509Certificate, now: number,
): Promise<boolean> {
  if (!dates(certificate, now)) return false;
  const algorithm = certificate.signatureAlgorithm;
  if (algorithm.name === "ECDSA" && algorithm.hash.name === "SHA-256" &&
      (issuer.publicKey.algorithm as EcKeyAlgorithm).namedCurve === "P-384") {
    const tbs = unhex(ASN1HEX.getTLVbyList(hex(certificate.rawData), 0, [0]));
    const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", tbs));
    return p384.verify(new Uint8Array(certificate.signature), digest,
      unhex(parsed(issuer).getSPKIValue()),
      { prehash: false, lowS: false, format: "der" });
  }
  return await certificate.verify({publicKey: issuer.publicKey, date: new Date(now)}, crypto);
}
/** Apple online-check parity: leaf AND intermediate status, signed response,
 * issuer/delegated responder authority, CertID and freshness. Never soft fail. */
export async function checkOcsp(
  cert: X509Certificate,
  issuer: X509Certificate,
  fetcher: typeof fetch = fetch,
  now = Date.now(),
): Promise<void> {
  let step = "AIA";
  let httpStatus: number | null = null;
  try {
    const c = parsed(cert);
    const uri = c.getExtAIAInfo()?.ocsp?.[0];
    if (typeof uri !== "string") throw Error();
    const url = new URL(uri);
    // AIA is signed, but also constrain egress to Apple's responders. No redirects.
    if (
      !["http:", "https:"].includes(url.protocol) ||
      !(url.hostname === "apple.com" || url.hostname.endsWith(".apple.com")) ||
      url.username || url.password || url.port
    ) throw Error();
    step = "REQUEST";
    const request = new ocsp.OCSPRequest({
      reqList: [{
        issuerCert: issuer.toString("pem"),
        subjectCert: cert.toString("pem"),
        alg: "sha256",
      }],
    });
    step = "FETCH";
    const response = await fetcher(url, {
      method: "POST",
      headers: { "Content-Type": "application/ocsp-request" },
      body: unhex(request.getEncodedHex()),
      redirect: "error",
      signal: AbortSignal.timeout(15000),
    });
    httpStatus = response.status;
    if (!response.ok) throw Error();
    step = "PARSE";
    const raw = hex(await boundedBytes(response));
    const data = new ocsp.OCSPParser().getOCSPResponse(raw);
    step = "RESPONSE_STATUS";
    if (data.resstatus !== 0) throw Error();
    step = "SIGNER";
    const candidates = [
      issuer,
      ...(data.certs ?? []).slice(0, 8).map((h: string) =>
        new X509Certificate(unhex(h))
      ),
    ];
    let signer: X509Certificate | undefined;
    for (const candidate of candidates) {
      const x = parsed(candidate);
      const match = data.respid?.key
        ? hex(await crypto.subtle.digest("SHA-1", unhex(x.getSPKIValue()))) ===
          data.respid.key
        : data.respid?.name?.str === x.getSubject().str;
      if (!match) continue;
      const direct = hex(candidate.rawData) === hex(issuer.rawData);
      if (!dates(candidate, now)) continue;
      if (
        !direct &&
        (candidate.issuer !== issuer.subject ||
          !await verifyCertificateSignature(candidate, issuer, now) || !x.getExtExtKeyUsage()?.array?.includes("ocspSigning"))
      ) continue;
      signer = candidate;
      break;
    }
    if (!signer) throw Error();
    step = "ALGORITHM";
    const alg = /^SHA(256|384|512)with(RSA|ECDSA)$/.exec(data.alg);
    if (!alg) throw Error();
    const hash = "SHA-" + alg[1];
    let signature = unhex(data.sighex);
    let key: CryptoKey;
    let verify: AlgorithmIdentifier | EcdsaParams;
    if (alg[2] === "RSA") {
      key = await signer.publicKey.export({ name: "RSASSA-PKCS1-v1_5", hash }, [
        "verify",
      ], crypto);
      verify = { name: "RSASSA-PKCS1-v1_5" };
    } else {
      key = await signer.publicKey.export(crypto);
      const size =
        ({ "P-256": 32, "P-384": 48, "P-521": 66 } as Record<string, number>)[
          (key.algorithm as EcKeyAlgorithm).namedCurve
        ];
      if (!size) throw Error();
      const ints = ASN1HEX.getChildIdx(data.sighex, 0);
      if (ints.length !== 2) throw Error();
      signature = new Uint8Array(size * 2);
      for (let n = 0; n < 2; n++) {
        let h = ASN1HEX.getV(data.sighex, ints[n]);
        while (h.startsWith("00") && h.length > 2) h = h.slice(2);
        const b = unhex(h);
        if (b.length > size) throw Error();
        signature.set(b, n * size + size - b.length);
      }
      verify = { name: "ECDSA", hash };
    }
    step = "SIGNATURE";
    const tbsHex = ASN1HEX.getTLVbyList(raw, 0, [1, 0, 1, 0, 0]);
    if (!tbsHex) throw Error();
    const tbs = unhex(tbsHex);
    if (!await crypto.subtle.verify(verify, key, signature, tbs)) throw Error();
    step = "CERT_ID";
    const expected = new ocsp.CertID().getParamByCerts(
      issuer.toString("pem"),
      cert.toString("pem"),
      "sha256",
    );
    const statuses = data.array.filter((
      r: { certid: Record<string, string> },
    ) =>
      ["alg", "issname", "isskey", "sbjsn"].every((k) =>
        r.certid[k] === expected[k]
      )
    );
    if (statuses.length !== 1) throw Error();
    step = "FRESHNESS_STATUS";
    const status = statuses[0];
    if (
      status.status.status !== "good" || time(status.thisupdate) > now ||
      time(status.nextupdate) < now ||
      time(status.nextupdate) < time(status.thisupdate)
    ) throw Error();
  } catch {
    console.error(JSON.stringify({ event: "IAP_OCSP_FAILURE", step, httpStatus }));
    throw new AppleFailure("OCSP");
  }
}
export async function verifyAppleJws(
  signed: string,
  roots: string[],
  fetcher: typeof fetch = fetch,
  now = Date.now(),
): Promise<Record<string, unknown>> {
  let leaf: X509Certificate,
    intermediate: X509Certificate,
    root: X509Certificate;
  const parts = signed.split(".");
  try {
    if (
      parts.length !== 3 || signed.length > 100000 ||
      parts.some((p) => !p || !/^[A-Za-z0-9_-]+$/.test(p))
    ) throw Error();
    const header = JSON.parse(new TextDecoder().decode(decode64(parts[0])));
    if (
      header.alg !== "ES256" || header.crit !== undefined ||
      header.b64 !== undefined || !Array.isArray(header.x5c) ||
      header.x5c.length !== 3 || header.x5c.some((c: unknown) =>
        typeof c !== "string" || c.length > 20000
      )
    ) throw Error();
    [leaf, intermediate, root] = header.x5c.map((c: string) =>
      new X509Certificate(decode64(c))
    );
    if (!roots.some((r) => hex(decode64(r)) === hex(root.rawData))) {
      throw Error();
    }
    if (![leaf, intermediate, root].every((c) => dates(c, now))) throw Error();
    if (
      leaf.issuer !== intermediate.subject ||
      intermediate.issuer !== root.subject ||
      !intermediate.getExtension(BasicConstraintsExtension)?.ca ||
      !root.getExtension(BasicConstraintsExtension)?.ca
    ) throw Error();
    if (
      !leaf.getExtension("1.2.840.113635.100.6.11.1") ||
      !intermediate.getExtension("1.2.840.113635.100.6.2.1")
    ) throw Error();
    if (
      !await verifyCertificateSignature(intermediate, root, now) ||
      !await verifyCertificateSignature(leaf, intermediate, now)
    ) throw Error();
  } catch {
    throw new AppleFailure("CHAIN");
  }
  try {
    const key = await leaf.publicKey.export(
      { name: "ECDSA", namedCurve: "P-256" },
      ["verify"],
      crypto,
    );
    const signature = decode64(parts[2]);
    if (
      signature.length !== 64 ||
      !await crypto.subtle.verify(
        { name: "ECDSA", hash: "SHA-256" },
        key,
        signature,
        utf8(parts[0] + "." + parts[1]),
      )
    ) throw Error();
  } catch {
    throw new AppleFailure("JWS");
  }
  await Promise.all([
    checkOcsp(leaf, intermediate, fetcher, now),
    checkOcsp(intermediate, root, fetcher, now),
  ]);
  try {
    const value = JSON.parse(new TextDecoder().decode(decode64(parts[1])));
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      throw Error();
    }
    return value;
  } catch {
    throw new AppleFailure("CLAIMS");
  }
}
