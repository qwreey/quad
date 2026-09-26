#!/usr/bin/env python3
"""E33 static comparison: doc member text vs source declaration text (whitespace/comment-normalized).
Source records are parsed from quad-types/src/init.luau, quad-roblox/src/{types,init}.luau,
quad-roblox/src/Declaration/init.luau, quad-error/src/init.luau.  Output: static.json"""
import json, re, pathlib
R = pathlib.Path(__file__).resolve().parents[3]
FILES = ["quad-types/src/init.luau", "quad-roblox/src/types.luau", "quad-roblox/src/init.luau",
         "quad-roblox/src/Declaration/init.luau", "quad-error/src/init.luau"]
def strip_comments(s):
    return "\n".join(re.sub(r"\s--(?!\[).*$", "", l) if not l.strip().startswith("--") else "" for l in s.split("\n"))
def norm(s):
    s = strip_comments(s)
    s = re.sub(r"\s+", "", s)
    return s.rstrip(",")
records = {}   # (recordName, field) -> (file, line, text)
aliases = {}   # name -> (file, line, text)
for f in FILES:
    lines = (R / f).read_text().split("\n")
    i = 0
    while i < len(lines):
        m = re.match(r"^export type (\w+)(<[^=]*>)?\s*=\s*(.*)$", lines[i])
        if m:
            name = m.group(1); start = i; body = m.group(3); depth = 0
            text = [body]
            def d(s): 
                s = re.sub(r"--.*$", "", s)
                return s.count("{") + s.count("(") + s.count("<") - s.count("}") - s.count(")") - s.count(">") + s.count("->")
            depth = d(body)
            j = i
            while depth > 0 and j + 1 < len(lines):
                j += 1; text.append(lines[j]); depth += d(lines[j])
            full = "\n".join(text)
            aliases[name] = (f, start + 1, full)
            # fields at depth 1
            if "{" in body:
                dep = 0; cur = None
                for k, l in enumerate(text):
                    code = re.sub(r"--.*$", "", l)
                    if dep == 1:
                        fm = re.match(r"^\s*(?:read\s+)?(\w+):\s*(.*)$", code)
                        if fm:
                            cur = [fm.group(1), fm.group(2), start + 1 + k]
                            records[(name, fm.group(1))] = (f, start + 1 + k, fm.group(2))
                        elif cur is not None and code.strip():
                            records[(name, cur[0])] = (f, cur[2], records[(name, cur[0])][2] + "\n" + code)
                    elif dep > 1 and cur is not None:
                        records[(name, cur[0])] = (f, cur[2], records[(name, cur[0])][2] + "\n" + code)
                    dep += d(code)
                    if dep == 1 and cur is not None and code.strip().endswith(","):
                        cur = None
            i = j
        i += 1
json.dump({"records": {f"{k[0]}.{k[1]}": v for k, v in records.items()}, "aliases": aliases},
          open("source_index.json", "w"), ensure_ascii=False, indent=0)
print(len(records), len(aliases))
