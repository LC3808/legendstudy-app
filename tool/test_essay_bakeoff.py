"""Offline adapter/parity/privacy tests: no credentials, network, DB or AI calls."""
import copy
import json
import os
from pathlib import Path
import tempfile
import unittest
from urllib.error import HTTPError, URLError
from tool.essay_lab.bakeoff import *
from tool.essay_lab.prepare_bakeoff import verify_parity, assemble, CASES
from tool.test_essay_live_worker import fixture


class MockTransport:
    synthetic_only = True

    def __init__(self, response=None, error=None):
        self.response, self.error, self.calls = response, error, []

    def __call__(self, request, timeout):
        self.calls.append((request, timeout))
        if self.error:
            raise self.error
        response = self.response
        class Response:
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def read(self, limit): return response[:limit]
        return Response()


def envelope(provider, output):
    if provider == 'openai':
        return dict(model='gpt-5.6-sol', status='completed',
                    usage=dict(input_tokens=10, output_tokens=20, total_tokens=30),
                    output=[dict(type='reasoning'), dict(type='message', content=[dict(type='output_text', text=output)])])
    return dict(type='message', role='assistant', model='claude-sonnet-5-5', stop_reason='end_turn',
                usage=dict(input_tokens=10, output_tokens=20),
                content=[dict(type='thinking', thinking='synthetic'), dict(type='text', text=output)])


