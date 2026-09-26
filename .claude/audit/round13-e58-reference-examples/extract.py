#!/usr/bin/env python3
"""E58: extract ```luau fences from docs/reference (errors/ excluded) into blocks/<slug>-L<line>.luau + index.tsv"""
import re, pathlib, sys
root = pathlib.Path(__file__).resolve().parents[3]
ref = root / "docs/reference"
out = pathlib.Path(__file__).parent / "blocks"
out.mkdir(exist_ok=True)
files = [ref / "00-index.md"] + sorted(p for d in ("core","sugar","roblox","extend") for p in (ref/d).glob("*.md"))
rows = []
for f in files:
    lines = f.read_text().splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r'^(\s*)```(luau|lua)\b', lines[i])
        if m:
            ind = len(m.group(1)); start = i + 1; body = []
            i += 1
            while i < len(lines) and not re.match(r'^\s*```\s*$', lines[i]):
                body.append(lines[i][ind:] if lines[i][:ind].strip()=="" else lines[i]); i += 1
            rel = f.relative_to(ref)
            slug = str(rel.with_suffix("")).replace("/", "_")
            name = f"{slug}-L{start}.luau"
            (out / name).write_text("\n".join(body) + "\n")
            rows.append((str(rel), start, len(body), name))
        i += 1
(pathlib.Path(__file__).parent / "index.tsv").write_text("".join(f"{a}\t{b}\t{c}\t{d}\n" for a,b,c,d in rows))
print(len(rows), "blocks")
