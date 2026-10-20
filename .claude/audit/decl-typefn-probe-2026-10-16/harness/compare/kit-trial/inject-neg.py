#!/usr/bin/env python3
"""[2026-10-20 kit trial] false-clean guard: put ONE deliberate error into every file that uses the Declaration surface.
  inject-neg.py <variant-root> <base|new> <codemod-report.json> <out-list.json>
new:  right after the per-file header block  `local _zzNeg = <Elem local> { Name = 5 }`  (or `<X>Modifier():Name(5)`)
base: right after `local D = q.Declaration`  `local _zzNeg = D.<C> { Name = 5 }`      (or `D.Modifier.<C>():Name(5)`)
Same scope as the surface it probes (the header / D binding may sit inside a function). Writes the injected
(file, line) list; `neg-tally.py` reads it against a run output. A file whose line stays clean is a false clean.
"""
import json, re, sys
root, variant, repf, outf = sys.argv[1:]
reps = json.load(open(repf))
done = []
for r in reps:
    if r.get("setup") or not (r.get("elems") or r.get("mods")):
        continue
    p = f"{root}/{r['file']}"
    src = open(p, encoding="utf-8").read()
    lines = src.split("\n")
    if variant == "new":
        idx = None
        for i, l in enumerate(lines):
            if re.match(r"\s*local \w+ = \w+\.(Elem|Modifier) \"\w+\"\s*$", l):
                idx = i
        if idx is None:
            print("no header:", r["file"]); continue
        indent = re.match(r"\s*", lines[idx]).group(0)
        m = re.match(r"\s*local (\w+) = (\w+)\.(Elem|Modifier) \"(\w+)\"", lines[idx])
        # prefer an Elem local
        e = None
        for l in lines[: idx + 1]:
            mm = re.match(r"\s*local (\w+) = \w+\.Elem \"\w+\"\s*$", l)
            if mm:
                e = mm.group(1)
        neg = f"{indent}local _zzNeg = {e} {{ Name = 5 }} -- ZZNEG" if e else f"{indent}local _zzNeg = {m.group(1)}():Name(5) -- ZZNEG"
    else:
        idx = None
        for i, l in enumerate(lines):
            if re.match(r"\s*local D = \w+\.Declaration\s*$", l):
                idx = i
                break
        if idx is None:
            # direct q.Declaration.X use: after the module-level local of the quad name
            qn = None
            for i, l in enumerate(lines):
                mm = re.search(r"(\w+)\.Declaration\.", l)
                if mm and not l.strip().startswith("--"):
                    qn = mm.group(1); break
            for i, l in enumerate(lines):
                if qn and re.match(rf"local {qn}\s*=", l):
                    idx = i; break
            if idx is None:
                print("no D:", r["file"]); continue
            pre = f"{qn}.Declaration"
        else:
            pre = "D"
        indent = re.match(r"\s*", lines[idx]).group(0)
        if r.get("elems"):
            neg = f"{indent}local _zzNeg = {pre}.{r['elems'][0]} {{ Name = 5 }} -- ZZNEG"
        else:
            neg = f"{indent}local _zzNeg = {pre}.Modifier.{r['mods'][0]}():Name(5) -- ZZNEG"
    lines.insert(idx + 1, neg)
    open(p, "w", encoding="utf-8").write("\n".join(lines))
    done.append([r["file"], idx + 2])
json.dump(done, open(outf, "w"))
print(f"{variant}: injected {len(done)}")
