"""L2-C2 two-slot private validation. Closed unless explicitly enabled in-process.
No production worker/policy/DB integration. Historical dispatch remains closed.
Preparation is offline; only dispatch() can access the approved credential/network.
"""
from base64 import b64encode
from hashlib import sha256
import http.client
import json
import os
from pathlib import Path
import re
import ssl
import stat
import subprocess
import time
from . import official_evidence_package as evidence
from .positive_learning import prompt_contract
from .bakeoff import OpenAIPilot, TRANSPORT_SETTINGS
from .live_worker import Invalid, ProviderFailure, encoded, digest, output_schema, parse_provider, require, strict_json
from .round1_dispatcher import (freeze, child_dir, read_private, private_dir, no_symlinks,
                                credential, metadata, now, MAX_RESPONSE, block)

REPO=Path(__file__).resolve().parents[2]
ROOT=REPO/'.local/essay-vnext-l2c2'
PACKAGES=REPO/'.local/essay-evidence-vnext-l2c1'
SLOTS={'sookmyung-openai-vnext-l2c2-1':'sookmyung','hanyang-openai-vnext-l2c2-1':'hanyang'}
AUTHORIZATION='OWNER_L2_C2_MAX_TWO_AFTER_PHASE_A'
EXECUTION_AUTHORIZATION=None
POLICY=dict(provider='openai',model='gpt-5.6-sol',model_version='gpt-5.6-sol',
            policy_version='pilot-openai-gpt56-sol-vnext-l2c2-v1',
            prompt_version='scaffolding-1.3-v3',contract_version='1.3')
REGIME='l2-c2-original-positive-learning-v1'
HISTORICAL_REPO=Path.home()/'development/legendstudy-app'
HISTORICAL_PRIVATE=HISTORICAL_REPO/'.local/essay-bakeoff-l2b'
PINS={'sookmyung':('7490a3f6e4617d0f9d488dc9552a1e6ace4daa17fac90712b1dee70450a5cc08','89906e81be608ef8792a5acd7c3ba5887b1efc03d0f3ca603319c246c5abc3f4'),
      'hanyang':('0d6c20bc7d3309ec22548e49293b233f92df981325d35aec5f7cdc6f147586fc','642616484cad24a9ebfce21621e250b8c359a87319b67be55c4522cdadbb61ed')}
PHASE_CHECKS=('owner_principle','zero_core','positive_feedback','example_not_answer_key','criterion_alignment','positive_logic_transfer','no_forced_defect','contract','evidence','dispatcher')


def blob(path):
    p=Path(path);p=p if p.is_absolute() else REPO/p
    no_symlinks(p)
    return p.read_bytes()


