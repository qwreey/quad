#!/usr/bin/env python3
"""
.claude/ 코퍼스 기계 점검 — 깊은 수동 감사가 반복되는 걸 막기 위한 도구.

배경: 2026-08-13 일곱/여덟 번째 세션에 6+6라운드 수동 감사를 돌려 총 39+16건을
찾았는데, **그중 대부분이 grep으로 잡히는 종류**였음(옮겨간 절을 가리키는 참조,
색인 누락, 날짜 없는 "아직 안 함" 주장). 사람/에이전트의 성실성에 기대는 대신
기계가 매번 같은 걸 확인하게 함.

실행:  python3 .claude/tools/doc-check.py
       python3 .claude/tools/doc-check.py --quiet   # 실패한 검사만
종료코드: 오류(ERROR)가 하나라도 있으면 1, 경고만 있으면 0.

검사 항목  ([2026-08-16 정정] 1·2번의 심각도를 실제 코드에 맞춰 고침 —
           예전엔 둘 다 [ERROR]라고 적어놨지만 코드는 그렇게 동작한 적이 없음)
  1. [ERROR/WARN] 깨진 파일 참조 — 라이브 문서가 가리키는 .md/.luau가 실제로
     없음. 파일명이 이 레포의 명명 관례(`OURS`)에 걸리면 ERROR, 아니면
     외부 문서명일 수 있어 WARN.
  2. [ERROR] 깨진 절 참조 — `foo.md` "절 제목" 이 그 파일에 없음
     (문서를 쪼개거나 헤딩을 고칠 때 가장 잘 걸리는 것 — 아홉 번째 세션에
      bind-system-plan.md를 분할하며 20곳이 여기 걸렸음)
     [2026-08-16] 판정 규칙은 `BOLD_LEAD` 주석과 `conventions.md`의
     "절 인용 규약"이 소스 — `#` 헤딩은 부분문자열, `**볼드**` 절은 줄머리 +
     앞부분일치. 예전엔 `#` 헤딩만 읽어서 볼드 절 인용을 전부 오탐으로
     냈고(78건 중 30건), "의역 인용 관례 때문에 오탐이 섞인다"며 WARN에
     묶여 있었다. 의역 인용을 규약으로 금지하고 불일치를 78→0으로 정리한
     뒤 ERROR로 승격함.
  3. [ERROR] 색인 누락 — base/research/archive/reference 파일이 README에 없음
  4. [WARN]  날짜 없는 시한부 주장 — "아직 안 돌려봄", "열린 질문 없음" 등
     시간이 지나면 거짓이 되는데 언제 기준인지 안 적힌 문장
  5. [WARN]  미반영 배너를 단 파일 vs 반영 목록 일치 여부

검사 대상에서 제외되는 폴더는 `SKIP_DIRS`가 소스 — `session/`(원문 보존),
`initreq/`(읽기 전용 클론), `worktrees/`, `tools/`(이 스크립트 자신이 여기
있으므로 **doc-check.py는 자기 자신을 검사하지 않음**, 이 docstring의 주장은
사람이 손으로 확인해야 함).
`archive/`와 `.claude/session-summary.md`는 검사 대상이되 **히스토리 문서**라
절 참조/시한부 주장 검사는 면제(`is_history()` 참고).
"""
import os, re, sys, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLAUDE = os.path.join(ROOT, '.claude')
SKIP_DIRS = ('session', 'initreq', 'worktrees', 'tools')

errors, warns = [], []


def live_docs():
    out = []
    for base in (CLAUDE, ROOT):
        for dp, dn, fn in os.walk(base):
            rel = os.path.relpath(dp, ROOT)
            if any(p in rel.split(os.sep) for p in SKIP_DIRS):
                dn[:] = []
                continue
            if base is ROOT and rel != '.' and not rel.startswith('.claude'):
                continue
            for f in fn:
                if f.endswith('.md'):
                    out.append(os.path.join(dp, f))
        if base is ROOT:
            break
    # 루트 md 직접 추가
    for f in ('CLAUDE.md', 'ROADMAP.md', 'HUMAN_TODO.md', 'SAFETY.md'):
        p = os.path.join(ROOT, f)
        if os.path.exists(p):
            out.append(p)
    return sorted(set(out))


