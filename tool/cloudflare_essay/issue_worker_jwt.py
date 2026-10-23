"""Owner-only terminal helper. No secrets in arguments/files/stdout; read-only probe."""
import argparse,base64,datetime,getpass,hashlib,hmac,json,secrets,subprocess,sys,time
from pathlib import Path
from urllib.request import Request,build_opener,HTTPRedirectHandler
from urllib.error import HTTPError,URLError
ORIGIN='https://stlhijzpjfgwwdgunlsd.supabase.co'
class NoRedirect(HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None

ROLES={'essay_worker':('ESSAY_REGISTRY_WORKER_JWT',365),'math_evaluation_worker':('MATH_EVALUATION_WORKER_JWT',7),'math_extraction_worker':('MATH_EXTRACTION_WORKER_JWT',7)}

def mint(secret,now,role='essay_worker'):
 if role not in ROLES:raise ValueError('Unsupported role')
 if len(secret)<32 or secret.startswith(('sb_','eyJ')) or any(c.isspace() for c in secret):
  raise ValueError('Legacy JWT Secret을 확인하세요. 로그인 비밀번호·API 키·JWT는 사용할 수 없습니다.')
 def enc(value):return base64.urlsafe_b64encode(json.dumps(value,separators=(',',':')).encode()).rstrip(b'=')
 expires=now+ROLES[role][1]*24*60*60
 claims={'role':role,'iat':now,'exp':expires}
 if role!='essay_worker':claims['iss']='supabase'
 # Preserve existing contracts: no audience, subject or service_role claims.
 message=enc({'alg':'HS256','typ':'JWT'})+b'.'+enc(claims)
 signature=base64.urlsafe_b64encode(hmac.new(secret.encode(),message,hashlib.sha256).digest()).rstrip(b'=')
 return message+b'.'+signature,expires

def verify(token,config,opener=None):
 v=config['vars'];key=v['SUPABASE_PUBLISHABLE_KEY'];subjects=json.loads(v['ESSAY_ALLOWED_SUBJECTS'])
 if not key.startswith('sb_publishable_') or not subjects:raise ValueError('기존 공개키/허용계정 설정이 없습니다.')
 request=Request(ORIGIN+'/rest/v1/rpc/essay_registered_questions',method='POST',
  headers={'apikey':key,'Authorization':'Bearer '+token.decode(),'Content-Type':'application/json'},
  data=json.dumps({'p_subject':subjects[0]}).encode())
 with (opener or build_opener(NoRedirect())).open(request,timeout=25) as response:
  raw=response.read(1048577)
  if response.status!=200 or len(raw)>1048576:raise ValueError('읽기 검증 실패. Secret 설정을 진행하지 마세요.')
  rows=json.loads(raw)
  if not isinstance(rows,list) or not all(isinstance(row,dict) for row in rows):raise ValueError('Registry 검증 결과가 예상과 다릅니다. Secret 설정을 진행하지 마세요.')
 return len(rows)

def verify_math(token,config,role,opener=None):
 if role not in ('math_evaluation_worker','math_extraction_worker'):raise ValueError('Unsupported role')
 key=config['vars']['SUPABASE_PUBLISHABLE_KEY']
 if not key.startswith('sb_publishable_'):raise ValueError('Missing publishable key')
 own='math_evaluation' if role=='math_evaluation_worker' else 'math_extraction'
 other='math_extraction' if own=='math_evaluation' else 'math_evaluation'
 checks=[]
 for rpc,expected in ((own,(400,'22023')),(other,(403,'42501'))):
  req=Request(ORIGIN+'/rest/v1/rpc/'+rpc,method='POST',
   headers={'apikey':key,'Authorization':'Bearer '+token.decode(),'Content-Type':'application/json'},
   data=b'{"p_request":null}')
  try:
   with (opener or build_opener(NoRedirect())).open(req,timeout=25) as response:
    status=response.status;raw=response.read(16385)
  except HTTPError as error:
   status=error.code;raw=error.read(16385)
  if len(raw)>16384:raise ValueError('Oversized response')
  value=json.loads(raw)
  if not isinstance(value,dict) or (status,value.get('code'))!=expected:raise ValueError('Role probe failed')
  checks.append((rpc,status,value['code']))
 return checks

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--config',type=Path)
 p.add_argument('--service-token',action='store_true')
 p.add_argument('--role',choices=tuple(ROLES),default='essay_worker')
 a=p.parse_args()
 if a.service_token:
  subprocess.run(['pbcopy'],input=secrets.token_urlsafe(48).encode(),check=True)
  print('Service Token을 클립보드에 복사했습니다. 같은 값을 Worker와 Pages의 ESSAY_WORKER_SERVICE_TOKEN에 붙여넣으세요.')
  return
 if not a.config:p.error('--config 경로가 필요합니다.')
 if not sys.stdin.isatty():raise ValueError('Mac 터미널에서 직접 실행하세요. Secret은 화면에 표시되지 않습니다.')
 config=json.loads(a.config.read_text())
 secret=getpass.getpass('Supabase Legacy JWT Secret (비밀번호 아님, 붙여넣기 후 Enter): ').strip()
 token,expires=mint(secret,int(time.time()),a.role);del secret
 if a.role=='essay_worker':
  count=verify(token,config)
  result=f'Registry 읽기 HTTP200 ({count}문항)'
 else:
  verify_math(token,config,a.role)
  result='자체 역할 HTTP400/22023 · 교차 역할 HTTP403/42501'
 subprocess.run(['pbcopy'],input=token,check=True)
 print(f'{a.role} 인증 검증 PASS: {result}. JWT를 클립보드에 복사했습니다.')
 print('만료:',datetime.datetime.fromtimestamp(expires).astimezone().isoformat())
 print(f'Pages legendstudy-lab → Production → {ROLES[a.role][0]}에 붙여넣으세요. 기존 Worker 설정은 변경하지 마세요.')
 print('등록 후 pbcopy < /dev/null 로 클립보드를 비우세요. JWT를 채팅에 보내지 마세요.')
if __name__=='__main__':
 try:main()
 except HTTPError as e:raise SystemExit(f'읽기 검증 HTTP {e.code}: 클립보드에 JWT를 복사하지 않았습니다. 상태 코드만 알려 주세요.')
 except (URLError,TimeoutError):raise SystemExit('네트워크 검증 실패: JWT를 복사하지 않았습니다. 재시도할 수 있습니다.')
 except (ValueError,KeyError,OSError) as e:
  # Never print exception payload: transport errors may contain request context.
  raise SystemExit('설정/입력/검증 실패: JWT를 복사하지 않았습니다. Secret 값 없이 실패 사실만 알려 주세요.')
