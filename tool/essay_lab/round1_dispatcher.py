"""Private L2-B1: four fixed slots, no DB, no scheduler, no retries.
REAL mode is compiled closed; no flag, credential or environment variable enables it.
Tests inject a fake HTTPS connection into the same single-POST path.
"""
import argparse
from datetime import datetime, timezone
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
from .bakeoff import (OpenAIPilot, AnthropicPilot, CREDENTIAL_NAMES, PILOT_PROMPT,
                      TRANSPORT_SETTINGS, policy)
from .live_worker import Invalid, ProviderFailure, encoded, digest, output_schema, parse_provider, require, strict_json

REPO = Path(__file__).resolve().parents[2]
PRIVATE = REPO/'.local/essay-bakeoff-l2b'
EVIDENCE = REPO/'tool/essay_lab/evidence'
# Separate Owner approval plus reviewed activation change is required in L2-B2.
EXECUTION_AUTHORIZATION = None
SLOTS = {
    'sookmyung-openai': ('sookmyung', 'pilot-openai-gpt56-sol-v1'),
    'sookmyung-anthropic': ('sookmyung', 'pilot-anthropic-sonnet55-v1'),
    'hanyang-openai': ('hanyang', 'pilot-openai-gpt56-sol-v1'),
    'hanyang-anthropic': ('hanyang', 'pilot-anthropic-sonnet55-v1'),
}
ENDPOINTS = {'openai': ('api.openai.com', '/v1/responses'),
             'anthropic': ('api.anthropic.com', '/v1/messages')}
SUPPLEMENTAL = {
    'sookmyung-openai-supplemental-1': 'sookmyung-openai',
    'hanyang-openai-supplemental-1': 'hanyang-openai',
}
MAX_RESPONSE = 262144


def now():
    return datetime.now(timezone.utc).isoformat()


def real_gate():
    # Intentionally not an env/CLI toggle. A later reviewed change must name authorization.
    require(EXECUTION_AUTHORIZATION is not None, 'REAL_EXECUTION_DISABLED_L2_B1')


def no_symlinks(path):
    path = Path(path).absolute()
    for item in [*reversed(path.parents), path]:
        require(not item.is_symlink(), 'SYMLINK_DENIED')
    return path


def private_dir(path):
    path = no_symlinks(path)
    info = path.stat()
    require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid()
            and stat.S_IMODE(info.st_mode) == 0o700, 'PRIVATE_DIRECTORY_REQUIRED')
    return path


def read_private(path, limit=8*1024*1024):
    path = no_symlinks(path)
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        info = os.fstat(fd)
        require(stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid() and info.st_nlink == 1
                and stat.S_IMODE(info.st_mode) in (0o400, 0o600) and info.st_size <= limit,
                'UNSAFE_PRIVATE_FILE')
        with os.fdopen(fd, 'rb', closefd=False) as stream:
            raw = stream.read(limit+1)
        require(len(raw) <= limit, 'PRIVATE_FILE_TOO_LARGE')
        return raw
    finally:
        os.close(fd)


def credential(provider, environment):
    """L2-B names/contract, stricter empty-source/FIFO/error redaction. Never probe network."""
    name = CREDENTIAL_NAMES[provider]
    require(sum(k in environment for k in (name, name+'_FILE')) == 1, 'CREDENTIAL_SOURCE_COUNT')
    try:
        value = environment[name] if name in environment else read_private(environment[name+'_FILE'], 4096).decode().strip()
        require(type(value) is str and 8 <= len(value) <= 4096
                and re.fullmatch(r'[!-~]+', value) is not None, 'INVALID_CREDENTIAL')
        return value
    except (OSError, ValueError, TypeError):
        raise Invalid('CREDENTIAL_UNAVAILABLE_OR_UNSAFE') from None


def freeze(path, data):
    private_dir(path.parent)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as stream:
        stream.write(data); stream.flush(); os.fsync(stream.fileno())
        os.fchmod(stream.fileno(), 0o400); os.fsync(stream.fileno())
    parent = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
    try: os.fsync(parent)
    finally: os.close(parent)


def child_dir(parent, name):
    private_dir(parent)
    path = parent/name
    try: path.mkdir(mode=0o700)
    except FileExistsError: pass
    fd = os.open(parent, os.O_RDONLY | os.O_DIRECTORY)
    try: os.fsync(fd)
    finally: os.close(fd)
    return private_dir(path)