def rel(p):
    return os.path.relpath(p, ROOT)


# ---------- 1 & 2: 참조 무결성 ----------
# `(경로/)파일.md` 또는 `파일.luau`  (+ 바로 뒤에 "절 제목"이 오면 절 검사도)
# [2026-08-14] 파일명과 "절 제목"이 **줄바꿈에 걸쳐 있어도** 잡도록 개행 허용.
# 예전엔 줄 단위로 돌려서 `base/\nbind-system-plan.md`의 "Length/Offset" 같은
# 자연스러운 줄바꿈 인용을 통째로 놓쳤고, 실제로 문서 분할 후 stale 참조
# 20여 곳이 이 사각지대로 빠져나갔음(14차 세션 리뷰에서 발견).
# [2026-08-16] 인용 길이 상한을 60→160자로 넓힘. 60자를 넘는 절 인용은 매치
# 자체가 안 걸려 **검사에서 조용히 빠져나갔다** — 위양성보다 나쁜 종류의 구멍.
REF = re.compile(r'`\.?/?((?:[\w.-]+/\s*)*[\w.@-]+\.(?:md|luau))`(\s*(?:의\s*)?"([^"]{2,160})")?')

def resolve(target, src):
    """참조 문자열을 실제 경로로 해석 — 상대/부분 경로를 관대하게 매칭."""
    cands = [
        os.path.join(ROOT, target),
        os.path.join(CLAUDE, target),
        os.path.join(os.path.dirname(src), target),
    ]
    for c in cands:
        if os.path.exists(c):
            return c
    # 파일명만으로 찾히면 인정(initreq 포함 — 읽기 전용 클론이지만 실재함)
    name = os.path.basename(target)
    for dp, dn, fn in os.walk(CLAUDE):
        if 'worktrees' in os.path.relpath(dp, ROOT).split(os.sep):
            dn[:] = []
            continue
        if name in fn:
            return os.path.join(dp, name)
    return None


# 이 레포의 문서 명명 관례 — 여기 걸리면 "우리 문서"이므로 못 찾으면 ERROR.
# 안 걸리면 외부 문서명(Compose 가이드라인 등)일 수 있어 WARN으로 낮춤.
OURS = re.compile(r'(-plan|-reversed|-rejected|-findings|-map|-audit|-verification'
                  r'|^README|^STATUS|^CLAUDE|^ROADMAP|^HUMAN_TODO|^SAFETY'
                  r'|^question|^architecture|^agent-mistake'
                  # [2026-08-16] CLAUDE.md 분할 산물. 여기 안 넣으면 이 파일들로
                  # 가는 깨진 참조가 ERROR가 아니라 WARN으로만 잡힌다 — 일곱 번째
                  # 세션에 store-semantics.md에서 실제로 당했던 사각지대.
                  r'|^conventions|^project-context|^todos|^session-summary)\.md$')


