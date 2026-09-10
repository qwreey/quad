#!/usr/bin/env python3
"""docs/ 정본 → site/src/content/docs/ 동기화(한국어가 root 로케일 — 2026-09-10) (2026-09-09, sync-docs.sh 대체).

- 트랙 폴더를 재귀 복사한다(reference/core 같은 하위 폴더 포함).
- 원본은 Starlight frontmatter(title/description)를 갖는다 — 없으면 실패한다(사용자 결정: frontmatter는 원본에).
- 복사본에서는 본문 첫 H1을 지운다(Starlight가 title로 H1을 그리므로 중복 방지; 원본은 GitHub에서 읽히게 H1 유지).
- 상대 링크 `(../x/y.md)`·`(./y.md)`·`(../../x/y.md)`(+#anchor)를 사이트 경로 `/<path without .md>/`로 바꾼다(base `/`, 한국어 root 로케일).
- GitHub 경고 블록(`> [!NOTE]` 등)은 Starlight aside(`:::note` …)로 바꾼다(2026-09-10).
- `docs/assets/**`를 `site/public/assets/`로 복사하고 `../assets/x.svg` 참조를 `/assets/x.svg`로 바꾼다; 다크 대응 `<picture>`(GitHub 방식)는 `.light-only`/`.dark-only` 이미지 둘로 바꾼다(2026-09-10).
- 트랙 밖(`skills/` 등 사이트에 복사되지 않는 곳)을 가리키는 링크는 링크를 벗기고 텍스트만 남긴다(GitHub에서는 원본 링크가 그대로 산다).
"""
import os, re, shutil, sys

SITE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(SITE)
DEST = os.path.join(SITE, 'src', 'content', 'docs')  # 한국어 = root 로케일(2026-09-10); en/은 별도
BASE = '/'  # [2026-09-10] Cloudflare Pages 루트 배포 + 한국어 root 로케일 — astro.config의 base '/'와 짝
TRACKS = ['overview', 'getting-started', 'how-to', 'quadnomicon', 'reference']
LINK = re.compile(r'\[([^\]]*)\]\(((?:\.\.?/)+[^)#\s]+?\.md)(#[^)\s]*)?\)')

def convert(src_path, text):
    def rep(m):
        label, href, anchor = m.group(1), m.group(2), m.group(3) or ''
        target = os.path.normpath(os.path.join(os.path.dirname(src_path), href))
        rel = os.path.relpath(target, DOCS)
        if rel.startswith('..'):
            return m.group(0)
        if rel.split(os.sep)[0] not in TRACKS:
            return label  # 사이트에 없는 페이지 — 링크를 벗긴다
        slug = rel[:-3] if rel.endswith('.md') else rel
        return f'[{label}]({BASE}{slug}/{anchor})'
    return LINK.sub(rep, text)

# [2026-09-10 사용자 버그 리포트] GitHub 스타일 경고(`> [!CAUTION]` …)는 Starlight가 그대로 텍스트로 그린다 —
# 사본에서는 Starlight aside(`:::caution` … `:::`)로 바꾼다. 원본은 GitHub에서 렌더되게 그대로 둔다.
ALERT_KIND = {'NOTE': 'note', 'TIP': 'tip', 'IMPORTANT': 'tip', 'WARNING': 'caution', 'CAUTION': 'danger'}
ALERT_HEAD = re.compile(r'^> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*)$')

def alerts_to_asides(text):
    lines = text.split('\n')
    out = []
    i = 0
    while i < len(lines):
        m = ALERT_HEAD.match(lines[i])
        if not m:
            out.append(lines[i]); i += 1
            continue
        kind, title = ALERT_KIND[m.group(1)], m.group(2).strip()
        body = []
        i += 1
        while i < len(lines) and lines[i].startswith('>'):
            body.append(lines[i][2:] if lines[i].startswith('> ') else lines[i][1:])
            i += 1
        out.append(f':::{kind}[{title}]' if title else f':::{kind}')
        out.extend(body)
        out.append(':::')
    return '\n'.join(out)

ASSETS_SRC = os.path.join(DOCS, 'assets')                      # 정본 그림(SVG 등) — 2026-09-10 사용자 결정
ASSETS_DEST = os.path.join(SITE, 'public', 'assets')            # 사이트에선 /assets/<name>
PICTURE = re.compile(r'<picture>\s*<source\s+media="\(prefers-color-scheme:\s*dark\)"\s+srcset="([^"]+)"\s*/?>\s*<img\s+([^>]*?)src="([^"]+)"([^>]*?)/?>\s*</picture>', re.S)
ASSET_REF = re.compile(r'((?:\.\./)+|\./)assets/([A-Za-z0-9_./-]+)')

