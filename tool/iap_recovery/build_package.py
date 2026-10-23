"""Build reviewable local source manifests only. No credentials or network calls."""
from pathlib import Path
import json, hashlib
ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
SRC=ROOT/'supabase/functions/verify-iap-purchase'
BASE=HERE/'rollback'
OUT=HERE/'prepared'
OUT.mkdir(exist_ok=True)
for mode in ('google-diagnostics','combined'):
 target=OUT/mode;target.mkdir(exist_ok=True)
 files={'index.ts':(BASE/'index.ts').read_text()}
 core=(SRC/'core.ts').read_text();stores=(SRC/'stores.ts').read_text()
 if mode=='combined':
  for name in ('core.ts','stores.ts','apple.ts','apple-crypto.ts','apple-certificates.ts','deno.lock'):
   files[name]=(SRC/name).read_text()
 else:
  basecore=(BASE/'core.ts').read_text()
  types=core[core.index('export type RejectionReason'):core.index('export type Ports')]
  files['core.ts']=basecore.replace('export class Rejected extends Error {}',types)
  marker='    } catch (e) {'
  start=files['core.ts'].index(marker)+len(marker)
  files['core.ts']=files['core.ts'][:start]+"\n      if (e instanceof GoogleFailure) console.error(JSON.stringify({event:'IAP_GOOGLE_FAILURE',stage:e.stage,httpStatus:e.httpStatus}));\n      if (e instanceof Rejected) console.error(JSON.stringify({event:'IAP_PURCHASE_REJECTED',reason:e.reason}));"+files['core.ts'][start:]
  old=(BASE/'stores.ts').read_text()
  normalization=old[old.index('// Reconstruct'):old.index('export async function googleAccessToken')]
  prefix=stores[:stores.index('export async function verifyStore')].replace("import { verifyApple } from './apple.ts';\n",'')
  google=stores[stores.index('export async function verifyStore'):stores.index('  return await verifyApple')]
  apple=old[old.index("  const environment = env('IAP_APPLE_ENVIRONMENT')"):]
  files['stores.ts']=old.splitlines()[0]+'\n'+prefix+normalization+google+apple
 for name,content in files.items():(target/name).write_text(content)
 manifest={'mode':mode,'project':'stlhijzpjfgwwdgunlsd','function':'verify-iap-purchase','verify_jwt':True,'index':'Production snapshot unchanged','files':{name:hashlib.sha256(content.encode()).hexdigest() for name,content in files.items()},'deployed':False}
 (target/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print(json.dumps({'mode':mode,'files':len(files),'deployed':False}))
