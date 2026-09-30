"""Offline opt-in prompt asset. No provider, policy registration, or worker activation.

Wire 1.3/parser/finalize remain authoritative. This module is deliberately not wired
into the historical worker or bake-off: a future approved experiment must freeze a
new prompt/package/policy binding. Importing it never inspects credentials/network.
"""
from hashlib import sha256
from pathlib import Path
from .live_worker import output_schema

PROMPT_VERSION = 'scaffolding-1.3-v2'
CONTRACT_VERSION = '1.3'
PROMPT = (Path(__file__).parent / 'prompts' / (PROMPT_VERSION + '.txt')).read_text()
ABSTRACT_FEEDBACK_GATE = 'PROMPT_AND_FIXTURE'


def prompt_contract():
    """Fresh schema + exact prompt identity for later offline package preparation."""
    return {'contract_version': CONTRACT_VERSION, 'prompt_version': PROMPT_VERSION,
            'prompt': PROMPT, 'prompt_sha256': sha256(PROMPT.encode()).hexdigest(),
            'schema': output_schema()}
