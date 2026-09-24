#!/usr/bin/env python3
"""Read-only Wiki link, routing and current-status handoff checks (stdlib only)."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / 'wiki'


def prose(text):
    return re.sub(r'```.*?```', '', text, flags=re.S)


def anchors(path):
    result, counts = set(), {}
    for heading in re.findall(r'^#{1,6} (.*)$', prose(path.read_text()), re.M):
        slug = re.sub(r'[^\w\-\s]', '', heading.strip().lower()).replace(' ', '-')
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        result.add(slug + (f'-{count}' if count else ''))
    return result


def main():
    errors, links = [], 0
    for path in sorted(WIKI.rglob('*.md')) + [ROOT / 'AGENTS.md']:
        for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', prose(path.read_text())):
            target = target.split(' "')[0]
            if re.match(r'\w+://|mailto:', target):
                continue
            filename, _, fragment = target.partition('#')
            destination = (path.parent / filename).resolve() if filename else path
            links += 1
            if not destination.exists():
                errors.append(f'{path.relative_to(ROOT)}: missing {target}')
            elif fragment and destination.suffix == '.md' and fragment not in anchors(destination):
                errors.append(f'{path.relative_to(ROOT)}: missing anchor {target}')
    index = (WIKI / 'index.md').read_text()
    routing = index.split('## Task Routing Map', 1)[-1].split('## Product/platform', 1)[0]
    required = {
        'ADMISSIONS': ('ADMISSIONS DATA / ANALYTICS', ['roadmap-academic-analytics.md', 'research-registry.md', 'decisions.md']),
        'DAILY_SYNC': ('DAILY SYNC / INGESTION', ['ingestion.md', 'day-9-ingestion.md', 'research-registry.md']),
        'RELEASE': ('COMPLIANCE / RELEASE', ['account-deletion-privacy.md', 'current-status.md', 'research-registry.md']),
        'STRATEGY': ('PRODUCT STRATEGY', ['product-architecture.md', 'product-scope.md', 'research-registry.md']),
        'COMMUNITY': ('COMMUNITY /', ['product-platform-boundaries.md', 'database.md', 'research-registry.md']),
        'BADGE': ('ACHIEVEMENT / BADGE', ['decisions.md#2026-09-19--achievements', 'roadmap-academic-analytics.md#9-achievement--badge-engine', 'product-scope.md']),
        'MEAL': ('MEAL / SCHOOL', ['day-7-neis.md', 'day-10-b-home-polish.md', 'day-7-school-storage-proposal.md']),
        'AUTH': ('AUTH /', ['decisions.md', 'auth-native-owner-acceptance.md', 'auth-recovery.md', 'account-deletion-privacy.md']),
        'MOCK': ('MOCK EXAM / SCORING', ['day-8-d2-answer-scoring.md#current-exam-selection-and-scoring-handoff--2026-09-24', 'mock-exam-scoring-v1.md', 'day-8-scoring-storage-proposal.md']),
        'STUDY': ('STUDY / TIMER', ['study-v1.md', 'day-8-study-ui-review.md', 'day-8-study-storage-proposal.md']),
    }
    for name, (alias, docs) in required.items():
        row = next((line for line in routing.splitlines() if line.startswith('| ' + alias)), '')
        ok = all(doc in row for doc in docs)
        print(f'HANDOFF_{name}: {"PASS" if ok else "FAIL"}')
        if not ok:
            errors.append(f'Missing required route: {name}')
    current_size = (WIKI / 'current-status.md').stat().st_size
    if current_size > 12000:
        errors.append('current-status exceeds 12 KB restore budget; move history to feature/log evidence')
    print(f'CURRENT_STATUS_BYTES: {current_size}; INTERNAL_LINKS: {links}')
    for error in errors:
        print(error)
    print(f'WIKI_CHECK: {"FAIL" if errors else "PASS"}')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
