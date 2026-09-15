#!/usr/bin/env python3
"""버전 리터럴 정합성 검사 + 릴리즈 bump (2026-09-10).

quad는 워크스페이스 멤버 다섯을 같은 버전으로 게시한다(lockstep). 버전 문자열은 매니페스트 여섯과 소스·테스트 몇 곳에
따로 박혀 있는데, 소스끼리는 타입 캐스트와 스펙으로 묶여 있지만 매니페스트는 아무 게이트도 보지 않았다 — 이 스크립트가 그 구멍을 막는다.

  python3 scripts/check-version.py            # 전 자리가 quad-base/pesde.toml의 version과 같은지, VERSION_PATTERN이 그 버전을 받는지 (exit 1이면 불일치)
  python3 scripts/check-version.py bump 3.0.0 # 전 자리를 새 버전으로 바꾸고 CHANGELOG의 [Unreleased]를 잘라 버전 헤딩으로. VERSION_PATTERN은 새 버전을 하한으로 한 `M.m^.p^`(2026-09-15 — 메이저 고정 사전식 하한, 프리릴리즈 bump면 꼬리를 붙여 `M.m^.p^-rc.N`).
                                              # docs/ 안의 옛 버전 문자열은 바꾸지 않고 목록만 찍는다(verbatim 에러 문구가 섞여 있어 손으로 볼 것).
"""
import datetime, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFESTS = ['pesde.toml', 'quad-base/pesde.toml', 'quad-roblox/pesde.toml', 'quad-types/pesde.toml', 'quad-error/pesde.toml',
             'type-version-check/pesde.toml']
# (파일, 정규식 — 그룹 1이 버전) : 소스·테스트 리터럴
SITES = [
    ('quad-base/src/init.luau', r'(?m)^(\s*Version = ")([^"]+)(",)'),
    ('quad-types/src/init.luau', r'(?m)^(\s*Version: ")([^"]+)(",)'),
    ('quad-base/test/smoke.plugin.luau', r'(Quad\.Version == ")([^"]+)(")'),
]
# [2026-09-15] the spec asserts the pattern string itself, so it is checked against VERSION_PATTERN (not the version)
PATTERN_ECHO_SITE = ('quad-roblox/test/spec.robloxfactory.luau', r"(version pattern ')([^']+)(')")
# bump 때만: 같은 파일에 일부러 틀린 값(9.9.9)도 있어 검사 대상은 아니고, 옛 버전과 같은 대입만 새 버전으로 바꾼다
BUMP_ONLY = [('quad-roblox/test/spec.robloxfactory.luau', r'(:: any\)\.Version = ")OLD(")')]
PATTERN_SITE = ('quad-roblox/src/init.luau', r'(?m)^(local VERSION_PATTERN = ")([^"]+)(")')


def read(p):
    return open(os.path.join(ROOT, p), encoding='utf-8').read()


def write(p, s):
    open(os.path.join(ROOT, p), 'w', encoding='utf-8').write(s)


def manifest_version(text):
    m = re.search(r'(?m)^version = "([^"]+)"$', text)
    return m.group(1) if m else None


def split_tail(v):
    core = v.split('+', 1)[0]
    if '-' in core:
        c, pre = core.split('-', 1)
        return c, pre
    return core, None


def matches_pattern(actual, pattern):
    """type-version-check/src/init.luau의 matchesPattern과 같은 규칙(포트) — 규칙이 바뀌면 여기도 같이."""
    ac, apre = split_tail(actual)
    pc, ppre = split_tail(pattern)
    if ppre is not None and apre != ppre:
        return False
    a, p = ac.split('.'), pc.split('.')
    if len(a) != len(p):
        return False
    for x, y in zip(a, p):
        if y == '*':
            continue
        if y.endswith('^'):
            try:
                xi, yi = int(x), int(y[:-1])
            except ValueError:
                return False
            if xi < yi:
                return False
            if xi > yi:
                return True  # [2026-09-15] lexicographic floor: a leading ^ place above its minimum ignores later places
        elif x != y:
            return False
    return True


def collect():
    found = []
    for m in MANIFESTS:
        found.append((m, manifest_version(read(m))))
    for f, rx in SITES:
        mm = re.search(rx, read(f))
        found.append((f, mm.group(2) if mm else None))
    return found


