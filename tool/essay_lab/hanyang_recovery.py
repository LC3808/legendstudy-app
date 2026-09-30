"""L2-C3 Gate B only. New one-shot slot, bounded diagnostic transport; no Gate D.
Historical C2 dispatcher/artifacts, model prompt/schema/evidence remain unchanged.
"""
from copy import deepcopy
import http.client
import json
import os
from pathlib import Path
import re
import signal
import ssl
import subprocess
import threading
import time
from . import vnext_validation as old
from .live_worker import Invalid, ProviderFailure

ROOT=old.REPO/'.local/essay-vnext-l2c3'
SLOT='hanyang-openai-vnext-l2c3-1'
OLD_SLOT='hanyang-openai-vnext-l2c2-1'
TIMEOUT=600
AUTHORIZATION='OWNER_L2_C3_GATE_B_ONE_CALL'
EXECUTION_AUTHORIZATION=None
POLICY=dict(old.POLICY,policy_version='pilot-openai-gpt56-sol-l2c3-v1')
REGIME='l2-c3-hanyang-original-recovery-v1'


def assemble():
    value,claim,payload,binding=deepcopy(old.assemble(OLD_SLOT))
    value['attempt_id']=SLOT;claim['input']['attempt_id']=SLOT
    payload['input'][0]['content'][0]['text']=old.encoded(value).decode()
    binding.update(slot=SLOT,policy=POLICY,regime=REGIME,payload_hash=old.digest(payload),claim_hash=old.digest(claim),
                   timeout_seconds=TIMEOUT,total_network_deadline_seconds=TIMEOUT,prior_slot=OLD_SLOT)
    old.require(binding['prompt_hash']=='25ff799c962d4b77ab2cf4e5d6bc693c4e815f47c2798d79acc3b8bf7cd98ca0','PROMPT_HASH')
    return value,claim,payload,binding


def protection():
    old.repository_gate()
    roots={old.REPO,old.HISTORICAL_REPO}
    for repo in tuple(roots):
        text=subprocess.check_output(['git','worktree','list','--porcelain'],cwd=repo).decode()
        roots.update(Path(x[9:]) for x in text.splitlines() if x.startswith('worktree '))
    for repo in roots:
        for path in ('.local/essay-bakeoff-l2b/safe-test-file','.local/essay-vnext-l2c3/safe-test-file'):
            result=subprocess.check_output(['git','-c','core.excludesFile=/dev/null','check-ignore','-v',path],cwd=repo)
            old.require(result.startswith(b'.gitignore:'),'REPOSITORY_IGNORE_REQUIRED')
        old.require(not subprocess.check_output(['git','ls-files','--','.local/**'],cwd=repo),'PRIVATE_TRACKED')


def gate_a():
    protection();g=old.strict_json(old.read_private(ROOT/'gate-a.json'))
    old.require(g['status']=='PASS' and g['slot']==SLOT and g['maximum_calls']==1,'GATE_A')
    for path,expected in g['historical_hashes'].items():
        old.require(old.sha256(Path(path).read_bytes()).hexdigest()==expected,'HISTORICAL_DRIFT')
    for path,expected in g['implementation_hashes'].items():
        old.require(old.sha256((old.REPO/path).read_bytes()).hexdigest()==expected,'IMPLEMENTATION_DRIFT')
    return g


def prepare():
    gate_a();target=old.child_dir(old.child_dir(ROOT,'prepared'),SLOT)
    for name,data in zip(('input','claim','payload','binding'),assemble()):old.freeze(target/f'{name}.json',old.encoded(data))


class DeadlineExceeded(TimeoutError):pass


def safe_exception(error):
    if isinstance(error,DeadlineExceeded):return 'TOTAL_DEADLINE'
    if isinstance(error,TimeoutError):return 'SOCKET_TIMEOUT'
    if isinstance(error,ssl.SSLError):return 'TLS_ERROR'
    if isinstance(error,http.client.IncompleteRead):return 'INCOMPLETE_READ'
    if isinstance(error,http.client.HTTPException):return 'HTTP_PROTOCOL_ERROR'
    if isinstance(error,OSError):return 'OS_TRANSPORT_ERROR'
    if isinstance(error,KeyboardInterrupt):return 'LOCAL_INTERRUPT'
    return 'UNCLASSIFIED_LOCAL_ERROR'


