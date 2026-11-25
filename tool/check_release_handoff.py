"""Metadata/Git checks only; never asserts live Store/DB truth."""
import json
import re
import subprocess
from pathlib import Path

REQUIRED = {'wiki_branch', 'last_verified', 'release_record', 'candidate', 'unreleased',
            'web', 'worker', 'db', 'payment', 'finance', 'development', 'work',
            'blocked', 'approval', 'next'}

def record(path, marker):
    matches = re.findall(r'<!-- '+re.escape(marker)+r' -->\s*```json\s*(.*?)\s*```', path.read_text(), re.S)
    if len(matches) != 1:
        raise ValueError(f'{marker}: expected exactly one record')
    value = json.loads(matches[0])
    if not isinstance(value, dict):
        raise ValueError(f'{marker}: object required')
    return value

def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True, stderr=subprocess.DEVNULL, timeout=20).strip()

def validate(root, official=False):
    groups = {'RELEASE_CONSISTENCY': [], 'GIT_BASELINE': [], 'OFFICIAL_WIKI': []}
    errors = groups['RELEASE_CONSISTENCY']
    wiki = root / 'wiki'
    for stale in ('APP 릴리스 HOLD 유지.', '최신 APP 릴리스 판단은 아래 APP82'):
        if stale in (wiki/'index.md').read_text(): errors.append('Known stale current-state label: '+stale)
    try:
        status = record(wiki/'current-status.md', 'handoff-status')
        missing = REQUIRED - status.keys()
        if missing: errors.append('Missing fields: '+', '.join(sorted(missing)))
        if status.get('wiki_branch') != 'main': errors.append('Canonical Wiki must be main')
        if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', status.get('last_verified', '')): errors.append('Verification date required')
        for field in ('unreleased', 'development', 'work', 'blocked', 'approval', 'next'):
            if not status.get(field): errors.append(f'{field}: explicit state required (use None/none entry, not omission)')
        release_path = (wiki / status['release_record']).resolve()
        if not release_path.is_relative_to(wiki.resolve()): raise ValueError('Release record escapes wiki')
        if status['release_record'] not in (wiki/'current-status.md').read_text() or status['release_record'] not in (wiki/'index.md').read_text():
            errors.append('Release record must be linked by current and index')
        release = record(release_path, 'release-record')
        for field in ('version', 'build', 'source', 'branch', 'last_verified', 'evidence'):
            if not release.get(field): errors.append('Release missing '+field)
        if not (wiki/release['evidence']).is_file(): errors.append('Release evidence missing')
        platforms = release.get('platforms', [])
        if len(platforms) != 2 or {p.get('platform') for p in platforms} != {'ios','android'}: errors.append('Exactly two distinct platform receipts required')
        for p in platforms:
            if any(p.get(k) != release.get(k) for k in ('version','build','source')): errors.append('Conflicting release version/build/source')
            if p.get('state') != 'RELEASED': errors.append('Current release receipt must be RELEASED; keep pending candidates separate')
            if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', p.get('released_on','')): errors.append('Platform release date required')
        candidate = status['candidate']
        if candidate.get('release_state') != 'UNRELEASED': errors.append('Candidate release state must be explicit UNRELEASED')
        if candidate.get('state') not in {'IMPLEMENTED','TESTED','BUILT','UPLOADED','SUBMITTED','APPROVED','RELEASE_CONFIRMATION_PENDING'}: errors.append('Invalid candidate stage')
        if not candidate.get('branch') or not (wiki/candidate.get('evidence','')).is_file(): errors.append('Candidate branch/evidence missing')
        for item in (status['web'], status['worker']):
            if not (wiki/item.get('evidence','')).is_file(): errors.append('Deployment evidence missing')
    except (KeyError, TypeError, ValueError, OSError) as e:
        errors.append(str(e))
        groups['GIT_BASELINE'].append('Not evaluated: malformed release metadata')
        return groups
    gerrors=groups['GIT_BASELINE']
    for label, obj in [('release',release),('candidate',candidate)]:
        try:
            sha=obj['source']
            if not re.fullmatch('[0-9a-f]{40}',sha): raise ValueError('Full commit SHA required')
            git(root,'cat-file','-e',sha+'^{commit}')
            pubspec=git(root,'show',sha+':pubspec.yaml')
            if not re.search(r'^version:\s*'+re.escape(f"{obj['version']}+{obj['build']}")+r'\s*$',pubspec,re.M): raise ValueError('pubspec version/build mismatch')
        except (KeyError, ValueError, subprocess.SubprocessError) as e:
            gerrors.append(label+': '+str(e))
    for descendant in (candidate.get('source',''), 'main'):
        try: git(root,'merge-base','--is-ancestor',release['source'],descendant)
        except subprocess.SubprocessError: gerrors.append('Released source is not ancestor of '+descendant)
    if official:
        try:
            remote=git(root,'ls-remote','origin','refs/heads/main').split()[0]
            if remote != git(root,'rev-parse','origin/main'): raise ValueError('origin/main stale: fetch and recheck')
            paths=['AGENTS.md','wiki','tool/check_wiki_handoff.py','tool/check_release_handoff.py','tool/test_release_handoff.py']
            if git(root,'diff',remote,'--',*paths): raise ValueError('Official remote Wiki/tools differ from working tree')
            if git(root,'ls-files','--others','--exclude-standard','--','wiki'): raise ValueError('Unpublished untracked Wiki files')
        except (ValueError, IndexError, subprocess.SubprocessError) as e:
            groups['OFFICIAL_WIKI'].append(str(e))
    return groups
