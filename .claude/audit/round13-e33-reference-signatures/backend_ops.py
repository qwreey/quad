#!/usr/bin/env python3
"""E33 supplement: extend/01 op blocks (`name  (params) -> ret`, no **시그니처** label) vs quad-types Backend record."""
import json, re, pathlib
R = pathlib.Path(__file__).resolve().parents[3]
idx = json.load(open("source_index.json"))["records"]
doc = (R / "docs/reference/extend/01-backend-provider-contract.md").read_text().split("\n")
norm = lambda s: re.sub(r"\s+", "", re.sub(r"\s--\s.*$", "", s)).rstrip(",")
n = eq = 0
for i, l in enumerate(doc, 1):
    m = re.match(r"^(\w+)\s+(\(.*)$", l)
    if not m: continue
    src = idx.get("Backend." + m.group(1))
    n += 1
    ok = src is not None and norm(m.group(2)) == norm(src[2])
    eq += ok
    print(f"extend/01:{i} {m.group(1)} | {'EQ' if ok else 'DIFF'} | {src[0]+':'+str(src[1]) if src else '-'}")
print(n, eq)
