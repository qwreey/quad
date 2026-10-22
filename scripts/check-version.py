#!/usr/bin/env python3
"""버전 리터럴 정합성 검사 + 릴리즈 bump (2026-09-10).

quad는 워크스페이스 멤버 셋(quad_base·quad_roblox·quad_types)을 같은 버전으로 게시한다(lockstep). 범용 패키지 둘
(quad_error·type_version_check)은 **4.0.0 전까지는 같은 lockstep에 들어 있고**, 4.0.0부터 자기 SemVer를 따로 올린다
([2026-10-12 사용자 결정 — round14 Q131]: 3.x는 다섯 패키지 모두에게 호환이 깨질 수 있는 안정화 구간이라, 범용 쪽에 breaking이
나와도 메이저를 따로 올리지 않도록 "지금은 계속 싱크 맞추고, 4.x.x 가 나올 때 한번에 올린다"; 2026-09-15의 "첫 독립 릴리즈가
4.0.0"은 그대로이고 그 전 기간만 lockstep으로 바뀌었다. 옛 3.x의 yank는 4.0.0 뒤.) 판정은 그 패키지의 지금 버전이다 —
4.0.0 미만이면 `bump`가 같이 올리고(자기 CHANGELOG.md도 같이 자른다) `bump-package`는 거부한다; `bump 4.0.0`이 다섯을 같이
올린 뒤로는 `bump`가 건드리지 않고 `bump-package`로만 올린다(태그는 `<패키지 이름>/N.N.N` — 본체 태그 `N.N.N`과 겹치지 않게).
lockstep 버전 문자열은 매니페스트와 소스·테스트 몇 곳, 그리고 `pesde.lock` 여섯에
따로 박혀 있는데, 소스끼리는 타입 캐스트와 스펙으로 묶여 있지만 매니페스트는 아무 게이트도 보지 않았다 — 이 스크립트가 그 구멍을 막는다.

  python3 scripts/check-version.py            # 전 자리가 quad-base/pesde.toml의 version과 같은지, VERSION_PATTERN이 그 버전을 받는지, pesde.lock이 매니페스트와 같은 버전인지 (exit 1이면 불일치)
  python3 scripts/check-version.py bump-package type-version-check 4.1.0  # 독립한 뒤의 패키지 하나: 매니페스트 + <폴더>/CHANGELOG.md의 [Unreleased] 절단
  python3 scripts/check-version.py bump 3.0.0 # 전 자리를 새 버전으로 바꾸고 CHANGELOG의 [Unreleased]를 잘라 버전 헤딩으로. VERSION_PATTERN은 새 버전을 하한으로 한 `M.m^.p^`(2026-09-15 — 메이저 고정 사전식 하한, 프리릴리즈 bump면 그 빌드 정확히 `M.m.p-rc.N`).
                                              # docs/ 안의 옛 버전 문자열은 바꾸지 않고 목록만 찍는다(verbatim 에러 문구가 섞여 있어 손으로 볼 것).
"""
import datetime, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFESTS = ['pesde.toml', 'quad-base/pesde.toml', 'quad-roblox/pesde.toml', 'quad-types/pesde.toml']
# [2026-10-12 user decision] the two general-purpose packages: in LOCKSTEP while their own version is below
# INDEPENDENT_FROM (bumped by `bump`), versioned on their own from there on (`bump-package`). See the docstring.
INDEPENDENT = ['quad-error', 'type-version-check']
INDEPENDENT_FROM = (4, 0, 0)
REGISTRY_NAME = {'quad-error': 'quad_error', 'type-version-check': 'type_version_check'}
# every committed lock file and the manifest whose version it must repeat (`pesde install` rewrites them after a bump)
LOCKS = [('pesde.lock', 'pesde.toml')] + [(f'{m}/pesde.lock', f'{m}/pesde.toml') for m in
                                           ('quad-base', 'quad-roblox', 'quad-types', 'quad-error', 'type-version-check')]