def check():
    canonical = manifest_version(read('quad-base/pesde.toml'))
    bad = [(f, v) for f, v in collect() if v != canonical]
    pm = re.search(PATTERN_SITE[1], read(PATTERN_SITE[0]))
    pattern = pm.group(2) if pm else None
    print(f'check-version: canonical {canonical} (quad-base/pesde.toml), VERSION_PATTERN {pattern}')
    ok = True
    for f, v in bad:
        print(f'  MISMATCH {f}: {v}')
        ok = False
    if pattern is None or not matches_pattern(canonical, pattern):
        print(f'  MISMATCH {PATTERN_SITE[0]}: VERSION_PATTERN {pattern!r} does not accept {canonical!r}')
        ok = False
    em = re.search(PATTERN_ECHO_SITE[1], read(PATTERN_ECHO_SITE[0]))
    if em is None or em.group(2) != pattern:
        print(f'  MISMATCH {PATTERN_ECHO_SITE[0]}: asserted pattern {em.group(2) if em else None!r} != VERSION_PATTERN {pattern!r}')
        ok = False
    if not ok:
        sys.exit(1)


def bump(new):
    if not re.match(r'^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$', new):
        sys.exit(f'not a SemVer version: {new}')
    old = manifest_version(read('quad-base/pesde.toml'))
    for m in MANIFESTS:
        write(m, re.sub(r'(?m)^version = "[^"]+"$', f'version = "{new}"', read(m), count=1))
    for f, rx in SITES + [(f, rx.replace('OLD', re.escape(old))) for f, rx in BUMP_ONLY]:
        s, n = re.subn(rx, lambda mo: mo.group(1) + new + mo.group(3) if mo.lastindex == 3 else mo.group(1) + new + mo.group(2), read(f))
        if n == 0:
            sys.exit(f'site not found: {f} {rx}')
        write(f, s)
    # [2026-09-15 사용자 결정] VERSION_PATTERN is a floor within the major: "M.m^.p^" of the new release.
    # A prerelease bump keeps its tail ("M.m^.p^-rc.2") so an rc backend accepts only the same rc base —
    # prerelease and release builds must not mix (code-review 1a7c4dc..04e8bad, user (가)).
    core, pre = split_tail(new)
    major, minor, patch = core.split('.')
    floor = f'{major}.{minor}^.{patch}^' + (f'-{pre}' if pre is not None else '')
    for f, rx in [PATTERN_SITE, PATTERN_ECHO_SITE]:
        s, n = re.subn(rx, lambda mo: mo.group(1) + floor + mo.group(3), read(f))
        if n == 0:
            sys.exit(f'site not found: {f} {rx}')
        write(f, s)
    cl = read('CHANGELOG.md')
    head = f'## [{new}] - {datetime.date.today().isoformat()}'
    # [2026-09-13 사용자] [Unreleased] 아래에는 고정 안내문 한 줄과 `---`가 있다(비어 있을 때 다음 버전 헤딩이 붙어 보이던 것을 가른다).
    # 안내문·hr은 남기고 그 사이의 항목만 새 버전 헤딩 아래로 옮긴다. 안내문/hr이 없으면 옛 방식(헤딩 바로 뒤에 삽입).
    m = re.search(r'## \[Unreleased\]\n\n(_[^\n]*_)\n\n(.*?)---\n', cl, re.S)
    if m:
        entries = m.group(2).strip('\n')
        body = (entries + '\n\n') if entries else ''
        cl = cl[:m.start()] + f'## [Unreleased]\n\n{m.group(1)}\n\n---\n\n{head}\n\n{body}' + cl[m.end():].lstrip('\n')
        write('CHANGELOG.md', cl)
    elif '## [Unreleased]' in cl:
        cl = cl.replace('## [Unreleased]', f'## [Unreleased]\n\n{head}', 1)
        write('CHANGELOG.md', cl)
    print(f'bumped {old} -> {new}; CHANGELOG [Unreleased] cut to {head}')
    print(f'next (after commit): git tag -a {new} -m "quad {new}" && git push origin {new}   # tags do not follow branch sync — push them to github/upstream too (conventions 2026-09-11)')
    leftovers = []
    for dp, dn, fn in os.walk(os.path.join(ROOT, 'docs')):
        if 'site' in dp.split(os.sep):
            continue
        for f in fn:
            if f.endswith('.md'):
                p = os.path.join(dp, f)
                for i, line in enumerate(open(p, encoding='utf-8'), 1):
                    if old in line:
                        leftovers.append(f'{os.path.relpath(p, ROOT)}:{i}')
    if leftovers:
        print(f'docs still mention {old} (fix by hand, then run docs/site/sync-docs.py):')
        for l in leftovers:
            print('  ', l)


if __name__ == '__main__':
    if len(sys.argv) >= 3 and sys.argv[1] == 'bump':
        bump(sys.argv[2])
    else:
        check()
