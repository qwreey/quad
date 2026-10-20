#!/usr/bin/env python3
"""[2026-10-20] Declaration 3.4.0 kit-trial codemod PROTOTYPE (probe tool, not the release script).

  codemod-proto.py <repo-root> <dest-root> <kit-dir>... [--parts src,stories,gallery,test] [--report <json>]

Copies <repo-root>/<kit>/<part> to <dest-root>/<kit>/<part> and rewrites every .luau file to the new surface
(`research/declaration-surface-plan.md` 5절, `research/declaration-naming-table.md` 5절, 2026-10-20 marker decision):

  * `local D = q.Declaration` → per-file header `local Frame = q.Elem "Frame"` / `local FrameModifier = q.Modifier "Frame"`
    (only the classes the file uses); `D.Frame` → `Frame`, `D.Modifier.Frame` → `FrameModifier`
    (also `q.Declaration.Frame` written without a `D` local). A header name that the file already declares is
    suffixed `_` and reported.
  * type `<Q>.<C>Modifier` / `<Q>.Into<C>` (Q = any local bound to the kit's `Quad` module):
      input position (table-type field, function parameter) → `<Q>.ModifierInto<C>`
      anything else (local annotation, return type, indexer value, cast, generic argument) → `<Q>.Modifier<C>`
    an input whose field/param name gets a non-As method call in the same file stays `<Q>.Modifier<C>` and is
    reported as NEEDS-FULL (`:As…()` chains on it are stripped instead: `props.Modifier:AsGuiObject():AsFrame()` →
    `props.Modifier`).
  * `q.OnChange("Name", fn)` / `q.Out("Name", src)` → `q.OnChange "C" "Name" (fn)` / `q.Out "C" "Name" (src)`, C = the
    element whose array part encloses the call; if the call is assigned to a variable, the element that encloses the
    variable's first later use. Otherwise reported UNRESOLVED and left as is.
  * the kit setup modules (`src/Quad.luau`, `gallery/Quad.luau`) are rewritten to the new re-export set.

Analysis runs on a masked copy (comments and strings blanked, same offsets); edits are applied right to left.
Report: JSON (per file edits + the lists) and a summary on stdout.
"""
import json
import os
import re
import shutil
import sys

PROBE_EXT = ".claude/audit/decl-typefn-probe-2026-10-16/harness/compare/kit-trial/Ext4"


# ── masking ────────────────────────────────────────────────────────────────
def mask(src: str) -> str:
    out = list(src)
    i, n = 0, len(src)

    def blank(a, b):
        for k in range(a, b):
            if out[k] != "\n":
                out[k] = " "

    while i < n:
        c = src[i]
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, i + len(m.group(0)))
                j = n if j < 0 else j + len(close)
            else:
                j = src.find("\n", i)
                j = n if j < 0 else j
            blank(i, j)
            i = j
            continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            j = src.find(close, i + len(m.group(0)))
            j = n if j < 0 else j + len(close)
            blank(i + 1, j - 1)
            i = j
            continue
        if c in "\"'`":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                elif src[j] == "\n" and c != "`":
                    break
                j += 1
            blank(i + 1, j)  # keep the quotes
            i = j + 1
            continue
        i += 1
    return "".join(out)


OPEN = {"(": ")", "{": "}", "[": "]"}
CLOSE = {v: k for k, v in OPEN.items()}


def bracket_stack(ms: str):
    """for every offset, the stack of open brackets (as (char, pos)) — computed lazily via a parent map."""
    parent = {}  # pos of open bracket -> its enclosing open bracket pos (or -1)
    closes = {}
    st = []
    enclosing = [None] * (len(ms) + 1)
    for i, c in enumerate(ms):
        enclosing[i] = st[-1] if st else -1
        if c in OPEN:
            parent[i] = st[-1] if st else -1
            st.append(i)
        elif c in CLOSE and st:
            o = st.pop()
            closes[o] = i
    enclosing[len(ms)] = -1
    return enclosing, parent, closes


