import sys, os, re, collections, glob
S = os.path.dirname(os.path.abspath(__file__))
for fz, tag in [("fuzz.e19", "plain"), ("fuzz.e19", "ss"), ("fuzz.q111", "plain"), ("fuzz.q111", "ss"), ("fuzz.q111", "q111"), ("fuzz.q111", "q111ss")]:
    for v in ["base", "A", "Ap"]:
        d = f"{S}/fzout/{fz}.{tag}.{v}"
        if not os.path.isdir(d):
            continue
        ok = 0
        c = collections.Counter()
        for f in glob.glob(d + "/*.txt"):
            for l in open(f):
                if not l.startswith("R "):
                    continue
                p = l.split()
                if p[2] == "ok":
                    ok += 1
                    continue
                m = re.search(r"op=(\S+) (ERR-\S+)(?: want (\S+))?(?: got .*?(Quad\d+))?", l)
                if m:
                    key = f"op={m.group(1)} {m.group(2)}" + (f" want {m.group(3)}" if m.group(3) else "") + (f" got {m.group(4)}" if m.group(4) else "")
                else:
                    key = re.sub(r"step=\d+ ", "", " ".join(p[2:]))[:100]
                c[key] += 1
        print(f"{v:5s} {fz}.{tag:7s} ok={ok}" + "".join(f" | {k} x{n}" for k, n in c.most_common()))