def rewrite_assets(text):
    """`../assets/x.svg`류를 `/assets/x.svg`로, `<picture>`(GitHub 다크 대응)를 테마 클래스 이미지 둘로.
    Starlight는 OS 설정이 아니라 `data-theme`로 테마를 잡으므로 media query가 토글을 못 따른다 —
    `src/styles/theme-images.css`가 `.light-only`/`.dark-only`를 가른다."""
    def pic(m):
        dark, pre, light, post = m.group(1), m.group(2), m.group(3), m.group(4)
        attrs = (pre + post).strip()
        return f'<img class="light-only" src="{light}" {attrs}>\n<img class="dark-only" src="{dark}" {attrs}>'
    text = PICTURE.sub(pic, text)
    return ASSET_REF.sub(lambda m: f'{BASE}assets/{m.group(2)}', text)

def sync_assets():
    if not os.path.isdir(ASSETS_SRC):
        return 0
    n = 0
    written = set()
    for dp, dn, fn in os.walk(ASSETS_SRC):
        for f in fn:
            sp = os.path.join(dp, f)
            dst = os.path.join(ASSETS_DEST, os.path.relpath(sp, ASSETS_SRC))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            written.add(os.path.abspath(dst))
            data = open(sp, 'rb').read()
            if not os.path.exists(dst) or open(dst, 'rb').read() != data:
                open(dst, 'wb').write(data)
            n += 1
    if os.path.isdir(ASSETS_DEST):
        for dp, dn, fn in os.walk(ASSETS_DEST, topdown=False):
            for f in fn:
                fp = os.path.abspath(os.path.join(dp, f))
                if fp not in written:
                    os.remove(fp)
    return n

def strip_h1(text):
    lines = text.split('\n')
    i = 0
    if lines and lines[0].strip() == '---':
        i = 1
        while i < len(lines) and lines[i].strip() != '---':
            i += 1
        i += 1
    for j in range(i, min(i + 5, len(lines))):
        if lines[j].startswith('# '):
            del lines[j]
            if j < len(lines) and lines[j].strip() == '':
                del lines[j]
            break
    return '\n'.join(lines)

def main():
    failed = 0
    print(f'  ✓ assets: {sync_assets()} files')
    for track in TRACKS:
        src_dir = os.path.join(DOCS, track)
        if not os.path.isdir(src_dir):
            continue
        dest_dir = os.path.join(DEST, track)
        # [2026-09-10] rmtree 하지 않는다 — `astro dev`(chokidar)가 감시하던
        # 디렉터리가 통째로 사라지면 그 뒤 변경을 못 보고 옛 렌더를 계속 준다
        # (실측: dev 중 두 번째 변경부터 반영 안 됨). 대신 내용이 달라진 파일만
        # 쓰고, 정본에서 사라진 사본만 지운다 — 출력은 동일하고 idempotent하다.
        n = 0
        written = set()
        for dp, dn, fn in os.walk(src_dir):
            for f in sorted(fn):
                if not f.endswith('.md'):
                    continue
                sp = os.path.join(dp, f)
                text = open(sp, encoding='utf-8').read()
                if not text.startswith('---\n'):
                    print(f'ERROR: frontmatter 없음 — {os.path.relpath(sp, DOCS)}', file=sys.stderr)
                    failed += 1
                    continue
                out = rewrite_assets(alerts_to_asides(strip_h1(convert(sp, text))))
                dst = os.path.join(dest_dir, os.path.relpath(sp, src_dir))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                written.add(os.path.abspath(dst))
                prev = None
                if os.path.exists(dst):
                    prev = open(dst, encoding='utf-8').read()
                if prev != out:
                    open(dst, 'w', encoding='utf-8').write(out)
                n += 1
        # 정본에서 없어진 사본 청소(빈 디렉터리도)
        for dp, dn, fn in os.walk(dest_dir, topdown=False):
            for f in fn:
                fp = os.path.abspath(os.path.join(dp, f))
                if fp not in written:
                    os.remove(fp)
            if dp != dest_dir and not os.listdir(dp):
                os.rmdir(dp)
        print(f'  ✓ {track}: {n} files')
    if failed:
        print(f'{failed} file(s) skipped — add frontmatter', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