# (파일, 정규식 — 그룹 1이 버전) : 소스·테스트 리터럴
SITES = [
    ('quad-base/src/init.luau', r'(?m)^(\s*Version = ")([^"]+)(",)'),
    ('quad-types/src/init.luau', r'(?m)^(\s*Version: ")([^"]+)(",)'),
    ('quad-base/test/smoke.plugin.luau', r'(Quad\.Version == ")([^"]+)(")'),
    ('quad-roblox/src/init.luau', r'(?m)^(local VERSION = ")([^"]+)(")'),
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


def core_tuple(v):
    return tuple(int(x) for x in split_tail(v)[0].split('.'))


def follows_lockstep(member):
    """A general-purpose package still below the FINAL INDEPENDENT_FROM rides the quad lockstep
    (a pre-release of that version is still below it — otherwise `bump 4.0.0-rc.1` then `bump 4.0.0`
    left the two at the rc; code review 2026-10-12)."""
    v = manifest_version(read(f'{member}/pesde.toml'))
    return core_tuple(v) < INDEPENDENT_FROM or (core_tuple(v) == INDEPENDENT_FROM and split_tail(v)[1] is not None)


def matches_places(actual, pattern):
    a, p = actual.split('.'), pattern.split('.')
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
                return True  # lexicographic floor: the rest of this section is ignored
        elif x != y:
            return False
    return True


def matches_pattern(actual, pattern):
    """type-version-check/src/init.luau의 matchesPattern과 같은 규칙(포트) — 규칙이 바뀌면 여기도 같이.
    check()가 Luau spec의 케이스를 이 함수에도 먹인다(self_test_matcher).
    [2026-09-27 round13 E12] 숫자 파서만 다르다: 여기는 int(x, 10)이라 "0x10"/"1e2"가 False인데, Luau 쪽은 tonumber라
    16진수·지수 표기도 숫자로 본다(caret 자리 "16^"에 "0x10"이 통과). SemVer 자리에 그런 표기는 없어 실무 차이는 없다.
    [2026-09-15] `|` 대안, 프리릴리즈 꼬리 유무 일치, core·prerelease 따로 사전식 판정."""
    for alt in pattern.split('|'):
        ac, apre = split_tail(actual)
        pc, ppre = split_tail(alt)
        if (apre is None) != (ppre is None):
            continue
        if not matches_places(ac, pc):
            continue
        if ppre is not None and not matches_places(apre, ppre):
            continue
        return True
    return False


def collect():
    found = []
    for m in MANIFESTS + [f'{p}/pesde.toml' for p in INDEPENDENT if follows_lockstep(p)]:
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
    # [2026-10-12 round14 Q131] a bump without `pesde install` left the six lock files on the old version and every
    # gate green (release rehearsal E43) — the lock's own `version` line must repeat its manifest's.
    stale = []
    for lock, manifest in LOCKS:
        if not os.path.exists(os.path.join(ROOT, lock)):
            continue  # a tree that was never installed (an export without lock files) has nothing to compare
        lv, mv = manifest_version(read(lock)), manifest_version(read(manifest))
        if lv != mv:
            stale.append(f'{lock}: {lv} (manifest {mv})')
    if stale:
        for s in stale:
            print(f'  STALE LOCK {s}')
        print('  run `mise exec -- pesde install` (it rewrites the lock files; then relink — ./scripts/test.sh does)')
        ok = False
    if not self_test_matcher():
        ok = False
    if not ok:
        sys.exit(1)


MATCHER_SPEC = 'quad-base/test/spec.versioncheck.luau'


def self_test_matcher():
    """[2026-10-20 round15 H-936] matches_pattern is the third copy of the pattern rule (runtime, type function,
    this port) and the Luau spec checked only the first two. Its `expect(actual, pattern, want)` lines ARE the case
    table — read them here instead of keeping a second list that would drift the same way."""
    cases = re.findall(r'expect\("([^"]*)", "([^"]*)", (true|false)\)', read(MATCHER_SPEC))
    if len(cases) < 50:  # the spec moved or changed shape: say so instead of passing on nothing
        print(f'  MATCHER SELF-TEST: only {len(cases)} expect(...) cases found in {MATCHER_SPEC} (expected 50+)')
        return False
    bad = [(a, pat, w) for a, pat, w in cases if matches_pattern(a, pat) != (w == 'true')]
    for a, pat, w in bad:
        print(f'  MATCHER SELF-TEST: matches_pattern({a!r}, {pat!r}) != {w} (the Luau rule says {w})')
    return not bad


def check_semver(new):
    if not re.match(r'^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$', new):
        sys.exit(f'not a SemVer version: {new}')


def cut_changelog(path, new):
    cl = read(path)
    head = f'## [{new}] - {datetime.date.today().isoformat()}'
    # [2026-10-22] a rerun of the same bump must not add a second heading for that version (it did — the first
    # run's cut leaves [Unreleased] empty, and an empty cut still wrote a heading)
    if re.search(rf'(?m)^## \[{re.escape(new)}\]', cl):
        return head
    # [2026-09-13 사용자] [Unreleased] 아래에는 고정 안내문 한 줄과 `---`가 있다(비어 있을 때 다음 버전 헤딩이 붙어 보이던 것을 가른다).
    # 안내문·hr은 남기고 그 사이의 항목만 새 버전 헤딩 아래로 옮긴다. 안내문/hr이 없으면 옛 방식(헤딩 바로 뒤에 삽입).
    m = re.search(r'## \[Unreleased\]\n\n(_[^\n]*_)\n\n(.*?)---\n', cl, re.S)
    if m:
        entries = m.group(2).strip('\n')
        body = (entries + '\n\n') if entries else ''
        cl = cl[:m.start()] + f'## [Unreleased]\n\n{m.group(1)}\n\n---\n\n{head}\n\n{body}' + cl[m.end():].lstrip('\n')
        write(path, cl)
    elif '## [Unreleased]' in cl:
        cl = cl.replace('## [Unreleased]', f'## [Unreleased]\n\n{head}', 1)
        write(path, cl)
    else:
        # [2026-09-27 T2] 헤딩이 없으면 예전엔 아무것도 안 쓰고 "cut to …"를 찍으며 성공 종료했다 —
        # 매니페스트·소스 버전만 올라간 채 CHANGELOG에 릴리즈 절이 없는 릴리즈가 "완료"됐다.
        sys.exit(f'{path}: no "## [Unreleased]" heading — cannot cut the changelog (manifests already bumped; fix the heading and rerun bump)')
    return head


def bump_package(member, new):
    if member not in INDEPENDENT:
        sys.exit(f'not an independently versioned package: {member} (choose from {", ".join(INDEPENDENT)})')
    if follows_lockstep(member):
        sys.exit(f'{member} is still in the quad lockstep (its version is below {".".join(map(str, INDEPENDENT_FROM))}) — '
                 f'`bump <version>` raises it together with quad; `bump-package` is for after that')
    check_semver(new)
    manifest = f'{member}/pesde.toml'
    old = manifest_version(read(manifest))
    write(manifest, re.sub(r'(?m)^version = "[^"]+"$', f'version = "{new}"', read(manifest), count=1))
    head = cut_changelog(f'{member}/CHANGELOG.md', new)
    print(f'bumped {member} {old} -> {new}; {member}/CHANGELOG.md [Unreleased] cut to {head}')
    print('next: mise exec -- pesde install   # rewrites the pesde.lock files — check-version fails until then')
    tag = f'{REGISTRY_NAME[member]}/{new}'
    print(f'then (after commit): git tag -a {tag} -m "{REGISTRY_NAME[member]} {new}" && git push origin {tag}')
    print('publish it before (or together with) the quad release that needs it: python3 scripts/publish.py --with ' + member)


def bump(new):
    check_semver(new)
    old = manifest_version(read('quad-base/pesde.toml'))
    riding = [p for p in INDEPENDENT if follows_lockstep(p)]  # decided BEFORE any manifest changes
    for m in MANIFESTS + [f'{p}/pesde.toml' for p in riding]:
        write(m, re.sub(r'(?m)^version = "[^"]+"$', f'version = "{new}"', read(m), count=1))
    for f, rx in SITES + [(f, rx.replace('OLD', re.escape(old))) for f, rx in BUMP_ONLY]:
        s, n = re.subn(rx, lambda mo: mo.group(1) + new + mo.group(3) if mo.lastindex == 3 else mo.group(1) + new + mo.group(2), read(f))
        if n == 0:
            sys.exit(f'site not found: {f} {rx}')
        write(f, s)
    # [2026-09-15 사용자 결정] VERSION_PATTERN is a floor within the major: "M.m^.p^" of the new release.
    # A prerelease bump pins the exact build ("M.m.p-rc.2") — the user: whoever writes an rc knows the
    # core is a fixed version; prerelease and release builds never mix (the matcher enforces that too).
    core, pre = split_tail(new)
    major, minor, patch = core.split('.')
    floor = f'{major}.{minor}^.{patch}^' if pre is None else f'{core}-{pre}'
    for f, rx in [PATTERN_SITE, PATTERN_ECHO_SITE]:
        s, n = re.subn(rx, lambda mo: mo.group(1) + floor + mo.group(3), read(f))
        if n == 0:
            sys.exit(f'site not found: {f} {rx}')
        write(f, s)
    head = cut_changelog('CHANGELOG.md', new)
    # [2026-09-13 사용자] [Unreleased] 아래에는 고정 안내문 한 줄과 `---`가 있다(비어 있을 때 다음 버전 헤딩이 붙어 보이던 것을 가른다).
    # 안내문·hr은 남기고 그 사이의 항목만 새 버전 헤딩 아래로 옮긴다. 안내문/hr이 없으면 옛 방식(헤딩 바로 뒤에 삽입).
    print(f'bumped {old} -> {new}; CHANGELOG [Unreleased] cut to {head}')
    for p in riding:
        print(f'  with it (lockstep until {".".join(map(str, INDEPENDENT_FROM))}): {p} -> {new}; {p}/CHANGELOG.md cut to {cut_changelog(f"{p}/CHANGELOG.md", new)}')
    for p in INDEPENDENT:
        if p not in riding:
            print(f'  NOT bumped (versioned on its own): {p} {manifest_version(read(f"{p}/pesde.toml"))} — `bump-package {p} <version>` first if this release needs a new one')
    print('next: mise exec -- pesde install   # rewrites the six pesde.lock files — check-version (and so test.sh) fails until then')
    print(f'then (after commit): git tag -a {new} -m "quad {new}" && git push origin {new}   # tags do not follow branch sync — push them to github/upstream too (conventions 2026-09-11)')
    # What the bump does not rewrite: prose that names the old version. Verbatim error strings are mixed in, so
    # this only lists them. On a MAJOR change the install ranges and "N.x" wording go stale too (rehearsal E43).
    needles = [old]
    old_major, new_major = split_tail(old)[0].split('.')[0], split_tail(new)[0].split('.')[0]
    if old_major != new_major:
        needles += [f'^{old_major}.', f'{old_major}.x']
    files = [os.path.join(ROOT, 'README.md'), os.path.join(ROOT, 'docs', 'site', 'sync-docs.py')]
    for dp, dn, fn in os.walk(os.path.join(ROOT, 'docs')):
        if 'site' in dp.split(os.sep):
            continue
        files += [os.path.join(dp, f) for f in fn if f.endswith('.md')]
    leftovers = []
    for p in files:
        if not os.path.exists(p):
            continue
        for i, line in enumerate(open(p, encoding='utf-8'), 1):
            hit = [n for n in needles if n in line]
            if hit:
                leftovers.append(f'{os.path.relpath(p, ROOT)}:{i}  ({", ".join(hit)})')
    if leftovers:
        print(f'still mention {" / ".join(needles)} (fix by hand, then run docs/site/sync-docs.py):')
        for l in leftovers:
            print('  ', l)


if __name__ == '__main__':
    if len(sys.argv) >= 4 and sys.argv[1] == 'bump-package':
        bump_package(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 3 and sys.argv[1] == 'bump':
        bump(sys.argv[2])
    else:
        check()