def prev_token_end(ms: str, i: int) -> int:
    j = i - 1
    while j >= 0 and ms[j] in " \t\r\n":
        j -= 1
    return j


def line_of(src: str, pos: int) -> int:
    return src.count("\n", 0, pos) + 1


# ── per-file rewrite ─────────────────────────────────────────────────────────
QUAD_REQ = re.compile(r"local\s+(\w+)\s*=\s*[^\n=]*require\(\"[^\"]*Quad\"\)")
QUAD_ALIAS = re.compile(r"local\s+(\w+)\s*=\s*(\w+)\s*$", re.M)
D_BIND = re.compile(r"^([ \t]*)local\s+(\w+)\s*=\s*(\w+)\.Declaration[ \t]*\n", re.M)


def declared_names(ms: str) -> set:
    names = set(re.findall(r"\blocal\s+function\s+(\w+)", ms))
    for m in re.finditer(r"\blocal\s+([\w\s,]+?)(?:=|\n|:)", ms):
        for n in m.group(1).split(","):
            n = n.strip()
            if re.fullmatch(r"\w+", n):
                names.add(n)
    for m in re.finditer(r"\bfunction\b[\w.:\s]*\(([^)]*)\)", ms):
        for p in m.group(1).split(","):
            p = p.split(":")[0].strip()
            if re.fullmatch(r"\w+", p):
                names.add(p)
    for m in re.finditer(r"\bfor\s+([\w\s,]+?)\s+(?:in|=)", ms):
        for n in m.group(1).split(","):
            names.add(n.strip())
    return names


def element_class_of_open(src_ms: str, open_pos: int, dname: str, qnames: set):
    """the class if the bracket at open_pos is an element constructor's table: `D.C {`, `D.C({`, `q.Declaration.C {`."""
    j = prev_token_end(src_ms, open_pos)
    if j >= 0 and src_ms[j] == "(" and src_ms[open_pos] == "{":
        j = prev_token_end(src_ms, j)
    k = j + 1
    while j >= 0 and (src_ms[j].isalnum() or src_ms[j] in "_."):
        j -= 1
    ref = src_ms[j + 1:k]
    m = re.fullmatch(r"(\w+)\.(?:Declaration\.)?([A-Z]\w*)", ref)
    if not m:
        return None
    base, cls = m.group(1), m.group(2)
    if cls == "Modifier":
        return None
    if base == dname or (base in qnames and ".Declaration." in ref):
        return cls
    return None


