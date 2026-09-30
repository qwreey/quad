import os, glob
S = os.path.dirname(os.path.abspath(__file__))


def lines(d):
    out = []
    for f in sorted(glob.glob(d + "/*.txt"), key=lambda p: int(os.path.basename(p)[:-4])):
        out += open(f).readlines()
    return out


for mode in ["plain", "rowgrow"]:
    for a, b in [("base", "q74"), ("base", "q76"), ("base", "A"), ("q76", "A"), ("A", "Ap")]:
        da, db = f"{S}/fzout/list.{mode}.{a}", f"{S}/fzout/list.{mode}.{b}"
        if not (os.path.isdir(da) and os.path.isdir(db)):
            continue
        la, lb = lines(da), lines(db)
        n = max(len(la), len(lb))
        d = sum(1 for i in range(n) if (la[i] if i < len(la) else None) != (lb[i] if i < len(lb) else None))
        print(f"list.{mode} {a} vs {b}: difflines={d} (of {n})")
