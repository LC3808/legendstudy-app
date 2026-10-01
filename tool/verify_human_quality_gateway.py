"""HQP gateway authorization only. No operator submit, DML or response-body persistence.
Password sign-in creates Auth sessions/logs; application writes remain zero.
"""
import argparse, base64, json, sys, urllib.error, urllib.request
from verify_quality_gateway import HOST, NoRedirect, CheckFailed, private_json, require
EMPTY_ID='00000000-0000-0000-0000-000000000000'
TABLES=('human_quality_judgments','human_quality_findings')
RPCS=('ql_review_state','ql_list_human_judgments','ql_submit_human_judgment')

def allowed(role,path,data,method):
    if path=='/auth/v1/token?grant_type=password':
        return role in ('ADMIN','STUDENT') and method=='POST' and isinstance(data,dict) and set(data)=={'email','password'}
    if path=='/auth/v1/user':return role in ('ADMIN','STUDENT') and method=='GET' and data is None
    if path in ['/rest/v1/'+t+'?select=id&limit=0' for t in TABLES]:return method=='GET' and data is None
    if method!='POST':return False
    if path=='/rest/v1/rpc/ql_submit_human_judgment':
        return role in ('STUDENT','ANON') and data in ({'p_payload':{}},{'p_payload':{'reviewer_user_id':EMPTY_ID}})
    payloads={'ql_review_state':{'p_evaluation_ids':[]},'ql_list_human_judgments':{'p_evaluation_id':EMPTY_ID},'is_quality_operator':{},'ql_list_cases':{'p_limit':1},'ql_case_detail':{'p_evaluation_id':EMPTY_ID}}
    return any(path=='/rest/v1/rpc/'+n and data==p for n,p in payloads.items())