# [2026-08-16] 이 코퍼스의 "절"은 `#` 헤딩만이 아니다 — `**볼드**`로 시작하는
# 줄을 하위 절로 쓰고, 다른 문서들이 그걸 "절"이라 부르며 인용해왔다. 그걸
# 안 읽어서 절 참조 WARN 상당수가 위양성이었음 — 라운드별 실측 수치는
# `session/2026-08-16-03-doc-check-section-convention.md`가 소스(여기 복제 안 함).
#
# 다만 볼드를 통째로 절 제목으로 인정하면 검사가 장식이 된다 — 실측상 볼드는
# `#` 헤딩보다 압도적으로 흔하고 대부분은 그냥 강조다. 인용이 무관한 강조
# 스팬에 우연히 걸리면 검사가 조용히 통과해버려 진짜 rot을 놓친다. 그래서
# 규칙을 비대칭으로 둔다:
#   - `#` 헤딩  : **부분문자열** 인용 허용 (명시적 절 마커라 오인 위험 없음)
#   - `**볼드**` 절: 빈 줄 다음이나 리스트 항목 머리에 있고, 인용이 제목
#                    **앞부분부터**일 때만 인정
# 이 비대칭이 곧 `conventions.md`의 "절 인용 규약"이다. 느슨한 규칙과 해소
# 건수는 같으면서 매칭 표면만 좁다는 걸 실측으로 확인하고 채택했다.
# 절 제목으로 인정하는 볼드는 **빈 줄 다음** 또는 **리스트 항목**뿐이다.
# 그냥 "줄머리 볼드"로 두면 **문단이 줄바꿈되며 우연히 줄머리에 걸린 강조**까지
# 절로 잡힌다 — `architecture.md`의 `**pluggable 디스패치 엔진 자체도 …**`가
# 실제 사례로, 진짜 절은 두 줄 위의 `**패키지 경계**`인데 두 문서가 그 우연한
# 자리를 절이라며 인용하고 있었다(커밋 전 감사가 잡음).
# 리스트 마커는 `-`/`*`/`>`뿐 아니라 `1.`도 인정 — `conventions.md`의 핸드오버
# 체크리스트처럼 **번호 항목 자체가 절**이고 다른 문서가 그걸 인용하는 형태가 있다.
BOLD_LEAD = re.compile(
    r'(?:\A|\n[ \t]*\n)[ \t]{0,6}\*\*(.+?)\*\*'                    # 빈 줄 다음
    r'|(?:\A|\n)[ \t]{0,6}(?:[-*>]|\d+\.)[ \t]+\*\*(.+?)\*\*',     # 리스트 항목
    re.S)
# 선두 장식(⚠️/⭐ 등)은 인용할 때 관례적으로 생략되므로 양쪽에서 벗겨내고 비교
DECOR = re.compile(r'^[^\w가-힣`(\[]+')
# 선두 상태/날짜 태그(`[2026-08-16 신설]`, `[해소됨, …]`)도 제목의 일부가 아니다 —
# 시간이 지나면 내용이 바뀌는 메타 표시라 여기에 인용을 묶으면 태그가 갱신될 때마다
# 참조가 깨진다. 양쪽에서 똑같이 벗겨내므로 태그째 인용해도 여전히 매칭된다.
TAG = re.compile(r'^\[[^\]]{2,80}\]\s*')


def norm_section(s):
    """절 제목/인용문을 비교 가능한 형태로 정규화."""
    s = re.sub(r'\s+', ' ', re.sub(r'[`*]', '', s)).strip()
    s = DECOR.sub('', s).strip()
    stripped = DECOR.sub('', TAG.sub('', s)).strip()
    return stripped or s   # 태그가 제목 전부였다면 원본을 남긴다


def squash(s):
    """비교 전용 — 정규화 후 공백까지 전부 제거(줄바꿈 인용 대응)."""
    return re.sub(r'\s+', '', norm_section(s))


def headings(path):
    if not path.endswith('.md') or not os.path.exists(path):
        return None
    hs = []
    for line in open(path, encoding='utf-8'):
        if line.startswith('#'):
            # 백틱/강조 표기는 인용할 때 자주 빠지므로 정규화해서 비교
            hs.append(norm_section(line.lstrip('#')))
    return hs


def bold_leads(path):
    """줄머리 `**볼드**` 절 제목. 위 BOLD_LEAD 주석의 비대칭 규칙 참고."""
    if not path.endswith('.md') or not os.path.exists(path):
        return []
    txt = open(path, encoding='utf-8').read()
    return [norm_section(a or b) for a, b in BOLD_LEAD.findall(txt)]


