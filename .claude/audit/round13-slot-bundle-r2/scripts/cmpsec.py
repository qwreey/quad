"""diff two sections of one probe output: cmpsec.py <file> <secA> <secB>"""
import sys, difflib
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from cmpold import sections  # noqa

s = sections(sys.argv[1])
a, b = s.get(sys.argv[2], []), s.get(sys.argv[3], [])
d = [l for l in difflib.unified_diff(a, b, sys.argv[2], sys.argv[3], n=1) if not l.startswith(("---", "+++"))]
print(f"{sys.argv[2]} vs {sys.argv[3]}: {'IDENTICAL' if not d else str(sum(1 for l in d if l[:1] in '+-')) + ' changed lines'}")
for l in d:
    print("   " + l.rstrip("\n")[:240])
