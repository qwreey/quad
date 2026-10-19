#!/usr/bin/env python3
"""[2026-10-19 M4] class maps + owner-keyed Policy from a raw Roblox API dump, for Lib2's Build.
  python3 -I harness/gen-fullmaps.py <raw-API-Dump.json> <dumpVersion> <checker defs .d.luau>  > src/FullMaps.luau

Maps (only classes the checker defs declare — a map entry names the global class type):
  CreatableMapFull  every Instance class without NotCreatable/Service (Elem / Mapper)
  ModClassMapFull   CreatableMapFull ∪ all their ancestors (Modifier / Spread — abstract classes included)
Policy (owner-keyed, so a name denied on one class does not leak to another — Lib's global name Deny did):
  DenyIn       both surfaces: member tags Deprecated/NotScriptable/Hidden (minus gen-d's HIDDEN/DEPRECATED_NAME_KEEP),
               Read security != None; events tagged Deprecated/Hidden or Security != None
  DenyWriteIn  write surface only: ReadOnly (no other exclusion), Write security != None, Parent (H-142)
Same tag rules as scripts/gen-d.py normalize (PROP_TAG_EXCLUDE, HIDDEN_NAME_KEEP, DEPRECATED_NAME_KEEP, EVENT_TAG_EXCLUDE).
"""
import json, re, sys
dump = json.load(open(sys.argv[1]))
ver = sys.argv[2]
defs = open(sys.argv[3]).read()
declared = set(re.findall(r"^declare extern type (\w+) (?:extends \w+ )?with", defs, re.M))
cls = {c["Name"]: c for c in dump["Classes"]}
HIDDEN_NAME_KEEP = {"Font", "Transparency"}
# --keep-hidden a,b: extra Hidden names to keep (M4: BasePart/Attachment Position·Orientation are Hidden in the dump)
if "--keep-hidden" in sys.argv:
    HIDDEN_NAME_KEEP |= set(sys.argv[sys.argv.index("--keep-hidden") + 1].split(","))
DEPRECATED_NAME_KEEP = {"FontSize", "TextWrap"}

def tags(x):
    return set(x.get("Tags") or [])

def chain(n):
    out = []
    while n in cls:
        out.append(n)
        n = cls[n]["Superclass"]
    return out

inst = [n for n in cls if "Instance" in chain(n) and n in declared]
creatable = sorted(n for n in inst if not (tags(cls[n]) & {"NotCreatable", "Service"}))
mod = set()
for n in creatable:
    mod.update(c for c in chain(n) if c in declared)
mod = sorted(mod)
owners = set()
for n in mod:
    owners.update(chain(n))
deny, denyw = {}, {}
for o in sorted(owners):
    for m in cls[o].get("Members", []):
        mt = tags(m)
        nm = m["Name"]
        if m["MemberType"] == "Property":
            if nm == "Parent":
                denyw.setdefault(o, set()).add(nm)
                continue
            keep = ({"Deprecated"} if "Deprecated" in mt and nm in DEPRECATED_NAME_KEEP else set()) | ({"Hidden"} if nm in HIDDEN_NAME_KEEP else set())
            other = mt & ({"Deprecated", "NotScriptable", "Hidden"} - keep)
            sec = m.get("Security") or {}
            if other or sec.get("Read") != "None":
                deny.setdefault(o, set()).add(nm)
            elif "ReadOnly" in mt or sec.get("Write") != "None":
                denyw.setdefault(o, set()).add(nm)
        elif m["MemberType"] == "Event":
            if mt & {"Deprecated", "Hidden"} or m.get("Security") != "None":
                deny.setdefault(o, set()).add(nm)

def key(s):
    return s if re.fullmatch(r"[A-Za-z_]\w*", s) else '["' + s + '"]'

def tbl(d):
    rows = []
    for o in sorted(d):
        rows.append(f"\t{key(o)}: {{ " + ", ".join(f"{key(x)}: true" for x in sorted(d[o])) + " },")
    return "{\n" + "\n".join(rows) + "\n}"

print("--!strict")
print(f"-- GENERATED [2026-10-19 M4] by harness/gen-fullmaps.py from API dump {ver} + {sys.argv[3].split('/')[-1]}; HIDDEN_NAME_KEEP={sorted(HIDDEN_NAME_KEEP)}")
print(f"-- CreatableMapFull {len(creatable)} classes, ModClassMapFull {len(mod)} classes, DenyIn owners {len(deny)} ({sum(map(len, deny.values()))} names),"
      f" DenyWriteIn owners {len(denyw)} ({sum(map(len, denyw.values()))} names)")
print('local L = require("./Lib2")')
print("export type CreatableMapFull = {\n" + "\n".join(f"\t{n}: {n}," for n in creatable) + "\n}")
print("export type ModClassMapFull = {\n" + "\n".join(f"\t{n}: {n}," for n in mod) + "\n}")
print("-- the same names as literal unions: a `K & keyof<Map>` bound over >~130 keys is too complex under the Roblox-sync limits, a literal union is not (M4)")
print("export type CreatableNamesFull = " + " | ".join(f'"{n}"' for n in creatable))
print("export type ModClassNamesFull = " + " | ".join(f'"{n}"' for n in mod))
print("type DenyInFull = " + tbl(deny))
print("type DenyWriteInFull = " + tbl(denyw))
print("export type DenyInFullX = DenyInFull -- re-exported for the isolation probes (fullmap/iso-*)")
print("export type DenyWriteInFullX = DenyWriteInFull")
print("type Inject = {\n\tGuiObject: { Transparency: number },\n\tTextLabel: { FontSize: Enum.FontSize, TextWrap: boolean },\n"
      "\tTextButton: { FontSize: Enum.FontSize, TextWrap: boolean },\n\tTextBox: { FontSize: Enum.FontSize, TextWrap: boolean },\n}")
for nm, classes, depth in (("FullPolicy", "ModClassMapFull", None), ("FullPolicyAs0", "ModClassMapFull", "0")):
    extra = f', AsDepth: "{depth}"' if depth else ""
    print(f"export type {nm} = {{ Deny: {{}}, DenyWrite: {{}}, DenyIn: DenyInFull, DenyWriteIn: DenyWriteInFull, Inject: Inject,"
          f" Shorthand: L.Shorthand, Child: L.NewChild, Classes: {classes}{extra} }}")
print("export type FProps<C> = L.Build<\"props\", C, FullPolicy>")
print("export type FModifier<C> = L.Build<\"modifier\", C, FullPolicy>")
print("export type FModifierAs0<C> = L.Build<\"modifier\", C, FullPolicyAs0>")
print("export type FReadMap<C> = L.Build<\"readmap\", C, FullPolicy>")
print("export type FEvents<C> = L.Build<\"events\", C, FullPolicy>")
print("export type FSpread<C> = L.Build<\"spreadmarker\", C, FullPolicy>")
print("export type FBrief<C> = L.Build<\"brief\", C, FullPolicy>")
print("type _Prime = L.Build<\"classname\", Part, FullPolicy>")
print("return {}")