def interesting(target):
    """검사 가치가 있는 참조인가.

    제외: (a) `initreq/`(읽기 전용 클론, gitignore됨), (b) 아직 존재하지 않는
    **미래 소스 트리**의 `.luau`(구현 시작 전이라 당연히 없음 — `architecture.md`가
    설계로서 적어둔 것), (c) `YYYY-MM-DD-NN-slug.md` 같은 템플릿 자리표시자.
    실제로 지금 존재해야 하는 건 `.md` 문서와 `luau-test/`의 스파이크뿐.
    """
    if 'YYYY' in target:
        return False
    if target.endswith('.luau'):
        return 'luau-test' in target or re.match(r'^\d\d-', os.path.basename(target))
    return True


def is_history(path):
    """히스토리 문서인가 — 절 참조/시한부 주장 검사를 면제한다.

    `archive/`는 뒤집힌 결정의 원문 보존, `session-summary.md`는 세션별
    과거 기록이라 둘 다 "그때는 그렇게 적었다"가 정상이다. 여기에 현재형
    검사를 걸면 영원히 안 꺼지는 WARN만 쌓인다.
    [2026-08-16] CLAUDE.md 분할로 세션 히스토리가 별도 파일이 되면서 추가.
    """
    r = rel(path)
    return '/archive/' in r or os.path.basename(r) == 'session-summary.md'


def check_refs(docs):
    hcache = {}
    for d in docs:
        # 히스토리 문서는 절 참조까지 강제하지 않음(파일 존재만)
        is_archive = is_history(d)
        # 줄 단위가 아니라 **파일 전체**를 한 번에 스캔 — 파일명/절 제목이
        # 줄바꿈에 걸친 인용도 잡기 위함(위 REF 주석 참고). 줄 번호는 매치
        # 시작 오프셋으로 역산.
        text = open(d, encoding='utf-8').read()
        for m in REF.finditer(text):
            ln = text.count('\n', 0, m.start()) + 1
            target, _, section = m.group(1), m.group(2), m.group(3)
            target = re.sub(r'\s+', '', target)
            if section is not None:
                section = re.sub(r'\s+', ' ', section).strip()
            if not interesting(target):
                continue
            p = resolve(target, d)
            if p is None:
                name = os.path.basename(target)
                msg = f"{rel(d)}:{ln}  깨진 파일 참조 → `{target}`"
                (errors if OURS.search(name) else warns).append(
                    msg if OURS.search(name) else msg + " (외부 문서명일 수 있음)")
                continue
            # `initreq/`를 가리키는 인용은 절 검사 제외 — 읽기 전용 외부 원본이라
            # 절 구조가 없다(`raw-userinput.md`는 스스로 "정리가 없는 생각의 흐름"
            # 이라고 밝힌 원문). 저기로 가는 인용은 절 제목이 아니라 원문 문장을
            # 따오는 것이므로 헤딩과 대조하는 게 애초에 의미가 없다.
            if section and not is_archive and p.endswith('.md') \
                    and 'initreq' not in rel(p).split(os.sep):
                if p not in hcache:
                    hcache[p] = (headings(p) or [], bold_leads(p))
                heads, leads = hcache[p]
                # 공백을 뺀 형태로 비교 — 인용이 줄바꿈에 걸리면 원문엔 없는
                # 공백이 끼어든다(`canExecute/\nunbindLifetime` → "canExecute/
                # unbindLifetime"). 이것 때문에 실재하는 절이 불일치로 잡혔음.
                core = squash(section)
                if not (any(core in squash(h) for h in heads)
                        or any(squash(s).startswith(core) for s in leads)):
                    # [2026-08-16] WARN → ERROR로 승격. 예전엔 "절 제목을
                    # 의역해 인용하는 관례" 탓에 오탐이 섞여 WARN이었지만,
                    # `conventions.md`의 "절 인용 규약"이 의역을 금지하고
                    # 불일치를 78→0으로 정리한 뒤 게이트로 올렸다. 문서를
                    # 쪼개거나 헤딩을 고칠 때 여기가 제일 먼저 걸린다.
                    errors.append(
                        f"{rel(d)}:{ln}  절 참조 불일치 → {os.path.basename(p)}에 "
                        f'"{section}" 절 없음')


