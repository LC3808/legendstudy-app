"""L2-B private Pilot preparation. No network client, DB connection, or live launcher.
The two adapters require an injected transport. The only dispatcher is mock-only.
A separately authorized execution phase must provide a reviewed live dispatcher.
"""
from base64 import b64encode
from copy import deepcopy
from dataclasses import asdict
from hashlib import sha256
import json
import os
from pathlib import Path
import stat
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request

from .live_worker import (Invalid, ProviderFailure, Unknown, ProviderResult, PROMPT,
                          PROMPT_VERSION, encoded, digest, require, strict_json,
                          output_schema, parse_provider, telemetry_payload)

POLICIES = {
    'pilot-openai-gpt56-sol-v1': dict(provider='openai', model='gpt-5.6-sol'),
    'pilot-anthropic-sonnet55-v1': dict(provider='anthropic', model='claude-sonnet-5-5'),
}
TRANSPORT_SETTINGS = {'timeout_seconds': 300, 'max_output_tokens': 12000, 'effort': 'high',
                      'automatic_retries': 0, 'tools': False, 'explicit_prompt_cache': False}

CREDENTIAL_NAMES = {
    'openai': 'ESSAY_PILOT_OPENAI_API_KEY',
    'anthropic': 'ESSAY_PILOT_ANTHROPIC_API_KEY',
}
# Both providers see exactly this product instruction and the same ordered image bytes.
# Extension describes existing blind artifacts, not any previous model judgment.
PILOT_PROMPT_VERSION = PROMPT_VERSION + '-bakeoff1'
PILOT_PROMPT = PROMPT + '''\n이번 입력은 비공개 비교 Pilot입니다. 첨부 이미지는 image_order 순서입니다.
answer는 기존 이미지 대조 전사본이며 인용의 고정 기준입니다. 원본 이미지는 별도로 유지됩니다.
[판독 어려움]은 원문 글자가 아니므로 해당 구간을 추측하거나 오류로 만들지 마세요.
전사 길이를 손글씨 원고지 분량과 동일시하지 마세요. 공식 length_requirement만 참고하세요.
criteria_note의 보고 축과 공식 배점을 구분하세요. level 1~5는 충족도 보조 지표이며 대학 점수가 아닙니다.
이전 평가가 없는 경우 previous_improvement_reviews=[]이며 새 과제는 open입니다.
'''


def policy(name):
    require(name in POLICIES, 'UNKNOWN_PILOT_POLICY')
    values = POLICIES[name]
    return dict(policy_version=name, **values, model_version=values['model'],
                prompt_version=PILOT_PROMPT_VERSION, contract_version='1.3')


def credential(provider, environment):
    """Explicit environment mapping only. No implicit credential probing in preparation.
    Optional NAME_FILE: private regular file, owned by operator, 0400/0600, no symlink.
    Neither secrets nor secret paths are returned in any report.
    """
    name = CREDENTIAL_NAMES[provider]
    value, filename = environment.get(name), environment.get(name + '_FILE')
    require(not (value and filename), 'AMBIGUOUS_CREDENTIAL')
    if filename:
        fd = os.open(filename, os.O_RDONLY | os.O_NOFOLLOW)
        try:
            info = os.fstat(fd)
            require(stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid()
                    and not info.st_mode & 0o077 and info.st_size <= 4096,
                    'UNSAFE_CREDENTIAL_FILE')
            value = os.read(fd, 4097).decode().strip()
        finally:
            os.close(fd)
    require(isinstance(value, str) and bool(value.strip()) and len(value) <= 4096
            and '\n' not in value and '\r' not in value, 'MISSING_OR_INVALID_CREDENTIAL')
    return value


def image_parts(images, expected=None):
    if expected is not None:
        require(expected == [item['sha256'] for item in images], 'PACKAGE_IMAGE_DRIFT')
    parts = []
    for item in images:
        require(set(item) == {'sha256', 'bytes'}, 'IMAGE_SHAPE')
        require(sha256(item['bytes']).hexdigest() == item['sha256'], 'IMAGE_DRIFT')
        require(item['bytes'].startswith(b'\x89PNG\r\n\x1a\n'), 'IMAGE_FORMAT')
        parts.append(b64encode(item['bytes']).decode('ascii'))
    return parts


