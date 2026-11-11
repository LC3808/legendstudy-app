"""Re-fetch pinned public evidence only. TLS verification stays enabled.
Existing matching files are reused; changed bytes never replace pinned evidence.
No database, authentication, crawler, or production modifications.
"""
import hashlib,json,time,urllib.request
from pathlib import Path
from urllib.parse import urlparse
R=Path(__file__).resolve().parents[1]
def main():
 manifest=json.loads((R/'data/mock_expansion/task03a/source_manifest.json').read_text())
 dest=R/'.local/task03a/official';dest.mkdir(parents=True,exist_ok=True)
 for s in manifest['sources']+manifest['additional_sources']:
  u=s['url'];assert urlparse(u).hostname in ('www.suneung.re.kr','www.korea.kr')
  name=s.get('filename','2022-biology-correction.html');path=dest/name
  if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest()==s['sha256']:continue
  data=urllib.request.urlopen(u,timeout=60).read()
  if hashlib.sha256(data).hexdigest()!=s['sha256']:raise RuntimeError('Source changed; re-review required: '+u)
  path.write_bytes(data);time.sleep(.2)
 (dest/'manifest.json').write_text(json.dumps(manifest['sources'],ensure_ascii=False,indent=2))
 print('Pinned public source digests verified; no DB access')
if __name__=='__main__':main()
