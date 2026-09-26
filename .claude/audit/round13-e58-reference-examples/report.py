#!/usr/bin/env python3
"""E58: build README table rows from index.tsv + spec.py + out/"""
import re, pathlib, collections
here = pathlib.Path(__file__).parent
exec(open(here / "spec.py").read())
idx = [l.rstrip("\n").split("\t") for l in open(here / "index.tsv")]
mock = {l.split("\t")[0]: l.split("\t")[2].strip() for l in open(here / "out/mock-summary.tsv")}
te = collections.Counter(); lint = collections.Counter()
for l in open(here / "out/strict.txt"):
    m = re.match(r"strict/(\S+)\.luau\(\d+,\d+\): (\w+):", l)
    if m:
        (te if m.group(2) == "TypeError" else lint)[m.group(1)] += 1
MATCH = {  # 수동 판정(출력 대조) — 기본은 "일치"
    "core_09-tag-attr-L392": "— (mock 한계: SetAttribute가 Color3 셔임(테이블) 거부)",
    "extend_02-dispatch-handler-contract-L353": "일치(등록·mount); 뒤 문장 '철거' 경로 → 발견 A2",
    "roblox_05-onchange-L95": "일치(런타임)",
    "roblox_02-d-L287": "일치(런타임 무에러, 문서 주장은 타입 쪽)",
}
STRICT_NOTE = {
    "core_09-tag-attr-L392": "8.17(문서 caution에 이미)",
    "roblox_02-d-L287": "의도(문서가 '타입 에러'라 말함) — 12행 한 자리",
    "roblox_05-onchange-L95": "**새로움** → 발견 A1",
}
cls_count = collections.Counter(); rows = []; agg = collections.defaultdict(lambda: collections.defaultdict(list))
prolog_seen = set()
for f, s, n, name in idx:
    key = name[:-5]
    sp = S.get(key)
    body = (here / "blocks" / name).read_text()
    if sp is None:
        c = "P" if ("require(" in body and f not in prolog_seen and ("local q" in body or "local Quad" in body)) else "b"
        if c == "P": prolog_seen.add(f)
        cls_count[c] += 1; agg[f][c].append(s); continue
    cls_count[sp["cls"]] += 1
    ms = mock.get(key, "—")
    if sp.get("skip"):
        mcol, match, st = "구문/미정의(조각)", "해당 없음", "제외"
    else:
        mcol = "통과" if ms == "END" else "실패"
        match = MATCH.get(key, "일치")
        st = "0" if te[key] == 0 else f"{te[key]} TypeError"
        if key in STRICT_NOTE: st += " — " + STRICT_NOTE[key]
    note = sp.get("note") or sp.get("skip") or ""
    if sp.get("pre") or sp.get("post") or sp.get("sub"):
        if "보강" not in note: note = ("보강(확인 출력)" + ("; " + note if note else ""))
    rows.append(f"| {f} | {s} | {sp['cls']} | {mcol} | {match} | {st} | {note} |")
out = ["| 파일 | 블록(줄) | 분류 | mock | 출력 일치 | strict | 비고 |", "|---|---|---|---|---|---|---|"] + rows
out += ["", "프롤로그(P)·시그니처/타입(b) 블록(실행·strict 안 함 — b는 E33 범위):", "", "| 파일 | P 줄 | b 줄 |", "|---|---|---|"]
for f in agg:
    out.append(f"| {f} | {', '.join(agg[f]['P']) or '—'} | {', '.join(agg[f]['b']) or '—'} |")
(here / "out/table.md").write_text("\n".join(out) + "\n")
print(dict(cls_count), "total", sum(cls_count.values()))
print("TypeError files:", {k: v for k, v in te.items()}); print("lint lines:", sum(lint.values()))