def verify(config,accounts,opener=None):
    require(config.get('SUPABASE_URL','').rstrip('/')==HOST,'PROJECT_MISMATCH')
    key=config.get('SUPABASE_PUBLISHABLE_KEY','');require(isinstance(key,str) and key.startswith('sb_publishable_'),'PUBLIC_KEY_REQUIRED')
    opener=opener or urllib.request.build_opener(NoRedirect());tokens={};records=[]
    def call(role,path,data=None,method='POST',override=None):
        require(allowed(role,path,data,method),'REQUEST_NOT_ALLOWED')
        headers={'apikey':key,'Content-Type':'application/json','Cache-Control':'no-store'}
        token=override or tokens.get(role)
        if token:headers['Authorization']='Bearer '+token
        req=urllib.request.Request(HOST+path,data=None if data is None else json.dumps(data).encode(),headers=headers,method=method)
        try:
            with opener.open(req,timeout=30) as response:
                code=response.status;body=json.loads(response.read())
        except urllib.error.HTTPError as exc:
            code=exc.code
            try:body=json.loads(exc.read())
            except Exception:body={}
            finally:exc.close()
        error=body.get('code') if isinstance(body,dict) else None
        # Only static route labels, role categories and numeric status leave memory.
        records.append({'role':role,'route':path.split('?')[0],'http':code})
        return code,body,error
    ids={}
    for role in ('ADMIN','STUDENT'):
        email=accounts.get('QUALITY_'+role+'_EMAIL');password=accounts.get('QUALITY_'+role+'_PASSWORD')
        require(isinstance(email,str) and isinstance(password,str) and email and password,'ACCOUNT_REQUIRED')
        code,body,_=call(role,'/auth/v1/token?grant_type=password',{'email':email,'password':password})
        require(code==200 and isinstance(body,dict),'LOGIN_FAILED')
        token=body['access_token'];claims=json.loads(base64.urlsafe_b64decode(token.split('.')[1]+'==='))
        require(claims.get('role')=='authenticated','JWT_ROLE_INVALID');tokens[role]=token
        code,user,_=call(role,'/auth/v1/user',method='GET')
        require(code==200 and user.get('id')==claims.get('sub') and user.get('email','').casefold()==email.casefold(),'IDENTITY_MISMATCH')
        ids[role]=user['id'];del body,user,email,password,claims
    require(ids['ADMIN']!=ids['STUDENT'],'DISTINCT_ACCOUNTS_REQUIRED')
    def rpc(role,name,data):return call(role,'/rest/v1/rpc/'+name,data)
    for role,want in [('ADMIN',True),('STUDENT',False)]:
        code,value,_=rpc(role,'is_quality_operator',{});require(code==200 and value is want,'EXISTING_HELPER_REGRESSION')
    code,value,_=rpc('ADMIN','ql_review_state',{'p_evaluation_ids':[]})
    require(code==200 and value=={'dto_version':'hq-read-v1','cases':[]},'OPERATOR_EMPTY_STATE_FAILED')
    code,_,err=rpc('ADMIN','ql_list_human_judgments',{'p_evaluation_id':EMPTY_ID})
    require(code in (400,404,500) and err=='P0002','OPERATOR_MISSING_CASE_FAILED_HTTP_'+str(code)+'_SQLSTATE_'+(err if isinstance(err,str) and len(err)<=10 and err.isalnum() else 'UNAVAILABLE'))
    missing_http=code
    for role in ('STUDENT','ANON'):
        for name,data in [('ql_review_state',{'p_evaluation_ids':[]}),('ql_list_human_judgments',{'p_evaluation_id':EMPTY_ID}),('ql_submit_human_judgment',{'p_payload':{}})]:
            code,_,err=rpc(role,name,data);require(code==(403 if role=='STUDENT' else 401) and err=='42501','NON_OPERATOR_GATE_FAILED')
    for role in ('ADMIN','STUDENT','ANON'):
        for table in TABLES:
            code,_,err=call(role,'/rest/v1/'+table+'?select=id&limit=0',method='GET')
            require(code in (401,403) and err=='42501','DIRECT_TABLE_NOT_DENIED')
    code,_,err=rpc('STUDENT','ql_submit_human_judgment',{'p_payload':{'reviewer_user_id':EMPTY_ID}})
    require(code==403 and err=='42501','FORGED_REVIEWER_NOT_DENIED')
    parts=tokens['STUDENT'].split('.');claims=json.loads(base64.urlsafe_b64decode(parts[1]+'==='));claims['sub']=ids['ADMIN']
    parts[1]=base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip('=')
    code,_,_=call('FORGED','/rest/v1/rpc/ql_review_state',{'p_evaluation_ids':[]},override='.'.join(parts));require(code==401,'FORGED_JWT_NOT_DENIED')
    # Existing read-v1 behavior regression: list is bounded; never read a real answer.
    code,page,_=rpc('ADMIN','ql_list_cases',{'p_limit':1})
    require(code==200 and page.get('dto_version')=='ql-read-v1' and isinstance(page.get('cases'),list) and len(page['cases'])<=1,'EXISTING_LIST_REGRESSION')
    for role in ('STUDENT','ANON'):
        for name,data in [('ql_list_cases',{'p_limit':1}),('ql_case_detail',{'p_evaluation_id':EMPTY_ID})]:
            code,_,err=rpc(role,name,data);require(code==(403 if role=='STUDENT' else 401) and err=='42501','EXISTING_READ_DENY_REGRESSION')
    return {'PRODUCTION_HQP_AUTHORIZATION':'PASS','OPERATOR_READ_PATH':'PASS','OPERATOR_MISSING_CASE_HTTP':missing_http,'OPERATOR_MISSING_CASE_SQLSTATE':'P0002','NON_OPERATOR_DENY':'PASS','ANON_DENY':'PASS','DIRECT_TABLE_DENY':'PASS','FORGED_IDENTITY_DENY':'PASS','EXISTING_QL_READ_GATEWAY_BEHAVIOR':'PASS','EXISTING_FUNCTION_BODY_ACL_RECHECK':'NOT_RUN_GATEWAY_CANNOT_PROVE_CATALOG_EQUALITY','OPERATOR_WRITE_SUCCESS':'NOT_ASSESSABLE','PRODUCTION_HQ_ROWS_CREATED':0,'PRODUCTION_APPLICATION_DATA_WRITES':0,'PROVIDER_CALLS':0,'WRITE_SAFETY_BASIS':'no operator submit; only non-operator/anon structurally invalid payloads; no REST DML','AUTH_SIDE_EFFECT':'password sign-in creates Auth sessions/logs','requests':records}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('public_config');ap.add_argument('credentials');args=ap.parse_args()
    try:result=verify(private_json(args.public_config),private_json(args.credentials))
    except CheckFailed as error:result={'status':'STOP','check':str(error)}
    except Exception:result={'status':'STOP','check':'LOCAL_OR_TRANSPORT_ERROR'}
    print(json.dumps(result,indent=2));return 1 if result.get('status')=='STOP' else 0
if __name__=='__main__':sys.exit(main())
