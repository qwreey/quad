#!/usr/bin/env python3
"""E25 set probe — generated Declaration Param/Modifier keys vs api-surface.json (props/readProps/events).
Run from repo root: python3 .claude/audit/round13-e25-probe-sets.py"""
import json, re
S = json.load(open("quad-roblox/dump/api-surface.json"))
D = open("quad-roblox/src/Declaration/init.luau").read()
SH = {"UICorner", "UIPadding", "UIPaddingOffset", "UIScale"}
def block(head):
    m = re.search(rf"^export type {head} = \{{\n(.*?)^\}}", D, re.S | re.M)
    return m.group(1) if m else None
def keys(body):
    return set(re.findall(r"^\t([A-Za-z_][A-Za-z0-9_]*)\s*:", body, re.M))
tot = {"param_extra": 0, "param_missing": 0, "mod_extra": 0, "mod_missing": 0}
for cls, c in sorted(S["classes"].items()):
    props = {p["name"] for p in c["props"]}
    rprops = {p["name"] for p in c["readProps"]}
    evs = {e["name"] for e in c["events"]}
    pk = keys(block(f"{cls}Param<E>"))
    gui = "GuiObject" in c["chain"]
    exp = props | evs | (SH if gui else set())
    mb = keys(block(f"{cls}Modifier"))
    mprops = {k for k in mb if not k.startswith("As") and k not in ("Peek", "Apply", "Overridden", "read")} - {"__quadModifier"}
    mexp = props | (SH if gui else set())
    pe, pm = pk - exp, exp - pk
    me, mm = mprops - mexp, mexp - mprops
    overlap_pe = props & evs
    overlap_rw = (props | evs) & rprops
    print(f"{cls:26} props={len(props):3} read={len(rprops):2} ev={len(evs):2} paramKeys={len(pk):3} "
          f"extra={sorted(pe)} missing={sorted(pm)} modExtra={sorted(me)} modMissing={sorted(mm)} "
          f"prop∩ev={sorted(overlap_pe)} (w∪ev)∩read={sorted(overlap_rw)}")
    for k, v in (("param_extra", pe), ("param_missing", pm), ("mod_extra", me), ("mod_missing", mm)):
        tot[k] += len(v)
print(tot)
# legacy
for cls, c in sorted(S["classes"].items()):
    for p in c["props"] + c["readProps"]:
        if p.get("legacy"):
            print("legacy", cls, p["name"], p["legacy"], p["type"], "read" if p in c["readProps"] else "write")
# lowercase names anywhere in the surface
for cls, c in sorted(S["classes"].items()):
    for p in c["props"] + c["readProps"]:
        if p["name"][0].islower():
            print("lowercase", cls, p["name"])
    for e in c["events"]:
        if e["name"][0].islower():
            print("lowercase-event", cls, e["name"])
