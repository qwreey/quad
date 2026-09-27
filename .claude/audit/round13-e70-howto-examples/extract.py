#!/usr/bin/env python3
"""E70: extract ```luau/```lua fences from docs/how-to, docs/overview, docs/quadnomicon, landing index.mdx → blocks/<slug>-L<line>.luau + index.tsv (E58 extract.py 변형)"""
import re, pathlib
root = pathlib.Path(__file__).resolve().parents[3]
out = pathlib.Path(__file__).parent / "blocks"
out.mkdir(exist_ok=True)
files = sorted((root/"docs/how-to").glob("*.md")) + sorted((root/"docs/overview").glob("*.md")) + sorted((root/"docs/quadnomicon").glob("*.md")) + [root/"docs/site/src/content/docs/index.mdx"]
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
            rel = f.relative_to(root/"docs")
            slug = str(rel.with_suffix("")).replace("/", "_").replace("site_src_content_docs_", "landing_")
            name = f"{slug}-L{start}.luau"
            (out / name).write_text("\n".join(body) + "\n")
            rows.append((str(rel), start, len(body), name))
        i += 1
(pathlib.Path(__file__).parent / "index.tsv").write_text("".join(f"{a}\t{b}\t{c}\t{d}\n" for a,b,c,d in rows))
print(len(rows), "blocks")