class PilotTransport:
    """No default urlopen, SDK, retries, tools or fallback model. Mock injection only
    in this phase; payload builders are usable by a later approved dispatcher.
    Native provider envelope and private raw sink never enter the Product DB.
    """
    endpoint = ''

    def __init__(self, name, key, *, transport=None, timeout=TRANSPORT_SETTINGS['timeout_seconds']):
        self.binding = policy(name)
        require(self.binding['provider'] == self.provider, 'ADAPTER_BINDING')
        require(isinstance(key, str) and bool(key.strip()) and '\n' not in key
                and '\r' not in key, 'MISSING_OR_INVALID_CREDENTIAL')
        require(timeout == TRANSPORT_SETTINGS['timeout_seconds'], 'FROZEN_TIMEOUT')
        self.key, self.transport, self.timeout = key, transport, timeout

    def headers(self):
        raise NotImplementedError

    def payload(self, value, images):
        raise NotImplementedError

    def decode(self, data, latency):
        raise NotImplementedError

    def usage(self, data, latency, raw=''):
        require(type(data) is dict and data.get('model') == self.binding['model_version'],
                'RESPONSE_IDENTITY_MISMATCH')
        usage = data.get('usage')
        require(usage is None or type(usage) is dict, 'INVALID_USAGE')
        usage = usage or {}
        # Anthropic cache counters are preserved separately, never silently omitted
        # from a purported all-input total. No prompt caching is requested in Pilot.
        for key in ['cache_creation_input_tokens', 'cache_read_input_tokens']:
            require(usage.get(key) is None or type(usage[key]) is int and usage[key] >= 0,
                    'INVALID_USAGE')
        inp = usage.get('input_tokens')
        if self.provider == 'anthropic' and inp is not None:
            require(type(inp) is int and inp >= 0, 'INVALID_USAGE')
            inp += sum(usage.get(k) or 0 for k in ['cache_creation_input_tokens', 'cache_read_input_tokens'])
        result = ProviderResult(raw, self.provider, self.binding['model'], inp,
                                usage.get('output_tokens'), latency,
                                usage.get('total_tokens'), data['model'])
        telemetry_payload({}, result, self.binding)
        return result

    def evaluate(self, value, images=(), *, raw_sink=lambda _: None):
        require(self.transport is not None and getattr(self.transport, 'synthetic_only', False),
                'REAL_PROVIDER_NOT_AUTHORIZED')
        request = Request(self.endpoint, data=encoded(self.payload(value, images)), headers=self.headers())
        started = time.monotonic()
        try:
            with self.transport(request, timeout=self.timeout) as response:
                raw = response.read(262145)
            # Freeze before JSON validation, including malformed/refused/truncated output.
            raw_sink(raw)
        except HTTPError as error:
            # No raw HTTP error body/headers in ordinary telemetry or exception strings.
            if error.code >= 500:
                raise Unknown('PROVIDER_UNAVAILABLE') from None
            raise ProviderFailure('PROVIDER_REJECTED') from None
        except (TimeoutError, URLError):
            raise Unknown('PROVIDER_NETWORK_UNKNOWN') from None
        data = strict_json(raw)
        latency = round((time.monotonic() - started) * 1000)
        try:
            return self.decode(data, latency)
        except (KeyError, TypeError, AttributeError):
            raise Invalid('MALFORMED_PROVIDER_ENVELOPE') from None


class OpenAIPilot(PilotTransport):
    provider = 'openai'
    endpoint = 'https://api.openai.com/v1/responses'

    def headers(self):
        return {'Authorization': 'Bearer ' + self.key, 'Content-Type': 'application/json'}

    def payload(self, value, images):
        content = [{'type': 'input_text', 'text': encoded(value).decode()}]
        content += [{'type': 'input_image', 'image_url': 'data:image/png;base64,' + img,
                     'detail': 'high'} for img in image_parts(images, value.get('image_sha256'))]
        return dict(model=self.binding['model'], store=False, max_output_tokens=TRANSPORT_SETTINGS['max_output_tokens'],
                    reasoning={'effort': 'high'}, instructions=PILOT_PROMPT,
                    input=[{'role': 'user', 'content': content}],
                    text={'format': {'type': 'json_schema', 'name': 'essay_evaluation_13',
                                     'strict': True, 'schema': output_schema()}})

    def decode(self, data, latency):
        usage = self.usage(data, latency)
        if data.get('status') != 'completed':
            raise ProviderFailure('INCOMPLETE_OR_REFUSED', usage=usage)
        require(type(data.get('output')) is list, 'PROVIDER_OUTPUT')
        texts = []
        for item in data['output']:
            require(type(item) is dict, 'PROVIDER_OUTPUT')
            if item.get('type') == 'reasoning':
                continue
            require(item.get('type') == 'message' and type(item.get('content')) is list,
                    'UNEXPECTED_PROVIDER_CONTENT')
            for part in item['content']:
                require(type(part) is dict, 'PROVIDER_OUTPUT')
                if part.get('type') == 'refusal':
                    raise ProviderFailure('REFUSED', usage=usage)
                require(part.get('type') == 'output_text' and type(part.get('text')) is str,
                        'UNEXPECTED_PROVIDER_CONTENT')
                texts.append(part['text'])
        require(len(texts) == 1, 'PROVIDER_OUTPUT')
        return self.usage(data, latency, texts[0])


