#!/usr/bin/env python3
import re, json

PROP_TYPE = {
    "Text": "string", "PlaceholderText": "string",
    "BackgroundColor3": "Color3", "TextColor3": "Color3", "BorderColor3": "Color3",
    "BackgroundTransparency": "number", "TextTransparency": "number", "Transparency": "number",
    "Size": "UDim2", "Position": "UDim2",
    "Visible": "boolean", "Interactable": "boolean", "Active": "boolean",
    "LayoutOrder": "number", "ZIndex": "number",
    "AutoButtonColor": "boolean",
    "AbsoluteSize": "Vector2",
}

rows = []
cur = None
for line in open("/code/Projects/quad/.claude/audit/round13-drafts-2026-09-27/q105-check/sweep2.out"):
    line = line.rstrip("\n")
    if line.startswith("=" * 20):
        if cur: rows.append(cur)
        cur = {"usages": []}
        continue
    m = re.match(r"(\S+):(\d+)\s+\[(\w+)\]\s+name=(\S+)\s+annotated=(Y|N)\s*(.*)", line)
    if m:
        cur["file"] = m.group(1); cur["line"] = int(m.group(2)); cur["method"] = m.group(3)
        cur["name"] = m.group(4); cur["annotated"] = m.group(5) == "Y"; cur["ann"] = m.group(6).strip()
        continue
    if line.strip().startswith("bind:"):
        cur["bind"] = line.strip()[6:]
        continue
    if line.strip().startswith("usage@"):
        m2 = re.match(r"usage@(\d+):\s*(.*)", line.strip())
        cur["usages"].append((int(m2.group(1)), m2.group(2)))
        continue
if cur: rows.append(cur)

def classify(r):
    name = r["name"]
    cats = set()
    prop = None
    for (_, u) in r["usages"]:
        # receiver/dep of another compute-family call
        if re.search(r"\b" + re.escape(name) + r"\s*:(Compute|Apply|Gate|Mapped|Depend|Observer)\s*\(", u):
            cats.add("receiver")
        if re.search(r",\s*" + re.escape(name) + r"\s*\)", u) and re.search(r":(Compute|Apply)\(", u):
            cats.add("dep")
        # property value: NAME appears as RHS of a `Key = NAME` inside a table literal
        if re.search(r"=\s*" + re.escape(name) + r"\s*[,}\)]", u):
            cats.add("prop")
        # arithmetic/indexing/condition on :Get()
        if re.search(re.escape(name) + r":Get\(\)", u):
            if re.search(r"(assert|if|and|or|==|~=|[+\-*/]|#)", u):
                cats.add("arith")
        if re.search(r"\b" + re.escape(name) + r"\[", u):
            cats.add("arith")
        if re.search(r"print\s*\(.*\b" + re.escape(name) + r"\b", u) or re.search(r"tostring\s*\(\s*" + re.escape(name), u):
            cats.add("print")
        if re.search(r"return\s.*\b" + re.escape(name) + r"\b", u) and not cats:
            cats.add("return")
    if not r["usages"]:
        return "unused", None
    real = cats & {"receiver", "dep", "prop", "arith", "return"}
    if real:
        # infer prop type if prop-usage
        proptype = None
        for (_, u) in r["usages"]:
            mm = re.search(r"(\w+)\s*=\s*" + re.escape(name) + r"\s*[,}\)]", u)
            if mm and mm.group(1) in PROP_TYPE:
                proptype = PROP_TYPE[mm.group(1)]
                break
        label = "+".join(sorted(real))
        return label, proptype
    if "print" in cats:
        return "print-only", None
    return "other", None

out = []
for r in rows:
    label, proptype = classify(r)
    out.append({**r, "usecat": label, "proptype": proptype})

json.dump(out, open("/code/Projects/quad/.claude/audit/round13-drafts-2026-09-27/q105-check/classified.json", "w"), ensure_ascii=False, indent=1)

from collections import Counter
c = Counter((r["usecat"], r["annotated"]) for r in out)
for k, v in sorted(c.items()):
    print(k, v)
print("TOTAL", len(out))
