"""Offline review-fragment oracle only. Not a provider/RPC/production validator.

Checks the proposed binding/count/provenance/history semantics against trusted synthetic
context. It cannot prove diagnosis truth, stance preservation or priority quality.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CONTRACT = ROOT / 'tool/essay_lab/evidence/evaluation_contract_v1_3.review.json'


def contract():
    return json.loads(CONTRACT.read_text())


def check(condition, reason):
    if not condition:
        raise ValueError(reason)


def nonblank(value):
    return isinstance(value, str) and bool(value.strip())


def validate_fragment(output, context):
    """Context is server-owned; all values in fixtures are synthetic, no live DB."""
    c = contract()
    check(output['version'] == c['version'], 'contract')
    check(hashlib.sha256(context['answer'].encode()).hexdigest() == context['answer_hash'], 'source hash')
    improvements = output['improvements']
    issues = {x['issue_key']: x for x in improvements}
    check(len(issues) == len(improvements), 'duplicate root')
    core = output['core_improvement_keys']
    check(len(core) <= c['core_focus']['default_maximum'] and len(core) == len(set(core)), 'core count')
    check(all(k in issues for k in core), 'core link')
    check(all(issues[k]['status'] != 'resolved' for k in core), 'resolved is not active focus')
    sentences = output['sentence_feedback']
    check(len(sentences) <= c['sentence_feedback']['maximum'], 'sentence count')
    seen_ids, seen_spans = set(), set()
    for s in sentences:
        required = set(c['sentence_feedback']['fields']) - {'example'}
        check(required <= set(s) <= required | {'example'}, 'sentence fields')
        check(s['linked_issue_key'] in issues, 'sentence root link')
        check(s['category'] in c['sentence_feedback']['categories'], 'category')
        check(s['priority'] in c['sentence_feedback']['priority_order'], 'priority')
        check(all(nonblank(s[k]) for k in ('observation_key','quote','diagnosis','direction')), 'blank')
        check('example' not in s or nonblank(s['example']), 'optional example')
        start, end = s['start'], s['end']
        check(type(start) is int and type(end) is int and 0 <= start < end <= len(context['answer']), 'offset')
        check(context['answer'][start:end] == s['quote'], 'exact quote')
        check(s['observation_key'] not in seen_ids and (start,end) not in seen_spans, 'duplicate observation')
        seen_ids.add(s['observation_key']); seen_spans.add((start,end))
    for key, item in issues.items():
        check(nonblank(key), 'issue key')
        refs = item['evidence_ids']
        check(set(refs) <= set(context['evidence_ids']), 'official evidence membership')
        linked = [s for s in sentences if s['linked_issue_key'] == key]
        scope = item['claim_scope']
        check(scope in ('official_criterion','local_sentence'), 'claim scope')
        if scope == 'official_criterion':
            check(bool(refs), 'official evidence required')
        else:
            check(key in context.get('approved_local_issue_keys', []), 'trusted local classification')
            prior = context['previous'].get(item.get('previous_progress_id'), {})
            resolved_local = item['status'] == 'resolved' and prior.get('verified_local_quote') is True
            check(bool(linked) or resolved_local, 'narrow local exception')
        # A local enum cannot establish semantic eligibility; separate trusted review remains.
    previous = context['previous']
    reviews = output['previous_improvement_reviews']
    ids = [x['previous_progress_id'] for x in reviews]
    required = {k for k,v in previous.items() if v['core']}
    check(len(ids) == len(set(ids)) and required <= set(ids) <= set(previous), 'previous coverage')
    linked_priors = [x['previous_progress_id'] for x in improvements if x.get('previous_progress_id')]
    check(len(linked_priors) == len(set(linked_priors)) and set(linked_priors) <= set(ids), 'progress predecessors')
    for review in reviews:
        prior = previous[review['previous_progress_id']]
        outcome = review['outcome']
        check(outcome in c['previous_review']['outcomes'] and nonblank(review['reason']), 'review outcome')
        linked = [x for x in improvements if x.get('previous_progress_id') == review['previous_progress_id']]
        if outcome == 'not_assessable':
            check(not linked and nonblank(output.get('uncertainty_note')), 'unknown must not assert progress')
            continue
        check(len(linked) == 1 and linked[0]['issue_key'] == prior['issue_key'], 'history root link')
        check(linked[0]['status'] == outcome, 'history status')
        if outcome == 'recurred':
            check(prior['status'] == 'resolved', 'recurrence requires resolution')
    return True
