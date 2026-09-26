#!/usr/bin/env python3
"""E33 extractor: every **시그니처** (block or inline) in docs/reference (errors/ excluded),
plus the **인자** table and **반환** sentence of the same section.
Usage: python3 extract.py out.json"""
import re, sys, json, pathlib
root = pathlib.Path(__file__).resolve().parents[3] / "docs" / "reference"
out = []
def section_end(lines, i):
    j = i
    while j < len(lines) and not lines[j].startswith("#") and lines[j].strip() != "---":
        j += 1
    return j
for p in sorted(root.rglob("*.md")):
    if "errors" in p.parts: continue
    lines = p.read_text().splitlines()
    heading = None; in_code = False
    i = 0
    while i < len(lines):
        l = lines[i]
        if l.startswith("```"): in_code = not in_code
        if not in_code and l.startswith("#"): heading = l.lstrip("#").strip()
        s = l.strip()
        if not in_code and s.startswith("**시그니처**"):
            m = re.match(r"\*\*시그니처\*\*\s*—\s*`([^`]+)`", s)
            if m:
                sig, sigline, k = m.group(1), i + 1, i
            else:
                j = i + 1
                while j < len(lines) and not lines[j].startswith("```"): j += 1
                k = j + 1
                while k < len(lines) and not lines[k].startswith("```"): k += 1
                sig, sigline = "\n".join(lines[j+1:k]), j + 2
            rec = {"file": str(p.relative_to(root)), "line": sigline, "heading": heading, "sig": sig, "args": [], "argsInline": None, "ret": None}
            end = section_end(lines, k + 1)
            m2 = k + 1; code = False
            while m2 < end:
                t = lines[m2].strip()
                if t.startswith("```"): code = not code
                if not code and t.startswith("**인자**"):
                    if "—" in t or "없음" in t: rec["argsInline"] = t
                    n = m2 + 1
                    while n < end and lines[n].strip() == "": n += 1
                    while n < end and lines[n].startswith("|"):
                        rec["args"].append(lines[n]); n += 1
                if not code and "**반환**" in t and rec["ret"] is None:
                    rec["ret"] = t[t.index("**반환**"):]
                m2 += 1
            out.append(rec)
            i = k
        i += 1
json.dump(out, open(sys.argv[1], "w"), ensure_ascii=False, indent=1)
print(len(out))
