#!/usr/bin/env python3
"""migrate-3.4.py — rewrite Luau sources from the generated `Declaration` surface to the 3.4.0 class-first surface.

  python3 scripts/migrate-3.4.py [--check] [--report <json>] <path>...

<path> is a .luau file or a directory (walked for .luau files). Files are rewritten IN PLACE unless --check (then only
the report is printed). Re-running on converted code changes nothing. Plan `.claude/research/release-3.4.0-plan.md`
단위 5 (ported from the kit-trial prototype `.claude/audit/decl-typefn-probe-2026-10-16/harness/codemod-proto.py`
with the eleven fixes of that REPORT's "킷 규모 시험" 8절). Surface canon: `research/declaration-surface-plan.md` 5절,
names `research/declaration-naming-table.md` 5절.

Rewrites (Q = any name bound to a quad module instance — see `quad_names`):
  * `local D = Q.Declaration` → per-file header locals `local Frame = Q.Elem "Frame"` / `local FrameModifier =
    Q.Modifier "Frame"` (only the classes the file uses) in the binding's place; `D.Frame` → `Frame`,
    `D.Modifier.Frame` → `FrameModifier`. A header name the file already declares gets a `_` suffix (reported).
  * `Q.Declaration.Frame` / `Q.Declaration.Modifier.Frame` written without a `D` (also `require("…Quad").Declaration…`)
    → inline `Q.Elem "Frame"` / `Q.Modifier "Frame"`.
  * `D.New(x)` → `Q.Elem(x)`, `D.Mapper.Frame` → `Q.Mapper "Frame"`, `D.Mapper.Root` → `Q.MapperRoot`,
    `(D.Modifier :: any)[x]` → `(Q.Modifier :: any)(x)`, `getfenv(Q.Declaration.New)` → `getfenv(Q.Elem)`.
  * `Q.OnChange("Name", fn)` / `Q.Out("Name", src)` → `Q.OnChange "C" "Name" (fn)` / `Q.Out "C" "Name" (src)`; C is
    the element whose array part encloses the call, else the element enclosing the first later use of the variable
    the call is assigned to. Otherwise UNRESOLVED (a hook exported to another module — a person picks the class).
  * types `T.<C>Modifier` / `T.Into<C>` (T = a quad name or a name bound to quad-roblox's root/Declaration module):
    input position (table-type field, function parameter) → `T.ModifierInto<C>`; anything else → `T.Modifier<C>`.
    An input whose name gets a non-As method call in the same file stays `T.Modifier<C>` (NEEDS-FULL); `:As…()`
    chains on marker inputs are stripped. `T.Field<` → `T.ModifierField<`, `T.FieldOut<` → `T.ModifierFieldOut<`.
  * base renames: `X.New()` on a quad-base module → `X.NewModule()`, `Q.Modifier(…)`/`Q.Modifier.<member>` (not the
    one-string typed form) → `Q.Raw.Modifier…`, `Q.newMapperClass` → `Q.Raw.Mapper`.
  * setup modules (any file whose code calls `UseProvider(`) drop the per-class re-exports (`<C>Modifier`, `Into<C>`,
    `OnChangeFn`, `OutFn`) and re-export the generic set from quad-roblox's root.

Reported, never rewritten (fix 3/6/9): a `Declaration` reached through a cast (`(… :: any).Declaration`) or used as a
value; unresolved OnChange/Out; remaining `D.`/old type names in comments and strings (a separate docs pass).
Analysis runs on a masked copy (comments/strings blanked, same offsets); line numbers in the report are the ORIGINAL
file's (fix 8). Edits are applied right to left.
"""
import json
import os
import re
import sys

# generic re-exports a converted setup module carries (quad-roblox root names after the 3.4.0 switch)
SETUP_EXPORTS = [
    ("Modifier<C>", "Modifier<C>"),
    ("ModifierInto<C>", "ModifierInto<C>"),
    ("Spread<C>", "Spread<C>"),
    ("SpreadInto<C>", "SpreadInto<C>"),
    ("Props<C>", "Props<C>"),
    ("ElemCtor<C>", "ElemCtor<C>"),
    ("OnChangeDescriptor<K>", "OnChangeDescriptor<K>"),
    ("OnEventDescriptor<K>", "OnEventDescriptor<K>"),
]


