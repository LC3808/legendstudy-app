"""Lossless transport encoding for the Owner-approved TASK03B SQL. No DB calls."""
import json,re,hashlib
from pathlib import Path
root=Path.cwd();src=root/'supabase/candidates/task03b_ready_20261111';out=root/'.local/task03c/compact';out.mkdir(parents=True,exist_ok=True)
def compact(m):
 rows=json.loads(m[1]);allcols=list(rows[0]);const={c:rows[0][c] for c in allcols if all(r[c]==rows[0][c] for r in rows)};cols=[c for c in allcols if c not in const];dictionary=[];lookup={};encoded=[]
 for row in rows:
  assert list(row)==allcols
  values=[]
  for c in cols:
   v=row[c];k=json.dumps(v,ensure_ascii=False,separators=(',',':'))
   if k not in lookup:lookup[k]=len(dictionary);dictionary.append(v)
   values.append(lookup[k])
  encoded.append(values)
 assert [{**const,**{c:dictionary[a[i]] for i,c in enumerate(cols)}} for a in encoded]==rows
 raw=json.dumps({'d':dictionary,'r':encoded,'c':const},ensure_ascii=False,separators=(',',':'))
 pairs=','.join("'"+c+"',v.d->((a.r->>"+str(i)+")::int)" for i,c in enumerate(cols))
 print('compact records',len(rows),'bytes',len(raw.encode()))
 return "(with v as (select j->'d' d,j->'r' r,j->'c' c from (select $packed$"+raw+"$packed$::jsonb j) s) select jsonb_agg(v.c || jsonb_build_object("+pairs+")) from v cross join lateral jsonb_array_elements(v.r) a(r))"
s=src.joinpath('payload.sql').read_text();s=re.sub(r'\$task03b\$(.*?)\$task03b\$::jsonb',compact,s,flags=re.S)
for p in src.glob('*.sql'):out.joinpath(p.name).write_text(s if p.name=='payload.sql' else p.read_text())
def expand(p):return re.sub(r'^\\ir (.+)$',lambda m:expand(p.parent/m[1].strip()),p.read_text(),flags=re.M)
for n in ['02_seed_drafts','03_publish','04_validate']:
 sql=expand(out/(n+'.sql'));out.joinpath(n+'-expanded.sql').write_text(sql);print(n,len(sql.encode()),hashlib.sha256(sql.encode()).hexdigest())
