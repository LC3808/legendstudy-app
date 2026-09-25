"""Polite source access.

robots.txt observed 2026-09-15: `User-agent: *` disallows /guestbook, /manage,
/owner, /admin, /search, /m/search; numeric post paths and /sitemap.xml are
allowed. `bingbot` carries `Crawl-delay: 20`; no directive targets `*`, so this
crawler applies its own conservative default delay.

Network access is optional. The offline sample source reads the extracted
records committed under `tool/ingestion/samples/` so parser work, tests and
dry-runs never require the site to be reachable.
"""
from __future__ import annotations

import json
import re
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from xml.etree import ElementTree
from pathlib import Path
from typing import Callable
from urllib.parse import urlsplit

from . import SITE_ORIGIN
from .models import RawPost
from .parser import parse_html, parse_record

# Conventional single-comment crawler UA. The earlier value carried extra
# free text and semicolons inside the comment; Tistory's edge answered 406 to
# it. Keep the shape "<name>/<version> (+<url>)".
USER_AGENT = 'LegendStudyIngest/0.1 (+https://legendstudy.com)'
# Accept must name the type the resource is actually served as and still end in
# a wildcard. sitemap.xml is served as text/xml, which the previous header
# (text/html, application/xhtml+xml, application/xml — no text/xml, no */*)
# did not cover, so strict content negotiation rejected the request.
ACCEPT_HTML = ('text/html,application/xhtml+xml,application/xml;q=0.9,'
               'text/xml;q=0.9,*/*;q=0.8')
ACCEPT_XML = ('application/xml,text/xml,application/rss+xml;q=0.9,'
              'application/xhtml+xml;q=0.8,text/html;q=0.7,*/*;q=0.5')
DEFAULT_DELAY_SECONDS = 1.5
DEFAULT_TIMEOUT_SECONDS = 20
DEFAULT_MAX_RETRIES = 2
DISALLOWED_PREFIXES = ('/guestbook', '/m/guestbook', '/manage', '/owner',
                       '/admin', '/search', '/m/search')
POST_URL = re.compile(r'^https://legendstudy\.com/(\d+)$')
LOC = re.compile(r'<loc>\s*([^<\s]+)\s*</loc>', re.I)


@dataclass(frozen=True)
class SitemapEntry:
    """Numeric source identity plus optional discovery-only lastmod hint."""
    external_post_id: str
    lastmod: str | None = None


class FetchError(Exception):
    """Transport-level failure. Distinct from a malformed-source parse failure."""

    def __init__(self, url: str, reason: str, transient: bool) -> None:
        super().__init__(f'{url}: {reason}')
        self.url = url
        self.reason = reason
        self.transient = transient


class BudgetExceeded(RuntimeError):
    """Raised before an attempt would exceed the hard per-run ceiling."""


@dataclass
class RequestBudget:
    """Attempt-level request accounting shared by discovery and retries."""
    ceiling: int = 24
    requests: int = 0
    retries: int = 0

    def reserve(self, request_label: str, *, retry: bool = False) -> None:
        if self.requests >= self.ceiling:
            raise BudgetExceeded(request_label)
        self.requests += 1
        if retry:
            self.retries += 1

    @property
    def remaining(self) -> int:
        return max(0, self.ceiling - self.requests)

    def as_dict(self) -> dict:
        return {
            'ceiling': self.ceiling,
            'requests': self.requests,
            'retries': self.retries,
            'remaining': self.remaining,
        }


def robots_allows(path: str) -> bool:
    return not any(path.startswith(p) for p in DISALLOWED_PREFIXES)


@dataclass
class FetchStats:
    requests: int = 0
    retries: int = 0
    failures: int = 0
    bytes_read: int = 0