def rewrite(path: str, src: str, rel: str):
    rep = {"file": rel, "elems": [], "mods": [], "types": [], "needs_full": [], "as_stripped": [],
           "onchange": [], "unresolved": [], "collisions": [], "notes": []}
    ms = mask(src)
    # require strings are blanked in the mask: match on the source, keep only matches that start in code
    qnames = {m.group(1) for m in QUAD_REQ.finditer(src) if ms[m.start():m.start() + 5] == "local"}
    for m in QUAD_ALIAS.finditer(ms):
        if m.group(2) in qnames:
            qnames.add(m.group(1))
    for m in re.finditer(r"local\s+(\w+)\s*=\s*[\w.:]+\(\s*(\w+)\s*\)", ms):  # `local q = H.attach(Q)`
        if m.group(2) in qnames:
            qnames.add(m.group(1))
    edits = []  # (start, end, text)

    # ---- D binding and value uses
    dm = D_BIND.search(ms)
    dname = dm.group(2) if dm else None
    vq = dm.group(3) if dm else None
    elem_classes, mod_classes = set(), set()
    pats = []
    taken = []
    if dname:
        # dynamic class name: `(D.Modifier :: any)[cls]` → `(q.Modifier :: any)(cls)` (the typed factory, cast away)
        for m in re.finditer(r"\(\s*" + dname + r"\.Modifier\s*::\s*any\s*\)\s*\[([^\]\n]+)\]", ms):
            edits.append((m.start(), m.end(), ("DYN", src[m.start(1):m.end(1)])))
            taken.append((m.start(), m.end()))
            rep.setdefault("dynamic", []).append((line_of(src, m.start()), src[m.start():m.end()]))
        pats.append(re.compile(r"(?<![\w.:])" + dname + r"\s*\.\s*Modifier\s*\.\s*([A-Za-z]\w*)"))
        pats.append(re.compile(r"(?<![\w.:])" + dname + r"\.([A-Z]\w*)\b"))
    for qn in qnames:
        pats.append(re.compile(r"(?<![\w.:])" + qn + r"\.Declaration\.Modifier\.([A-Za-z]\w*)"))
        pats.append(re.compile(r"(?<![\w.:])" + qn + r"\.Declaration\.([A-Z]\w*)\b"))
    for p in pats:
        for m in p.finditer(ms):
            if any(a <= m.start() < b for a, b in taken):
                continue
            cls = m.group(1)
            if re.search(r"\.\s*Modifier\s*\.", m.group(0)):
                mod_classes.add(cls)
                edits.append((m.start(), m.end(), ("MOD", cls)))
            elif cls == "Modifier":
                rep["unresolved"].append((line_of(src, m.start()), "bare D.Modifier (not followed by a class)"))
                continue
            elif cls in ("New", "Mapper"):
                rep["unresolved"].append((line_of(src, m.start()), f"D.{cls} — no rule in the prototype"))
                continue
            else:
                elem_classes.add(cls)
                edits.append((m.start(), m.end(), ("ELEM", cls)))
            taken.append((m.start(), m.end()))
            if vq is None:
                vq = re.match(r"(\w+)", m.group(0)).group(1) if ".Declaration." in m.group(0) else vq
    if vq is not None and vq not in qnames and dname:
        rep["notes"].append(f"D bound from non-Quad name {vq}")

    declared = declared_names(ms)
    names = {}
    for cls in sorted(elem_classes):
        nm = cls
        if nm in declared:
            rep["collisions"].append((cls, nm))
            nm = nm + "_"
        names[("ELEM", cls)] = nm
    for cls in sorted(mod_classes):
        nm = cls + "Modifier"
        if nm in declared:
            rep["collisions"].append((cls + "Modifier", nm))
            nm = nm + "_"
        names[("MOD", cls)] = nm
    rep["elems"] = sorted(elem_classes)
    rep["mods"] = sorted(mod_classes)
    final_edits = []
    for a, b, key in edits:
        if key[0] == "DYN":
            final_edits.append((a, b, f"({vq or 'q'}.Modifier :: any)({key[1]})"))
        else:
            final_edits.append((a, b, names[key]))

    if elem_classes or mod_classes:
        q = vq or (sorted(qnames)[0] if qnames else "q")
        if dm:
            indent = dm.group(1)
            hdr = "".join(f'{indent}local {names[("ELEM", c)]} = {q}.Elem "{c}"\n' for c in sorted(elem_classes))
            hdr += "".join(f'{indent}local {names[("MOD", c)]} = {q}.Modifier "{c}"\n' for c in sorted(mod_classes))
            final_edits.append((dm.start(), dm.end(), hdr))
        else:
            # no `local D = …`: insert after the line that defines the value-side quad name
            m = re.search(r"^local\s+" + re.escape(q) + r"\s*=.*\n", ms, re.M)
            if m is None:
                rep["unresolved"].append((0, f"cannot place header (no module-level local {q})"))
            else:
                hdr = "".join(f'local {names[("ELEM", c)]} = {q}.Elem "{c}"\n' for c in sorted(elem_classes))
                hdr += "".join(f'local {names[("MOD", c)]} = {q}.Modifier "{c}"\n' for c in sorted(mod_classes))
                final_edits.append((m.end(), m.end(), hdr))
    elif dm:
        final_edits.append((dm.start(), dm.end(), ""))
        rep["notes"].append("D binding with no D.<C> use removed")
    if dname:
        # bare `D` uses (not `D.`): a keep-alive `local _ = D` is dropped, anything else is reported
        for m in re.finditer(r"(?<![\w.:])" + dname + r"(?![\w])(?!\s*\.)", ms):
            if dm and dm.start() <= m.start() < dm.end():
                continue
            if any(a <= m.start() < b for a, b in taken):
                continue
            lm = re.match(r"[ \t]*local\s+_\s*=\s*" + dname + r"[ \t]*\n", ms[ms.rfind("\n", 0, m.start()) + 1:])
            ln = line_of(src, m.start())
            if lm:
                ls = ms.rfind("\n", 0, m.start()) + 1
                final_edits.append((ls, ls + lm.end(), ""))
                rep["notes"].append(f"L{ln}: keep-alive `local _ = {dname}` dropped")
            else:
                rep["unresolved"].append((ln, f"bare `{dname}` value use"))

    enclosing, parent, closes = bracket_stack(ms)

    # ---- Modifier types
    if qnames:
        tpat = re.compile(r"(?<![\w.:])(" + "|".join(map(re.escape, sorted(qnames))) + r")\.(?:Into([A-Z]\w*)|([A-Z]\w*)Modifier)\b")
        method_calls = {}
        for m in re.finditer(r"([\w.]*\w)\s*:\s*([A-Z]\w*)\s*\(", ms):
            last = m.group(1).split(".")[-1]
            method_calls.setdefault(last, []).append((m.start(), m.group(2), m.group(1)))
        for m in tpat.finditer(ms):
            qn, into_cls, mod_cls = m.group(1), m.group(2), m.group(3)
            cls = into_cls or mod_cls
            # input position?
            j = prev_token_end(ms, m.start())
            kind, field = "full", None
            if j >= 0 and ms[j] == ":" and (j == 0 or ms[j - 1] != ":"):
                k = prev_token_end(ms, j)
                e = k + 1
                while k >= 0 and (ms[k].isalnum() or ms[k] == "_"):
                    k -= 1
                ident = ms[k + 1:e]
                before = prev_token_end(ms, k + 1)
                b_ch = ms[before] if before >= 0 else ""
                bword = re.search(r"(\w+)\s*$", ms[:k + 1])
                bw = bword.group(1) if bword else ""
                enc = enclosing[m.start()]
                enc_ch = ms[enc] if enc >= 0 else ""
                if not ident:
                    kind = "full"  # `): T` return type, `]: T` indexer value
                elif bw == "local":
                    kind = "full"
                elif enc_ch == "{" and (b_ch in "{,;" or bw in ("read", "write") or ms[before] == "\n" or b_ch == ""):
                    kind, field = "input", ident
                elif enc_ch == "(":
                    # function parameter list?
                    pj = prev_token_end(ms, enc)
                    head = ms[max(0, pj - 80):pj + 1]
                    if re.search(r"\bfunction\b[\w.:\s]*$", head) and (b_ch in "(," ):
                        kind, field = "input", ident
            if into_cls:
                kind = "input" if kind == "input" else "into-noninput"
            new = None
            ln = line_of(src, m.start())
            if kind == "input":
                calls = [c for c in method_calls.get(field, []) if not c[1].startswith("As")]
                if calls:
                    new = f"{qn}.Modifier<{cls}>"
                    rep["needs_full"].append((ln, field, cls, sorted({c[1] for c in calls}),
                                              [line_of(src, c[0]) for c in calls][:6]))
                else:
                    new = f"{qn}.ModifierInto<{cls}>"
            elif kind == "into-noninput":
                new = f"{qn}.ModifierInto<{cls}>"
                rep["notes"].append(f"L{ln}: Into<{cls}> outside an input position — kept as ModifierInto")
            else:
                new = f"{qn}.Modifier<{cls}>"
            rep["types"].append((ln, m.group(0), new, kind, field))
            final_edits.append((m.start(), m.end(), new))
        # strip `:As…()` chains on input fields/params that became markers
        marker_fields = {t[4] for t in rep["types"] if t[2].endswith(">") and "ModifierInto" in t[2] and t[4]}
        for f in marker_fields:
            for m in re.finditer(r"((?:[\w]+\.)*" + re.escape(f) + r")((?:\s*:\s*As[A-Z]\w*\s*\(\s*\))+)", ms):
                final_edits.append((m.start(2), m.end(2), ""))
                rep["as_stripped"].append((line_of(src, m.start()), src[m.start():m.end()].strip()))

    # ---- OnChange / Out
    for qn in qnames:
        for m in re.finditer(r"(?<![\w.:])" + re.escape(qn) + r"\.(OnChange|Out)\s*\(", ms):
            fn = m.group(1)
            op = m.end() - 1
            cl = closes.get(op)
            ln = line_of(src, m.start())
            am = re.match(r"\s*([\"'])", ms[op + 1:])
            if cl is None or not am:
                rep["unresolved"].append((ln, f"q.{fn}: first argument is not a string literal"))
                continue
            q0 = op + 1 + am.end() - 1
            q1 = ms.index(am.group(1), q0 + 1)
            name = src[q0 + 1:q1]
            cm = re.match(r"\s*,\s*", ms[q1 + 1:])
            if not cm:
                rep["unresolved"].append((ln, f"q.{fn}(\"{name}\"): no second argument"))
                continue
            # class from the enclosing element
            cls, how = None, None
            e = enclosing[m.start()]
            while e is not None and e >= 0:
                if ms[e] == "{":
                    cls = element_class_of_open(ms, e, dname or "D", qnames)
                    if cls:
                        how = "enclosing element"
                    break
                if ms[e] == "(" and re.search(r"\bfunction\b[\w.:\s]*$", ms[max(0, prev_token_end(ms, e) - 60):prev_token_end(ms, e) + 1]):
                    break
                e = parent.get(e, -1)
            if cls is None:
                am2 = re.search(r"(?:local\s+)?(\w+)\s*(?::[^=\n]*)?=\s*$", ms[max(0, m.start() - 120):m.start()])
                if am2:
                    var = am2.group(1)
                    for um in re.finditer(r"(?<![\w.:])" + re.escape(var) + r"(?![\w])", ms[cl:]):
                        upos = cl + um.start()
                        e2 = enclosing[upos]
                        if e2 is not None and e2 >= 0 and ms[e2] == "{":
                            c2 = element_class_of_open(ms, e2, dname or "D", qnames)
                            if c2:
                                cls, how = c2, f"via variable `{var}` (L{line_of(src, upos)})"
                                break
            if cls is None:
                rep["unresolved"].append((ln, f"q.{fn}(\"{name}\", …): placing element not found"))
                continue
            new_head = f'{qn}.{fn} "{cls}" "{name}" ('
            final_edits.append((m.start(), q1 + 1 + cm.end(), new_head))
            rep["onchange"].append((ln, fn, cls, name, how))

    # ---- apply
    final_edits.sort(key=lambda t: (t[0], t[1]))
    for x, y in zip(final_edits, final_edits[1:]):
        if y[0] < x[1]:
            raise SystemExit(f"{rel}: overlapping edits {x} {y}")
    out = src
    for a, b, t in reversed(final_edits):
        out = out[:a] + t + out[b:]
    rep["n_edits"] = len(final_edits)
    return out, rep


