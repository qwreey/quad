#!/usr/bin/env python3
"""E33: heading parameter names vs signature parameter names vs 인자-table names."""
import json, re
from common import parse_block
recs = json.load(open("extracted.json"))
def sig_params(text):
    # first top-level parenthesised list after optional generics
    t = re.sub(r"^<[^>]*>", "", text.strip())
    if not t.startswith("("): return None
    depth = 0; buf = ""; out = []
    for ch in t[1:]:
        if ch in "({<[": depth += 1
        if ch in ")}>]":
            if depth == 0: out.append(buf); break
            depth -= 1
        if ch == "," and depth == 0: out.append(buf); buf = ""; continue
        buf += ch
    names = []
    for p in out:
        p = p.strip()
        m = re.match(r"^(\.\.\.)?(\w+)\s*:", p)
        if m: names.append((m.group(1) or "") + m.group(2))
        elif p.startswith("..."): names.append("...")
        elif p: names.append("?")
    return [n for n in names if n != "self"]
for rid, r in enumerate(recs):
    h = r["heading"] or ""
    hm = re.search(r"\(([^)]*)\)`?\s*$", h)
    if not hm: continue
    hp = [x.strip().rstrip("?") for x in hm.group(1).split(",") if x.strip()]
    items = [i for i in parse_block(r["sig"]) if i[0] == "member"]
    if not items: continue
    sp = sig_params(items[0][3])
    tp = [re.match(r"\|\s*`([^`]*)`", a).group(1) for a in r["args"][2:] if re.match(r"\|\s*`([^`]*)`", a)]
    norm = lambda xs: [x.replace("...", "").strip() for x in xs]
    flag = ""
    if sp is not None and norm(hp) != norm(sp): flag += " HEAD≠SIG"
    if tp and norm(tp) != norm(sp or []): flag += " TABLE≠SIG"
    if flag: print(rid, r["file"], r["line"], h, "| head", hp, "| sig", sp, "| table", tp, flag)
