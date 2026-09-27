#!/usr/bin/env python3
"""E75: check every link in docs/reference/errors/*.md "참고" lines (and all links in those pages)
resolves to an existing file and, if it has #anchor, to a heading slug in that file.
Slug = github-slugger (Starlight/rehype-slug): lowercase, drop chars that are not letters/numbers/
marks/space/-/_ , spaces -> '-'. Duplicate headings get -1, -2 suffixes."""
import re, sys, pathlib, unicodedata
root = pathlib.Path(__file__).resolve().parents[4]
errs = root / "docs/reference/errors"

def slug(s):
    s = s.strip().lower()
    out = []
    for ch in s:
        cat = unicodedata.category(ch)
        if ch in "-_" or ch == " ":
            out.append("-" if ch == " " else ch)
        elif cat[0] in "LNM":
            out.append(ch)
    return "".join(out)

def heading_text(line):
    t = re.sub(r"^#+\s*", "", line).strip()
    t = re.sub(r"`([^`]*)`", r"\1", t)
    t = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", t)
    t = re.sub(r"[*_]{1,2}([^*_]+)[*_]{1,2}", r"\1", t)
    return t

cache = {}
def slugs(p):
    if p in cache: return cache[p]
    seen = {}; res = set(); fence = False
    for line in p.read_text(encoding="utf-8").splitlines():
        if line.startswith("```"): fence = not fence; continue
        if fence: continue
        if re.match(r"^#{1,6}\s", line):
            s = slug(heading_text(line))
            if s in seen:
                seen[s] += 1; s2 = f"{s}-{seen[s]}"
            else:
                seen[s] = 0; s2 = s
            res.add(s2)
    cache[p] = res
    return res

bad = 0; total = 0
for page in sorted(errs.glob("*.md")):
    cur = None
    for n, line in enumerate(page.read_text(encoding="utf-8").splitlines(), 1):
        m = re.match(r"^### (Quad\d{4})", line)
        if m: cur = m.group(1)
        for lm in re.finditer(r"\]\(([^)\s]+)\)", line):
            href = lm.group(1)
            if href.startswith("http"): continue
            total += 1
            path, _, anc = href.partition("#")
            tgt = (page.parent / path).resolve() if path else page
            if not tgt.exists():
                print(f"MISSINGFILE\t{page.name}:{n}\t{cur}\t{href}"); bad += 1; continue
            if anc:
                from urllib.parse import unquote
                a = unquote(anc)
                if a not in slugs(tgt):
                    near = [s for s in slugs(tgt) if a[:6] in s][:3]
                    print(f"BADANCHOR\t{page.name}:{n}\t{cur}\t{href}\tnear={near}"); bad += 1
print(f"links={total} bad={bad}")
