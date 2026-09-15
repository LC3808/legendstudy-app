"""Source-post parsing: HTML or extracted record -> observed raw facts.

Two generations of attachment markup exist on legendstudy.com and both are
supported:

  modern  (post id >= ~1481, 2021-06 onward)
          <figure class="fileblock"><a href="https://blog.kakaocdn.net/dna/
          {s1}/{s2}/{s3}/{name}?credential=..&expires=..&signature=..">
          The query string is a site-wide rolling signature. It is never kept.

  legacy  (post id <= ~1475)
          <a href="https://t1.daumcdn.net/cfile/tistory/{HEXID}">{name}</a>
          No query string; the path alone is the stable identity.

Exam identity is parsed from the post title and category only. Attachment
filenames carry too many prefix generations ('2026년 5월 고3_', '2024_5월_',
'25학년도 9월 모평_', '2021-4월-') to be a trustworthy identity source; they
are used for subject and resource kind only.
"""
from __future__ import annotations

import re
from html import unescape
from html.parser import HTMLParser
from urllib.parse import urlsplit, urlunsplit

from .models import RawAttachment, RawPost
from .taxonomy import (
    EXAM_TYPE_TOKENS, GRADE_SPACE, GROUP_PREFIXES, HISTORICAL_SUBJECT_TOKENS,
    RESOURCE_KIND_TOKENS, SUBJECT_TOKENS, clean,
)

KAKAO_RE = re.compile(r'^https?://blog\.kakaocdn\.net/dna/([^/]+)/([^/]+)/', re.I)
CFILE_RE = re.compile(r'^https?://[a-z0-9.]*daumcdn\.net/cfile/tistory/([A-Za-z0-9]+)', re.I)
BOX_RE = re.compile(r'^https?://(?:app\.)?box\.com/s/([A-Za-z0-9]+)', re.I)
GDRIVE_RE = re.compile(r'^https?://(?:drive|docs)\.google\.com/\S*?([-\w]{20,})', re.I)
SIGNED_PARAMS = ('credential', 'signature', 'expires', 'attach', 'knm',
                 'allow_ip', 'allow_referer')


def strip_query(url: str) -> tuple[str, bool]:
    """Return (url without query/fragment, whether a signing query was present)."""
    parts = urlsplit(url)
    signed = any(f'{p}=' in parts.query for p in SIGNED_PARAMS)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, '', '')), signed


def canonical_post_url(post_id: str) -> str:
    return f'https://legendstudy.com/{post_id}'


def normalize_post_url(url: str) -> str | None:
    """Reduce any observed post location to the canonical numeric form.

    Handles trailing slashes, the /m/ mobile path and the coroico.tistory.com
    origin, all of which appear in the page's own metadata.
    """
    parts = urlsplit(url.strip())
    host = parts.netloc.lower()
    if host not in ('legendstudy.com', 'www.legendstudy.com', 'coroico.tistory.com'):
        return None
    path = parts.path.rstrip('/')
    if path.startswith('/m/'):
        path = path[2:]
    m = re.fullmatch(r'/(\d+)', path)
    return canonical_post_url(m.group(1)) if m else None


def classify_attachment(href: str, text: str, size: str | None) -> RawAttachment | None:
    """Map an observed href to a provider identity, or None if not an attachment."""
    unsigned, signed = strip_query(href)
    m = KAKAO_RE.match(href)
    if m:
        return RawAttachment('kakaocdn', f'{m.group(1)}/{m.group(2)}',
                             clean(text), unsigned, signed, size)
    m = CFILE_RE.match(href)
    if m:
        return RawAttachment('cfile', m.group(1), clean(text), unsigned, signed, size)
    m = BOX_RE.match(href)
    if m:
        return RawAttachment('box', f'box:{m.group(1)}', clean(text), unsigned, signed, size)
    m = GDRIVE_RE.match(href)
    if m:
        return RawAttachment('gdrive', f'gdrive:{m.group(1)}', clean(text), unsigned, signed, size)
    return None


