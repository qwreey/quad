#!/usr/bin/env python3
"""입력 자리 마커 규칙 검사 (2026-09-15 사용자 결정 — `base/typing-limits.md` 8.11·8.21).

규칙: 공개 타입에서 **입력 자리**(사용자가 quad에 건네는 값)는 재귀 구조가 없는 마커(`StateMarker<T>` 등)로 받고,
**출력 자리**(quad가 사용자에게 건네는 값 — 반환, 사용자 콜백의 인자, 읽기 필드)만 전체형 `State<T>`/`Source<T>`를 쓴다.
근거: 전체형 대조는 재귀 메소드 구조 비교라 복잡도 예산을 사용자 코드와 나눠 쓰고, 비균일 재귀 확장이 선언 순서에
따라 조용히 에러 타입이 되는 신 솔버 결함(8.21)의 표면이 된다.

판정(휴리스틱 — 산문이 아니라 타입 문법 위의 극성 계산):
- `State<`/`Source<` 토큰의 극성 = 그것을 감싸는 **함수 매개변수 목록**(`( … )` 바로 뒤에 `->`)의 개수. 홀수면 입력.
  콜백 매개변수 안(짝수)은 사용자에게 건네는 값이라 허용, 콜백 반환(매개변수 목록 안의 `-> State<…>`, 홀수)은 입력.
- 이름이 `…Options`/`…Opts`/`…Info`로 끝나는 레코드 별칭은 통째로 입력 값이라 본문 전체의 극성을 한 번 뒤집는다.
- 메소드 수신자 `self: State<T>`/`self: Source<T>`는 출력·수신자 자리라 허용(8.11).
- 줄에 `type-surface: allow`가 있으면 그 줄은 건너뛴다(이유를 같은 주석에 적을 것).
사용법: python3 scripts/type-surface-check.py [파일 …]   (인자 없으면 기본 공개 타입 파일 셋; 위반이 있으면 exit 1)
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = ['quad-types/src/init.luau', 'quad-roblox/src/types.luau', 'quad-roblox/src/Declaration/init.luau']
INPUT_RECORD = re.compile(r'^export type ([A-Za-z_]+(?:Options|Opts|Info))(?:<[^>]*>)? = \{', re.M)
TOKEN = re.compile(r'(?<![A-Za-z0-9_.])(State|Source)<')


def blank(text):
    """주석과 문자열을 같은 길이의 공백으로 — 위치(줄 번호)는 보존."""
    def sp(m):
        return re.sub(r'[^\n]', ' ', m.group(0))
    text = re.sub(r'--\[(=*)\[.*?\]\1\]', sp, text, flags=re.S)
    text = re.sub(r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|`(?:[^`\\]|\\.)*`', sp, text)
    return re.sub(r'--[^\n]*', sp, text)


def check(path):
    raw = open(path if os.path.isabs(path) else os.path.join(ROOT, path), encoding='utf-8').read()
    raw_lines = raw.split('\n')
    text = blank(raw)
    # matching parens
    match, stack = {}, []
    for i, c in enumerate(text):
        if c == '(':
            stack.append(i)
        elif c == ')' and stack:
            match[stack.pop()] = i
    param_lists = [(o, cl) for o, cl in match.items() if re.match(r'\s*->', text[cl + 1:cl + 40])]
    # input record bodies
    records = []
    for m in INPUT_RECORD.finditer(text):
        i, depth = m.end() - 1, 0
        for j in range(i, len(text)):
            if text[j] == '{':
                depth += 1
            elif text[j] == '}':
                depth -= 1
                if depth == 0:
                    records.append((i, j))
                    break
    bad = []
    for m in TOKEN.finditer(text):
        pos = m.start()
        polarity = sum(1 for o, cl in param_lists if o < pos < cl)
        polarity += sum(1 for o, cl in records if o < pos < cl)
        if polarity % 2 == 1:
            if re.search(r'\bself\s*:\s*$', text[max(0, pos - 20):pos]):
                continue  # method receiver — 8.11 allows the full type for `self`
            ln = text.count('\n', 0, pos) + 1
            if 'type-surface: allow' in raw_lines[ln - 1]:
                continue
            bad.append((ln, raw_lines[ln - 1].strip()))
    return bad


def main():
    total = 0
    files = sys.argv[1:] or FILES
    for f in files:
        if not os.path.exists(f if os.path.isabs(f) else os.path.join(ROOT, f)):
            continue
        for ln, line in check(f):
            total += 1
            print(f'{f}:{ln}: full State/Source in an input position — use StateMarker<T> (or mark `type-surface: allow` with a reason)\n    {line[:160]}')
    print(f'type-surface-check: {total} input-position State/Source')
    if total:
        sys.exit(1)


if __name__ == '__main__':
    main()