def verify_frozen(root, slot):
    require(slot in SLOTS, 'SLOT_NOT_ALLOWED')
    private_dir(root)
    ignored = subprocess.run(['git','check-ignore','-q',str(PRIVATE/'round1')],cwd=REPO).returncode == 0
    tracked = subprocess.check_output(['git','ls-files','--','.local/essay-bakeoff-l2b'],cwd=REPO)
    require(ignored and not tracked, 'PRIVATE_GIT_EXCLUSION_REQUIRED')
    pins = json.loads((EVIDENCE/'l2_b1_frozen_files.json').read_text())
    report_raw = (EVIDENCE/'l2_b_preparation_result.json').read_bytes()
    require(sha256(report_raw).hexdigest() == pins['preparation_result_sha256'], 'PREPARATION_REPORT_DRIFT')
    report = json.loads(report_raw)
    # Verify all four-slot plan inputs, not only one answer; never reassemble/repair them.
    content = {}
    for name, expected in pins['files'].items():
        require(not Path(name).is_absolute() and '..' not in Path(name).parts, 'PIN_PATH')
        private_dir((root/name).parent)
        raw = read_private(root/name)
        require(sha256(raw).hexdigest() == expected, 'FROZEN_FILE_DRIFT')
        content[name] = raw
    plan = strict_json(content['manifest.json'])
    require(plan['real_ai_calls'] == 0 and len(plan['round1_slots']) == 4, 'FROZEN_PLAN')
    require(strict_json(content['policy-regimes.json']) == report['policies'], 'POLICY_DRIFT')
    require(strict_json(content['transport-plan.json']) == TRANSPORT_SETTINGS, 'SETTINGS_DRIFT')
    case, pname = SLOTS[slot]
    manifest = strict_json(content[case+'/manifest.json'])
    require(manifest == next(p for p in report['packages'] if p['case'] == case), 'MANIFEST_DRIFT')
    value = strict_json(content[case+'/package.json'])
    claim = strict_json(content[case+'/validation-context.json'])
    require(digest(value) == manifest['package_sha256'] and value['contract_version'] == '1.3', 'PACKAGE_DRIFT')
    require(sha256(value['answer'].encode()).hexdigest() == manifest['answer_sha256'] == value['answer_hash'], 'ANSWER_DRIFT')
    require(claim['answer'] == value['answer'] and claim['input']['attempt_id'] == value['attempt_id'], 'CONTEXT_DRIFT')
    require(content[case+'/prompt.txt'] == PILOT_PROMPT.encode(), 'PROMPT_DRIFT')
    require(strict_json(content[case+'/schema.json']) == output_schema(), 'SCHEMA_DRIFT')
    require(digest(output_schema()) == manifest['schema_sha256'], 'SCHEMA_HASH')
    for name, expected in manifest['contract_hashes'].items():
        require(sha256((EVIDENCE/name).read_bytes()).hexdigest() == expected, 'CONTRACT_DRIFT')
    binding = policy(pname)
    frozen_policy = next(p for p in report['policies'] if p['binding']['policy_version'] == pname)
    require(binding == frozen_policy['binding'], 'MODEL_POLICY_DRIFT')
    # Frozen SQL-generated regime retained exactly; no Python recreation of jsonb::text hash.
    images = [{'sha256': h, 'bytes': content[case+'/input_'+str(i+1)+'.png']}
              for i,h in enumerate(manifest['input_images'])]
    require([sha256(i['bytes']).hexdigest() for i in images] == value['image_sha256'], 'IMAGE_DRIFT')
    return value, images, claim, binding, frozen_policy['regime'], manifest


class OfficialHTTP:
    """One HTTPS POST, TLS verification, no proxy/env endpoint, no redirect handler.
    http.client never follows a Location or automatically retries a POST.
    Only an explicitly synthetic injected connection can run in L2-B1.
    """
    def __init__(self, connection_factory=None):
        self.factory = connection_factory
        self.synthetic_only = connection_factory is not None and getattr(connection_factory, 'synthetic_only', False)
        self.used = False

    def send(self, provider, endpoint, body, headers):
        if not self.synthetic_only: real_gate()
        require(provider in ENDPOINTS, 'PROVIDER_NOT_ALLOWED')
        host, path = ENDPOINTS[provider]
        require(endpoint == 'https://'+host+path, 'ENDPOINT_NOT_ALLOWED')
        require(not self.used, 'HTTP_ALREADY_CONSUMED')
        self.used = True
        factory = self.factory if self.synthetic_only else http.client.HTTPSConnection
        connection = factory(host, timeout=TRANSPORT_SETTINGS['timeout_seconds'], context=ssl.create_default_context())
        try:
            connection.request('POST', path, body=body, headers=headers)
            response = connection.getresponse()
            # No response headers saved; body contains native model/id/status/usage envelope.
            status = response.status
            raw = response.read(MAX_RESPONSE+1)
            return status, raw
        finally:
            connection.close()


