#!/usr/bin/env python3
"""docs/ 정본 → site/src/content/docs/ 동기화(한국어가 root 로케일 — 2026-09-10) (2026-09-09, sync-docs.sh 대체).

- 트랙 폴더를 재귀 복사한다(reference/core 같은 하위 폴더 포함).
- 원본은 Starlight frontmatter(title/description)를 갖는다 — 없으면 실패한다(사용자 결정: frontmatter는 원본에).
- 복사본에서는 본문 첫 H1을 지운다(Starlight가 title로 H1을 그리므로 중복 방지; 원본은 GitHub에서 읽히게 H1 유지).
- 상대 링크 `(../x/y.md)`·`(./y.md)`·`(../../x/y.md)`(+#anchor)를 사이트 경로 `/<path without .md>/`로 바꾼다(base `/`, 한국어 root 로케일).
- GitHub 경고 블록(`> [!NOTE]` 등)은 Starlight aside(`:::note` …)로 바꾼다(2026-09-10).
- `docs/assets/**`를 `site/public/assets/`로 복사하고 `../assets/x.svg` 참조를 `/assets/x.svg`로 바꾼다; 다크 대응 `<picture>`(GitHub 방식)는 `.light-only`/`.dark-only` 이미지 둘로 바꾼다(2026-09-10).
- 트랙 밖(`skills/` 등 사이트에 복사되지 않는 곳)을 가리키는 링크는 링크를 벗기고 텍스트만 남긴다(GitHub에서는 원본 링크가 그대로 산다).
- [2026-09-11 사용자 결정] 루트 `CHANGELOG.md`도 사이트에 싣는다(`/changelog/`) — 원본은 Keep a Changelog 형식 그대로 두고(GitHub·패키지 사본이 읽는 파일이라 frontmatter를 넣지 않는다), 사본에만 title/description을 앞에 붙인다. 원본의 `./docs/...` 링크는 루트 기준으로 풀려 사이트 경로가 된다(`research/roadmap-changelog-docs-plan.md` 2.4 실측).
- [2026-09-13] 한 줄 전체가 `<!-- ... -->` HTML 주석뿐인 줄(맨 앞 blockquote `> `는 허용, 코드 펜스 안·리스트 들여쓰기
  줄은 그대로 둔다)을 사본에서 지운다 — starlight-md-txt(플러그인 도입, astro.config 참고)가 모든 docs 항목을
  remark-mdx로 다시 파싱하는데, MDX는 HTML 주석 문법 자체를 안 받고(공백을 앞뒤로 끼워도 마찬가지 — 실측) `{/* text */}`만
  허용한다. 이 코퍼스의 그런 주석은 전부 "mock 실측 …"/"strict 실측 …" 같은 **내부 감사 메모**라 어차피 HTML에서도 안
  보였다 — 읽는 사람에게 보여줄 내용이 아니므로 사이트 사본에서만 지우고 원본(`docs/`)엔 그대로 남긴다.
- [2026-09-13] 같은 이유(starlight-md-txt의 remark-mdx 재파싱)로, 백틱이 아니라 raw HTML `<code>` 태그로 감싼 인라인
  코드 안의 리터럴 `{`/`}`를 HTML 엔티티로 바꾼다 — 코퍼스 전체에서 단 두 곳(`getting-started/02-first-screen.md`·
  `getting-started/13-lists.md`의 `<details><summary><code>D.Frame { … }</code>…` 꼴 캡션)만 해당하고, `<code>` 태그
  안에서 엔티티는 그대로 `{`/`}`로 렌더되므로 화면엔 변화가 없다.
- [2026-09-13] 이해 점검 퀴즈(starlight-quiz, astro.config 참고) — 원본 `.md`는 GitHub에서도 읽히므로 MDX
  import/JSX를 직접 담을 수 없다. 대신 원본에 ` ```quiz ` 코드펜스(GitHub에선 무해한 코드 블록으로 보인다)로
  퀴즈를 적으면, `expand_quizzes()`가 펜스를 벗겨 `<Quiz>` 블록으로 편다 — 본문 파싱은 하지 않는다(질문/체크리스트/
  설명은 그 자체로 이미 GFM이고, starlight-quiz가 그 GFM을 렌더된 DOM에서 런타임에 읽는다 —
  `node_modules/starlight-quiz/lib/parse.ts`의 `findAnswerList`/`splitAtRule` 참고). 펜스 첫 줄 `# 제목`만 뽑아
  `title` prop으로 옮긴다. 펜스가 하나라도 있던 페이지는 (a) 사본 확장자를 `.mdx`로 바꾸고(슬러그는 같다 — 옛
  `.md` 사본은 기존 청소 로직이 지운다, `written` 집합에 `.mdx` 경로만 넣으므로), (b) frontmatter 뒤에
  `import { Quiz, QuizResults } from 'starlight-quiz/components';`를 삽입하고, (c) 파일 끝에
  `<QuizResults />`를 붙인다. 펜스 전개는 `strip_html_comments`/`escape_code_tag_braces`/`self_close_void_tags`
  (전부 ` ``` `/`~~~` 줄로 펜스를 세어 안쪽을 건너뛴다)보다 먼저 돈다 — 안 그러면 그 함수들이 방금 편
  `<Quiz>` 본문을 "코드 펜스 안"으로 착각하고 건너뛰거나, 반대로 펜스 카운트가 어긋난다. 펜스 형식·전개 예시는
  `docs/getting-started/03-flowing-values.md`(첫 파일럿)가 실물 소스.
"""
import json, os, re, shutil, sys