class DiagnosticHTTP:
    """One official TLS POST. Progress metadata contains no headers/body/exception text."""
    synthetic_only=False
    def __init__(self,*,factory=None,clock=time.monotonic):
        self.factory=factory;self.synthetic_only=factory is not None and getattr(factory,'synthetic_only',False)
        self.clock=clock;self.used=False;self.partial=b''
        self.progress=dict(stage='NOT_STARTED',request_write_returned=False,headers_received=False,http_status=None,bytes_received=0,exception_category=None)
    def send(self,body,headers):
        old.require(not self.used,'HTTP_CONSUMED')
        old.require(self.synthetic_only or (self.factory is None and EXECUTION_AUTHORIZATION==AUTHORIZATION),'LIVE_CLOSED')
        old.require(threading.current_thread() is threading.main_thread() and signal.getitimer(signal.ITIMER_REAL)==(0.0,0.0),'DEADLINE_CONTEXT')
        self.used=True;start=self.clock();connection=None
        def alarm(*_):raise DeadlineExceeded()
        prior=signal.signal(signal.SIGALRM,alarm);signal.setitimer(signal.ITIMER_REAL,TIMEOUT)
        try:
            self.progress['stage']='CONNECT_OR_WRITE'
            factory=self.factory or http.client.HTTPSConnection
            connection=factory('api.openai.com',timeout=TIMEOUT,context=ssl.create_default_context())
            connection.request('POST','/v1/responses',body=body,headers=headers)
            self.progress.update(request_write_returned=True,stage='WAIT_HEADERS')
            response=connection.getresponse()
            self.progress.update(headers_received=True,http_status=response.status,stage='READ_BODY')
            while len(self.partial)<=old.MAX_RESPONSE:
                chunk=response.read1(min(65536,old.MAX_RESPONSE+1-len(self.partial)))
                if not chunk:break
                self.partial+=chunk;self.progress['bytes_received']=len(self.partial)
                if len(self.partial)>old.MAX_RESPONSE:break
            self.progress['stage']='BODY_RECEIVED'
            return response.status,self.partial
        except BaseException as error:
            self.progress['exception_category']=safe_exception(error)
            # IncompleteRead can carry bytes not returned by read1. Preserve bounded partial.
            if isinstance(error,http.client.IncompleteRead):
                self.partial+=error.partial[:max(0,old.MAX_RESPONSE+1-len(self.partial))]
                self.progress['bytes_received']=len(self.partial)
            raise
        finally:
            signal.setitimer(signal.ITIMER_REAL,0);signal.signal(signal.SIGALRM,prior)
            self.progress['elapsed_ms']=round((self.clock()-start)*1000)
            if connection is not None:
                try:connection.close()
                except BaseException:self.progress['close_error']=True


def secret_echo(raw,key):
    scan=re.sub(rb'\\u00([0-9a-fA-F]{2})',lambda m:bytes([int(m[1],16)]),raw)
    return key.encode() in scan or json.dumps(key)[1:-1].encode() in raw or bool(re.search(rb'(?i)(authorization\s*[:=]|bearer\s+[A-Za-z0-9_-]+|sk-(?:proj|ant-api)[A-Za-z0-9_-]+)',scan))