class AnthropicPilot(PilotTransport):
    provider = 'anthropic'
    endpoint = 'https://api.anthropic.com/v1/messages'

    def headers(self):
        return {'x-api-key': self.key, 'anthropic-version': '2023-06-01',
                'Content-Type': 'application/json'}

    def payload(self, value, images):
        content = [{'type': 'text', 'text': encoded(value).decode()}]
        content += [{'type': 'image', 'source': {'type': 'base64', 'media_type': 'image/png',
                                                'data': img}} for img in image_parts(images, value.get('image_sha256'))]
        return dict(model=self.binding['model'], max_tokens=TRANSPORT_SETTINGS['max_output_tokens'], system=PILOT_PROMPT,
                    thinking={'type': 'adaptive'}, messages=[{'role': 'user', 'content': content}],
                    output_config={'effort': 'high', 'format': {'type': 'json_schema',
                                                              'schema': output_schema()}})

    def decode(self, data, latency):
        usage = self.usage(data, latency)
        require(data.get('type') == 'message' and data.get('role') == 'assistant', 'PROVIDER_OUTPUT')
        if data.get('stop_reason') != 'end_turn':
            raise ProviderFailure('INCOMPLETE_OR_REFUSED', usage=usage)
        require(type(data.get('content')) is list, 'PROVIDER_OUTPUT')
        texts = []
        for part in data['content']:
            require(type(part) is dict, 'PROVIDER_OUTPUT')
            if part.get('type') in {'thinking', 'redacted_thinking'}:
                continue
            require(part.get('type') == 'text' and type(part.get('text')) is str,
                    'UNEXPECTED_PROVIDER_CONTENT')
            texts.append(part['text'])
        require(len(texts) == 1, 'PROVIDER_OUTPUT')
        return self.usage(data, latency, texts[0])


def private_new(path, data):
    """Exclusive, owner-only, immutable-to-ordinary-writes artifact; caller owns directory."""
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    os.chmod(path, 0o400)


def offline_slot(directory, adapter, value, images, claim):
    """Tests the future one-shot freeze protocol WITHOUT a live transport/DB.
    Atomic directory creation consumes a slot even on timeout/crash; never rerun it.
    Valid normalized output is UNREVIEWED, not a signed receipt or RPC payload.
    """
    require(getattr(adapter.transport, 'synthetic_only', False), 'REAL_PROVIDER_NOT_AUTHORIZED')
    directory = Path(directory)
    require(directory.parent.is_dir() and not directory.parent.is_symlink()
            and not directory.parent.stat().st_mode & 0o077, 'PRIVATE_DIRECTORY_REQUIRED')
    directory.mkdir(mode=0o700, exist_ok=False)
    private_new(directory/'attempt.json', encoded({'no_retry': True, 'synthetic_only': True,
                                                 'package_sha256': digest(value), 'binding': adapter.binding}))
    result = None
    report = {'status': 'FAILED', 'human_review': 'NOT_RUN', 'real_ai_calls': 0}
    try:
        result = adapter.evaluate(value, images,
                                  raw_sink=lambda raw: private_new(directory/'raw-response.json', raw))
        out = parse_provider(result.raw, claim)
        private_new(directory/'normalized.json', encoded(out))
        report.update(status='SCHEMA_VALID_UNREVIEWED', output_sha256=digest(out))
    except (Invalid, Unknown, ProviderFailure) as error:
        if getattr(error, 'usage', None) is not None:
            result = error.usage
        report['status'] = 'UNKNOWN_NO_RETRY' if isinstance(error, Unknown) else 'FAILED_NO_RETRY'
        # No interpolated exception messages: provider content cannot enter sanitized report.
    finally:
        if result is not None:
            fields = asdict(result)
            fields.pop('raw')
            report['telemetry'] = fields
        report['files'] = {p.name: sha256(p.read_bytes()).hexdigest() for p in directory.iterdir()}
        private_new(directory/'receipt.json', encoded(report))
    return report