def slot_state(root, slot):
    require(slot in SLOTS or slot in SUPPLEMENTAL, 'SLOT_NOT_ALLOWED')
    supplemental = slot in SUPPLEMENTAL
    marker = root/('supplemental-started' if supplemental else 'round1-started')/f'{slot}.json'
    result = root/('supplemental-openai' if supplemental else 'round1')/slot/'terminal.json'
    if marker.exists() or marker.is_symlink():
        if result.is_file():
            return strict_json(read_private(result))['state']
        return 'UNKNOWN_CONSUMED_FOR_SUPPLEMENTAL' if supplemental else 'UNKNOWN_CONSUMED_FOR_ROUND1'
    require(not result.parent.exists(), 'ORPHAN_SLOT_REQUIRES_REVIEW')
    return 'NOT_STARTED'


def metadata(data, binding, elapsed):
    def counter(v): return v if type(v) is int and 0 <= v < 2**63 else None
    usage = data.get('usage') if type(data) is dict else None
    usage = usage if type(usage) is dict else {}
    returned = data.get('model') if type(data) is dict else None
    # Untrusted unexpected strings stay only in private raw, never sanitized metadata.
    out = dict(provider=binding['provider'], requested_model=binding['model'],
               returned_model=returned if returned == binding['model_version'] else None,
               returned_model_matches=returned == binding['model_version'], latency_ms=elapsed,
               input_tokens=counter(usage.get('input_tokens')), output_tokens=counter(usage.get('output_tokens')),
               total_tokens=counter(usage.get('total_tokens')),
               cache_read_input_tokens=counter(usage.get('cache_read_input_tokens')),
               cache_creation_input_tokens=counter(usage.get('cache_creation_input_tokens')),
               actual_cost=None, currency=None)
    details = usage.get('input_tokens_details')
    out['cached_input_tokens'] = counter(details.get('cached_tokens')) if type(details) is dict else None
    return out


