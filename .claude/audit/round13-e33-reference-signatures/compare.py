#!/usr/bin/env python3
"""E33 static table: doc item -> source record (normalized text equality)."""
import json, re
from common import parse_block
recs = json.load(open("extracted.json"))
idx = json.load(open("source_index.json"))
R, A = idx["records"], idx["aliases"]
def norm(s):
    s = "\n".join(re.sub(r"\s--\s.*$", "", l) for l in s.split("\n") if not l.strip().startswith("--"))
    return re.sub(r"\s+", "", s).rstrip(",")
RECV = {"source": "Source", "state": "State", "store": "Store", "observer": "Observer", "effect": "Effect",
        "slot": "Slot", "ref": "Ref", "mod": "Modifier", "tag": "Tag", "attr": "Attr", "ctx": "Context",
        "provider": "Provider", "handle": "GateHandle", "blocker": "Blocker", "tween": "Tween"}
NS = {"Dispatch": "Dispatch", "Bookkeeping": "Bookkeeping", "Backend": "Backend", "Operator": "Operator",
      "Modifier": "ModifierConstructor", "Tag": "TagConstructor", "Attr": "AttrConstructor", "Context": "ContextConstructor"}
def key_for(rid, r, name):
    h = r["heading"] or ""
    if rid == 117: return None
    if rid == 119: return "Declaration.Frame"
    if rid == 120: return "Declaration.New"
    if rid == 121: return "DeclarationModifier.Frame"
    if rid == 122: return "FrameModifier.Size"
    if rid == 123: return "GuiObjectModifier." + name
    if rid == 125: return "DeclarationMapper.Frame"
    if rid == 126: return "Quad." + name
    if rid == 81: return None
    if rid == 130: return None
    if rid == 131: return "RobloxExtension.isTween"
    if rid in (102, 103, 104, 105, 106, 107, 108) or r["file"].startswith("extend/02") and "Dispatch" in h: return "Dispatch." + name
    if r["file"].startswith("extend/02") and "Bookkeeping" in h: return "Bookkeeping." + name
    if rid == 6 and name == "errorNamespace": return "Quad.errorNamespace"
    m2 = re.match(r"`(\w+)[:.](\w+)", h)
    if m2 and m2.group(1) in RECV: return RECV[m2.group(1)] + "." + name
    m = re.match(r"`q[.:](\w+)(?:\.(\w+))?", h)
    if m:
        if m.group(2) and m.group(1) in NS: return NS[m.group(1)] + "." + name
        if m.group(1) == "Backend": return "Backend." + name
        if name in ("Tween","Animate","OnChange","Out","isTween","Declaration"): return "RobloxExtension." + name
        return "Quad." + name
    if "UseProvider" in h: return "Quad.UseProvider"
    return None
rows = []
for rid, r in enumerate(recs):
    for kind, name, params, text in parse_block(r["sig"]):
        if kind == "member":
            k = key_for(rid, r, name)
            src = R.get(k) if k else None
            if src is None:
                rows.append([rid, r["file"], r["line"], r["heading"], name, "-", "NOSRC", text.strip()]); continue
            eq = norm(text) == norm(src[2])
            rows.append([rid, r["file"], r["line"], r["heading"], name, f"{src[0]}:{src[1]}", "EQ" if eq else "DIFF", text.strip(), src[2].strip()])
        else:
            a = A.get(name)
            if a is None:
                rows.append([rid, r["file"], r["line"], r["heading"], "type " + name, "-", "NOSRC", text.strip()]); continue
            eq = norm(text) == norm(re.sub(r"^.*?=\s*", "", a[2], count=0) if False else a[2])
            rows.append([rid, r["file"], r["line"], r["heading"], "type " + name, f"{a[0]}:{a[1]}", "EQ" if eq else "DIFF", text.strip(), a[2].strip()])
json.dump(rows, open("static.json", "w"), ensure_ascii=False, indent=0)
from collections import Counter
print(Counter(r[6] for r in rows))
for r in rows:
    if r[6] != "EQ": print(r[0], r[1], r[2], r[4], r[5], r[6], "\n   DOC:", r[7].replace("\n"," ")[:220], "\n   SRC:", (r[8] if len(r)>8 else "").replace("\n"," ")[:220])
