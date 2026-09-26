"""Reference predicates transcribed from the docs, one per wording.

Each doc sentence is turned into a predicate; knobs cover the places where a doc is silent
(the knob value named in `DOC_READINGS` is the literal reading of that doc).
"""
import re

DIGITS = re.compile(r'^[0-9]+$')


def split_build_then_dash(v):
    # "+ 뒤 빌드 메타데이터를 버리고, 첫 -에서 core와 프리릴리즈 꼬리로 나눕니다" (extend/01)
    core = v.split('+', 1)[0]
    if '-' in core:
        c, pre = core.split('-', 1)
        return c, pre
    return core, None


def numeric(s, mode):
    """'숫자로 N 이상' — what counts as a number.
    digits: SemVer numeric identifier-ish (ASCII digits only), exact big-int compare
    luau:   approximate Luau tonumber (used only to attribute divergences)"""
    if mode == 'digits':
        return int(s) if DIGITS.match(s) else None
    t = s.strip(' \t\n\r\f\v')
    if t != s.strip() or '_' in t or t == '':
        return None
    try:
        if re.match(r'^[+-]?0[xX][0-9a-fA-F]+$', t):
            return float(int(t, 16))
        if re.match(r'^[+-]?(inf|nan|infinity)$', t, re.I):
            return float(t)
        if re.match(r'^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$', t):
            return float(t)
    except ValueError:
        return None
    return None


def places(actual, pattern, num='digits', caret_bad_n='false'):
    a, p = actual.split('.'), pattern.split('.')
    if len(a) != len(p):          # "자리 개수가 다르면 불일치"
        return False
    for x, y in zip(a, p):
        if y == '*':               # "*(뭐든)"
            continue
        if y.endswith('^'):
            n = numeric(y[:-1], num)
            if n is None:
                if caret_bad_n == 'exact':   # read "N^" as not-this-form -> "그 외 정확 일치"
                    if x != y:
                        return False
                    continue
                return False
            xv = numeric(x, num)
            if xv is None or xv < n:         # "숫자로 N 이상", "숫자가 아닌 자리엔 안 먹는다"
                return False
            if xv > n:                       # "N보다 크면 그 구간의 뒤 자리는 보지 않는"
                return True
            continue
        if x != y:                           # "그 외 정확 일치"
            return False
    return True


def ext01(actual, pattern, num='digits', caret_bad_n='false'):
    """extend/01-backend-provider-contract.md 232-236 (also the source header; README defers to it;
    core/01 169 states only the tail/build/| part and defers to extend/01)."""
    for alt in pattern.split('|'):                          # "|로 먼저 나눈 대안 중 하나라도"
        ac, apre = split_build_then_dash(actual)
        pc, ppre = split_build_then_dash(alt)
        if (apre is None) != (ppre is None):                # "꼬리의 있고 없음은 양쪽이 같아야"
            continue
        if not places(ac, pc, num, caret_bad_n):            # "core와 꼬리를 각각 .로 나눠 따로"
            continue
        if ppre is not None and not places(apre, ppre, num, caret_bad_n):
            continue
        return True
    return False


def rbx01(actual, pattern, num='digits', caret_bad_n='false'):
    """roblox/01-install.md 66-69: "대안마다 .로 나뉜 자리를 * / N^(N보다 크면 뒤 자리는 보지 않는) / 그 외"
    + build ignored + tail presence equal. It never says core and tail are judged separately, so the
    literal reading splits the whole (build-stripped) alternative on '.' and a '>' skips the tail too."""
    for alt in pattern.split('|'):
        a = actual.split('+', 1)[0]
        p = alt.split('+', 1)[0]
        if ('-' in a) != ('-' in p):
            continue
        if places(a, p, num, caret_bad_n):
            return True
    return False


def core01(actual, pattern):
    """core/01-quad-module.md 169: only build-ignored / tail-presence / | ; place rules deferred to extend/01."""
    return ext01(actual, pattern)