def _run(root, slot, environment, http, *, synthetic, supplemental=False):
    require(slot in (SUPPLEMENTAL if supplemental else SLOTS), 'SLOT_NOT_ALLOWED')
    if not synthetic: real_gate()
    else:
        require(http.synthetic_only and root.absolute().as_posix().startswith('/private/tmp/essay-l2b1-test'),
                'ISOLATED_SYNTHETIC_ROOT_REQUIRED')
    value, images, claim, binding, regime, manifest = verify_frozen(root, SUPPLEMENTAL[slot] if supplemental else slot)
    require(slot_state(root, slot) == 'NOT_STARTED', 'SLOT_ALREADY_CONSUMED')
    key = credential(binding['provider'], environment)
    cls = OpenAIPilot if binding['provider'] == 'openai' else AnthropicPilot
    adapter = cls(binding['policy_version'], key)
    payload = adapter.payload(value, images)
    require(adapter.binding == binding and payload['model'] == binding['model'], 'MODEL_BINDING')
    host, path = ENDPOINTS[binding['provider']]
    require(adapter.endpoint == 'https://'+host+path, 'ENDPOINT_NOT_ALLOWED')
    marker_dir = child_dir(root, 'supplemental-started' if supplemental else 'round1-started')
    slots_dir = child_dir(root, 'supplemental-openai' if supplemental else 'round1')
    # Permanent separate tombstone. O_EXCL is the process/concurrency boundary.
    freeze(marker_dir/f'{slot}.json', encoded(dict(state='STARTED_CONSUMED_FOR_SUPPLEMENTAL' if supplemental else 'STARTED_CONSUMED_FOR_ROUND1',slot=slot,
           original_round1_slot=SUPPLEMENTAL.get(slot),
           started_at=now(), policy=binding, regime=regime, package_sha256=manifest['package_sha256'],
           policy_sha256=digest(binding), prompt_sha256=sha256(PILOT_PROMPT.encode()).hexdigest(),
           schema_sha256=digest(output_schema()), case_manifest_sha256=digest(manifest),
           ordered_image_sha256=value['image_sha256'],
           synthetic=synthetic, automatic_retry=False)))
    target = slots_dir/slot
    target.mkdir(mode=0o700, exist_ok=False)
    record = dict(slot=slot, state='UNKNOWN_CONSUMED_FOR_ROUND1', human_review='NOT_RUN',
                  parser_status='NOT_RUN', request_outcome='UNKNOWN', synthetic=synthetic,
                  telemetry=metadata(None, binding, 0), policy=binding, regime=regime)
    start = time.monotonic()
    try:
        status, raw = http.send(binding['provider'], adapter.endpoint, encoded(payload), adapter.headers())
        record['http_status'] = status
        record['raw_sha256'] = sha256(raw).hexdigest()
        # A hostile/faulty endpoint echoing the credential must not persist the secret.
        # Store only a hash+redaction notice and fail; never normalize this response.
        # Decode JSON ASCII escapes lexically, before any envelope/product parsing.
        # This also catches escaped credential echoes without persisting their bytes.
        scan = re.sub(rb'\\u00([0-9a-fA-F]{2})', lambda m: bytes([int(m[1], 16)]), raw)
        secret_echo = key.encode() in scan or json.dumps(key)[1:-1].encode() in raw or re.search(rb'(?i)(authorization\s*[:=]|bearer\s+[A-Za-z0-9_-]+|sk-(?:proj|ant-api)[A-Za-z0-9_-]+)', scan)
        if secret_echo:
            freeze(target/'raw-withheld.json', encoded({'reason':'CREDENTIAL_PATTERN','sha256':record['raw_sha256']}))
            record.update(state='FAILED_CONSUMED_FOR_ROUND1',request_outcome='SECRET_ECHO_WITHHELD')
        else:
            freeze(target/'raw-response.bin', raw)  # Before ANY JSON parsing/normalization.
            record['raw_saved_sha256'] = sha256(raw).hexdigest()
            record['raw_capture_truncated'] = len(raw) > MAX_RESPONSE
            record['telemetry']['latency_ms'] = round((time.monotonic()-start)*1000)
            try: data = strict_json(raw)
            except Invalid: data = None
            record['telemetry'] = metadata(data, binding, record['telemetry']['latency_ms'])
            if 300 <= status < 400:
                record.update(state='FAILED_CONSUMED_FOR_ROUND1',request_outcome='REDIRECT_REJECTED')
            elif not 200 <= status < 300:
                record.update(state='FAILED_CONSUMED_FOR_ROUND1',request_outcome='HTTP_ERROR')
            else:
                record['request_outcome'] = 'RESPONSE_RECEIVED'
                try:
                    require(len(raw) <= MAX_RESPONSE, 'OVERSIZED_RESPONSE')
                    require(data is not None, 'MALFORMED_RESPONSE')
                    result = adapter.decode(data, record['telemetry']['latency_ms'])
                    normalized = parse_provider(result.raw, claim)
                except (Invalid, ProviderFailure, KeyError, TypeError, AttributeError):
                    record.update(state='FAILED_CONSUMED_FOR_ROUND1',parser_status='REJECTED')
                else:
                    freeze(target/'normalized.json', encoded(normalized))
                    record.update(state='VALID_UNREVIEWED',parser_status='PASS',normalized_sha256=digest(normalized))
    except BaseException:
        # No exception string/traceback can carry credentials, request headers or body.
        # Even KeyboardInterrupt/write failure is UNKNOWN, never retry/release the marker.
        record.update(state='UNKNOWN_CONSUMED_FOR_ROUND1', request_outcome='TRANSPORT_OR_LOCAL_OUTCOME_UNKNOWN')
    record['telemetry']['latency_ms'] = round((time.monotonic()-start)*1000)
    if supplemental: record['state'] = record['state'].replace('FOR_ROUND1','FOR_SUPPLEMENTAL')
    record['completed_at'] = now()
    try: freeze(target/'terminal.json', encoded(record))
    except BaseException:
        return dict(slot=slot, state='UNKNOWN_CONSUMED_FOR_SUPPLEMENTAL' if supplemental else 'UNKNOWN_CONSUMED_FOR_ROUND1', terminal_saved=False)
    return record


def dispatch(slot):
    real_gate()  # Before environment access, file mutation, socket or credential inspection.
    return _run(PRIVATE, slot, os.environ, OfficialHTTP(), synthetic=False)


