import { createPrivateKey, X509Certificate } from 'node:crypto';
import jwt from 'npm:jsonwebtoken@9.0.2';
import js from 'npm:jsrsasign@11.1.5';
import { Buffer } from 'node:buffer';
Deno.serve(async () => {
 const out: Record<string,unknown> = {runtime:Deno.version};
 const keys=await crypto.subtle.generateKey({name:'ECDSA',namedCurve:'P-256'},true,['sign','verify']);
 const pkcs8=await crypto.subtle.exportKey('pkcs8',keys.privateKey);
 const pem='-----BEGIN PRIVATE KEY-----\n'+Buffer.from(pkcs8).toString('base64').match(/.{1,64}/g)!.join('\n')+'\n-----END PRIVATE KEY-----';
 try {const key=createPrivateKey(pem); out.nodeKey=key.asymmetricKeyType; jwt.sign({test:true},pem,{algorithm:'ES256'});out.jwtSign='PASS'} catch(e){out.jwtSign=(e as Error).message}
 const fixture=js.KJUR.asn1.x509.X509Util.newCertPEM({serial:{int:1},sigalg:'SHA256withECDSA',issuer:{str:'/CN=Synthetic'},subject:{str:'/CN=Synthetic'},notbefore:{str:'20200101000000Z'},notafter:{str:'20990101000000Z'},sbjpubkey:js.KEYUTIL.getKey(await crypto.subtle.exportKey('jwk',keys.publicKey)),cakey:js.KEYUTIL.getKey(await crypto.subtle.exportKey('jwk',keys.privateKey))});
 try {const cert=new X509Certificate(fixture);out.x509Verify=cert.verify(cert.publicKey)}catch(e){out.x509Verify=(e as Error).message}
 try {const signature=await crypto.subtle.sign({name:'ECDSA',hash:'SHA-256'},keys.privateKey,new TextEncoder().encode('fixture'));out.webcryptoSign=signature.byteLength===64}catch(e){out.webcryptoSign=(e as Error).name}
 return Response.json(out);
});