def assemble(slot):
    """Re-materialize reviewed immutable bytes; examples/reviewer annotations never sent."""
    require(slot in SLOTS,'SLOT_NOT_ALLOWED');case=SLOTS[slot];root=PACKAGES/case
    catalog=strict_json(read_private(root/'catalog.json'));package=strict_json(read_private(root/'manifest.json'))
    require((package['hash'],evidence.catalog_digest(catalog))==PINS[case],'ACCEPTED_PACKAGE_BINDING')
    view=evidence.blind_input(package,catalog,blob)
    require(view==strict_json(read_private(root/'blind-input.json')),'BLIND_PROJECTION_DRIFT')
    prompt=prompt_contract();require(prompt['prompt_version']==POLICY['prompt_version'],'PROMPT_VERSION')
    require(digest(output_schema())=='737078fba6bfe5ad7828414c7d2ebdc048419f79f99670f5b06cee23e5509940','SCHEMA_DRIFT')
    ds={d['id']:d for d in catalog['derivatives']};images=[];refs=[]
    for ref in view['evidence']:
        d=ds[ref['id']];raw=blob(d['path'])
        require(sha256(raw).hexdigest()==ref['sha256'],'MATERIALIZED_HASH')
        r=dict(ref)
        if ref['media_type']=='text/plain':r['text']=raw.decode()
        else:
            require(ref['media_type']=='image/png' and raw.startswith(b'\x89PNG\r\n\x1a\n'),'IMAGE_TYPE')
            r['image_index']=len(images);images.append(raw)
        refs.append(r)
    answer=view['student_submission']['text'];answer_hash=sha256(answer.encode()).hexdigest()
    criteria=[dict(id=k,version=1,**v) for k,v in sorted(view['criteria'].items())]
    value=dict(contract_version='1.3',attempt_id=slot,answer_hash=answer_hash,answer=answer,
        question=view['question'],evidence_package_version=evidence.VERSION,evidence_package_hash=package['hash'],
        criteria=criteria,evidence=refs,scaffolding_context=dict(items=[],previous_core_progress_ids=[]),
        transcription={k:v for k,v in view['student_submission'].items() if k!='text'},
        image_order=[r['id'] for r in refs if 'image_index' in r])
    claim=dict(answer=answer,input=dict(contract_version='1.3',attempt_id=slot,answer_hash=answer_hash,
        criteria=criteria,evidence=refs,scaffolding_context=value['scaffolding_context']))
    content=[dict(type='input_text',text=encoded(value).decode())]
    content += [dict(type='input_image',image_url='data:image/png;base64,'+b64encode(raw).decode(),detail='high') for raw in images]
    payload=dict(model=POLICY['model'],store=False,max_output_tokens=TRANSPORT_SETTINGS['max_output_tokens'],
        reasoning={'effort':'high'},instructions=prompt['prompt'],input=[dict(role='user',content=content)],
        text={'format':dict(type='json_schema',name='essay_evaluation_13',strict=True,schema=output_schema())})
    binding=dict(slot=slot,case=case,answer_hash=answer_hash,package_hash=package['hash'],catalog_hash=package['catalog_hash'],
        prompt_version=prompt['prompt_version'],prompt_hash=prompt['prompt_sha256'],contract_version='1.3',
        schema_hash=digest(output_schema()),policy=POLICY,regime=REGIME,
        ordered_image_hashes=[sha256(x).hexdigest() for x in images],payload_hash=digest(payload),claim_hash=digest(claim))
    return value,claim,payload,binding


def phase_a():
    p=strict_json(read_private(ROOT/'phase-a.json'))
    require(set(p['checks'])==set(PHASE_CHECKS) and all(v is True for v in p['checks'].values()),'PHASE_A_REQUIRED')
    require(p['prompt']==prompt_contract()['prompt_sha256'],'PHASE_A_PROMPT_DRIFT')
    require(p['files'] and all(sha256((REPO/k).read_bytes()).hexdigest()==v for k,v in p['files'].items()),'PHASE_A_CODE_DRIFT')
    return p


def repository_gate():
    # Old artifacts stay in the original checkout: its branch-specific ignore policy
    # must protect them too, even when this worktree is correctly excluded.
    require(subprocess.run(['git','check-ignore','-q',str(HISTORICAL_PRIVATE)],cwd=HISTORICAL_REPO).returncode==0,'HISTORICAL_PRIVATE_NOT_IGNORED')
    require(subprocess.check_output(['git','ls-files','--',str(HISTORICAL_PRIVATE)],cwd=HISTORICAL_REPO)==b'','HISTORICAL_PRIVATE_TRACKED')
    require(subprocess.run(['git','check-ignore','-q',str(ROOT)],cwd=REPO).returncode==0,'PRIVATE_NOT_IGNORED')
    require(subprocess.check_output(['git','ls-files','--',str(ROOT)],cwd=REPO)==b'','PRIVATE_TRACKED')
    require(subprocess.check_output(['git','branch','--show-current'],cwd=REPO).strip()==b'codex/essay-scaffolding-vnext','BRANCH_DRIFT')
    require(subprocess.run(['git','merge-base','--is-ancestor','9346292', 'HEAD'],cwd=REPO).returncode==0,'BASELINE_MISSING')