def dispatch_supplemental(slot):
    real_gate()
    require(slot in SUPPLEMENTAL, 'SUPPLEMENTAL_SLOT_NOT_ALLOWED')
    for prior in list(SUPPLEMENTAL)[:list(SUPPLEMENTAL).index(slot)]:
        require((PRIVATE/'supplemental-openai'/prior/'terminal.json').is_file(), 'SEQUENTIAL_ONLY')
    return _run(PRIVATE, slot, os.environ, OfficialHTTP(), synthetic=False, supplemental=True)


def run_synthetic(root, slot, environment, connection_factory):
    require(getattr(connection_factory, 'synthetic_only', False), 'SYNTHETIC_CONNECTION_REQUIRED')
    return _run(Path(root), slot, environment, OfficialHTTP(connection_factory), synthetic=True)


def block(text):
    # Prevent provider text being rendered as HTML, tracking images or executable Markdown.
    fence = '`' * max(3, max((len(m.group())+1 for m in re.finditer(r'`+', text)), default=3))
    return '\n'+fence+'text\n'+text+'\n'+fence+'\n'


def build_review(root=PRIVATE):
    """Read four terminal frozen outputs; render full PRIVATE review, no scoring/model selection."""
    rows = []
    require(all((root/'round1-started'/f'{slot}.json').is_file()
                and (root/'round1'/slot/'terminal.json').is_file() for slot in SLOTS),
            'ALL_FOUR_FROZEN_TERMINALS_REQUIRED')
    for case in ('sookmyung','hanyang'):
        value, _, _, _, _, _ = verify_frozen(root, case+'-openai')
        rows += ['## '+case, '### Original Answer', block(value['answer']),
                 '### Frozen criterion labels / official evidence references',
                 block(json.dumps({k:value[k] for k in ('criteria','official_evidence','reference_catalog')},
                                  ensure_ascii=False,indent=2))]
        for provider in ('openai','anthropic'):
            slot = case+'-'+provider; target = root/'round1'/slot
            result = strict_json(read_private(target/'terminal.json'))
            if 'raw_saved_sha256' in result:
                require(sha256(read_private(target/'raw-response.bin')).hexdigest() == result['raw_saved_sha256'], 'RAW_DRIFT')
            rows += ['### '+result['policy']['model'], block(json.dumps(result,ensure_ascii=False,indent=2))]
            if result['parser_status'] == 'PASS':
                raw = read_private(target/'normalized.json')
                require(sha256(raw).hexdigest() == result['normalized_sha256'], 'OUTPUT_DRIFT')
                output = strict_json(raw)
                for title, field in [('종합 평가','summary'),('잘한 점','strengths'),('평가 항목별 진단','dimensions'),
                       ('핵심 과제 / 실행 방향','improvements'),('먼저 고칠 순서','core_improvement_keys'),
                       ('문장 다듬기 — 원문/진단/수정 방향/예시','sentence_feedback'),('다시 쓸 때 확인','checklist'),
                       ('이전 과제 검토','previous_improvement_reviews')]:
                    rows += ['#### '+title,block(json.dumps(output[field],ensure_ascii=False,indent=2))]
            else: rows += ['Parser rejected or transport failed; inspect private raw artifact. No repaired evaluation.']
        rows += ['### Human Review Sheet',
                 '| Criterion | GPT-5.6 Sol | Claude Sonnet 5.5 | Exact evidence |', '|---|---|---|---|']
        for criterion in ('official criterion grounding','major issue recall','false criticism','core-focus priority',
                          'sentence diagnosis','content vs clarity','stance preservation','minimal editing',
                          'excessive feedback','actionability','Korean clarity','evidence correctness'):
            rows += ['| '+criterion+' | NOT_REVIEWED | NOT_REVIEWED | |']
    freeze(root/'round1-owner-review.md', '\n'.join(rows).encode())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--slot', choices=list(SLOTS), required=True)
    parser.add_argument('--execute', action='store_true', help='Disabled in L2-B1; separate reviewed authorization required')
    args = parser.parse_args()
    try:
        if args.execute: result = dispatch(args.slot)
        else:
            subprocess.run(['git','check-ignore','-q',str(PRIVATE/'round1')],cwd=REPO,check=True)
            verify_frozen(PRIVATE,args.slot)
            result = {'slot':args.slot,'hash_validation':'PASS','real_execution':'DISABLED','real_ai_calls':0}
        print(json.dumps(result))
    except BaseException:
        print(json.dumps({'status':'REFUSED','real_execution':'DISABLED','real_ai_calls':0}))
        return 2
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