class Bakeoff(unittest.TestCase):
    def setUp(self):
        self.claim, _, self.output = fixture()
        self.value = {'contract_version': '1.3', 'answer': self.claim['answer']}

    def adapters(self, mutate=None, raw=None, error=None):
        for cls, name in [(OpenAIPilot, 'pilot-openai-gpt56-sol-v1'),
                          (AnthropicPilot, 'pilot-anthropic-sonnet55-v1')]:
            data = envelope(cls.provider, json.dumps(self.output))
            if mutate: mutate(data)
            mock = MockTransport(raw if raw is not None else encoded(data), error)
            yield cls(name, 'mock-key', transport=mock), mock

    def test_schema_and_package_parity(self):
        png = b'\x89PNG\r\n\x1a\nfixture'
        verify_parity(self.value, [{'sha256': sha256(png).hexdigest(), 'bytes': png}])
        for adapter, _ in self.adapters():
            request = adapter.payload(self.value, [])
            self.assertNotIn('tools', request)
            self.assertNotIn('temperature', request)
            self.assertNotIn('cache_control', json.dumps(request))
            self.assertEqual(adapter.binding['contract_version'], '1.3')

    @unittest.skipUnless(Path(".local/essay-bakeoff-l2b/manifest.json").is_file(), "private accepted fixtures unavailable")
    def test_frozen_cases_parity_and_history(self):
        for case in CASES:
            value, images, claim, manifest = assemble(case)
            verify_parity(value, images)
            self.assertEqual(manifest['package_sha256'], digest(value))
            self.assertEqual(claim['input']['answer_hash'], sha256(value['answer'].encode()).hexdigest())
            self.assertFalse(manifest['prior_evaluation_supplied'])
            self.assertFalse(manifest['quality_label_supplied'])
            self.assertFalse(manifest['separate_reference_answer_supplied'])
            self.assertEqual(value['scaffolding_context']['items'], [])
            self.assertEqual(value['length_requirement']['source_image_sha256'],
                             images[value['length_requirement']['image_index']]['sha256'])
            # Frozen preparation must remain identical to reproducible input assembly.
            frozen = Path(' .local/essay-bakeoff-l2b'.strip())/case/'package.json'
            self.assertEqual(frozen.read_bytes(), encoded(value))

    def test_strict_parser_both(self):
        self.output['sentence_feedback'][0]['example'] = None
        for adapter, mock in self.adapters():
            result = adapter.evaluate(self.value)
            parsed = parse_provider(result.raw, self.claim)
            self.assertNotIn('example', parsed['sentence_feedback'][0])
            self.assertEqual(result.input_tokens, 10)
            self.assertEqual(result.output_tokens, 20)
            self.assertIsNone(result.cost_amount)
            self.assertEqual(result.total_tokens, 30 if adapter.provider == 'openai' else None)
            self.assertEqual(len(mock.calls), 1)
            self.assertEqual(mock.calls[0][1], 300)

    def test_no_real_transport_default_or_injection(self):
        adapter = OpenAIPilot('pilot-openai-gpt56-sol-v1', 'not-real')
        with self.assertRaisesRegex(Invalid, 'REAL_PROVIDER_NOT_AUTHORIZED'):
            adapter.evaluate(self.value)
        adapter.transport = lambda *a, **kw: self.fail('network must not run')
        with self.assertRaises(Invalid): adapter.evaluate(self.value)

    def test_policy_binding_before_call(self):
        with self.assertRaises(Invalid): OpenAIPilot('pilot-anthropic-sonnet55-v1', 'mock')
        with self.assertRaises(Invalid): policy('unapproved')
        for adapter, mock in self.adapters(mutate=lambda d: d.update(model='another-model')):
            with self.assertRaises(Invalid): adapter.evaluate(self.value)
            self.assertEqual(len(mock.calls), 1)

    def test_missing_and_secure_credential(self):
        for provider in CREDENTIAL_NAMES:
            name = CREDENTIAL_NAMES[provider]
            with self.assertRaises(Invalid): credential(provider, {})
            with self.assertRaises(Invalid): credential(provider, {name: 'a\nb'})
            with self.assertRaises(Invalid): credential(provider, {name: 'a', name+'_FILE': 'x'})
            with tempfile.TemporaryDirectory() as tmp:
                p = Path(tmp)/'mock-key'; p.write_text('synthetic-only'); p.chmod(0o600)
                self.assertEqual(credential(provider, {name+'_FILE': str(p)}), 'synthetic-only')
                p.chmod(0o644)
                with self.assertRaises(Invalid): credential(provider, {name+'_FILE': str(p)})
                link = Path(tmp)/'link'; link.symlink_to(p)
                with self.assertRaises(OSError): credential(provider, {name+'_FILE': str(link)})
        with self.assertRaises(Invalid): OpenAIPilot('pilot-openai-gpt56-sol-v1', '')

    def test_malformed_envelopes(self):
        for raw in [b'{}', b'[]', b'null', b'{"model":1,"model":2}', b'{"x":NaN}', b'not json', b'x'*262145]:
            for adapter, mock in self.adapters(raw=raw):
                with self.assertRaises(Invalid): adapter.evaluate(self.value)
                self.assertEqual(len(mock.calls), 1)
        for adapter, _ in self.adapters(mutate=lambda d: d.update(usage=[])):
            with self.assertRaises(Invalid): adapter.evaluate(self.value)

    def test_refusal_and_truncation_keep_usage(self):
        for value in ['refusal', 'max_tokens', 'incomplete']:
            for adapter, mock in self.adapters(mutate=lambda d: d.update(status=value, stop_reason=value)):
                with self.assertRaises(ProviderFailure) as ctx: adapter.evaluate(self.value)
                self.assertEqual(ctx.exception.usage.input_tokens, 10)
                self.assertEqual(len(mock.calls), 1)

    def test_transport_errors_no_retry(self):
        errors = [TimeoutError(), URLError('secret must not escape'),
                  HTTPError('https://test.invalid', 429, 'private', {}, None),
                  HTTPError('https://test.invalid', 503, 'private', {}, None)]
        for error in errors:
            for adapter, mock in self.adapters(error=error):
                with self.assertRaises((Unknown, ProviderFailure)) as ctx: adapter.evaluate(self.value)
                self.assertNotIn('private', str(ctx.exception))
                self.assertNotIn('secret', str(ctx.exception))
                self.assertEqual(len(mock.calls), 1)

    def test_invalid_usage(self):
        for values in [dict(input_tokens=True), dict(output_tokens=-1), dict(total_tokens=999),
                       dict(input_tokens=2**63), dict(cache_read_input_tokens=-1)]:
            for adapter, _ in self.adapters(mutate=lambda d: d['usage'].update(values)):
                with self.assertRaises(Invalid): adapter.evaluate(self.value)

    def test_anthropic_cache_usage_not_lost(self):
        for adapter, _ in self.adapters(mutate=lambda d: d['usage'].update(cache_read_input_tokens=5)):
            if adapter.provider == 'anthropic':
                r = adapter.evaluate(self.value)
                self.assertEqual(r.input_tokens, 15)
                self.assertIsNone(r.total_tokens)

    def test_contract_not_weakened(self):
        changes = [lambda o: o.update(uncertainty_note='old Pilot field'),
                   lambda o: o.update(local_reviews=[]),
                   lambda o: o['dimensions'][0].update(level=6),
                   lambda o: o['improvements'][0].update(claim_scope='Official_Criterion'),
                   lambda o: o['sentence_feedback'][0].update(quote='fabricated'),
                   lambda o: o.update(core_improvement_keys=['1','2','3','4']),
                   lambda o: o.update(sentence_feedback=o['sentence_feedback']*6)]
        for change in changes:
            self.output = fixture()[2]; change(self.output)
            for adapter, _ in self.adapters():
                with self.assertRaises(Invalid): parse_provider(adapter.evaluate(self.value).raw, self.claim)

    def test_private_freeze_and_exclusive_slot(self):
        for adapter, mock in self.adapters():
            with tempfile.TemporaryDirectory() as tmp:
                directory = Path(tmp)/'slot'
                report = offline_slot(directory, adapter, self.value, [], self.claim)
                self.assertEqual(report['status'], 'SCHEMA_VALID_UNREVIEWED')
                self.assertEqual(report['human_review'], 'NOT_RUN')
                self.assertNotIn('winner', report)
                self.assertNotIn(self.claim['answer'], encoded(report).decode())
                for p in directory.iterdir(): self.assertEqual(p.stat().st_mode & 0o777, 0o400)
                with self.assertRaises(FileExistsError): offline_slot(directory, adapter, self.value, [], self.claim)
                self.assertEqual(len(mock.calls), 1)

    def test_failure_freeze_no_retry(self):
        for raw in [b'{bad json', encoded(envelope('openai', '{}'))]:
            adapter, mock = next(self.adapters(raw=raw))
            with tempfile.TemporaryDirectory() as tmp:
                directory = Path(tmp)/'slot'
                report = offline_slot(directory, adapter, self.value, [], self.claim)
                self.assertEqual(report['status'], 'FAILED_NO_RETRY')
                self.assertEqual((directory/'raw-response.json').read_bytes(), raw)
                self.assertFalse((directory/'normalized.json').exists())
                with self.assertRaises(FileExistsError): offline_slot(directory, adapter, self.value, [], self.claim)
                self.assertEqual(len(mock.calls), 1)
        adapter, mock = next(self.adapters(error=TimeoutError()))
        with tempfile.TemporaryDirectory() as tmp:
            report = offline_slot(Path(tmp)/'slot', adapter, self.value, [], self.claim)
            self.assertEqual(report['status'], 'UNKNOWN_NO_RETRY')
            self.assertEqual(len(mock.calls), 1)

    def test_image_hash_and_symlink_protection(self):
        with self.assertRaises(Invalid): image_parts([dict(bytes=b'bad', sha256='0'*64)])
        for adapter, _ in self.adapters():
            with self.assertRaises(Invalid): adapter.payload(dict(self.value, image_sha256=['0'*64]), [])
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'original'; p.write_bytes(b'preserve')
            q=Path(tmp)/'link'; q.symlink_to(p)
            with self.assertRaises(FileExistsError): private_new(q, b'replace')
            self.assertEqual(p.read_bytes(), b'preserve')

if __name__ == '__main__': unittest.main()
