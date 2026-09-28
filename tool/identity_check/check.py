"""Private one-time comparison. No Auth/Admin/DB calls; never accepts tokens/UUIDs.
Operator captures App marker records and browser digest responses, not Owner.
"""
import argparse, datetime as dt, hashlib, json, os, secrets, sys
from pathlib import Path
PROJECT = 'stlhijzpjfgwwdgunlsd'
ALLOWED = {'schema','surface','project','challenge','observed_at','event','status','digest'}
def now(): return dt.datetime.now(dt.timezone.utc)
def stamp(s): return dt.datetime.fromisoformat(s.replace('Z','+00:00'))
def private_write(path, value):
    path=Path(path)
    if not path.parent.is_dir(): raise ValueError('private directory required')
    fd=os.open(path, os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(fd,'w') as f: json.dump(value,f)
def validate(record, cfg, surface):
    if not isinstance(record,dict) or set(record)-ALLOWED: raise ValueError('invalid record')
    if record.get('schema')!='legendstudy-identity-v1' or record.get('project')!=PROJECT or record.get('surface')!=surface: raise ValueError('wrong context')
    if record.get('challenge')!=hashlib.sha256(cfg['salt'].encode()).hexdigest(): raise ValueError('wrong challenge')
    if not stamp(cfg['created_at']) <= stamp(record['observed_at']) <= now() or now()>=stamp(cfg['expires']): raise ValueError('expired observation')
    if now()-stamp(record['observed_at']) > dt.timedelta(minutes=5): raise ValueError('stale observation')
    if record.get('status') not in {'verified','signed_out','session_changed','verification_failed'}: raise ValueError('invalid status')
    if record.get('event') not in {'initial_snapshot','operator_snapshot','initialSession','signedIn','signedOut','tokenRefreshed','userUpdated','passwordRecovery','mfaChallengeVerified'}: raise ValueError('invalid event')
    if record.get('status')=='verified' and (len(record.get('digest',''))!=64 or any(c not in '0123456789abcdef' for c in record['digest'])): raise ValueError('invalid digest')
    if record.get('status')!='verified' and 'digest' in record: raise ValueError('invalid observation')
    return record

def compare(cfg, app, lab, attested):
    validate(app,cfg,'app');validate(lab,cfg,'lab')
    if not attested: return {'SAME_AUTH_USER_ID':'NOT_VERIFIED','RESULT':'OWNER_SAME_ACCOUNT_CONFIRMATION_REQUIRED'}
    if app['status']!='verified' or lab['status']!='verified': return {'SAME_AUTH_USER_ID':'NOT_VERIFIED','RESULT':'LOGIN_REQUIRED'}
    same=secrets.compare_digest(app['digest'],lab['digest'])
    return {'SAME_AUTH_USER_ID':'YES' if same else 'NO','RESULT':'PASS' if same else 'STOP_IDENTITY_CONFLICT'}

def main():
    p=argparse.ArgumentParser();p.add_argument('operation',choices=['init','app-log','lab-input','compare']);p.add_argument('--directory',required=True);p.add_argument('--same-provider-account-confirmed',action='store_true');a=p.parse_args()
    d=Path(a.directory).resolve()
    # This tool deliberately stores private, short-lived digests only outside repositories.
    if not str(d).startswith(('/private/tmp/','/tmp/')): raise ValueError('temporary private directory required')
    if a.operation=='init':
        d.mkdir(mode=0o700,parents=True,exist_ok=False)
        cfg={'salt':secrets.token_hex(32),'created_at':now().isoformat(),'expires':(now()+dt.timedelta(hours=1)).isoformat()}
        private_write(d/'challenge.json',cfg)
        private_write(d/'defines.json',{'IDENTITY_DIAGNOSTIC':True,'IDENTITY_DIAGNOSTIC_SALT':cfg['salt'],'IDENTITY_DIAGNOSTIC_EXPIRES':cfg['expires']})
        print('PRIVATE_CHALLENGE_READY');return
    cfg=json.loads((d/'challenge.json').read_text())
    if a.operation=='lab-input':
        rec=validate(json.load(sys.stdin),cfg,'lab')
        path=d/'lab.json'
        if path.exists(): path.unlink()
        private_write(path,rec)
        print('LAB_DIAGNOSTIC_'+rec['status'].upper());return
    if a.operation=='app-log':
        for line in sys.stdin:
            if 'LS_IDENTITY_CHECK ' not in line: continue
            try: rec=validate(json.loads(line.split('LS_IDENTITY_CHECK ',1)[1]),cfg,'app')
            except (ValueError,KeyError,TypeError): continue
            # Latest event supersedes prior identity; logout cannot leave stale PASS input.
            path=d/'app.json'
            if path.exists(): path.unlink()
            private_write(path,rec)
            print('APP_DIAGNOSTIC_'+rec['status'].upper(),flush=True)
    else:
        result=compare(cfg,json.loads((d/'app.json').read_text()),json.loads((d/'lab.json').read_text()),a.same_provider_account_confirmed)
        print(json.dumps(result))
if __name__=='__main__':
    try:main()
    except Exception: print('DIAGNOSTIC_NOT_READY',file=sys.stderr);sys.exit(1)