# ---------- 3: 색인 누락 ----------
def check_index():
    readme = os.path.join(CLAUDE, 'README.md')
    if not os.path.exists(readme):
        errors.append("`.claude/README.md`가 없음")
        return
    txt = open(readme, encoding='utf-8').read()
    for sub in ('base', 'research', 'archive', 'reference'):
        d = os.path.join(CLAUDE, sub)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if f.endswith('.md') and f'`{f}`' not in txt:
                errors.append(f"README 색인 누락 → {sub}/{f}")


# ---------- 4: 날짜 없는 시한부 주장 ----------
TEMPORAL = [
    (r'아직 (?:사용자가 )?안 돌려\S*', '실행 여부 주장'),
    (r'결과 미확인', '실행 여부 주장'),
    (r'열린 질문(?:은)? 없(?:음|다)', '완결 주장'),
    (r'더 이상 (?:막힌|열려있는|열려 있는)\S* 없\S*', '완결 주장'),
    (r'남은 (?:유일한|건)[^\n]{0,20}뿐', '완결 주장'),
    (r'전부 확정됨', '완결 주장'),
]
DATED = re.compile(r'20\d\d-\d\d-\d\d|\[\s*(?:해소|정정|갱신|확정|역전)')

def check_temporal(docs):
    for d in docs:
        if is_history(d):
            continue
        lines = open(d, encoding='utf-8').read().split('\n')
        for i, line in enumerate(lines, 1):
            for pat, kind in TEMPORAL:
                if re.search(pat, line):
                    ctx = '\n'.join(lines[max(0, i - 3):i + 2])
                    if not DATED.search(ctx):
                        warns.append(
                            f"{rel(d)}:{i}  날짜 없는 {kind} — "
                            f"\"{re.search(pat, line).group(0)}\" "
                            f"(언제 기준인지 적을 것)")


# ---------- 5: 미반영 배너 ----------
def check_banner(docs):
    banner = [d for d in docs if '아직 반영 안 됨' in open(d, encoding='utf-8').read()]
    if not banner:
        return
    names = sorted(os.path.basename(b) for b in banner)
    plan = os.path.join(CLAUDE, 'research', 'dispatch-redispatch-diff-plan.md')
    if os.path.exists(plan):
        txt = open(plan, encoding='utf-8').read()
        missing = [n for n in names if n not in txt]
        if missing:
            warns.append(
                "미반영 ⚠️ 배너를 달고 있는데 반영 목록"
                "(dispatch-redispatch-diff-plan.md 6절)에 없는 파일: "
                + ', '.join(missing))
    warns.append(f"미반영 배너를 단 파일 {len(names)}개 — 해소 시 배너도 같이 걷을 것: "
                 + ', '.join(names))


def main():
    quiet = '--quiet' in sys.argv
    docs = live_docs()
    check_refs(docs)
    check_index()
    check_temporal(docs)
    check_banner(docs)

    # 제외 목록은 SKIP_DIRS 하나만 소스로 두고 여기서 다시 적지 않음
    # ([2026-08-16] 예전엔 "session/·initreq/ 제외"라고 하드코딩돼 있어
    #  worktrees/·tools/가 빠진 채 stale했음)
    print(f"검사 대상 라이브 문서 {len(docs)}개 "
          f"({'·'.join(d + '/' for d in SKIP_DIRS)} 제외)\n")
    if errors:
        print(f"■ ERROR {len(errors)}건 — 고쳐야 함")
        for e in errors:
            print("  " + e)
        print()
    elif not quiet:
        print("■ ERROR 0건 ✓\n")
    if warns:
        print(f"■ WARN {len(warns)}건 — 확인 권장(자동 판정 불가)")
        for w in warns:
            print("  " + w)
        print()
    elif not quiet:
        print("■ WARN 0건 ✓\n")
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
