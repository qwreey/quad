"""Compare new probe outputs (probes/<p>.out.txt, sections '######## <v>') with the 2026-09-27 outputs.
usage: cmpold.py <newfile> <variant>=<oldfile>[#<oldsection>] ..."""
import sys, re, difflib


def sections(path):
    out, cur = {}, None
    for l in open(path):
        m = re.match(r"^######## (\S+)", l)
        if m:
            cur = m.group(1)
            out[cur] = []
            continue
        if l.startswith("[exit "):
            continue
        out.setdefault(cur, []).append(l)
    return out


def _main():
  pass
new = sections(sys.argv[1]) if __name__ == "__main__" else {}
for spec in (sys.argv[2:] if __name__ == "__main__" else []):
    v, old = spec.split("=", 1)
    if "#" in old:
        path, sec = old.split("#", 1)
        o = sections(path).get(sec)
    else:
        o = open(old).readlines()
    n = new.get(v)
    if o is None or n is None:
        print(f"[{v}] missing section (old {o is not None}, new {n is not None})")
        continue
    d = [l for l in difflib.unified_diff(o, n, "old", "new", n=0) if not l.startswith(("---", "+++"))]
    print(f"[{v}] {'IDENTICAL' if not d else str(sum(1 for l in d if l[:1] in '+-')) + ' changed lines'} ({len(n)} lines)")
    for l in d[:60]:
        print("   " + l.rstrip("\n")[:260])
