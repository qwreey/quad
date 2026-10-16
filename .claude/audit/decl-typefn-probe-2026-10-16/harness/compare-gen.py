#!/usr/bin/env python3
"""Q5: compare the type-function surface (Lib.Names<C> for the 31 scope classes) with the
generated Declaration's <Class>Param keys. Writes a temporary probe file next to Lib.luau,
runs harness/run-cli.sh <mode> on it, parses the [N] lines, deletes the probe.
  compare-gen.py vsc|pin|sync
"""
import os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "../src")
ROOT = os.path.abspath(os.path.join(HERE, "../../../.."))
CL = ("BillboardGui Camera CanvasGroup Folder Frame ImageButton ImageLabel ScreenGui ScrollingFrame SurfaceGui "
      "TextBox TextButton TextLabel UIAspectRatioConstraint UICorner UIDragDetector UIFlexItem UIGradient UIGridLayout "
      "UIListLayout UIPadding UIPageLayout UIScale UIShadow UISizeConstraint UIStroke UITableLayout UITextSizeConstraint "
      "VideoFrame ViewportFrame WorldModel").split()
SHORTHAND = {"UICorner", "UIPadding", "UIPaddingOffset", "UIScale"}  # quad sugar keys (gen-d H-336), not engine props
mode = sys.argv[1]
probe = os.path.join(SRC, "_allnames.luau")
with open(probe, "w") as f:
    f.write('--!strict\nlocal L = require("./Lib")\n')
    for i, c in enumerate(CL):
        f.write(f"type N{i} = L.Names<{c}>\n")
    f.write("return {}\n")
try:
    out = subprocess.run([os.path.join(HERE, "run-cli.sh"), mode, "_allnames.luau"], cwd=SRC,
                         capture_output=True, text=True).stdout
finally:
    os.remove(probe)
tf = {}
for l in out.splitlines():
    m = re.search(r"\[N\] (\w+) (props|events)\(\d+\): (.*)", l)
    if m:
        tf.setdefault(m.group(1), set()).update(x.rstrip("+") for x in m.group(3).split())
src = open(os.path.join(ROOT, "quad-roblox/src/Declaration/init.luau")).read()
gen = {}
for m in re.finditer(r"^export type (\w+)Param<E> = \{\n(.*?)^\}", src, re.S | re.M):
    gen[m.group(1)] = {mm.group(1) for l in m.group(2).split("\n") if (mm := re.match(r"\s*(\w+):", l))} - SHORTHAND
diff = 0
for c in sorted(gen):
    g, t = gen[c], tf.get(c, set())
    if g != t:
        diff += 1
        print(f"{c}: gen-only {sorted(g - t)} tf-only {sorted(t - g)}")
print(f"mode={mode}: {len(gen) - diff}/{len(gen)} classes identical key sets "
      f"(gen keys {sum(len(v) for v in gen.values())}, tf keys {sum(len(v) for v in tf.values())})")