# ── kit setup module ───────────────────────────────────────────────────────
def rewrite_setup(src: str, rel: str, depth_to_root: str):
    rep = {"file": rel, "setup": True, "notes": []}
    out = src
    out = re.sub(r"^export type (\w+Modifier|Into\w+|OnChangeFn|Field|FieldOut)\b.*\n", "", out, flags=re.M)
    out = out.replace('local RobloxModule = require("' + depth_to_root + 'quad-roblox/src")',
                      '-- [kit trial] untracked require: 3.4.0 drops the generated Declaration from quad-roblox; this keeps its\n'
                      '-- 5k-line module out of the check (the runtime value is irrelevant to a type check)\n'
                      'local RobloxModule = (require :: any)("' + depth_to_root + 'quad-roblox/src")\n'
                      'local RT = require("' + depth_to_root + 'quad-roblox/src/types")\n'
                      'local Ext = require("' + depth_to_root + PROBE_EXT + '")')
    out = re.sub(r"local q = (\w+):UseProvider\(RobloxModule\.QuadRoblox\)",
                 r"local q: Ext.Q = \1:UseProvider(RobloxModule.QuadRoblox) :: any", out)
    out = re.sub(r"RobloxModule\.(Tween|TweenOptions|AnimateInfo)\b", r"RT.\1", out)
    block = ("-- new Declaration surface (3.4.0 trial — Lib4/Ext4): one generic per axis, no per-class copies\n"
             "export type Modifier<C> = Ext.Modifier<C>\n"
             "export type ModifierInto<C> = Ext.ModifierInto<C>\n"
             "export type Spread<C> = Ext.Spread<C>\n"
             "export type Props<C> = Ext.Props<C>\n"
             "export type PropsArrayItem<C> = Ext.PropsArrayItem<C>\n"
             "export type ElemCtor<C> = Ext.ElemCtor<C>\n"
             "export type OnChangeDescriptor<K> = Ext.OnChangeDescriptor<K>\n"
             "export type OnEventDescriptor<K> = Ext.OnEventDescriptor<K>\n")
    out = re.sub(r"\nreturn q\s*$", "\n" + block + "\nreturn q\n", out)
    if "RobloxModule." in re.sub(r"RobloxModule\.QuadRoblox", "", out):
        rep["notes"].append("RobloxModule type references left")
    return out, rep