class _PostParser(HTMLParser):
    """Minimal Tistory reader: og/article meta, category path, entry anchors."""

    ENTRY_MARKERS = ('tt_article_useless_p_margin', 'contents_style')

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.meta: dict[str, str] = {}
        self.category_paths: list[str] = []
        self.anchors: list[dict] = []
        self.body_text: list[str] = []
        self._depth = 0          # nesting depth inside the entry container
        self._entry_depth = 0
        self._a: dict | None = None
        self._span: str | None = None

    # -- helpers
    @staticmethod
    def _attr(attrs, name):
        for k, v in attrs:
            if k == name:
                return v or ''
        return None

    @property
    def _in_entry(self) -> bool:
        return self._entry_depth > 0

    def handle_starttag(self, tag, attrs):
        if tag == 'meta':
            key = self._attr(attrs, 'property') or self._attr(attrs, 'name')
            if key:
                self.meta[key] = self._attr(attrs, 'content') or ''
            return
        if tag == 'link' and self._attr(attrs, 'rel') == 'canonical':
            self.meta['canonical'] = self._attr(attrs, 'href') or ''
            return

        cls = self._attr(attrs, 'class') or ''
        if tag == 'a':
            href = self._attr(attrs, 'href') or ''
            if '/category/' in href:
                self.category_paths.append(href)
            if self._in_entry:
                self._a = {'href': href, 'text': [], 'name': None, 'size': None}

        if self._in_entry:
            self._depth += 1
            if tag == 'span' and 'name' in cls.split():
                self._span = 'name'
            elif tag == 'div' and 'size' in cls.split():
                self._span = 'size'
        elif tag == 'div' and any(m in cls for m in self.ENTRY_MARKERS):
            self._entry_depth = 1
            self._depth = 1

    def handle_endtag(self, tag):
        if tag == 'a' and self._a is not None:
            self._a['text'] = clean(''.join(self._a['text']))
            self.anchors.append(self._a)
            self._a = None
        if tag in ('span', 'div'):
            self._span = None
        if self._in_entry:
            self._depth -= 1
            if self._depth <= 0:
                self._entry_depth = 0

    def handle_data(self, data):
        if not self._in_entry:
            return
        self.body_text.append(data)
        if self._a is not None:
            if self._span == 'name':
                self._a['name'] = clean(data)
            elif self._span == 'size':
                self._a['size'] = clean(data)
            else:
                self._a['text'].append(data)


def parse_html(post_id: str, html: str) -> RawPost:
    """Parse one fetched post page into observed raw facts."""
    p = _PostParser()
    p.feed(html)
    meta = p.meta
    category = None
    for href in p.category_paths:
        from urllib.parse import unquote
        path = clean(unquote(href).replace('/category/', ''))
        if path and (category is None or len(path) > len(category)):
            category = path

    attachments: list[RawAttachment] = []
    seen: set[str] = set()
    for a in p.anchors:
        label = a['name'] or a['text'] or ''
        att = classify_attachment(unescape(a['href']), label, a['size'])
        if att and att.resource_key not in seen:
            seen.add(att.resource_key)
            attachments.append(att)

    return RawPost(
        external_post_id=str(post_id),
        url=canonical_post_url(post_id),
        title=clean(meta.get('og:title') or ''),
        category=category,
        published_at=meta.get('article:published_time') or None,
        updated_at=meta.get('article:modified_time') or None,
        attachments=tuple(attachments),
        body_excerpt=clean(''.join(p.body_text))[:900] or None,
    )


def parse_record(record: dict) -> RawPost:
    """Parse one row of the offline survey sample (tool/ingestion/samples)."""
    prefix = record.get('x', '')
    names = [prefix + s for s in record.get('s', [])]
    keys = record.get('k', [])
    attachments = []
    for idx, name in enumerate(names):
        key = keys[idx] if idx < len(keys) else ''
        provider = 'kakaocdn' if '/' in key else 'cfile'
        attachments.append(RawAttachment(
            provider=provider,
            resource_key=key,
            display_name=clean(name),
            unsigned_url=(f'https://blog.kakaocdn.net/dna/{key}/x/{name}'
                          if provider == 'kakaocdn'
                          else f'https://t1.daumcdn.net/cfile/tistory/{key}'),
            had_signed_query=(provider == 'kakaocdn'),
        ))
    return RawPost(
        external_post_id=str(record['i']),
        url=canonical_post_url(record['i']),
        title=clean(record.get('t', '')),
        category=clean(record.get('c', '')) or None,
        published_at=record.get('p') or None,
        updated_at=record.get('m') or record.get('p') or None,
        attachments=tuple(attachments),
    )


# --- filename parsing ----------------------------------------------------

def split_resource_kind(filename: str) -> tuple[str, str | None, str]:
    """Return (left part, canonical resource_type, raw kind label).

    The kind is always the tail of the name. Longest token wins so that
    '정답,해설' is not read as '해설'.
    """
    base = clean(re.sub(r'\.[A-Za-z0-9]{2,5}$', '', filename))
    best: tuple[int, str, str] | None = None
    for token, canonical in RESOURCE_KIND_TOKENS:
        if base.endswith(token):
            score = len(token)
            if best is None or score > best[0]:
                best = (score, canonical, token)
    if best is None:
        return base, None, ''
    left = clean(base[: len(base) - len(best[2])].rstrip(' _-'))
    return left, best[1], best[2]


def _is_hangul(ch: str) -> bool:
    return '\uac00' <= ch <= '\ud7a3' or '\u1100' <= ch <= '\u11ff' or '\u3130' <= ch <= '\u318f'


