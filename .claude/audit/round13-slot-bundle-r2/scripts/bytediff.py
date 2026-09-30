import os, glob, sys
S = os.path.dirname(os.path.abspath(__file__))


def lines(d, noperf=True):
    out = []
    for f in sorted(glob.glob(d + "/*.txt"), key=lambda p: int(os.path.basename(p)[:-4])):
        for l in open(f):
            if noperf and l.startswith("P"):
                continue
            out.append(l)
    return out


def cmp(a, b):
    la, lb = lines(a), lines(b)
    n = max(len(la), len(lb))
    d = sum(1 for i in range(n) if (la[i] if i < len(la) else None) != (lb[i] if i < len(lb) else None))
    return d, n


pairs = sys.argv[1:]
for fz in sorted({os.path.basename(p).rsplit(".", 1)[0] for p in glob.glob(S + "/fzout/*")}):
    for a, b in [("base", "A"), ("A", "Ap")]:
        da, db = f"{S}/fzout/{fz}.{a}", f"{S}/fzout/{fz}.{b}"
        if os.path.isdir(da) and os.path.isdir(db):
            d, n = cmp(da, db)
            print(f"{fz} {a} vs {b} (non-perf lines): difflines={d} (of {n})")
