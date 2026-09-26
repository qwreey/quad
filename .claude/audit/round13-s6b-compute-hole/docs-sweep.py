#!/usr/bin/env python3
"""(3) sweep: every `:Compute(` call inside ```luau blocks of docs/ that passes a trailing dep.
Prints file:line, binding form, param count, param/return annotation, dep count."""
import re, pathlib, sys
ROOT = pathlib.Path("/code/Projects/quad/docs")
rows = []
for md in sorted(ROOT.rglob("*.md")):
    if "node_modules" in md.parts or "site" in md.parts and "src" in md.parts and "content" in md.parts:
        continue
    lines = md.read_text().split("\n")
    inb = False; start = 0; buf = []
    for i, l in enumerate(lines):
        if l.strip().startswith("```"):
            if not inb and l.strip().startswith("```lua"):
                inb = True; start = i + 1; buf = []
            elif inb:
                inb = False
                code = "\n".join(buf)
                for m in re.finditer(r":Compute\s*\(", code):
                    # balanced scan to call end, splitting top-level commas
                    j = m.end(); depth = 1; args = []; cur = ""; kw = 0
                    toks = re.finditer(r"\bfunction\b|\bend\b|\bdo\b|\bthen\b|[(){}\[\],]|\"(?:\\.|[^\"])*\"|'(?:\\.|[^'])*'|--[^\n]*|.", code[j:], re.S)
                    # simple: track paren depth + function/end nesting
                    blk = 0
                    for t in toks:
                        s = t.group(0)
                        if s in ("(", "{", "["): depth += 1
                        elif s in (")", "}", "]"):
                            depth -= 1
                            if depth == 0: args.append(cur); break
                        if s == "function": blk += 1
                        elif s == "end": blk -= 1
                        if s == "," and depth == 1 and blk == 0:
                            args.append(cur); cur = ""; continue
                        cur += s
                    if len(args) < 2: continue
                    fn = args[0].strip()
                    pm = re.match(r"function\s*\(([^)]*)\)\s*(:\s*[^\n]*?)?\s*(\n|return|local|if|$)", fn)
                    params = pm.group(1) if pm else "?"
                    np = len([p for p in params.split(",") if p.strip()]) if pm else "?"
                    pann = ":" in params if pm else "?"
                    rann = bool(pm and pm.group(2))
                    lineno = start + code[:m.start()].count("\n") + 1
                    linetxt = lines[lineno - 1]
                    bind = re.match(r"\s*(local|const)\s+\w+\s*:\s*\S", linetxt)
                    rows.append((f"{md.relative_to(ROOT.parent)}:{lineno}", np, len(args) - 1,
                                 "Y" if pann else "N", "Y" if rann else "N",
                                 "annot" if bind else ("local" if re.match(r"\s*(local|const)\s", linetxt) else "inline/other"),
                                 fn if isinstance(fn, str) else fn, linetxt.strip()[:90]))
            continue
        if inb: buf.append(l)
print("file:line | nparams | ndeps | param-annot | return-annot | binding | line")
for r in rows:
    print(" | ".join(str(x) for x in (r[0], r[1], r[2], r[3], r[4], r[5], r[7])))
print(len(rows), "calls", file=sys.stderr)
