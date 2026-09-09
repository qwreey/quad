#!/usr/bin/env python3
"""docs/ 정본 → site/src/content/docs/ko/ 동기화 (2026-09-09, sync-docs.sh 대체).

- 트랙 폴더를 재귀 복사한다(reference/core 같은 하위 폴더 포함).
- 원본은 Starlight frontmatter(title/description)를 갖는다 — 없으면 실패한다(사용자 결정: frontmatter는 원본에).
- 복사본에서는 본문 첫 H1을 지운다(Starlight가 title로 H1을 그리므로 중복 방지; 원본은 GitHub에서 읽히게 H1 유지).
- 상대 링크 `(../x/y.md)`·`(./y.md)`·`(../../x/y.md)`(+#anchor)를 사이트 경로 `/quad/ko/<path without .md>/`로 바꾼다.
"""
import os, re, shutil, sys

SITE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(SITE)
DEST = os.path.join(SITE, 'src', 'content', 'docs', 'ko')
BASE = '/quad/ko/'
TRACKS = ['overview', 'getting-started', 'how-to', 'quadnomicon', 'reference']
LINK = re.compile(r'\]\(((?:\.\.?/)+[^)#\s]+?\.md)(#[^)\s]*)?\)')

def convert(src_path, text):
    def rep(m):
        target = os.path.normpath(os.path.join(os.path.dirname(src_path), m.group(1)))
        rel = os.path.relpath(target, DOCS)
        if rel.startswith('..'):
            return m.group(0)
        slug = rel[:-3] if rel.endswith('.md') else rel
        return f']({BASE}{slug}/{m.group(2) or ""})'
    return LINK.sub(rep, text)

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
    for track in TRACKS:
        src_dir = os.path.join(DOCS, track)
        if not os.path.isdir(src_dir):
            continue
        dest_dir = os.path.join(DEST, track)
        shutil.rmtree(dest_dir, ignore_errors=True)
        n = 0
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
                out = strip_h1(convert(sp, text))
                dst = os.path.join(dest_dir, os.path.relpath(sp, src_dir))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                open(dst, 'w', encoding='utf-8').write(out)
                n += 1
        print(f'  ✓ {track}: {n} files')
    if failed:
        print(f'{failed} file(s) skipped — add frontmatter', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
