import 'npm:reflect-metadata@0.2.2';
import {X509Certificate} from 'npm:@peculiar/x509@2.2.0';
import js from 'npm:jsrsasign@11.1.5';
import {verifyCertificateSignature} from '../../supabase/functions/verify-iap-purchase/apple-certificates.ts';
export async function p384Cases() {
 const k=js.KEYUTIL.generateKeypair('EC','secp384r1');
 const other=js.KEYUTIL.generateKeypair('EC','secp384r1');
 const make=(key:any)=>new X509Certificate(js.KJUR.asn1.x509.X509Util.newCertPEM({serial:{int:1},sigalg:'SHA256withECDSA',issuer:{str:'/CN=Synthetic'},subject:{str:'/CN=Synthetic'},notbefore:{str:'20260101000000Z'},notafter:{str:'20300101000000Z'},sbjpubkey:key.pubKeyObj,cakey:key.prvKeyObj}));
 const cert=make(k),wrong=make(other),now=Date.now();
 if(!await verifyCertificateSignature(cert,cert,now))throw Error('valid P384/SHA256 rejected');
 if(await verifyCertificateSignature(cert,wrong,now))throw Error('wrong issuer accepted');
 const corrupt=new Uint8Array(cert.rawData.slice(0));corrupt[corrupt.length-1]^=1;
 if(await verifyCertificateSignature(new X509Certificate(corrupt),cert,now))throw Error('tampered signature accepted');
 if(await verifyCertificateSignature(cert,cert,Date.UTC(2031,0,1)))throw Error('expired certificate accepted');
 return 'P384/SHA256 valid, wrong issuer, tampered signature, expiry PASS';
}
