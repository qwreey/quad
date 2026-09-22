#!/usr/bin/env python3
"""에러 식별자(`QuadNNNN`) 게이트 — 2026-09-22 사용자 결정(`base/error-id-plan.md`).

규칙:
  1. quad가 던지는 모든 메시지는 `QuadNNNN ` (4자리, 공백 하나)로 시작한다 — 메시지 리터럴 안에 글자로.
     raise 자리 = `errorBefore`/`errorBeforeNearest`/`errorAt`/`errorAtNearest` 호출과 직접 `error(` 호출.
     첫 인자가 (a) `"QuadNNNN …"`/`` `QuadNNNN …` `` 리터럴이거나 (b) `"QuadNNNN " .. …` 연결이거나
     (c) 그 줄에 `-- error-code: <이유>` 주석이 있으면(메시지를 헬퍼가 만들거나 되던지기(rethrow)) 통과.
  2. ID는 소스 전체에서 유일하다(같은 ID 두 자리 = 실패). 한 번 붙은 ID는 재사용하지 않는다 — 폐기는 문서 헤딩에 `(폐기)`.
  3. 소스의 모든 ID는 `docs/reference/errors/*.md`에 `### QuadNNNN` 헤딩이 있어야 한다(없으면 실패).
     문서에만 있는 헤딩은 `(폐기)` 표시가 없으면 경고.
사용법:
  python3 scripts/error-codes.py check            # 게이트(test.sh) — 위반 시 exit 1
  python3 scripts/error-codes.py check --partial  # 롤아웃 중: 태그 없는 자리는 세기만 하고 실패시키지 않음
  python3 scripts/error-codes.py list             # raise 자리 전수(파일:줄, 태그 여부) — 배정 계획용
  python3 scripts/error-codes.py --next           # 다음 미사용 번호
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIRS = ['quad-base/src', 'quad-roblox/src', 'quad-types/src']  # quad-error는 던지는 메커니즘이지 메시지 주인이 아니다
DOC_DIR = 'docs/reference/errors'
ID_RE = re.compile(r'Quad(\d{4})')
CALL_RE = re.compile(r'(?<![\w.])(?:[\w.]+\.)?(errorBefore|errorBeforeNearest|errorAt|errorAtNearest|error)\s*\(')
ALLOW_RE = re.compile(r'--\s*error-code:\s*\S')


def src_files():
    out = []
    for d in SRC_DIRS:
        for dp, dn, fn in os.walk(os.path.join(ROOT, d)):
            for f in fn:
                if f.endswith('.luau'):
                    out.append(os.path.join(dp, f))
    return sorted(out)


def blank_comments(text):
    """주석만 같은 길이의 공백으로(문자열은 보존) — 위치 보존."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in '"\'':
            j = i + 1
            while j < n and text[j] != c:
                j += 2 if text[j] == '\\' else 1
            out.append(text[i:j + 1]); i = j + 1
        elif c == '`':
            j = i + 1
            while j < n and text[j] != '`':
                j += 2 if text[j] == '\\' else 1
            out.append(text[i:j + 1]); i = j + 1
        elif text.startswith('--[[', i) or text.startswith('--[=', i):
            m = re.match(r'--\[(=*)\[', text[i:])
            close = ']' + m.group(1) + ']'
            j = text.find(close, i)
            j = n if j < 0 else j + len(close)
            out.append(re.sub(r'[^\n]', ' ', text[i:j])); i = j
        elif text.startswith('--', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j
        else:
            out.append(c); i += 1
    return ''.join(out)


def first_arg(text, start):
    """`(` 다음부터 첫 최상위 `,` 또는 짝 `)` 전까지 — 문자열·괄호를 넘는다."""
    depth, i, n = 0, start, len(text)
    while i < n:
        c = text[i]
        if c in '"\'`':
            j = i + 1
            while j < n and text[j] != c:
                j += 2 if text[j] == '\\' else 1
            i = j + 1; continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            if depth == 0:
                return text[start:i]
            depth -= 1
        elif c == ',' and depth == 0:
            return text[start:i]
        i += 1
    return text[start:]


def scan():
    """raise 자리 목록과 ID 집합."""
    sites, ids = [], {}
    for path in src_files():
        raw = open(path, encoding='utf-8').read()
        text = blank_comments(raw)
        lines = raw.split('\n')
        for m in ID_RE.finditer(text):  # 주석은 지웠으니 문자열·코드 안의 ID만
            ln = text.count('\n', 0, m.start()) + 1
            ids.setdefault(m.group(0), []).append(f'{os.path.relpath(path, ROOT)}:{ln}')
        for m in CALL_RE.finditer(text):
            name = m.group(1)
            ln = text.count('\n', 0, m.start()) + 1
            line_start = text.rfind('\n', 0, m.start()) + 1
            if 'function' in text[line_start:m.start()]:
                continue  # 정의(`function ns.errorBefore(`)이지 호출이 아님
            arg = first_arg(text, m.end()).strip()
            line = lines[ln - 1]
            tagged = bool(re.match(r'^["`\']Quad\d{4} ', arg)) or bool(re.match(r'^"Quad\d{4} "\s*\.\.', arg))
            allowed = bool(ALLOW_RE.search(line))
            sites.append({'file': os.path.relpath(path, ROOT), 'line': ln, 'call': name,
                          'arg': arg[:80].replace('\n', ' '), 'tagged': tagged, 'allowed': allowed})
    return sites, ids


def doc_ids():
    found = {}
    d = os.path.join(ROOT, DOC_DIR)
    if not os.path.isdir(d):
        return found
    for f in sorted(os.listdir(d)):
        if not f.endswith('.md'):
            continue
        for i, line in enumerate(open(os.path.join(d, f), encoding='utf-8'), 1):
            m = re.match(r'^###\s+`?(Quad\d{4})`?(.*)$', line)
            if m:
                found.setdefault(m.group(1), []).append((f'{DOC_DIR}/{f}:{i}', '폐기' in m.group(2)))
    return found


def main():
    args = sys.argv[1:]
    sites, ids = scan()
    if '--next' in args:
        used = sorted(int(k[4:]) for k in ids)
        print(f'Quad{(used[-1] + 1 if used else 1):04d}')
        return 0
    if 'list' in args:
        for s in sites:
            flag = 'OK ' if (s['tagged'] or s['allowed']) else '-- '
            print(f"{flag}{s['file']}:{s['line']}  {s['call']}  {s['arg']}")
        print(f'{len(sites)} raise sites, {sum(1 for s in sites if s["tagged"] or s["allowed"])} tagged/allowed, {len(ids)} ids')
        return 0
    partial = '--partial' in args
    errors, warns = [], []
    for k, where in ids.items():
        if len(where) > 1:
            errors.append(f'{k} appears at {len(where)} places: ' + ', '.join(where))
    untagged = [s for s in sites if not (s['tagged'] or s['allowed'])]
    for s in untagged:
        (warns if partial else errors).append(f"{s['file']}:{s['line']}  {s['call']}(…) has no QuadNNNN prefix (or `-- error-code:` note): {s['arg']}")
    docs = doc_ids()
    for k in sorted(ids):
        if k not in docs:
            errors.append(f'{k} has no `### {k}` section under {DOC_DIR}/ (sources: {", ".join(ids[k])})')
        elif len(docs[k]) > 1:
            errors.append(f'{k} has {len(docs[k])} doc sections: ' + ', '.join(w for w, _ in docs[k]))
    for k in sorted(docs):
        if k not in ids and not docs[k][0][1]:
            warns.append(f'{k} documented at {docs[k][0][0]} but not raised anywhere — mark the heading `(폐기)` or remove')
    for w in warns:
        print('warn: ' + w)
    for e in errors:
        print('error: ' + e)
    print(f'error-codes: {len(ids)} ids, {len(sites)} raise sites, {len(untagged)} untagged, {len(errors)} errors, {len(warns)} warnings')
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