SITE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(SITE)
DEST = os.path.join(SITE, 'src', 'content', 'docs')  # 한국어 = root 로케일(2026-09-10); en/은 별도
BASE = '/'  # [2026-09-10] Cloudflare Pages 루트 배포 + 한국어 root 로케일 — astro.config의 base '/'와 짝
TRACKS = ['overview', 'getting-started', 'how-to', 'quadnomicon', 'reference']
ROOT = os.path.dirname(DOCS)
# 트랙 밖 원본 → 사본 경로, 사본에 붙일 frontmatter (원본은 건드리지 않는다)
EXTRA = [
    (os.path.join(ROOT, 'CHANGELOG.md'), 'changelog.md', {'title': 'Changelog (변경 이력)', 'description': '3.x 릴리즈마다 무엇이 생기고 바뀌고 없어졌는지 — 루트 CHANGELOG.md 원본 그대로'}),
]
LINK = re.compile(r'\[([^\]]*)\]\(((?:\.\.?/)+[^)#\s]+?\.md)(#[^)\s]*)?\)')

def convert(src_path, text):
    def rep(m):
        label, href, anchor = m.group(1), m.group(2), m.group(3) or ''
        target = os.path.normpath(os.path.join(os.path.dirname(src_path), href))
        rel = os.path.relpath(target, DOCS)
        if rel.startswith('..'):
            # [2026-09-11] 루트 CHANGELOG.md는 사이트 /changelog/로 실린다(EXTRA) — docs/ 안에서 그리로 가는 링크만 치환
            if os.path.abspath(target) == os.path.join(ROOT, 'CHANGELOG.md'):
                return f'[{label}]({BASE}changelog/{anchor})'
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
    `src/styles/theme-images.css`가 `.light-only`/`.dark-only`를 가른다.
    [2026-09-13] `<img ... />`로 셀프클로징한다 — starlight-md-txt의 remark-mdx 재파싱은 HTML(commonmark)과 달리
    void 요소도 명시적으로 닫지 않으면 "닫는 태그가 없다"고 에러 낸다(실측: `10-slot.md`)."""
    def pic(m):
        dark, pre, light, post = m.group(1), m.group(2), m.group(3), m.group(4)
        attrs = (pre + post).strip()
        return f'<img class="light-only" src="{light}" {attrs} />\n<img class="dark-only" src="{dark}" {attrs} />'
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

HTML_COMMENT_LINE = re.compile(r'^[ \t]*(?:>\s*)?<!--.*-->\s*$')
HTML_COMMENT_PREFIX = re.compile(r'^<!--.*?-->\s*')
CODE_TAG = re.compile(r'<code>([^<]*)</code>')
VOID_TAG = re.compile(r'<(br|hr|wbr)\s*>')

def self_close_void_tags(text):
    """`<br>`/`<hr>`/`<wbr>`(HTML의 안 닫는 void 요소)를 `<br />` 식으로 셀프클로징한다(코드 펜스는 건드리지 않는다) —
    `<img>`는 `rewrite_assets`의 `pic()`가 이미 셀프클로징으로 만든다. 이유는 그 함수 docstring 참고
    (실측: `reference/sugar/02-operator.md`의 표 안 `<br>` 하나가 이 경로로 걸렸다)."""
    lines = text.split('\n')
    out = []
    in_fence = False
    for line in lines:
        if line.strip().startswith('```') or line.strip().startswith('~~~'):
            in_fence = not in_fence
            out.append(line)
            continue
        out.append(line if in_fence else VOID_TAG.sub(lambda m: f'<{m.group(1)} />', line))
    return '\n'.join(out)

def escape_code_tag_braces(text):
    """raw HTML `<code>...</code>`(백틱이 아니라 태그를 쓴 인라인 코드 — `<details><summary>` 안 캡션에서 쓰인다) 안의
    리터럴 `{`/`}`를 HTML 엔티티로 바꾼다(코드 펜스는 건드리지 않는다: 펜스 안은 이미 안전).
    MDX는 마크다운 백틱 코드 스팬은 보호하지만 raw HTML 흐름 안의 `{}`는 여전히 JS 표현식 시작으로 읽는다 —
    실측: `q.Slot { … }`/`D.Frame { … }`를 `<code>`로 감싼 두 캡션(13-lists.md·02-first-screen.md)이 이 경로로 깨졌다.
    엔티티는 `<code>` 태그 안에서 그대로 `{`/`}`로 렌더되므로 화면엔 변화가 없다."""
    def esc(m):
        return '<code>' + m.group(1).replace('{', '&#123;').replace('}', '&#125;') + '</code>'
    lines = text.split('\n')
    out = []
    in_fence = False
    for line in lines:
        if line.strip().startswith('```') or line.strip().startswith('~~~'):
            in_fence = not in_fence
            out.append(line)
            continue
        out.append(line if in_fence else CODE_TAG.sub(esc, line))
    return '\n'.join(out)

def strip_html_comments(text):
    """`<!-- ... -->` 한 줄 전체가 주석뿐인 줄(들여쓰기·blockquote 머리 `> `는 허용)은 통째로 지우고, 줄 맨 앞에 주석이
    붙고 뒤에 진짜 본문이 이어지는 경우(`06-slot.md`의 "strict 실측 …" 한 줄이 실례)는 그 주석 부분만 잘라내 본문은
    남긴다. MDX가 HTML 주석 문법을 아예 못 받아 starlight-md-txt의 remark-mdx 파싱이 깨지는 것을 막는다(위 모듈
    docstring 참고). 내부 감사 메모라 지워도 읽는 사람에게 보이던 내용이 없다."""
    lines = text.split('\n')
    out = []
    in_fence = False
    for line in lines:
        if line.strip().startswith('```') or line.strip().startswith('~~~'):
            in_fence = not in_fence
            out.append(line)
            continue
        if not in_fence:
            if HTML_COMMENT_LINE.match(line):
                continue
            line = HTML_COMMENT_PREFIX.sub('', line)
        out.append(line)
    return '\n'.join(out)

QUIZ_FENCE = re.compile(r'^```quiz\n(.*?)\n```[ \t]*$', re.M | re.S)
QUIZ_IMPORT = "import { Quiz, QuizResults } from 'starlight-quiz/components';"

def expand_quizzes(text):
    """` ```quiz ` 펜스를 `<Quiz>` MDX 블록으로 편다. 펜스 첫(비어있지 않은) 줄이 `# 제목`이면 그 줄(+뒤 빈 줄)을
    떼어 `title` prop으로 옮기고(JSON 문자열로 이스케이프 — JSX 속성 안 따옴표 문제를 피한다), 나머지는 그대로
    본문에 넣는다 — 질문/체크리스트/설명 구조는 손대지 않는다(모듈 docstring 참고). 여는/닫는 태그 바로 안쪽에
    빈 줄을 하나씩 둔다 — MDX는 flow JSX 요소의 자식을 블록으로 띄워야 마크다운으로 파싱하므로, 붙여 쓰면
    질문 줄이 그냥 텍스트로 눌러앉거나 체크리스트가 `<ul>`로 안 열릴 수 있다(빌드는 그래도 exit 0이라 조용히 샌다).
    반환값 (변환된 텍스트, 펜스 개수) — 개수가 0보다 크면 호출자(`transform`)가 import 삽입·`<QuizResults />`를 붙인다."""
    count = 0
    def rep(m):
        nonlocal count
        count += 1
        lines = m.group(1).split('\n')
        while lines and lines[0].strip() == '':
            lines.pop(0)
        title = None
        if lines and lines[0].startswith('# '):
            title = lines[0][2:].strip()
            lines.pop(0)
            while lines and lines[0].strip() == '':
                lines.pop(0)
        inner = '\n'.join(lines).strip('\n')
        attr = f' title={{{json.dumps(title, ensure_ascii=False)}}}' if title else ''
        return f'<Quiz{attr}>\n\n{inner}\n\n</Quiz>'
    return QUIZ_FENCE.sub(rep, text), count

def insert_quiz_import(text):
    """frontmatter(첫 줄 `---` ~ 닫는 `---`) 바로 뒤에 퀴즈 컴포넌트 import를 끼운다. 호출 시점엔 텍스트가 이미
    `---\\n`으로 시작함이 보장돼 있다(main()의 frontmatter 체크)."""
    lines = text.split('\n')
    i = 1
    while i < len(lines) and lines[i].strip() != '---':
        i += 1
    i += 1
    lines[i:i] = ['', QUIZ_IMPORT, '']
    return '\n'.join(lines)

def transform(src_path, text):
    """정본 텍스트 하나에 모든 치환(링크 재작성 → H1 제거 → 퀴즈 펜스 전개 → 주석/코드태그/void태그 →
    asides/asset)을 순서대로 적용한다. 트랙 루프와 `EXTRA`(CHANGELOG) 루프가 이 한 함수를 공유한다 —
    갈라져 있으면 한쪽에만 단계를 추가하는 drift가 난다. 퀴즈 펜스가 있었으면 import를 끼우고 파일 끝에
    `<QuizResults />`를 붙인 뒤 (출력, True)를 반환 — 호출자가 사본 확장자를 `.mdx`로 바꾼다."""
    out = strip_h1(convert(src_path, text))
    out, quiz_count = expand_quizzes(out)
    out = rewrite_assets(alerts_to_asides(self_close_void_tags(escape_code_tag_braces(strip_html_comments(out)))))
    if quiz_count:
        out = insert_quiz_import(out).rstrip('\n') + '\n\n<QuizResults />\n'
    return out, bool(quiz_count)

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
                out, has_quiz = transform(sp, text)
                rel = os.path.relpath(sp, src_dir)
                if has_quiz:
                    rel = os.path.splitext(rel)[0] + '.mdx'
                dst = os.path.join(dest_dir, rel)
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
    for sp, name, fm in EXTRA:
        if not os.path.exists(sp):
            print(f'ERROR: 없음 — {sp}', file=sys.stderr)
            failed += 1
            continue
        text = open(sp, encoding='utf-8').read()
        head = '---\n' + ''.join(f'{k}: "{v}"\n' for k, v in fm.items()) + '---\n'
        out, has_quiz = transform(sp, head + text)
        dst_name = os.path.splitext(name)[0] + '.mdx' if has_quiz else name
        dst = os.path.join(DEST, dst_name)
        prev = open(dst, encoding='utf-8').read() if os.path.exists(dst) else None
        if prev != out:
            open(dst, 'w', encoding='utf-8').write(out)
        print(f'  ✓ {os.path.relpath(sp, ROOT)} → {name}')
    if failed:
        print(f'{failed} file(s) skipped — add frontmatter', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