def run(root,prepared,key,http,*,synthetic=False):
    old.private_dir(root)
    if synthetic:old.require(http.synthetic_only and root.as_posix().startswith('/private/tmp/essay-l2c3-test'),'SYNTHETIC_ONLY')
    else:
        old.require(root==ROOT and type(http) is DiagnosticHTTP and EXECUTION_AUTHORIZATION==AUTHORIZATION,'LIVE_CLOSED')
        gate_a();old.require(prepared==assemble(),'INPUT_DRIFT')
    value,claim,payload,binding=prepared
    old.require(binding['slot']==SLOT and binding['policy']==POLICY and binding['payload_hash']==old.digest(payload)
                and binding['claim_hash']==old.digest(claim),'BINDING')
    markers=old.child_dir(root,'started');target=old.child_dir(root,'results')/SLOT
    old.require(not target.exists() and not (markers/f'{SLOT}.json').exists(),'SLOT_CONSUMED')
    old.freeze(markers/f'{SLOT}.json',old.encoded(dict(slot=SLOT,state='STARTED_CONSUMED',binding=binding,started_at=old.now(),synthetic=synthetic)))
    record=dict(slot=SLOT,state='UNKNOWN_CONSUMED',request_outcome='UNKNOWN',binding=binding,parser='NOT_RUN',
                sentence_root='NOT_RUN',core_count=None,http_status=None,telemetry=old.metadata(None,POLICY,0),human_quality='PENDING_OWNER_REVIEW',synthetic=synthetic)
    start=time.monotonic()
    try:
        target.mkdir(mode=0o700,exist_ok=False)
        status,raw=http.send(old.encoded(payload),{'Authorization':'Bearer '+key,'Content-Type':'application/json'})
        record['http_status']=status;record['raw_hash']=old.sha256(raw).hexdigest()
        if secret_echo(raw,key):
            old.freeze(target/'raw-withheld.json',old.encoded(dict(reason='CREDENTIAL_PATTERN',sha256=record['raw_hash'])))
            record.update(state='FAILED_CONSUMED',request_outcome='SECRET_ECHO_WITHHELD')
        else:
            old.freeze(target/'raw-response.bin',raw)
            record.update(state='FAILED_CONSUMED',request_outcome='RESPONSE_RECEIVED',raw_before_parse=True)
            try:data=old.strict_json(raw)
            except Invalid:data=None
            record['telemetry']=old.metadata(data,POLICY,round((time.monotonic()-start)*1000))
            if status!=200:record['request_outcome']='HTTP_ERROR'
            elif isinstance(data,dict) and data.get('model')!=POLICY['model']:record['request_outcome']='MODEL_MISMATCH'
            else:
                try:
                    old.require(isinstance(data,dict),'MALFORMED_RESPONSE')
                    result=old.OpenAIPilot('pilot-openai-gpt56-sol-v1',key).decode(data,record['telemetry']['latency_ms'])
                    output=old.parse_provider(result.raw,claim)
                except (Invalid,ProviderFailure,KeyError,TypeError,AttributeError) as error:
                    code=str(error);record.update(parser='REJECTED',validation_error=code if re.fullmatch(r'[A-Z_]{1,80}',code) else 'STRICT_VALIDATION_REJECTED')
                    record['sentence_root']='FAIL' if code=='SENTENCE_ROOT' else 'NOT_CONFIRMED'
                else:
                    old.freeze(target/'normalized.json',old.encoded(output))
                    record.update(state='VALID_UNREVIEWED',parser='PASS',sentence_root='PASS',core_count=len(output['core_improvement_keys']),normalized_hash=old.digest(output))
    except BaseException as error:
        record.update(state='UNKNOWN_CONSUMED',request_outcome='TRANSPORT_OR_LOCAL_UNKNOWN',exception_category=safe_exception(error))
        record['http_status']=http.progress.get('http_status')
        if http.partial:
            try:
                if secret_echo(http.partial,key):
                    old.freeze(target/'partial-withheld.json',old.encoded(dict(reason='CREDENTIAL_PATTERN')))
                    record['request_outcome']='SECRET_ECHO_WITHHELD'
                else:
                    old.freeze(target/'raw-partial.bin',http.partial);record['partial_hash']=old.sha256(http.partial).hexdigest()
            except BaseException:record['partial_capture_failed']=True
    record['transport']=http.progress
    record['telemetry']['latency_ms']=round((time.monotonic()-start)*1000);record['completed_at']=old.now()
    try:old.freeze(target/'terminal.json',old.encoded(record))
    except BaseException:return dict(slot=SLOT,state='UNKNOWN_CONSUMED',request_outcome='TERMINAL_WRITE_UNKNOWN')
    return record


def dispatch():
    old.require(EXECUTION_AUTHORIZATION==AUTHORIZATION,'REAL_EXECUTION_CLOSED');gate_a()
    prepared=assemble();target=ROOT/'prepared'/SLOT
    for name,data in zip(('input','claim','payload','binding'),prepared):
        old.require(old.read_private(target/f'{name}.json',32*1024*1024)==old.encoded(data),'FROZEN_DRIFT')
    env=old.credential_environment(os.environ)
    return run(ROOT,prepared,old.credential('openai',env),DiagnosticHTTP())
