"""Freeze two accepted blind inputs for L2-B. Offline only; never executes a model.
Reads only original inputs, accepted input manifests, and existing answer transcriptions.
No old model output/ground truth is read. File hashes prevent silent fixture replacement.
"""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import subprocess
from . import scaffolding_pilot_run_a as prior
from .bakeoff import (POLICIES, PILOT_PROMPT, PILOT_PROMPT_VERSION, policy, private_new,
                      OpenAIPilot, AnthropicPilot)
from .live_worker import encoded, digest, output_schema, require

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.local/essay-bakeoff-l2b'
CASES = ('sookmyung', 'hanyang')


def assemble(case):
    require(case in CASES, 'CASE_NOT_APPROVED')
    prompt, accepted, paths, original = prior.assemble(case)
    old = json.loads(prompt.split('\nINPUT:\n', 1)[1])
    context = dict(old['scaffolding_context'], items=[])
    images = [{'sha256': sha256(p.read_bytes()).hexdigest(), 'bytes': p.read_bytes()} for p in paths]
    # Visually verified against these already frozen official question images on 2026-09-30.
    # Do NOT import old rewrite target ranges as official tolerances.
    length = {'text': '300±30자' if case == 'sookmyung' else '1,200자',
              'evidence_id': 'Q', 'image_index': 1 if case == 'sookmyung' else 0,
              'source_image_sha256': images[1 if case == 'sookmyung' else 0]['sha256'],
              'verification': 'existing_official_question_image_checked',
              'transcription_count_is_not_grid_count': True}
    value = dict(contract_version='1.3', attempt_id='blind-attempt-' + case,
                 answer_hash=sha256(original).hexdigest(), answer=original.decode(),
                 criteria=old['criterion_labels'], criteria_note=old['criterion_note'],
                 official_evidence=old['official_evidence'], reference_catalog=old['reference_catalog'],
                 image_order=old['image_order'], image_sha256=[x['sha256'] for x in images],
                 scaffolding_context=context, length_requirement=length)
    require(all(term.lower() not in encoded(value).decode().lower() for term in prior.FORBIDDEN),
            'BLIND_INPUT_LEAKAGE')
    claim = {'answer': value['answer'], 'input': {
        'contract_version': '1.3', 'attempt_id': value['attempt_id'],
        'answer_hash': value['answer_hash'], 'criteria': [{'id': key, 'version': 1} for key in value['criteria']],
        'evidence': [{'id': key} for key in value['reference_catalog']], 'scaffolding_context': context}}
    manifest = dict(case=case, package_sha256=digest(value), answer_sha256=value['answer_hash'],
                    input_images=value['image_sha256'], accepted_input_hash=accepted['accepted_input_artifact_hash'],
                    prompt_sha256=sha256(PILOT_PROMPT.encode()).hexdigest(),
                    prompt_version=PILOT_PROMPT_VERSION, schema_sha256=digest(output_schema()),
                    contract_hashes=accepted['contract_hashes'], contract_version='1.3',
                    prior_evaluation_supplied=False, quality_label_supplied=False,
                    separate_reference_answer_supplied=False, original_image_and_transcription_preserved=True,
                    length_source_verified=True, database_identity=False)
    return value, images, claim, manifest


def verify_parity(value, images):
    # Request construction is pure: dummy credentials are never transmitted.
    a = OpenAIPilot('pilot-openai-gpt56-sol-v1', 'offline-only').payload(value, images)
    b = AnthropicPilot('pilot-anthropic-sonnet55-v1', 'offline-only').payload(value, images)
    require(a['instructions'] == b['system'] == PILOT_PROMPT, 'PROMPT_PARITY')
    ac, bc = a['input'][0]['content'], b['messages'][0]['content']
    require(ac[0]['text'] == bc[0]['text'] == encoded(value).decode(), 'PACKAGE_PARITY')
    require([x['image_url'].split(',', 1)[1] for x in ac[1:]] ==
            [x['source']['data'] for x in bc[1:]], 'IMAGE_PARITY')
    require(a['text']['format']['schema'] == b['output_config']['format']['schema'] == output_schema(),
            'SCHEMA_PARITY')


def prepare():
    # Fail closed if the intended private root ceases to be ignored.
    subprocess.run(['git', 'check-ignore', '-q', str(OUT/'manifest.json')], cwd=ROOT, check=True)
    values = {case: assemble(case) for case in CASES}
    for value, images, _, _ in values.values():
        verify_parity(value, images)
    OUT.mkdir(mode=0o700, exist_ok=False)  # Never overwrite a preparation or execution.
    manifests = []
    for case, (value, images, claim, manifest) in values.items():
        target = OUT/case
        target.mkdir(mode=0o700)
        for name, data in [('package.json', encoded(value)), ('validation-context.json', encoded(claim)),
                           ('manifest.json', encoded(manifest)), ('prompt.txt', PILOT_PROMPT.encode()),
                           ('schema.json', encoded(output_schema()))]:
            private_new(target/name, data)
        for index, image in enumerate(images):
            private_new(target/f'input_{index+1}.png', image['bytes'])
        manifests.append(manifest)
    summary = {'phase': 'L2-B', 'preparation': 'READY', 'real_ai_calls': 0,
               'execution_authorized': False, 'round1_planned_calls': 4, 'round2_planned_calls': 2,
               'policies': [policy(name) for name in POLICIES], 'packages': manifests,
               'contract_parity': 'PASS', 'evidence_parity': 'PASS',
               'round1_slots': [dict(case=c, policy=p, status='NOT_RUN', max_calls=1)
                                for c in CASES for p in POLICIES],
               'production_apply': False, 'production_ai': False, 'real_student_traffic': False}
    private_new(OUT/'manifest.json', encoded(summary))
    return summary


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--freeze', action='store_true', help='Offline exclusive private preparation only')
    args = parser.parse_args()
    if args.freeze:
        result = prepare()
    else:
        result = {'packages': [assemble(case)[3] for case in CASES], 'real_ai_calls': 0}
    print(json.dumps(result, ensure_ascii=False, indent=2))  # Hashes/config only.