class PoliteFetcher:
    """Serial fetcher with a fixed minimum interval and bounded retries.

    No parallelism: the site is the owner's own small blog and a dry-run has no
    reason to add load. One request at a time, `delay` seconds apart.
    """

    def __init__(self, delay: float = DEFAULT_DELAY_SECONDS,
                 timeout: int = DEFAULT_TIMEOUT_SECONDS,
                 max_retries: int = DEFAULT_MAX_RETRIES,
                 max_requests: int | None = None,
                 request_budget: RequestBudget | None = None,
                 on_retry: Callable[[str, int, str], None] | None = None) -> None:
        self.delay = delay
        self.timeout = timeout
        self.max_retries = max_retries
        self.max_requests = max_requests
        self.request_budget = request_budget
        self.on_retry = on_retry
        self.stats = FetchStats()
        self._last = 0.0

    def _wait(self) -> None:
        gap = time.monotonic() - self._last
        if gap < self.delay:
            time.sleep(self.delay - gap)
        self._last = time.monotonic()

    def get(self, url: str, accept: str = ACCEPT_HTML,
            request_label: str = 'request') -> str:
        path = urlsplit(url).path or '/'
        if not robots_allows(path):
            raise FetchError(url, 'blocked by robots.txt', transient=False)

        attempt = 0
        while True:
            if self.max_requests is not None and self.stats.requests >= self.max_requests:
                raise FetchError(url, 'run request budget exhausted', transient=False)
            try:
                if self.request_budget is not None:
                    self.request_budget.reserve(request_label, retry=attempt > 0)
            except BudgetExceeded as exc:
                raise FetchError(url, 'run request budget exhausted', transient=False) from exc
            self._wait()
            self.stats.requests += 1
            req = urllib.request.Request(url, headers={
                'User-Agent': USER_AGENT,
                'Accept': accept,
                'Accept-Language': 'ko,en;q=0.8',
                # urllib does not decompress, so never invite a gzip body.
                'Accept-Encoding': 'identity',
            })
            try:
                with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                    body = resp.read()
                self.stats.bytes_read += len(body)
                return body.decode('utf-8', errors='replace')
            except urllib.error.HTTPError as exc:
                transient = exc.code in (408, 425, 429, 500, 502, 503, 504)
                reason = f'HTTP {exc.code}'
                if not transient or attempt >= self.max_retries:
                    self.stats.failures += 1
                    raise FetchError(url, reason, transient) from exc
            except (urllib.error.URLError, TimeoutError, OSError) as exc:
                reason = type(exc).__name__
                if attempt >= self.max_retries:
                    self.stats.failures += 1
                    raise FetchError(url, reason, True) from exc
            attempt += 1
            self.stats.retries += 1
            if self.on_retry is not None:
                self.on_retry(request_label, attempt + 1, reason)
            time.sleep(self.delay * (2 ** attempt))


def _xml_local_name(tag: str) -> str:
    return tag.rsplit('}', 1)[-1].lower()


def sitemap_entries(xml: str) -> list[SitemapEntry]:
    """Parse numeric sitemap entries without treating lastmod as a delta."""
    try:
        root = ElementTree.fromstring(xml)
    except ElementTree.ParseError:
        # Preserve the historical test/sample contract for a loc fragment
        # while structured sitemap documents use the lastmod-aware parser.
        fallback: dict[str, None] = {}
        for loc in LOC.findall(xml):
            match = POST_URL.match(loc.strip())
            if match:
                fallback[match.group(1)] = None
        return [SitemapEntry(post_id, None)
                for post_id in sorted(fallback, key=lambda value: int(value))]
    by_id: dict[str, str | None] = {}
    for url_node in root.iter():
        if _xml_local_name(url_node.tag) != 'url':
            continue
        loc = None
        lastmod = None
        for child in url_node:
            name = _xml_local_name(child.tag)
            if name == 'loc':
                loc = (child.text or '').strip()
            elif name == 'lastmod':
                lastmod = (child.text or '').strip() or None
        if not loc:
            continue
        match = POST_URL.match(loc)
        if not match:
            continue
        post_id = match.group(1)
        previous = by_id.get(post_id)
        # Duplicate locs are not source identity changes. Keep the
        # deterministic greatest hint for selection.
        by_id[post_id] = max(filter(None, (previous, lastmod)), default=None)
    return [SitemapEntry(post_id, by_id[post_id])
            for post_id in sorted(by_id, key=lambda value: int(value))]


def sitemap_post_ids(xml: str) -> list[int]:
    """Numeric post ids from sitemap.xml, newest id first, deduplicated."""
    return sorted((int(entry.external_post_id) for entry in sitemap_entries(xml)),
                  reverse=True)


class NetworkSource:
    """Live source. Used by --source network and --network-smoke only."""

    def __init__(self, fetcher: PoliteFetcher) -> None:
        self.fetcher = fetcher

    def post_ids(self) -> list[int]:
        return sitemap_post_ids(
            self.fetcher.get(f'{SITE_ORIGIN}/sitemap.xml', accept=ACCEPT_XML,
                             request_label='sitemap'))

    def post(self, post_id: int) -> RawPost:
        html = self.fetcher.get(f'{SITE_ORIGIN}/{post_id}', request_label=str(post_id))
        return parse_html(str(post_id), html)


class SampleSource:
    """Offline source over the committed extraction samples."""

    def __init__(self, path: Path) -> None:
        self.path = Path(path)

    def records(self) -> list[dict]:
        rows = []
        for line in self.path.read_text(encoding='utf-8').splitlines():
            line = line.strip()
            if line:
                rows.append(json.loads(line))
        return rows

    def posts(self) -> list[RawPost]:
        return [parse_record(r) for r in self.records()]