def prepare():
    """Called only after reviewed Phase A receipt exists. No credential/network."""
    repository_gate();phase_a();parent=child_dir(ROOT,'prepared')
    for slot in SLOTS:
        value,claim,payload,binding=assemble(slot);target=parent/slot
        target.mkdir(mode=0o700,exist_ok=False)
        for name,data in [('input',value),('claim',claim),('payload',payload),('binding',binding)]:
            freeze(target/f'{name}.json',encoded(data))
    return {slot:assemble(slot)[3] for slot in SLOTS}


def credential_environment(environment):
    name='ESSAY_PILOT_OPENAI_API_KEY'
    require(name not in environment and name+'_FILE' in environment,'ONE_FILE_CREDENTIAL_REQUIRED')
    # Forbid a second standard OpenAI source, even though this adapter never reads it.
    require(not any(k in environment for k in ('OPENAI_API_KEY','OPENAI_API_KEY_FILE')),'AMBIGUOUS_CREDENTIAL')
    p=Path(environment[name+'_FILE']).expanduser().absolute();no_symlinks(p)
    require(p==Path.home()/'.legendstudy/secrets/openai_pilot_api_key','UNAPPROVED_CREDENTIAL_PATH')
    require(not p.is_relative_to(REPO),'CREDENTIAL_INSIDE_REPO')
    info=p.stat();require(stat.S_ISREG(info.st_mode) and info.st_uid==os.getuid() and info.st_nlink==1
        and stat.S_IMODE(info.st_mode) in (0o400,0o600) and 0<info.st_size<=4096,'UNSAFE_CREDENTIAL')
    return {name+'_FILE':str(p)}


class SingleHTTP:
    """Exactly one official TLS POST; no SDK, redirect, retry, proxy, billing/model query."""
    synthetic_only=False
    def __init__(self):self.used=False
    def send(self,body,headers):
        require(EXECUTION_AUTHORIZATION==AUTHORIZATION and not self.used,'LIVE_GATE_OR_CONSUMED')
        self.used=True
        c=http.client.HTTPSConnection('api.openai.com',timeout=300,context=ssl.create_default_context())
        try:
            c.request('POST','/v1/responses',body=body,headers=headers)
            r=c.getresponse();return r.status,r.read(MAX_RESPONSE+1)
        finally:c.close()


def blocked_after(record):
    return record['state']=='UNKNOWN_CONSUMED' or record['request_outcome'] in ('SECRET_ECHO_WITHHELD','MODEL_MISMATCH')


