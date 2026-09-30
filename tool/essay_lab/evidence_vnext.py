"""Offline evidence sidecar preparation, NOT a new DB enum or live package adapter.

Reuse existing frozen reference ids/roles. Extra distinctions annotate the source;
examples stay reviewer-only. Current live_worker.package intentionally still accepts
only its four reviewed roles. This sidecar grants neither source verification nor
permission to disclose calibration answers to a future provider.
"""
from copy import deepcopy
from hashlib import sha256
from .live_worker import require, shape, text

VERSION = 'evidence-sidecar-review.1'
FACET_ROLES = {
    'question_displayed_length': {'question'},
    'scoring_length_rule': {'scoring_criteria'},
    'explicit_non_criterion': {'scoring_criteria'},
    'official_example_answer': {'official_example_answer'},
    'accepted_example_answer': {'accepted_student_example'},
}


def validate_sidecar(value, references):
    """Validate lineage/segregation only; official meaning needs source/human review.

references is an offline source inventory, not the live evidence allowlist. Its
example roles are conceptual future inventory labels, never production registration.
"""
    shape(value, 'version facets transcriptions')
    require(value['version'] == VERSION, 'SIDECAR_VERSION')
    require(type(references) is list and all(type(r) is dict for r in references), 'REFERENCES')
    require(all(type(r.get('id')) is str for r in references), 'REFERENCE_ID')
    by_id = {r['id']: r for r in references}
    require(len(by_id) == len(references), 'DUPLICATE_REFERENCE')
    require(type(value['facets']) is list and type(value['transcriptions']) is list, 'SIDECAR_ARRAY')
    ids = set()
    for f in value['facets']:
        shape(f, 'id kind source_id source_hash locator text usage')
        for k in ('id', 'kind', 'source_id', 'source_hash', 'locator', 'text', 'usage'): text(f[k])
        require(f['id'] not in ids, 'DUPLICATE_FACET'); ids.add(f['id'])
        require(f['kind'] in FACET_ROLES and f['source_id'] in by_id, 'FACET_SOURCE')
        r = by_id[f['source_id']]
        require(r.get('role') in FACET_ROLES[f['kind']] and r.get('hash') == f['source_hash'], 'FACET_BINDING')
        expected = 'calibration_only' if 'example' in f['kind'] else 'rule_context'
        require(f['usage'] == expected, 'EXAMPLE_NOT_RUBRIC')
    versions = {}
    for t in value['transcriptions']:
        shape(t, 'version text text_hash source_id source_hash prior_version reason reviewer reviewed_at')
        for k in ('version', 'text', 'text_hash', 'source_id', 'source_hash'): text(t[k])
        require(t['version'] not in versions and t['source_id'] in by_id, 'TRANSCRIPTION_ID')
        require(t['source_hash'] == by_id[t['source_id']].get('hash'), 'TRANSCRIPTION_SOURCE')
        require(t['text_hash'] == sha256(t['text'].encode()).hexdigest(), 'TRANSCRIPTION_HASH')
        p = t['prior_version']
        if p is not None:
            require(type(p) is str and p in versions and versions[p]['source_id'] == t['source_id'], 'CORRECTION_LINEAGE')
            for k in ('reason', 'reviewer', 'reviewed_at'): text(t[k])
        else:
            require(all(t[k] is None for k in ('reason', 'reviewer', 'reviewed_at')), 'INITIAL_NOT_CORRECTION')
        versions[t['version']] = t
    return deepcopy(value)
