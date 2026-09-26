#!/usr/bin/env python3
"""E33: merge static (compare.py) + machine probe (probe_sigs.out) + manual adjudication into TABLE.md rows."""
import json, re
from common import parse_block
recs = json.load(open("extracted.json"))
static = {(r[0], r[4].replace("type ", "")): r for r in json.load(open("static.json"))}
pm = json.load(open("probe_map.json"))["lines"]
out = open("probe_sigs.out").read()
diag = {}
for blk in re.split(r"\n(?=\S+\.luau\()", out):
    mm = re.search(r"probe_sigs\.luau\((\d+),(\d+)\): (\w+): (.*)", blk, re.S)
    if not mm or mm.group(3) in ("FunctionUnused", "LocalUnused"): continue
    key = pm.get(mm.group(1))
    if not key: continue
    e = re.search(r"Expected this to be\s*'(.*?)'\s*but got\s*'(.*?)'", mm.group(4), re.S)
    same = bool(e) and (e.group(1) == e.group(2) or ("TRUNCATED" in mm.group(4) and e.group(1)[:200] == e.group(2)[:200]))
    diag.setdefault(key, set()).add("same-print" if same else "diff")
# manual verdicts (see README 발견) keyed by "rid|name"
MANUAL = {
    "74|Tag": "불일치 (a) — `...TagMarker?`/`...TagNames?`(nil 슬롯) 누락",
    "80|Merged": "불일치 (a) — `(...TagMarker?) -> Tag`",
    "85|AttrKeyObject": "불일치 (a) — 실제 `{ read Name: string }`",
    "48|Single": "일치(텍스트) — 단 (b) 추론 결함, 문서의 '그대로 통과' 주장 과장",
    "122|Field": "일치(텍스트) — (c) 이 페이지의 `FieldOut`은 core/08과 다른 별칭(Tween 포함)",
    "127|OnChangeFn": "일치(텍스트)",
    "127|OnChangeDescriptor": "일치(생성 모듈) — (c) 패키지 재수출 `OnChangeDescriptor`는 다른 비제네릭 타입",
}
QT = "quad-types/src/init.luau"
SRC_OVERRIDE = {"13|Get": QT+":186", "65|Modifier": QT+":425", "66|FieldOut": QT+":198", "70|As<Class>": "quad-roblox/src/Declaration/init.luau:2454 (AsFrame 예)",
 "71|Overridden": QT+":426", "72|TypedFactory": QT+":427", "73|DefineSubtype": QT+":428", "74|Tag": QT+":370",
 "75|Added": QT+":362", "76|Removed": QT+":363", "77|Contains": QT+":364", "78|Tag": QT+":360", "79|Apply": QT+":365",
 "80|Merged": QT+":370", "81|__call": QT+":384", "83|Merged": QT+":382", "84|Overridden": QT+":383", "85|AttrKey": QT+":389",
 "117|QuadRoblox": "quad-roblox/src/init.luau:221", "119|FrameParam": "quad-roblox/src/Declaration/init.luau:299",
 "128|OutFn": "quad-roblox/src/init.luau:197", "129|TweenConstructor": "quad-roblox/src/types.luau:104",
 "129|TweenOverride": "quad-roblox/src/types.luau:56", "129|TweenOptions": "quad-roblox/src/types.luau:59",
 "130|Mapped": "quad-roblox/src/types.luau:96", "132|AnimateFn": "quad-roblox/src/types.luau:145",
 "132|AnimateInfo": "quad-roblox/src/types.luau:129", "134|Provider": QT+":328", "66|Peek": QT+":406",
 "6|Namespace": "quad-error/src/init.luau:86", "8|Relate": QT+":118", "133|ContextConstructor": QT+":328",
 "122|FieldV": "quad-roblox/src/Declaration/init.luau:52", "122|Field": "quad-roblox/src/Declaration/init.luau:54"}
rows = []; cnt = {"일치": 0, "불일치": 0, "미대조": 0}
for rid, r in enumerate(recs):
    items = parse_block(r["sig"])
    if not items:
        items = [("member", "(retractor)", None, r["sig"])]
    for kind, name, params, text in items:
        key = f"{rid}|{name}"
        st = static.get((rid, name))
        src = st[5] if st else "-"
        s_eq = st[6] if st else "-"
        src = SRC_OVERRIDE.get(key, src)
        d = diag.get(key)
        if key in MANUAL: v = MANUAL[key]
        elif "…" in text or "<Class>" in name:
            v = "부분 대조(생략형) — 드러난 부분 일치"
        elif rid == 101:
            v = "일치(정적 — `Handler.process` 반환형과 같음)"; src = "quad-types/src/init.luau:457"
        elif d is None:
            v = "일치" + ("" if s_eq == "EQ" else " (기계)")
        elif d == {"same-print"}:
            v = "일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강"
        else:
            v = "확인 필요 " + str(d)
        c = "불일치" if v.startswith("불일치") else ("미대조" if v.startswith("확인") else "일치")
        cnt[c] += 1
        sig1 = re.sub(r"\s+", " ", text.strip())[:90].replace("|", "\\|")
        rows.append(f"| {r['file']}:{r['line']} `{name}` | `{sig1}` | {src} | {v} |")
open("TABLE.md", "w").write("| 페이지:줄 심볼 | 문서 시그니처(앞 90자) | 타입 소스 | 판정 |\n|---|---|---|---|\n" + "\n".join(rows) + "\n")
print(cnt, len(rows))
