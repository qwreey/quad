#!/usr/bin/env python3
"""Broader sweep for Q105: every local/const binding of a :Compute(/:Apply(/:Gate(/:Mapped(
call inside ```lua blocks of docs/ (site excluded). Reports binding annotation state and
scans the rest of the same code block for how the bound identifier is used downstream."""
import re, pathlib, sys

ROOT = pathlib.Path("/code/Projects/quad/docs")
METHOD_RE = re.compile(r":(Compute|Apply|Gate|Mapped)\s*\(")
BIND_RE = re.compile(r'^(?P<indent>\s*)(?P<kw>local|const)\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?P<ann>:\s*[^=]+?)?\s*=\s*(?P<rhs>.*)$')

rows = []
for md in sorted(ROOT.rglob("*.md")):
    if "site" in md.parts:
        continue
    lines = md.read_text().split("\n")
    inb = False
    blocks = []  # list of (start_line_idx, end_line_idx) 0-based, inclusive of code lines only
    start = 0
    for i, l in enumerate(lines):
        s = l.strip()
        if not inb and s.startswith("```lua"):
            inb = True
            start = i + 1
        elif inb and s.startswith("```"):
            inb = False
            blocks.append((start, i - 1))
    for (b0, b1) in blocks:
        block_lines = lines[b0:b1 + 1]
        blocktext = "\n".join(block_lines)
        for li, l in enumerate(block_lines):
            if not METHOD_RE.search(l):
                continue
            bm = BIND_RE.match(l)
            if not bm:
                continue
            rhs = bm.group("rhs")
            if not METHOD_RE.search(rhs):
                # the method call isn't on the RHS start of this line (could be later stmt) -- still record if line matches overall
                pass
            name = bm.group("name")
            ann = bm.group("ann")
            method = METHOD_RE.search(l).group(1)
            abs_line = b0 + li + 1
            # scan downstream usage within the rest of the block (after this line)
            usages = []
            ident_re = re.compile(r'\b' + re.escape(name) + r'\b')
            for j in range(li + 1, len(block_lines)):
                ul = block_lines[j]
                if ident_re.search(ul):
                    usages.append((b0 + j + 1, ul.strip()))
            rows.append({
                "file": str(md.relative_to(ROOT.parent)),
                "line": abs_line,
                "name": name,
                "method": method,
                "annotated": bool(ann),
                "ann_text": ann.strip() if ann else "",
                "snippet": l.strip()[:100],
                "usages": usages,
            })

for r in rows:
    print("=" * 100)
    print(f"{r['file']}:{r['line']}  [{r['method']}]  name={r['name']}  annotated={'Y' if r['annotated'] else 'N'} {r['ann_text']}")
    print(f"  bind: {r['snippet']}")
    if not r["usages"]:
        print("  usages: (none found later in block)")
    else:
        for (ln, txt) in r["usages"][:6]:
            print(f"  usage@{ln}: {txt[:100]}")
print(f"\nTOTAL rows: {len(rows)}", file=sys.stderr)
print(f"TOTAL annotated: {sum(1 for r in rows if r['annotated'])}", file=sys.stderr)
print(f"TOTAL unannotated: {sum(1 for r in rows if not r['annotated'])}", file=sys.stderr)