# ── masking ────────────────────────────────────────────────────────────────
def mask(src: str) -> str:
    """comments and string contents blanked (quotes kept), same length and newlines"""
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
            blank(i + 1, j)
            i = j + 1
            continue
        i += 1
    return "".join(out)


OPEN = {"(": ")", "{": "}", "[": "]"}
CLOSE = {v: k for k, v in OPEN.items()}


def brackets(ms: str):
    """enclosing[i] = position of the innermost open bracket around offset i (-1 at top level); parent/closes maps"""
    parent, closes, st = {}, {}, []
    enclosing = [-1] * (len(ms) + 1)
    for i, c in enumerate(ms):
        enclosing[i] = st[-1] if st else -1
        if c in OPEN:
            parent[i] = st[-1] if st else -1
            st.append(i)
        elif c in CLOSE and st:
            closes[st.pop()] = i
    return enclosing, parent, closes


def prev_tok(ms: str, i: int) -> int:
    j = i - 1
    while j >= 0 and ms[j] in " \t\r\n":
        j -= 1
    return j


def line_of(src: str, pos: int) -> int:
    return src.count("\n", 0, pos) + 1


WS = r"\s*"  # fix 4: whitespace/newlines allowed around dots


def dotted(*parts: str) -> str:
    return (WS + r"\." + WS).join(parts)


# ── names ──────────────────────────────────────────────────────────────────
def quad_names(src: str, ms: str, rel: str):
    """(quad instance names, quad-base module names, quad-roblox module names) — fix 2 (aliases) / 5 (require strings
    are read from the ORIGINAL source; a match counts only when it starts in code)."""
    def code(m):
        return ms[m.start():m.start() + 5] == "local"

    q, base_mod, rbx_mod = set(), set(), set()
    for m in re.finditer(r"local\s+(\w+)\s*(?::[^=\n]*)?=\s*[^\n]*?require\(\s*\"([^\"]*)\"\s*\)([^\n]*)", src):
        if not code(m):
            continue
        name, path, tail = m.group(1), m.group(2), m.group(3)
        last = path.rstrip("/").split("/")[-1]
        if re.match(r"\s*\.", tail):
            continue  # `require(…).QuadRoblox` etc. — a member, not the module
        if last == "Quad":
            q.add(name)
        elif last == "quad_base" or (last == "src" and "quad-base" in rel and "/test/" in "/" + rel):
            base_mod.add(name)
        elif last in ("src", "quad_roblox", "Declaration") and ("quad-roblox" in path or "quad_roblox" in path
                                                                  or ("quad-roblox" in rel and "/test/" in "/" + rel)):
            rbx_mod.add(name)
    for m in re.finditer(r"local\s+(\w+)\s*(?::[^=\n]*)?=\s*[^\n]*(?:UseProvider\(|newQuad\(|\.New\(\)|\.NewModule\(\))", ms):
        q.add(m.group(1))
    changed = True
    while changed:  # `local q = Q`, `local q = H.attach(Q)`, `local q = H.attach(require("…Quad"))`
        changed = False
        for m in re.finditer(r"local\s+(\w+)\s*(?::[^=\n]*)?=\s*(?:[\w.:]+\(\s*)?(\w+)\s*\)?\s*(?::[^\n]*)?$", ms, re.M):
            if m.group(2) in q and m.group(1) not in q:
                q.add(m.group(1))
                changed = True
        for m in re.finditer(r"local\s+(\w+)\s*=\s*[\w.:]+\(\s*require\(\s*\"([^\"]*)\"\s*\)\s*\)", src):
            if code(m) and m.group(2).rstrip("/").split("/")[-1] == "Quad" and m.group(1) not in q:
                q.add(m.group(1))
                changed = True
    return q, base_mod, rbx_mod


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