def main():
    args = sys.argv[1:]
    parts = ["src", "stories", "gallery", "test"]
    report_path = None
    if "--parts" in args:
        i = args.index("--parts")
        parts = args[i + 1].split(",")
        del args[i:i + 2]
    if "--report" in args:
        i = args.index("--report")
        report_path = args[i + 1]
        del args[i:i + 2]
    root, dest, *kits = args
    reports = []
    for kit in kits:
        for part in parts:
            sdir = os.path.join(root, kit, part)
            if not os.path.isdir(sdir):
                continue
            ddir = os.path.join(dest, kit, part)
            if os.path.exists(ddir):
                shutil.rmtree(ddir)
            shutil.copytree(sdir, ddir, symlinks=False, ignore=shutil.ignore_patterns("__pycache__"))
            for dp, _, fs in os.walk(ddir):
                for f in fs:
                    if not f.endswith(".luau"):
                        continue
                    p = os.path.join(dp, f)
                    rel = os.path.relpath(p, dest)
                    src = open(p, encoding="utf-8").read()
                    if f == "Quad.luau" and os.path.dirname(rel) == os.path.join(kit, part) and "UseProvider" in src:
                        out, rep = rewrite_setup(src, rel, "../../")
                    elif "/test/support/" in "/" + rel:
                        continue
                    else:
                        out, rep = rewrite(p, src, rel)
                    if out != src:
                        open(p, "w", encoding="utf-8").write(out)
                    reports.append(rep)
    if report_path:
        json.dump(reports, open(report_path, "w"), ensure_ascii=False, indent=1)
    # summary
    tot = lambda k: sum(len(r.get(k, [])) for r in reports)
    files = [r for r in reports if not r.get("setup")]
    touched = sum(1 for r in files if r.get("n_edits"))
    print(f"files {len(files)} (+{len(reports) - len(files)} setup), touched {touched}")
    print(f"header elem locals {tot('elems')}  modifier locals {tot('mods')}  type rewrites {tot('types')}"
          f"  (input→ModifierInto {sum(1 for r in files for t in r.get('types', []) if 'ModifierInto' in t[2])})")
    print(f"as-stripped {tot('as_stripped')}  needs-full {tot('needs_full')}  onchange/out {tot('onchange')}"
          f"  unresolved {tot('unresolved')}  collisions {tot('collisions')}")
    for r in files:
        for k in ("needs_full", "unresolved", "collisions"):
            for x in r.get(k, []):
                print(f"  {k.upper():11s} {r['file']}: {x}")
        for x in r.get("onchange", []):
            if x[4] != "enclosing element":
                print(f"  ONCHANGE    {r['file']}: {x}")


if __name__ == "__main__":
    main()
