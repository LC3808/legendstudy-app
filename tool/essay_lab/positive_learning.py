"""L2-C2 opt-in provider-neutral prompt; no live activation on import."""
from hashlib import sha256
from pathlib import Path
from .live_worker import output_schema
PROMPT_VERSION = 'scaffolding-1.3-v3'
PROMPT = (Path(__file__).parent/'prompts'/f'{PROMPT_VERSION}.txt').read_text()
QUALITY_GATE = 'PROMPT_AND_CURATED_FIXTURE_PLUS_OWNER_REVIEW'

def prompt_contract():
    return dict(prompt_version=PROMPT_VERSION, prompt=PROMPT,
                prompt_sha256=sha256(PROMPT.encode()).hexdigest(),
                contract_version='1.3', schema=output_schema())