# ── per-file rewrite ─────────────────────────────────────────────────────────
class Rewriter:
    def __init__(self, src: str, rel: str):
        self.src, self.rel = src, rel
        self.ms = mask(src)
        self.edits = []  # (start, end, text)
        self.taken = []  # analyzed spans already claimed by an edit
        self.rep = {"file": rel, "header": [], "inline": 0, "types": [], "needs_full": [], "as_stripped": [],
                    "onchange": [], "unresolved": [], "collisions": [], "cast_d": [], "notes": [], "base": []}
        self.q, self.base_mod, self.rbx_mod = quad_names(src, self.ms, rel)
        self.enclosing, self.parent, self.closes = brackets(self.ms)

    def ln(self, pos):
        return line_of(self.src, pos)

    def free(self, a, b):
        return not any(x < b and a < y for x, y in self.taken)

    def edit(self, a, b, text):
        self.edits.append((a, b, text))
        self.taken.append((a, b))

    # the class if the bracket at `open_pos` is an element constructor's table (`D.C {`, `D.C({`, `Q.Declaration.C {`)
    def element_class(self, open_pos: int, dname):
        ms = self.ms
        j = prev_tok(ms, open_pos)
        if j >= 0 and ms[j] == "(" and ms[open_pos] == "{":
            j = prev_tok(ms, j)
        rm = re.search(r"((?:\w+\s*\.\s*)*\w+)$", ms[max(0, j - 200):j + 1]) if j >= 0 else None
        ref = re.sub(r"\s+", "", rm.group(1)) if rm else ""
        m = re.fullmatch(r"(\w+)\.(?:Declaration\.)?([A-Z]\w*)", ref)
        if not m or m.group(2) in ("Modifier", "Mapper", "New"):
            return None
        if m.group(1) == dname or (m.group(1) in self.q and ".Declaration." in ref):
            return m.group(2)
        return None

    def run(self):
        src, ms, rep = self.src, self.ms, self.rep
        qs = sorted(self.q)
        qalt = "|".join(map(re.escape, qs)) if qs else r"(?!x)x"
        default_q = None

        # ---- casts of the Declaration (fix 3): reported, never rewritten
        for m in re.finditer(r"\)\s*\.\s*Declaration\b", ms):
            open_ = None
            depth = 0
            for k in range(m.start(), -1, -1):
                if ms[k] == ")":
                    depth += 1
                elif ms[k] == "(":
                    depth -= 1
                    if depth == 0:
                        open_ = k
                        break
            inner = ms[open_:m.start() + 1] if open_ is not None else ""
            if "::" in inner:
                rep["cast_d"].append((self.ln(m.start()), src[open_:m.end()].strip()))
                self.taken.append((open_, m.end()))

        # ---- `local D = Q.Declaration`
        dm = re.search(r"^([ \t]*)local\s+(\w+)\s*=\s*(" + qalt + r")\s*\.\s*Declaration[ \t]*(?:--[^\n]*)?\n", ms, re.M)
        dname = dm.group(2) if dm else None
        if dm:
            default_q = dm.group(3)
        elems, mods = set(), set()
        uses = []  # (start, end, kind, cls)

        def claim(m, kind, cls, a=None, b=None):
            a = m.start() if a is None else a
            b = m.end() if b is None else b
            if self.free(a, b):
                uses.append((a, b, kind, cls))
                self.taken.append((a, b))

        if dname:
            for m in re.finditer(r"\(\s*" + dname + dotted("", "Modifier")[len(WS):] + r"\s*::\s*any\s*\)\s*\[([^\]\n]+)\]", ms):
                claim(m, "DYN", src[m.start(1):m.end(1)])
            for m in re.finditer(r"(?<![\w.:])" + dotted(dname, "Modifier", r"([A-Za-z]\w*)") + r"\b", ms):
                claim(m, "MOD", m.group(1))
            for m in re.finditer(r"(?<![\w.:])" + dotted(dname, "Mapper", r"([A-Za-z]\w*)") + r"\b", ms):
                claim(m, "MAPPER", m.group(1))
            for m in re.finditer(r"(?<![\w.:])" + dotted(dname, "New") + r"\b", ms):
                claim(m, "NEW", None)
            for m in re.finditer(r"(?<![\w.:])" + dotted(dname, r"([A-Z]\w*)") + r"\b", ms):
                if m.group(1) in ("Modifier", "Mapper", "New"):
                    if self.free(m.start(), m.end()):
                        rep["unresolved"].append((self.ln(m.start()), f"bare {dname}.{m.group(1)}"))
                    continue
                claim(m, "ELEM", m.group(1))
        # inline `X.Declaration.…` (X a quad name or a `require("…Quad")` call)
        owner = r"(" + qalt + r"|require\(\s*\"[^\"]*\"\s*\))"
        osrc = r"(" + qalt + r"|require\(\s*\"[^\"]*Quad\"\s*\))"
        for m in re.finditer(r"getfenv\(\s*" + osrc.replace("(", "(?:", 1) + r"\s*\.\s*Declaration\s*\.\s*New\s*\)", src):
            if ms[m.start():m.start() + 7] == "getfenv":
                qn = re.search(r"getfenv\(\s*(.*?)\s*\.\s*Declaration", src[m.start():m.end()], re.S).group(1)
                if self.free(m.start(), m.end()):
                    self.edit(m.start(), m.end(), f"getfenv({qn}.Elem)")
        for pat, kind in ((dotted(osrc, "Declaration", "Modifier", r"([A-Za-z]\w*)"), "IMOD"),
                          (dotted(osrc, "Declaration", "Mapper", r"([A-Za-z]\w*)"), "IMAPPER"),
                          (dotted(osrc, "Declaration", "New"), "INEW"),
                          (dotted(osrc, "Declaration", r"([A-Z]\w*)"), "IELEM")):
            for m in re.finditer(r"(?<![\w.:])" + pat + r"\b", src):
                if ms[m.start()] == " " and not src[m.start()].isspace():
                    continue  # starts inside a comment/string
                if not self.free(m.start(), m.end()):
                    continue
                qn = m.group(1)
                cls = m.group(2) if m.lastindex and m.lastindex >= 2 else None
                if kind == "IELEM" and cls in ("Modifier", "Mapper", "New"):
                    rep["unresolved"].append((self.ln(m.start()), f"bare {qn}.Declaration.{cls}"))
                    continue
                text = {"IMOD": f'{qn}.Modifier "{cls}"', "IMAPPER": f"{qn}.MapperRoot" if cls == "Root" else f'{qn}.Mapper "{cls}"',
                        "INEW": f"{qn}.Elem", "IELEM": f'{qn}.Elem "{cls}"'}[kind]
                self.edit(m.start(), m.end(), text)
                rep["inline"] += 1
        # any `.Declaration` left in code is a value use
        for m in re.finditer(r"\.\s*Declaration\b", ms):
            if self.free(m.start(), m.end()) and not (dm and dm.start() <= m.start() < dm.end()):
                rep["unresolved"].append((self.ln(m.start()), "Declaration used as a value"))

        # header names
        q0 = default_q or (qs[0] if qs else "q")
        declared = declared_names(ms)
        names = {}
        for a, b, kind, cls in uses:
            if kind == "ELEM":
                elems.add(cls)
            elif kind == "MOD":
                mods.add(cls)
        for cls in sorted(elems):
            nm = cls if cls not in declared else cls + "_"
            if nm != cls:
                rep["collisions"].append((cls, nm))
            names[("ELEM", cls)] = nm
        for cls in sorted(mods):
            nm = cls + "Modifier"
            if nm in declared:
                rep["collisions"].append((nm, nm + "_"))
                nm += "_"
            names[("MOD", cls)] = nm
        for a, b, kind, cls in uses:
            if kind in ("ELEM", "MOD"):
                self.edits.append((a, b, names[(kind, cls)]))
            elif kind == "DYN":
                self.edits.append((a, b, f"({q0}.Modifier :: any)({cls})"))
            elif kind == "MAPPER":
                self.edits.append((a, b, f"{q0}.MapperRoot" if cls == "Root" else f'{q0}.Mapper "{cls}"'))
            elif kind == "NEW":
                self.edits.append((a, b, f"{q0}.Elem"))
        if dm:
            ind = dm.group(1)
            hdr = "".join(f'{ind}local {names[("ELEM", c)]} = {q0}.Elem "{c}"\n' for c in sorted(elems))
            hdr += "".join(f'{ind}local {names[("MOD", c)]} = {q0}.Modifier "{c}"\n' for c in sorted(mods))
            self.edit(dm.start(), dm.end(), hdr)
            rep["header"] = sorted(elems) + [c + "Modifier" for c in sorted(mods)]
            # bare `D` value uses: a keep-alive `local _ = D` is dropped, anything else reported
            for m in re.finditer(r"(?<![\w.:])" + dname + r"(?![\w])", ms):
                if not self.free(m.start(), m.end()):
                    continue
                ls = ms.rfind("\n", 0, m.start()) + 1
                lm = re.match(r"[ \t]*local\s+_\s*=\s*" + dname + r"[ \t]*\n", ms[ls:])
                if lm:
                    self.edit(ls, ls + lm.end(), "")
                    rep["notes"].append(f"L{self.ln(m.start())}: keep-alive `local _ = {dname}` dropped")
                else:
                    rep["unresolved"].append((self.ln(m.start()), f"bare `{dname}` value use"))

        self.types()
        self.onchange(dname)
        self.base_renames()
        self.leftovers(dname)
        return self.apply()

    # ---- Modifier types and Field renames (fix 7)
    def types(self):
        ms, src, rep = self.ms, self.src, self.rep
        tnames = sorted(self.q | self.rbx_mod)
        if not tnames:
            return
        talt = "|".join(map(re.escape, tnames))
        for m in re.finditer(r"(?<![\w.:])(" + talt + r")\s*\.\s*(Field|FieldOut)\s*<", ms):
            if self.free(m.start(), m.end()):
                self.edit(m.start(), m.end(), f"{m.group(1)}.Modifier{m.group(2)}<")
        for m in re.finditer(r"(?<![\w.:])(" + talt + r")\s*\.\s*(OnChangeFn|OutFn|PropTypes|PropTypesRead|DeclarationMapper)\b", ms):
            rep["unresolved"].append((self.ln(m.start()), f"old type {m.group(0)} (no 3.4.0 equivalent)"))
        method_calls = {}
        for m in re.finditer(r"([\w.]*\w)\s*:\s*([A-Z]\w*)\s*\(", ms):
            method_calls.setdefault(m.group(1).split(".")[-1], []).append((m.start(), m.group(2)))
        tpat = re.compile(r"(?<![\w.:])(" + talt + r")\s*\.\s*(?:Into([A-Z]\w*)|([A-Z]\w*)Modifier)\b")
        markers = set()
        for m in tpat.finditer(ms):
            if not self.free(m.start(), m.end()):
                continue
            tn, into_cls, mod_cls = m.group(1), m.group(2), m.group(3)
            cls = into_cls or mod_cls
            kind, field = "full", None
            j = prev_tok(ms, m.start())
            if j >= 0 and ms[j] == ":" and (j == 0 or ms[j - 1] != ":"):
                k = prev_tok(ms, j)
                e = k + 1
                while k >= 0 and (ms[k].isalnum() or ms[k] == "_"):
                    k -= 1
                ident = ms[k + 1:e]
                before = prev_tok(ms, k + 1)
                b_ch = ms[before] if before >= 0 else ""
                bw = (re.search(r"(\w+)\s*$", ms[:k + 1]) or [None, ""])[1] if k >= 0 else ""
                enc = self.enclosing[m.start()]
                enc_ch = ms[enc] if enc >= 0 else ""
                if not ident or bw == "local":
                    kind = "full"
                elif enc_ch == "{" and (b_ch in "{,;" or bw in ("read", "write") or b_ch == ""):
                    kind, field = "input", ident
                elif enc_ch == "(":
                    pj = prev_tok(ms, enc)
                    head = ms[max(0, pj - 80):pj + 1]
                    if re.search(r"\bfunction\b[\w.:\s]*$", head) and b_ch in "(,":
                        kind, field = "input", ident
            if into_cls and kind != "input":
                new = f"{tn}.ModifierInto<{cls}>"
                rep["notes"].append(f"L{self.ln(m.start())}: Into<{cls}> outside an input position — kept as ModifierInto")
            elif kind == "input":
                calls = [c for c in method_calls.get(field, []) if not c[1].startswith("As")]
                if calls:
                    new = f"{tn}.Modifier<{cls}>"
                    rep["needs_full"].append((self.ln(m.start()), field, cls, sorted({c[1] for c in calls})))
                else:
                    new = f"{tn}.ModifierInto<{cls}>"
                    markers.add(field)
            else:
                new = f"{tn}.Modifier<{cls}>"
            rep["types"].append((self.ln(m.start()), re.sub(r"\s+", "", m.group(0)), new, kind))
            self.edit(m.start(), m.end(), new)
        for f in markers:
            for m in re.finditer(r"((?:\w+\s*\.\s*)*" + re.escape(f) + r")((?:\s*:\s*As[A-Z]\w*\s*\(\s*\))+)", ms):
                if self.free(m.start(2), m.end(2)):
                    self.edit(m.start(2), m.end(2), "")
                    rep["as_stripped"].append((self.ln(m.start()), re.sub(r"\s+", "", src[m.start():m.end()])))

    # ---- OnChange / Out (fix 6)
    def onchange(self, dname):
        ms, src, rep = self.ms, self.src, self.rep
        for qn in sorted(self.q):
            for m in re.finditer(r"(?<![\w.:])" + re.escape(qn) + r"\s*\.\s*(OnChange|Out)\s*\(", ms):
                fn = m.group(1)
                op = m.end() - 1
                cl = self.closes.get(op)
                am = re.match(r"\s*([\"'])", ms[op + 1:])
                ln = self.ln(m.start())
                if cl is None or not am:
                    rep["unresolved"].append((ln, f"{qn}.{fn}: first argument is not a string literal"))
                    continue
                q0 = op + 1 + am.end() - 1
                q1 = ms.index(am.group(1), q0 + 1)
                name = src[q0 + 1:q1]
                cm = re.match(r"\s*,\s*", ms[q1 + 1:])
                if not cm:
                    rep["unresolved"].append((ln, f"{qn}.{fn}(\"{name}\"): no second argument"))
                    continue
                cls, how = None, None
                e = self.enclosing[m.start()]
                while e is not None and e >= 0:
                    if ms[e] == "{":
                        cls = self.element_class(e, dname)
                        how = "enclosing element" if cls else None
                        break
                    pj = prev_tok(ms, e)
                    if ms[e] == "(" and re.search(r"\bfunction\b[\w.:\s]*$", ms[max(0, pj - 60):pj + 1]):
                        break
                    e = self.parent.get(e, -1)
                if cls is None:
                    am2 = re.search(r"(?:local\s+)?(\w+)\s*(?::[^=\n]*)?=\s*$", ms[max(0, m.start() - 120):m.start()])
                    if am2:
                        var = am2.group(1)
                        for um in re.finditer(r"(?<![\w.:])" + re.escape(var) + r"(?![\w])", ms[cl:]):
                            upos = cl + um.start()
                            e2 = self.enclosing[upos]
                            if e2 >= 0 and ms[e2] == "{":
                                c2 = self.element_class(e2, dname)
                                if c2:
                                    cls, how = c2, f"via variable `{var}` (L{self.ln(upos)})"
                                    break
                if cls is None:
                    rep["unresolved"].append((ln, f"{qn}.{fn}(\"{name}\", …): placing element not found — pick the class by hand"))
                    continue
                if self.free(m.start(), q1 + 1 + cm.end()):
                    self.edit(m.start(), q1 + 1 + cm.end(), f'{qn}.{fn} "{cls}" "{name}" (')
                    rep["onchange"].append((ln, fn, cls, name, how))

    # ---- quad-base renames
    def base_renames(self):
        ms, rep = self.ms, self.rep
        # every quad instance had `New()` in 3.3 (base module, provider-installed `q`, setup-module aliases)
        known = self.q | self.base_mod
        for mod in sorted(known):
            for m in re.finditer(r"(?<![\w.:])" + re.escape(mod) + r"\s*\.\s*New\s*\(\s*\)", ms):
                if self.free(m.start(), m.end()):
                    self.edit(m.start(), m.end(), f"{mod}.NewModule()")
                    rep["base"].append((self.ln(m.start()), "New() → NewModule()"))
        # `.New()` on a name not recognised as quad (an Instance-path require, a field of another table, ...) —
        # not rewritten (it may not be quad), but reported so it is not silently left behind
        for m in re.finditer(r"\.\s*New\s*\(\s*\)", ms):
            if not self.free(m.start(), m.end()):
                continue
            rep["unresolved"].append((self.ln(m.start()), "`.New()` on a module not recognised as quad: if it is one, rename to `.NewModule()`"))
        for qn in sorted(self.q | self.base_mod):
            for m in re.finditer(r"(?<![\w.:])" + re.escape(qn) + r"\s*\.\s*Modifier\b(?!\s*\.\s*(?:Raw)\b)", ms):
                if not self.free(m.start(), m.end()):
                    continue
                rest = ms[m.end():]
                # the typed one-string form stays: `q.Modifier "Frame"` / `q.Modifier("Frame")`
                if re.match(r"\s*\"\s*\"", rest) or re.match(r"\s*\(\s*\"[^\"\n]*\"\s*\)", rest):
                    continue
                # a call or a member is base's untyped constructor; the bare value too, but only where no provider is
                # installed (quad-base code) — under a provider `(q.Modifier :: any)(cls)` is the typed factory
                # `q.Modifier { … }` (3.3's table-call form) is the untyped constructor too
                if re.match(r"\s*(\(|\{|\.\s*(Overridden|TypedFactory|DefineSubtype)\b)", rest) or "quad-base/" in self.rel:
                    self.edit(m.start(), m.end(), f"{qn}.Raw.Modifier")
                    rep["base"].append((self.ln(m.start()), "Modifier → Raw.Modifier"))
                    # an untyped Modifier VALUE (a call / table call, not the namespace fields) is refused by 3.4.0's
                    # typed elements — not rewritten (the class is the element's, which may be far away), but reported
                    if "quad-base/" not in self.rel and re.match(r"\s*(\(|\{)", rest):
                        rep["unresolved"].append((self.ln(m.start()), "untyped Modifier: 3.4.0 typed elements refuse it - if it goes on an element, build it with q.Modifier \"Class\" (…)"))
            for m in re.finditer(r"(?<![\w.:])" + re.escape(qn) + r"\s*\.\s*newMapperClass\b", ms):
                if self.free(m.start(), m.end()):
                    self.edit(m.start(), m.end(), f"{qn}.Raw.Mapper")
                    rep["base"].append((self.ln(m.start()), "newMapperClass → Raw.Mapper"))

    # ---- what stays for people (fix 9): old names in comments/strings
    def leftovers(self, dname):
        src, ms = self.src, self.ms
        n = 0
        for m in re.finditer(r"\bD\s*\.\s*[A-Z]\w*|\bDeclaration\b|\b(?:Into[A-Z]\w*|[A-Z]\w*Modifier)\b|\bOnChange\(\"", src):
            if ms[m.start()] == " " and not src[m.start()].isspace():
                n += 1
        self.rep["doc_leftovers"] = n

    def apply(self):
        es = sorted(self.edits, key=lambda t: (t[0], t[1]))
        for x, y in zip(es, es[1:]):
            if y[0] < x[1]:
                raise SystemExit(f"{self.rel}: overlapping edits {x} {y}")
        out = self.src
        for a, b, t in reversed(es):
            out = out[:a] + t + out[b:]
        self.rep["n_edits"] = len(es)
        return out, self.rep


