import { p384Cases } from './p384_cases.ts';
Deno.test('Apple OCSP P384/SHA256 certificate compatibility',async()=>{console.log(await p384Cases())});