def _tail_match(text: str, token: str) -> bool:
    """Token must end the text AND start at a word boundary.

    Without the boundary rule the source typo '생화활과윤리' would end with the
    historical subject '윤리' and silently become a 윤리 occurrence. A token may
    only start the text or follow a separator / non-Hangul character.
    """
    if not text.endswith(token):
        return False
    head = text[: len(text) - len(token)]
    return not head or not _is_hangul(head[-1])


def split_subject(left: str) -> tuple[str | None, bool]:
    """Return (raw subject label, is_historical) from the left part of a filename."""
    text = clean(left)
    for prefix in GROUP_PREFIXES:
        idx = text.rfind(prefix)
        if idx >= 0:
            text = clean(text[idx + len(prefix):])
            break
    # Longest match across both vocabularies at once. Matching historical
    # tokens first would read '한국사' as the historical '국사', and matching
    # modern tokens first would read '한국근현대사' as '한국사'.
    best: tuple[int, str, bool] | None = None
    for token in SUBJECT_TOKENS:
        if _tail_match(text, token) and (best is None or len(token) > best[0]):
            best = (len(token), token, False)
    for token in HISTORICAL_SUBJECT_TOKENS:
        if _tail_match(text, token) and (best is None or len(token) > best[0]):
            best = (len(token), token, True)
    if best is None:
        return None, False
    return best[1], best[2]


# --- title parsing -------------------------------------------------------

ADMIN_PREFIX = re.compile(r'[\[(]\s*(\d{4})\s*년\s*(\d{1,2})\s*월\s*시행\s*[\])]')
ACADEMIC_YEAR = re.compile(r'(\d{4})\s*학년도')
SHORT_ACADEMIC_YEAR = re.compile(r'(?<!\d)(\d{2})\s*학년도')
CALENDAR_YEAR = re.compile(r'(?<!\d)((?:19|20)\d{2})\s*년?(?!\s*학년도)')
NOMINAL_MONTH = re.compile(r'(?<!\d)(1[0-2]|[1-9])\s*월')
GRADE_IN_TITLE = re.compile(r'고\s*([123])(?!\d)')


def parse_title(title: str, category: str | None) -> dict:
    """Extract observed exam facts. Values are None when not stated."""
    text = clean(title)
    cat = clean(category or '')
    facts: dict = {
        'raw_title': text,
        'raw_category': cat or None,
        'administered_year': None,
        'administered_month': None,
        'calendar_year': None,
        'academic_year_label': None,
        'academic_year': None,
        'nominal_month': None,
        'grade_level': None,
        'raw_grade_label': None,
        'exam_type': None,
        'raw_exam_type': None,
    }

    m = ADMIN_PREFIX.search(text)
    remainder = text
    if m:
        facts['administered_year'] = int(m.group(1))
        facts['administered_month'] = int(m.group(2))
        facts['calendar_year'] = int(m.group(1))
        remainder = clean(text[: m.start()] + ' ' + text[m.end():])

    am = ACADEMIC_YEAR.search(remainder) or ACADEMIC_YEAR.search(text)
    if am:
        facts['academic_year_label'] = am.group(0)
        facts['academic_year'] = int(am.group(1))
    else:
        sm = SHORT_ACADEMIC_YEAR.search(remainder)
        if sm:
            facts['academic_year_label'] = sm.group(0)
            facts['academic_year'] = 2000 + int(sm.group(1))

    if facts['calendar_year'] is None:
        scan = ACADEMIC_YEAR.sub(' ', remainder)
        cy = CALENDAR_YEAR.search(scan)
        if cy:
            facts['calendar_year'] = int(cy.group(1))

    # Nominal month: the month a student would search for. Scanned after the
    # '시행' prefix is removed so a postponed sitting keeps both values.
    scan = ACADEMIC_YEAR.sub(' ', remainder)
    nm = NOMINAL_MONTH.search(scan)
    if nm:
        facts['nominal_month'] = int(nm.group(1))

    gm = GRADE_IN_TITLE.search(text)
    if gm:
        facts['grade_level'] = int(gm.group(1))
        facts['raw_grade_label'] = gm.group(0)
    else:
        cm = GRADE_SPACE.search(cat)
        if cm:
            facts['grade_level'] = int(cm.group(1))
            facts['raw_grade_label'] = cm.group(0)
        elif re.search(r'([123])\s*학년', cat):
            g = re.search(r'([123])\s*학년', cat)
            facts['grade_level'] = int(g.group(1))
            facts['raw_grade_label'] = g.group(0)

    for token, canonical in EXAM_TYPE_TOKENS:
        if token in text:
            facts['exam_type'] = canonical
            facts['raw_exam_type'] = token
            break
    return facts
