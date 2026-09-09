#!/usr/bin/env python3
"""docs/reference 커버리지 검사 (2026-09-09).

공개 표면의 심볼이 `docs/reference/**/*.md`의 `##` 헤딩(심볼 절)에 존재하는지 본다.
사용자 결정: 레퍼런스는 손으로 "관리"한다 — 생성기는 없고, 이 검사가 빠진 심볼만 알려준다.

심볼 소스(코드가 진실):
  - `quad-types/src/init.luau`의 `export type Quad = { ... }` 필드 → `q.<name>` (모듈 표면 전부: 설치되는 것 포함)
  - `quad-roblox/src/init.luau`의 `export type RobloxExtension = { ... }` 필드 → `q.<name>`
  - `quad-types`의 주요 타입(State/Source/Store/Slot/Ref/Observer/EffectHandle/Blocker/Modifier/Tag/Attr/Context/
    TimedGate/GateHandle/Handler/Dispatch) 최상위 필드 → 멤버 이름
매치 규칙(`##`/`###` 헤딩과 표 행 텍스트, 백틱·역슬래시·HTML 엔티티 무시, `00-index.md` 제외):
  - 모듈 키: `q.<name>`/`q:<name>` 뒤에 `(`/`{`/`.`/공백/끝
  - 멤버: `:<name>(` 또는 `.<name>`(필드) — 타입별로 어느 페이지든 헤딩에 있으면 통과(타입 구분은 안 한다: 이름이 겹치는
    멤버(`Set`/`Get`/`Apply`)는 한 페이지만 있어도 통과한다 — 검사의 목적은 "통째로 빠진 심볼"을 잡는 것)
제외: `__`로 시작하는 내부 필드, `read __quad*` 마커, 주입 op(bindLifetime 등 19개 — extend/01이 계약 에세이로 덮는다).
사용법: python3 scripts/doc-coverage.py  (빠진 심볼이 있으면 exit 1)
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TYPES = os.path.join(ROOT, 'quad-types', 'src', 'init.luau')
RBX = os.path.join(ROOT, 'quad-roblox', 'src', 'init.luau')
REF = os.path.join(ROOT, 'docs', 'reference')

CONTRACT_ONLY = {'Handler'}  # 레코드 계약 — extend/02가 필드 표로 설명한다(멤버 헤딩을 요구하지 않는다)
INJECTED = {
    'nativeInsert', 'nativeExtract', 'nativeRemove', 'nativeMove', 'nativeSwap', 'nativeDispose', 'isInst',
    'onDestroying', 'nativeClaim', 'nativeFindChild', 'bindLifetime', 'unbindLifetime', 'canBound', 'canExecute',
    'addTag', 'removeTag', 'setAttr', 'setTimeout', 'clearTimeout',
}
MEMBER_TYPES = ['State', 'Source', 'Store', 'Slot', 'Ref', 'Observer', 'EffectHandle', 'Blocker', 'Modifier', 'Tag',
                'Attr', 'Context', 'TimedGate', 'GateHandle', 'Handler', 'Dispatch']


def strip_comments(text):
    """주석을 지운다 — 주석 안의 짝 없는 `<`/`(`가 괄호 깊이를 망가뜨린다."""
    text = re.sub(r'--\[(=*)\[.*?\]\1\]', '', text, flags=re.S)
    return re.sub(r'--[^\n]*', '', text)


def block_fields(text, head_regex):
    """`export type X = {` (또는 `X<T> = A & {`) 블록의 최상위 필드 이름."""
    text = strip_comments(text)
    m = re.search(head_regex, text, re.M)
    if not m:
        return []
    i = text.index('{', m.end() - 1)
    depth = 0
    paren = 0  # 여러 줄로 쓴 함수 타입의 파라미터 줄(`self: any,`)을 필드로 오인하지 않게 괄호 깊이도 센다
    fields = []
    j = i
    line_start = True
    while j < len(text):
        c = text[j]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                break
        elif c == '(' or c == '<':
            paren += 1
        elif c == ')' or (c == '>' and text[j - 1] != '-'):  # `->` 화살표의 `>`는 닫는 괄호가 아니다
            paren = max(0, paren - 1)
        elif c == '\n':
            line_start = True
            j += 1
            continue
        if depth == 1 and paren == 0 and line_start:
            mm = re.match(r'[ \t]*(?:read )?([A-Za-z_][A-Za-z0-9_]*)\s*:', text[j:j + 200])
            if mm and not mm.group(1).startswith('__'):
                fields.append(mm.group(1))
            line_start = False
        j += 1
    return fields


def main():
    types = open(TYPES, encoding='utf-8').read()
    rbx = open(RBX, encoding='utf-8').read()
    module_keys = [f for f in block_fields(types, r'^export type Quad = \{') if f not in INJECTED]
    module_keys += block_fields(rbx, r'^export type RobloxExtension = \{')
    members = {}
    for t in MEMBER_TYPES:
        fs = block_fields(types, rf'^export type {t}(?:<[^>]*>)? = (?:[^\n{{]*)\{{')
        if fs:
            members[t] = fs

    headings = []
    for dp, dn, fn in os.walk(REF):
        for f in fn:
            if f.endswith('.md') and f != '00-index.md':  # 색인은 표 행으로 전부를 담아 게이트를 무력화한다 — 제외
                for line in open(os.path.join(dp, f), encoding='utf-8'):
                    if line.startswith('## ') or line.startswith('### ') or line.startswith('|'):
                        # 헤딩 + 표 행(술어 페이지는 표 한 장이 정본). 백틱·역슬래시·HTML 엔티티는 벗긴다
                        headings.append(line.replace('`', '').replace('\\', '').replace('&lt;', '<').replace('&gt;', '>').strip())
    htext = '\n'.join(headings)

    missing = []
    for k in module_keys:
        if not re.search(rf'q[.:]{re.escape(k)}(?:[\s(\{{.<:]|$)', htext, re.M):
            missing.append(f'q.{k}')
    for t, fs in members.items():
        if t in CONTRACT_ONLY:
            continue
        for f in fs:
            if f in INJECTED:
                continue
            if not re.search(rf'[:.]{re.escape(f)}(?:[\s(<]|$)', htext, re.M):
                missing.append(f'{t}.{f}')

    total = len(module_keys) + sum(len(v) for v in members.values())
    print(f'doc-coverage: {total - len(missing)}/{total} symbols have a heading in docs/reference')
    if missing:
        print('missing:')
        for m in missing:
            print('  ', m)
        sys.exit(1)


if __name__ == '__main__':
    main()