def run_slot(root,slot,prepared,key,http,*,synthetic=False):
    """Shared deterministic lifecycle; real callers must use the fixed dispatch entry."""
    require(slot in SLOTS,'SLOT_NOT_ALLOWED');private_dir(root)
    if synthetic:
        require(getattr(http,'synthetic_only',False) and root.as_posix().startswith('/private/tmp/essay-l2c2-test'),'ISOLATED_ONLY')
    else:
        require(root==ROOT and EXECUTION_AUTHORIZATION==AUTHORIZATION and type(http) is SingleHTTP,'LIVE_GATE')
        repository_gate();phase_a()
        require(prepared==assemble(slot),'LIVE_PREPARED_BINDING')
    value,claim,payload,binding=prepared
    require(binding['payload_hash']==digest(payload) and binding['claim_hash']==digest(claim)
        and binding['slot']==slot and binding['policy']==POLICY,'EXECUTION_BINDING')
    marks=child_dir(root,'started');slots=child_dir(root,'results');target=slots/slot
    for prior in list(SLOTS)[:list(SLOTS).index(slot)]:
        require((slots/prior/'terminal.json').is_file(),'SEQUENTIAL_ONLY')
        require(not blocked_after(strict_json(read_private(slots/prior/'terminal.json'))),'PRIOR_STOP_CONDITION')
    require(not target.exists() and not (marks/f'{slot}.json').exists(),'SLOT_CONSUMED')
    freeze(marks/f'{slot}.json',encoded(dict(state='STARTED_CONSUMED',started_at=now(),binding=binding,synthetic=synthetic)))
    record=dict(slot=slot,state='UNKNOWN_CONSUMED',request_outcome='UNKNOWN',parser='NOT_RUN',
        sentence_root='NOT_RUN',core_count=None,http_status=None,telemetry=metadata(None,POLICY,0),
        binding=binding,human_quality='PENDING_OWNER_REVIEW',synthetic=synthetic)
    start=time.monotonic()
    try:
        target.mkdir(mode=0o700,exist_ok=False)
        status,raw=http.send(encoded(payload),{'Authorization':'Bearer '+key,'Content-Type':'application/json'})
        record['http_status']=status;record['raw_hash']=sha256(raw).hexdigest()
        scan=re.sub(rb'\\u00([0-9a-fA-F]{2})',lambda m:bytes([int(m[1],16)]),raw)
        if key.encode() in scan or json.dumps(key)[1:-1].encode() in raw or re.search(rb'(?i)(authorization\s*[:=]|bearer\s+[A-Za-z0-9_-]+|sk-(?:proj|ant-api)[A-Za-z0-9_-]+)',scan):
            freeze(target/'raw-withheld.json',encoded(dict(reason='CREDENTIAL_PATTERN',sha256=record['raw_hash'])))
            record.update(state='FAILED_CONSUMED',request_outcome='SECRET_ECHO_WITHHELD')
        else:
            freeze(target/'raw-response.bin',raw) # Must precede every envelope/product parse.
            record.update(state='FAILED_CONSUMED',request_outcome='RESPONSE_RECEIVED',raw_before_parse=True)
            try:data=strict_json(raw)
            except Invalid:data=None
            record['telemetry']=metadata(data,POLICY,round((time.monotonic()-start)*1000))
            if not 200<=status<300:record['request_outcome']='HTTP_ERROR'
            elif data is not None and data.get('model')!=POLICY['model_version']:
                record['request_outcome']='MODEL_MISMATCH'
            else:
                try:
                    require(len(raw)<=MAX_RESPONSE,'OVERSIZED_RESPONSE');require(data is not None,'MALFORMED_RESPONSE')
                    # Decode logic reused exactly; no historical payload/prompt dispatched.
                    adapter=OpenAIPilot('pilot-openai-gpt56-sol-v1',key)
                    result=adapter.decode(data,record['telemetry']['latency_ms'])
                    normalized=parse_provider(result.raw,claim)
                except (Invalid,ProviderFailure,KeyError,TypeError,AttributeError) as error:
                    code=str(error)
                    record.update(parser='REJECTED',validation_error=code if re.fullmatch(r'[A-Z_]{1,80}',code) else 'STRICT_VALIDATION_REJECTED')
                    record['sentence_root']='FAIL' if code=='SENTENCE_ROOT' else 'NOT_CONFIRMED'
                else:
                    freeze(target/'normalized.json',encoded(normalized))
                    record.update(state='VALID_UNREVIEWED',parser='PASS',sentence_root='PASS',
                        core_count=len(normalized['core_improvement_keys']),normalized_hash=digest(normalized))
    except BaseException:
        record.update(state='UNKNOWN_CONSUMED',request_outcome='TRANSPORT_OR_LOCAL_UNKNOWN')
    record['telemetry']['latency_ms']=round((time.monotonic()-start)*1000);record['completed_at']=now()
    try:freeze(target/'terminal.json',encoded(record))
    except BaseException:return dict(slot=slot,state='UNKNOWN_CONSUMED',request_outcome='TERMINAL_WRITE_UNKNOWN')
    return record


def dispatch(slot):
    require(EXECUTION_AUTHORIZATION==AUTHORIZATION,'REAL_EXECUTION_CLOSED')
    require(slot in SLOTS,'SLOT_NOT_ALLOWED');repository_gate();phase_a()
    prepared=assemble(slot);target=ROOT/'prepared'/slot
    for name,data in zip(('input','claim','payload','binding'),prepared):
        require(read_private(target/f'{name}.json',32*1024*1024)==encoded(data),'FROZEN_EXECUTION_DRIFT')
    env=credential_environment(os.environ)
    return run_slot(ROOT,slot,prepared,credential('openai',env),SingleHTTP())
