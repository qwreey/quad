#!/usr/bin/env python3
"""pesde 게시 — luau/roblox 두 타깃을 한 번에 (2026-09-10 신설).

## 왜 스크립트가 필요한가

`quad_roblox`는 roblox 타깃인데 `quad_types`/`type_version_check`를 luau 타깃으로 물고 있어
`pesde publish`가 거부한다(실측 verbatim):

    error: roblox packages may not depend on non-roblox packages

pesde 매니페스트의 `[target]`은 **하나뿐**이고, 타깃을 지정하는 publish 옵션도 **없다**
(`pesde publish --help`: -d/--dry-run, -y/--yes, -i/--index, --no-verify 뿐).
pesde 문서 "Multi-target Packages"가 정한 유일한 방법은 *"같은 이름·버전으로 타깃만 달리해
두 번 게시"* — 즉 **매니페스트를 바꿔 다시 publish** 하는 것이다(타깃이 달라도 description은
같아야 한다).

그런데 매니페스트만 바꿔서는 안 된다. **의존 패키지가 놓이는 폴더는 "의존하는 쪽"이 아니라
"의존되는 쪽"의 타깃이 정한다**(실측) — 즉 `quad_types`를 roblox 타깃으로 물면 그것은
`luau_packages/`가 아니라 `roblox_packages/`에 설치되고, 소스의
`require("./luau_packages/quad_types")`는 **끊긴다**. `pesde publish --dry-run`은 이걸 잡지
못한다(require 해소를 안 봄) — 게시된 뒤에야 깨지는 "거짓 클린"이다.

## 그래서 이 스크립트가 하는 일

레포는 **건드리지 않는다**(임시 치환·복구가 아예 없다 — 원상 복구 실패 위험도 없다).
대신 임시 디렉터리에 **스테이징 워크스페이스**를 짓고 거기서 install → test → publish 한다:

  * roblox 쌍둥이 멤버 `rbx-<member>/` 를 만든다 — 같은 `name`/`version`/`description`,
    `[target] environment = "roblox"` + `build_files = ["src"]`(roblox 타깃 필수 — 없으면
    `error: no build files found in target`), 워크스페이스 의존은 `target = "roblox"`.
  * 쌍둥이와 `quad-roblox`의 소스/테스트에서 `luau_packages/<그 셋>` → `roblox_packages/<그 셋>`
    으로 require 경로를 고친다.
  * 스테이징 루트 `pesde.toml`의 `workspace_members`에 쌍둥이를 더한다. pesde는 워크스페이스
    멤버를 **(이름, 타깃) 쌍**으로 찾으므로(lock 파일의 `[workspace."qwreey/quad_types"]`
    아래 타깃별 경로) 같은 이름의 멤버가 둘 있어도 된다 — 실측 확인.
  * 스테이징에서 `./scripts/test.sh`를 돌린다. **게시되는 그 트리가 게이트를 통과한 트리다.**
  * 의존 순서대로 publish 한다: luau 넷 → roblox 넷 → `quad_roblox`.

## 사용법

    python3 scripts/publish.py                 # dry-run (기본) — 타르볼만 만들고 아무것도 안 올린다
    python3 scripts/publish.py --real          # 실제 게시 (사용자 전용; 확인 프롬프트가 있다)
    python3 scripts/publish.py --no-test       # 스테이징 test.sh 생략 (빠른 확인용, 권장 안 함)
    python3 scripts/publish.py --twins three   # 옛 구성(quad_base는 luau만) — 아래 실측 차이 참고
    python3 scripts/publish.py --keep          # 스테이징 트리를 지우지 않고 경로를 찍는다

`--real`은 `pesde auth login`(GitHub)과 `qwreey` 스코프 소유가 선행돼야 한다 — dry-run은 둘 다
필요 없다.

## `--twins four`(기본 — 사용자 결정 2026-09-10 저녁) vs `--twins three`(옛 결정) — 실측 차이

처음 결정(같은 날 오후)은 `three` — `quad_types`/`type_version_check`/
`quad_error` 셋만 양 타깃. 이 구성은 게시 9건 중 8건이 **dry-run 전부 통과**하지만,
스테이징 `./scripts/test.sh`는 **exit 1**이다. 깨지는 자리는 딱 두 줄:

    quad-roblox/test/spec.reftypes.luau(43,18): TypeError: Expected this to be 'Self', but got 'Ref<Frame?>'
    quad-roblox/test/spec.reftypes.luau(44,23): TypeError: Expected this to be '<큰 유니언>', but got 'Self'

스펙 51개는 전부 실행되고(런타임 통과), 깨지는 건 luau-lsp 타입 패스뿐이다.
**원인은 미확인** — `quad_types` 사본이 둘로 갈린 탓(quad_base가 보는 luau 사본 vs
quad_roblox가 보는 roblox 사본)으로 보이나, 그 스펙의 import를 luau 쪽으로 되돌려도 같은
에러가 났다. `Callback: <Self>(self: Self, fn: RefCallback<T>) -> Self`
(`quad-types/src/init.luau:168`)의 `Self` 바인딩 쪽일 가능성도 남아 있다. 소비자가 같은
조합에서 같은 에러를 보는지는 **확인하지 않았다** — 같은 파일 38~42줄(`q.Ref`를 `D.TextLabel`
children에 넣는 자리)은 이 구성에서도 깨끗하게 통과한다.

`--twins four`는 `quad_base`까지 양 타깃으로 게시해 quad_roblox 쪽 세계를 roblox 하나로 맞춘
것으로, 스테이징 `./scripts/test.sh`가 **exit 0**(스펙 51)이고 게시는 9건이 된다. 위 실측을 본
사용자가 **[2026-09-10 저녁] `four`를 기본값으로 확정**했다 — Roblox 소비자는 `roblox_packages/`
하나만 Rojo에 매핑하면 되고(설치 문서 2단계), luau 타깃 소비자(헤드리스 테스트)는 그대로 luau
사본을 받는다. `three`는 대조용으로만 남긴다.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 멤버 디렉터리 -> pesde 패키지 이름(진단 출력용)
MEMBERS = {
    'quad-error': 'qwreey/quad_error',
    'type-version-check': 'qwreey/type_version_check',
    'quad-types': 'qwreey/quad_types',
    'quad-base': 'qwreey/quad_base',
    'quad-roblox': 'qwreey/quad_roblox',
}
# 양 타깃으로 게시하는 멤버(의존 순). `three`는 사용자 결정 원안, `four`는 이 스크립트의 제안.
TWIN_SETS = {
    'three': ['quad-error', 'type-version-check', 'quad-types'],
    'four': ['quad-error', 'type-version-check', 'quad-types', 'quad-base'],
}
# 스테이징에 복사하는 최상위 항목(존재하는 것만)
COPY_TOP = list(MEMBERS) + ['scripts', 'pesde.toml', 'LICENSE', 'README.md', 'CHANGELOG.md',
                            'default.project.json',
                            # [2026-09-10] 핀 툴체인·strict 모드가 스테이징에도 적용되게 — 없으면 `mise exec`가
                            # 전역 pesde(0.7.3)로 떨어지고 luau-analyze가 nonstrict로 돈다(실측: 0.7.3 배너)
                            'mise.toml', '.luaurc']
TWIN_PREFIX = 'rbx-'


def run(cmd, cwd, capture=True, check=False):
    p = subprocess.run(cmd, cwd=cwd, text=True,
                       stdout=subprocess.PIPE if capture else None,
                       stderr=subprocess.STDOUT if capture else None)
    if check and p.returncode != 0:
        if capture:
            sys.stderr.write(p.stdout or '')
        sys.exit(f'FAILED ({p.returncode}): {" ".join(cmd)} (cwd={cwd})')
    return p


def sub1(path, pattern, repl, what, expect=1):
    """정확히 `expect`번 치환되지 않으면 죽는다 — 앵커가 사라지거나 늘어난 걸 조용히 넘기지 않기 위함."""
    s = open(path, encoding='utf-8').read()
    s2, n = re.subn(pattern, repl, s)
    if n != expect:
        sys.exit(f'staging: {what} — 앵커가 {n}번 매치됐다({expect}이어야 함): {path}')
    open(path, 'w', encoding='utf-8').write(s2)


def rewrite_requires(root, names, skip=()):
    """`luau_packages/<name>` -> `roblox_packages/<name>`. 고친 파일 수를 돌려준다."""
    changed = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames
                       if d not in ('luau_packages', 'roblox_packages', '.pesde', 'dump')]
        for fn in filenames:
            if not fn.endswith('.luau'):
                continue
            p = os.path.join(dirpath, fn)
            if os.path.relpath(p, root) in skip:
                continue
            s = open(p, encoding='utf-8').read()
            s2 = s
            for n in names:
                s2 = s2.replace(f'luau_packages/{n}', f'roblox_packages/{n}')
            if s2 != s:
                open(p, 'w', encoding='utf-8').write(s2)
                changed += 1
    return changed


def make_twin(stage, member, twin_names):
    """`<member>`의 roblox 쌍둥이 `rbx-<member>`를 만든다. 만든 디렉터리 이름을 돌려준다."""
    src = os.path.join(stage, member)
    dst = os.path.join(stage, TWIN_PREFIX + member)
    shutil.rmtree(dst, ignore_errors=True)
    os.makedirs(dst)
    shutil.copytree(os.path.join(src, 'src'), os.path.join(dst, 'src'))
    for extra in ('README.md', 'LICENSE'):
        if os.path.exists(os.path.join(src, extra)):
            shutil.copy2(os.path.join(src, extra), os.path.join(dst, extra))
    manifest = os.path.join(dst, 'pesde.toml')
    shutil.copy2(os.path.join(src, 'pesde.toml'), manifest)
    # [target] environment = "luau" -> roblox (+ roblox 필수 build_files)
    sub1(manifest, r'(?m)^environment = "luau"$',
         'environment = "roblox"\nbuild_files = ["src"]', f'{member} target 전환')
    # 워크스페이스 의존도 roblox 타깃으로 (명시 안 하면 "의존하는 쪽의 타깃"이 기본이라 결과는
    # 같지만, 게시된 매니페스트에 target이 드러나게 명시한다)
    s = open(manifest, encoding='utf-8').read()
    s = re.sub(r'(\{ workspace = "qwreey/[a-z_]+", version = "[^"]*")( \})',
               r'\1, target = "roblox"\2', s)
    open(manifest, 'w', encoding='utf-8').write(s)
    rewrite_requires(os.path.join(dst, 'src'), twin_names)
    return TWIN_PREFIX + member


def build_stage(stage, twins):
    """레포를 스테이징으로 복사하고 roblox 패스를 구성한다. 레포 자체는 안 건드린다."""
    print(f'staging: {stage}')
    for item in COPY_TOP:
        s = os.path.join(ROOT, item)
        if not os.path.exists(s):
            continue
        d = os.path.join(stage, item)
        if os.path.isdir(s):
            shutil.copytree(s, d, symlinks=True,
                            ignore=shutil.ignore_patterns('luau_packages', 'roblox_packages',
                                                          '__pycache__', 'package.tar.gz'))
        else:
            shutil.copy2(s, d)
    # test.sh의 doc-coverage가 docs/를 읽는다 — 원본을 심볼릭으로 빌려온다(읽기 전용)
    docs = os.path.join(ROOT, 'docs')
    if os.path.exists(docs):
        os.symlink(docs, os.path.join(stage, 'docs'))

    twin_names = [MEMBERS[m].split('/', 1)[1] for m in twins]   # quad_types, ...
    twin_dirs = [make_twin(stage, m, twin_names) for m in twins]

    # quad-roblox: 쌍둥이가 생긴 패키지들을 roblox 타깃으로 물고, require 경로를 옮긴다
    rb = os.path.join(stage, 'quad-roblox')
    manifest = os.path.join(rb, 'pesde.toml')
    s = open(manifest, encoding='utf-8').read()
    for n in twin_names:
        pat = (rf'(?m)^({n} = \{{ workspace = "qwreey/{n}", version = "[^"]*")'
               rf'(?:, target = "[a-z_]+")?( \}})$')
        s = re.sub(pat, r'\1, target = "roblox"\2', s)
    open(manifest, 'w', encoding='utf-8').write(s)
    n_src = rewrite_requires(os.path.join(rb, 'src'), twin_names)
    n_test = rewrite_requires(os.path.join(rb, 'test'), twin_names)
    print(f'staging: quad-roblox require 경로 재작성 — src {n_src} 파일, test {n_test} 파일')

    # 루트 워크스페이스 멤버에 쌍둥이 추가
    root_manifest = os.path.join(stage, 'pesde.toml')
    s = open(root_manifest, encoding='utf-8').read()
    m = re.search(r'(?m)^workspace_members = \[(.*)\]$', s)
    if not m:
        sys.exit('staging: 루트 pesde.toml에서 workspace_members를 못 찾았다')
    extra = ''.join(f', "{d}"' for d in twin_dirs)
    s = s[:m.end(1)] + extra + s[m.end(1):]
    open(root_manifest, 'w', encoding='utf-8').write(s)

    patch_stage_tooling(stage, twin_names, 'quad-base' in twins)


def patch_stage_tooling(stage, twin_names, quad_base_is_roblox):
    """스테이징에서 게이트가 돌게 도구 넷을 고친다.

    ⚠️ 넷 다 **레포에도 필요한 변경**이다 — 쌍둥이를 레포에 두는 쪽(스테이징 대신)을 택하면
    그대로 옮기면 되고, 스테이징을 쓰더라도 "레포엔 없는 수정"이라는 부채로 남는다."""
    # 1) relink.sh — 매니페스트가 없을 때의 복구 경로가 패키지 이름을 멤버 폴더 이름으로
    #    되돌려 추측한다(`member="${pkg//_/-}"`). 쌍둥이가 생기면 같은 이름의 멤버가 둘이라
    #    **엉뚱한 쪽(luau 원본)을 복사**한다 — 실측으로 확인됨. 아직 심볼릭인 항목은
    #    1) 단계가 정확한 대상을 기록하므로 여기서 건너뛰게 한다.
    relink = os.path.join(stage, 'scripts', 'relink.sh')
    sub1(relink, r'(?m)^(\t\t\[ -d "\$d" \] \|\| continue\n)',
         r'\1\t\t[ -L "$d" ] && continue\n', 'relink.sh 심볼릭 스킵(디렉터리)')
    sub1(relink, r'(?m)^(\t\t\tn="\$\(basename "\$e"\)"\n)',
         r'\1\t\t\t[ -L "$e" ] && continue\n', 'relink.sh 심볼릭 스킵(엔트리)')
    # 2) test.sh — luau-lsp 패스가 `luau_packages` 사본만 무시한다. 의존이 roblox 타깃이 되면
    #    사본이 `roblox_packages`로 옮겨가 그대로 진단 대상이 된다(원본은 위 그룹이 이미 봄).
    test_sh = os.path.join(stage, 'scripts', 'test.sh')
    #    [2026-09-11] 앵커가 둘이다 — 2026-09-10 밤 `2bdc3f0`이 엔진 무관 그룹의 신 솔버 패스를 더해
    #    luau-lsp 블록이 두 개가 됐다(3.1.0 bump 때 dry-run이 "앵커 2번"으로 죽어 발견). 둘 다 확장한다.
    sub1(test_sh, r'--ignore "\*\*/luau_packages/\*\*" \\',
         '--ignore "**/luau_packages/**" --ignore "**/roblox_packages/**" \\\\',
         'test.sh luau-lsp ignore 확장', expect=2)
    # 3) gen-d.py — 생성 `D`가 박아 넣는 require 한 줄
    gen_d = os.path.join(stage, 'scripts', 'gen-d.py')
    if 'quad_types' in twin_names:
        sub1(gen_d, r'\.\./luau_packages/quad_types', '../roblox_packages/quad_types',
             'gen-d.py require 경로')
        run(['python3', 'scripts/gen-d.py', 'emit'], cwd=stage, check=True)
    # 4) default.project.json — quad-roblox의 링크 폴더가 이름을 바꾼다
    proj = os.path.join(stage, 'default.project.json')
    if os.path.exists(proj):
        d = json.load(open(proj, encoding='utf-8'))
        try:
            node = d['tree']['ReplicatedStorage']['quad-roblox']
        except (KeyError, TypeError):
            node = None
        if node is not None and 'luau_packages' in node:
            del node['luau_packages']
            node['roblox_packages'] = {'$path': 'quad-roblox/roblox_packages'}
        if quad_base_is_roblox:
            # quad-base 자신은 여전히 luau 멤버라 그대로 둔다 — 쌍둥이는 rojo 트리에 안 올린다
            pass
        json.dump(d, open(proj, 'w', encoding='utf-8'), indent='\t', ensure_ascii=False)


def summarize_publish(out, pkgdir, dry):
    """pesde publish 출력에서 확인 블록만 뽑고, dry-run이면 타르볼 엔트리 수도 센다."""
    keep = []
    for line in out.splitlines():
        t = line.strip()
        if not t or t.startswith('┃') or 'update available' in t or 'self-upgrade' in t \
                or t.startswith('changelog:'):
            continue
        keep.append(t)
    info = {}
    for k in ('name', 'version', 'target', 'description'):
        for t in keep:
            if t.startswith(k + ':'):
                info[k] = t.split(':', 1)[1].strip()
                break
    entries = None
    tb = os.path.join(pkgdir, 'package.tar.gz')
    if dry and os.path.exists(tb):
        with tarfile.open(tb) as f:
            entries = len(f.getnames())
    return keep, info, entries


def main():
    ap = argparse.ArgumentParser(description='quad pesde 게시 (luau + roblox 두 타깃)')
    g = ap.add_mutually_exclusive_group()
    g.add_argument('--dry-run', action='store_true', default=True,
                   help='타르볼만 만든다 (기본)')
    g.add_argument('--real', action='store_true',
                   help='실제로 게시한다 — 사용자 전용, 확인 프롬프트가 있다')
    ap.add_argument('--twins', choices=sorted(TWIN_SETS), default='four',
                    help='양 타깃으로 게시할 멤버 집합 (기본 four = 사용자 결정 2026-09-10; '
                         'three는 옛 구성 — 위 독스트링 참고)')
    ap.add_argument('--no-test', action='store_true', help='스테이징 test.sh 생략')
    ap.add_argument('--keep', action='store_true', help='스테이징 트리를 남긴다')
    ap.add_argument('--stage-only', action='store_true', help='스테이징만 짓고 멈춘다')
    ap.add_argument('--stage-dir', default=None,
                    help='스테이징을 만들 상위 디렉터리 (기본: 시스템 임시 디렉터리)')
    args = ap.parse_args()
    dry = not args.real

    print('== check-version')
    run(['python3', 'scripts/check-version.py'], cwd=ROOT, capture=False, check=True)

    if args.real:
        print('\n실제 게시입니다. pesde auth login과 qwreey 스코프 소유가 선행돼야 합니다.')
        print('게시는 되돌릴 수 없습니다(같은 이름+버전+타깃은 다시 못 올림).')
        if input('계속하려면 정확히 `publish` 를 입력: ').strip() != 'publish':
            sys.exit('취소됨')

    stage = tempfile.mkdtemp(prefix='quad-publish-', dir=args.stage_dir)
    try:
        build_stage(stage, TWIN_SETS[args.twins])

        print('\n== pesde install (staging)')
        run(['mise', 'exec', '--', 'pesde', 'install'], cwd=stage, capture=False, check=True)

        if args.stage_only:
            print(f'\n스테이징만 지었습니다: {stage}')
            args.keep = True
            return 0

        if not args.no_test:
            print('\n== ./scripts/test.sh (staging) — 판정은 exit code')
            p = run(['./scripts/test.sh'], cwd=stage, capture=True)
            passes = p.stdout.count('=== ALL PASS ===')
            print(f'test.sh exit {p.returncode} (스펙 {passes})')
            if p.returncode != 0:
                sys.stderr.write(p.stdout)
                args.keep = True
                sys.exit('스테이징 게이트 실패 — 게시하지 않습니다.')

        order = [(m, 'luau') for m in ('quad-error', 'type-version-check', 'quad-types',
                                       'quad-base')]
        order += [(TWIN_PREFIX + m, 'roblox') for m in TWIN_SETS[args.twins]]
        order += [('quad-roblox', 'roblox')]

        print(f'\n== publish ({"dry-run" if dry else "REAL"}) — {len(order)}건')
        rows, failed = [], []
        for d, target in order:
            cmd = ['mise', 'exec', '--', 'pesde', 'publish', '-y']
            if dry:
                cmd.append('--dry-run')
            p = run(cmd, cwd=os.path.join(stage, d))
            keep, info, entries = summarize_publish(p.stdout, os.path.join(stage, d), dry)
            ok = p.returncode == 0
            rows.append((d, info.get('name', '?'), info.get('target', target),
                         'OK' if ok else f'FAIL({p.returncode})', entries))
            print(f'  {"OK  " if ok else "FAIL"} {d:<24} {info.get("name", "?"):<28} '
                  f'{info.get("target", target):<7} entries={entries}')
            if not ok:
                failed.append(d)
                sys.stderr.write('\n'.join(keep) + '\n')

        print('\n== 요약')
        print(f'{"dir":<24} {"package":<28} {"target":<7} {"result":<10} entries')
        for r in rows:
            print(f'{r[0]:<24} {r[1]:<28} {r[2]:<7} {r[3]:<10} {r[4]}')
        if failed:
            args.keep = True
            sys.exit(f'실패: {", ".join(failed)}')
        return 0
    finally:
        if args.keep:
            print(f'\n스테이징 유지: {stage}')
        else:
            shutil.rmtree(stage, ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
