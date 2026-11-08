"""Daily source reconciliation. Pure planner; no network or DB side effects.

The original parser/normalizer/UUID contracts remain authoritative. This planner
never rewrites existing taxonomy, exam metadata, slugs, or manual publication.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import re
from urllib.parse import urlsplit

from .apply import resolve, row_id, assert_no_signing_material
from .normalizer import normalize
from .parser import _PostParser, parse_html, normalize_post_url, classify_attachment


class ReviewRequired(ValueError):
    pass


def require(condition, code):
    if not condition:
        raise ReviewRequired(code)


def timestamp(value):
    if not value:
        return None
    if isinstance(value, datetime):
        result = value
    else:
        result = datetime.fromisoformat(value.replace('Z', '+00:00'))
    require(result.tzinfo is not None, 'timestamp_timezone_missing')
    return result.astimezone(timezone.utc)


def observe(post_id, html, observed_at):
    """Reject error pages, wrong redirects, truncation and unsupported files."""
    require(bool(re.search(r'</html\s*>', html, re.I)), 'incomplete_html')
    p = _PostParser()
    p.feed(html)
    require(any(marker in html for marker in p.ENTRY_MARKERS), 'article_missing')
    identities = [normalize_post_url(p.meta[k]) for k in
                  ('canonical', 'og:url', 'article:pc_view_url') if p.meta.get(k)]
    require(bool(identities) and all(x == f'https://legendstudy.com/{post_id}'
                                   for x in identities), 'source_identity_mismatch')
    raw = parse_html(post_id, html)
    require(bool(raw.title and raw.category and raw.published_at), 'metadata_missing')
    published = timestamp(raw.published_at)
    modified = timestamp(raw.updated_at)
    now = timestamp(observed_at)
    require(published <= now and (modified is None or published <= modified <= now),
            'source_clock_invalid')
    # Unknown binary attachment hrefs may not silently disappear from the plan.
    keys = {}
    for a in p.anchors:
        href = a['href']
        label = a['name'] or a['text'] or ''
        att = classify_attachment(href, label, a['size'])
        if att:
            require(att.provider == 'kakaocdn' or not urlsplit(href).query, 'provider_query_review')
            prior = keys.get(att.resource_key)
            require(prior is None or prior == (att.unsigned_url, att.display_name),
                    'duplicate_attachment_identity')
            keys[att.resource_key] = (att.unsigned_url, att.display_name)
        elif re.search(r'\.(pdf|hwp|hwpx|zip|mp3)(?:[?#]|$)', href+' '+label, re.I):
            raise ReviewRequired('unsupported_attachment_provider')
    require(len(keys) == len(raw.attachments), 'attachment_parse_mismatch')
    # Every modern fileblock must close and yield a recognized attachment.
    opened = re.findall(r'<figure\b[^>]*class=["\'][^"\']*fileblock[^"\']*["\']', html, re.I)
    closed = re.findall(r'<figure\b[^>]*class=["\'][^"\']*fileblock[^"\']*["\'][^>]*>(.*?)</figure\s*>', html, re.I | re.S)
    require(len(opened) == len(closed), 'incomplete_fileblock')
    for block in closed:
        links = re.findall(r'href=["\']([^"\']+)', block, re.I)
        require(any((a := classify_attachment(href, '', None)) is not None
                    and a.resource_key in keys for href in links), 'unparsed_fileblock')
    plan = normalize(raw, observed_at, map_subjects=True)
    require(plan.publishable, 'classification_review')
    resolved = resolve(plan)
    assert_no_signing_material([resolved])
    for r in resolved.resources:
        u = urlsplit(r['source_url'])
        require(u.scheme == 'https' and not u.query and not u.fragment,
                'unsafe_resource_locator')
    return resolved


@dataclass
class Change:
    table: str
    key: str
    before: dict | None
    after: dict


SOURCE_FIELDS = ('title', 'category', 'source_published_at', 'source_updated_at',
                 'content_hash', 'parser_version', 'last_crawled_at', 'source_status')
CONTENT_FIELDS = ('title', 'published_at', 'source_updated_at')
RESOURCE_FIELDS = ('title', 'source_label', 'source_url', 'resource_type',
                   'file_extension', 'display_order')
TIME_FIELDS = {'published_at', 'source_published_at', 'source_updated_at', 'last_crawled_at'}


def equal(a, b, key):
    return timestamp(a) == timestamp(b) if key in TIME_FIELDS else a == b


def patch(table, old, new, fields):
    changed = {k: new[k] for k in fields if not equal(old.get(k), new.get(k), k)}
    return [] if not changed else [Change(table, str(old['id']),
                                          {k: old.get(k) for k in changed}, changed)]


def reconcile(post, current, *, new_since, confirmed_hash=None, managed_removed=()):
    """Produce one atomic source batch. Current uses live UUIDs, not assumed IDs.

    Removed active attachments need two complete matching fetches. Inactive rows
    stay inactive unless THIS pipeline previously removed them. Missing source,
    ambiguous taxonomy, inactive/merged parents and incomplete state fail closed.
    """
    if current is None:
        require(timestamp(post.source_post['source_published_at']) > timestamp(new_since),
                'historical_backfill_excluded')
        if post.exam:
            require('모의고사 전과목 자료' in (post.source_post['category'] or ''),
                    'new_exam_full_set_required')
            labels = {o['source_subject_key'] for o in post.occurrences}
            require(any('국어' in s for s in labels) and any('수학' in s for s in labels)
                    and any('영어' in s for s in labels), 'new_exam_incomplete')
        rows = [('source_posts', post.source_post), ('content_items', post.content_item)]
        if post.exam:
            rows.append(('exams', post.exam))
        rows += [('exam_subjects', r) for r in post.occurrences]
        rows += [('resources', r) for r in post.resources]
        result = []
        for table, row in rows:
            row = dict(row)
            if 'is_active' in row:
                row['is_active'] = True
            result.append(Change(table, str(row.get('id') or row['content_item_id']), None, row))
        return result

    source = current['source_posts'][0]
    parents = current['content_items']
    require(len(parents) == 1, 'multi_parent_review')
    parent = parents[0]
    require(parent['is_active'] and not parent.get('merged_into_content_item_id'),
            'parent_publication_hold')
    require(parent['source_content_key'] == 'main' and
            parent['content_type'] == post.content_item['content_type'], 'parent_type_changed')
    require(source['source'] == 'legendstudy' and
            source['external_post_id'] == post.external_post_id, 'source_identity_changed')
    require(not source.get('source_updated_at') or not post.source_post.get('source_updated_at')
            or timestamp(post.source_post['source_updated_at']) >= timestamp(source['source_updated_at']),
            'source_clock_regression')
    if post.exam:
        exams = current['exams']
        require(len(exams) == 1 and all(exams[0][k] == post.exam[k] for k in
                ('year', 'academic_year', 'exam_month', 'grade_level', 'exam_type')),
                'exam_metadata_changed')
    old_occ = {o['source_subject_key']: o for o in current['exam_subjects']}
    mapped = {}
    changes = []
    for occ in post.occurrences:
        old = old_occ.get(occ['source_subject_key'])
        if old:
            require(old['is_active'], 'subject_publication_hold')
            require(str(old.get('subject_id') or '') == str(occ.get('subject_id') or ''),
                    'subject_mapping_changed')
            mapped[occ['id']] = str(old['id'])
        else:
            row = dict(occ, id=row_id('exam_subject', str(parent['id']), occ['source_subject_key']),
                       content_item_id=str(parent['id']), is_active=True)
            mapped[occ['id']] = row['id']
            changes.append(Change('exam_subjects', row['id'], None, row))
    old_resources = {r['source_resource_key']: r for r in current['resources']}
    require(len(old_resources) == len(current['resources']), 'existing_duplicate_identity')
    desired = set()
    normalized_urls = set()
    for r in post.resources:
        row = dict(r, content_item_id=str(parent['id']), source_post_id=str(source['id']),
                   exam_subject_id=mapped.get(r['exam_subject_id']))
        require(row['source_url'] not in normalized_urls, 'duplicate_resource_locator')
        normalized_urls.add(row['source_url'])
        key = row['source_resource_key']
        desired.add(key)
        old = old_resources.get(key)
        if old:
            require(str(old['content_item_id']) == str(parent['id']) and
                    str(old.get('exam_subject_id') or '') == str(row.get('exam_subject_id') or ''),
                    'resource_scope_changed')
            fields = list(RESOURCE_FIELDS)
            if old['source_url'] != row['source_url']:
                fields += ['file_url', 'mime_type', 'file_size', 'link_status',
                           'last_checked_at', 'link_kind']
            if not old['is_active'] and str(old['id']) in managed_removed:
                row['is_active'] = True
                fields.append('is_active')
            changes += patch('resources', old, row, fields)
        else:
            row['id'] = row_id('resource', str(parent['id']), str(source['id']), key)
            row['is_active'] = True
            changes.append(Change('resources', row['id'], None, row))
    removed = [r for key, r in old_resources.items() if key not in desired and r['is_active']]
    require(not removed or confirmed_hash == post.source_post['content_hash'],
            'removal_needs_second_observation')
    for r in removed:
        changes.append(Change('resources', str(r['id']), {'is_active': True}, {'is_active': False}))
    # Never fabricate source time; absent modified time preserves prior evidence.
    source_new = dict(post.source_post)
    content_new = dict(post.content_item)
    if not source_new['source_updated_at']:
        source_new['source_updated_at'] = source.get('source_updated_at')
        content_new['source_updated_at'] = parent.get('source_updated_at')
    changes += patch('content_items', parent, content_new, CONTENT_FIELDS)
    changes += patch('source_posts', source, source_new, SOURCE_FIELDS)
    return changes