# ── setup modules (fix 1: found by `UseProvider(` in code, not by file name) ─────
def rewrite_setup(src: str, rel: str):
    rep = {"file": rel, "setup": True, "notes": []}
    ms = mask(src)
    m = re.search(r"local\s+(\w+)\s*=\s*require\([^\n]*quad-roblox/src\"\s*\)", src)
    rmod = m.group(1) if m and ms[m.start():m.start() + 5] == "local" else None
    out = re.sub(r"^export type (\w+Modifier|Into[A-Z]\w*|OnChangeFn|OutFn)\b[^\n]*\n", "", src, flags=re.M)
    out = re.sub(r"^export type Field<T> = (\w+)\.Field<T>", r"export type ModifierField<T> = \1.ModifierField<T>", out, flags=re.M)
    out = re.sub(r"^export type FieldOut<T> = (\w+)\.FieldOut<T>", r"export type ModifierFieldOut<T> = \1.ModifierFieldOut<T>", out, flags=re.M)
    if rmod and "export type ModifierInto<C>" not in out:
        block = "".join(f"export type {a} = {rmod}.{b}\n" for a, b in SETUP_EXPORTS)
        out, k = re.subn(r"(\n-- generated Declaration types[^\n]*\n)", "\n-- typed surface (quad-roblox module root): one generic per axis, the class is the type argument\n" + block, out, count=1)
        if k == 0:
            out = re.sub(r"\nreturn (\w+)\s*$", "\n-- typed surface (quad-roblox module root)\n" + block + "\nreturn \\1\n", out)
    elif not rmod:
        rep["notes"].append("setup module without a quad-roblox root require — re-exports not added")
    return out, rep


