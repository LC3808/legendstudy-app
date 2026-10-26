import copy
import unittest
from uuid import UUID

from tool.cloudflare_essay.pages_scope_patch import public_scope_patch


class PagesScopePatchTest(unittest.TestCase):
    def test_redacted_secrets_and_preview_are_never_replayed(self):
        first, second = str(UUID(int=1)), str(UUID(int=2))
        current = {'deployment_configs': {
            'production': {'env_vars': {
                'ESSAY_PUBLIC_EXAMS': {'type': 'plain_text', 'value': first},
                'ESSAY_REGISTRY_WORKER_JWT': {'type': 'secret_text', 'value': ''},
                'PAYMENT_FINANCE_TOKEN': {'type': 'secret_text', 'value': ''},
            }, 'services': {'existing': {'service': 'unchanged'}}},
            'preview': {'env_vars': {'unrelated': {'type': 'plain_text', 'value': 'keep'}}},
        }}
        before = copy.deepcopy(current)
        patch = public_scope_patch(current, [second, first])
        self.assertEqual(current, before)
        self.assertEqual(patch, {'deployment_configs': {'production': {'env_vars': {
            'ESSAY_PUBLIC_EXAMS': {'type': 'plain_text', 'value': first + ',' + second}
        }}}})

    def test_large_scope_preserves_exact_ids_and_never_replays_secrets(self):
        from essay_lab.cloudflare_http import parse_public_exams
        ids = [str(UUID(int=i)) for i in range(1, 182)]
        current = {'deployment_configs': {'production': {'env_vars': {
            'ESSAY_PUBLIC_EXAMS': {'type': 'plain_text', 'value': ','.join(ids[:147])},
            'SECRET': {'type': 'secret_text', 'value': ''}
        }}}}
        env = public_scope_patch(current, ids[147:])['deployment_configs']['production']['env_vars']
        self.assertEqual(list(env), ['ESSAY_PUBLIC_EXAMS'])
        raw = env['ESSAY_PUBLIC_EXAMS']['value']
        self.assertTrue(raw.startswith('uuid64:'))
        self.assertLess(len(raw), 5000)
        self.assertEqual(parse_public_exams(raw), ids)
        current['deployment_configs']['production']['env_vars']['ESSAY_PUBLIC_EXAMS']['value'] = raw
        self.assertEqual(public_scope_patch(current, ids[-1:])['deployment_configs']['production']['env_vars'], env)

    def test_invalid_or_over_limit_scope_fails_closed(self):
        current = {'deployment_configs': {'production': {'env_vars': {
            'ESSAY_PUBLIC_EXAMS': {'type': 'plain_text', 'value': str(UUID(int=1))}
        }}}}
        with self.assertRaises(ValueError):
            public_scope_patch(current, ['not-a-uuid'])
        with self.assertRaisesRegex(ValueError, 'CURRENT_RUNTIME_SCOPE_LIMIT'):
            public_scope_patch(current, [str(UUID(int=i)) for i in range(1, 258)])


if __name__ == '__main__':
    unittest.main()