def is_setup(src: str) -> bool:
    return re.search(r"UseProvider\(", mask(src)) is not None and re.search(r"^return \w+\s*$", src, re.M) is not None


def files_of(paths):
    for p in paths:
        if os.path.isfile(p):
            yield p
            continue
        for dp, dns, fs in os.walk(p):
            dns[:] = [d for d in dns if d not in ("luau_packages", "roblox_packages", "node_modules", ".git")]
            for f in sorted(fs):
                if f.endswith(".luau"):
                    yield os.path.join(dp, f)


def main():
    args = sys.argv[1:]
    check = "--check" in args
    if check:
        args.remove("--check")
    report_path = None
    if "--report" in args:
        i = args.index("--report")
        report_path = args[i + 1]
        del args[i:i + 2]
    if not args:
        print(__doc__)
        sys.exit(2)
    reports = []
    for p in files_of(args):
        rel = os.path.relpath(p)
        src = open(p, encoding="utf-8").read()
        if is_setup(src) and "/test/" not in "/" + rel:
            out, rep = rewrite_setup(src, rel)
        else:
            out, rep = Rewriter(src, rel).run()
        rep["changed"] = out != src
        if out != src and not check:
            open(p, "w", encoding="utf-8").write(out)
        reports.append(rep)
    if report_path:
        json.dump(reports, open(report_path, "w"), ensure_ascii=False, indent=1)
    tot = lambda k: sum(len(r.get(k, [])) for r in reports)
    files = [r for r in reports if not r.get("setup")]
    print(f"files {len(reports)} (setup {len(reports) - len(files)}), changed {sum(1 for r in reports if r['changed'])}"
          + (" [check — nothing written]" if check else ""))
    print(f"header locals {tot('header')}  inline {sum(r.get('inline', 0) for r in files)}  types {tot('types')}"
          f"  as-stripped {tot('as_stripped')}  onchange/out {tot('onchange')}  base renames {tot('base')}")
    print(f"needs-full {tot('needs_full')}  unresolved {tot('unresolved')}  cast-D {tot('cast_d')}  collisions {tot('collisions')}"
          f"  comment/string leftovers {sum(r.get('doc_leftovers', 0) for r in files)}")
    for r in reports:
        for k in ("cast_d", "unresolved", "needs_full", "collisions"):
            for x in r.get(k, []):
                print(f"  {k.upper():10s} {r['file']}: {x}")
        for x in r.get("onchange", []):
            if x[4] != "enclosing element":
                print(f"  ONCHANGE   {r['file']}: {x}")
        for x in r.get("notes", []):
            print(f"  NOTE       {r['file']}: {x}")


if __name__ == "__main__":
    main()
