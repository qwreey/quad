#!/usr/bin/env bash
# usage: spike-q126/run.sh <file.luau>  — luau-lsp new solver with test.sh's limit flags; prints label → error lines
set -uo pipefail
cd "$(dirname "$0")/.."
f="$1"
start=$(date +%s.%N)
out=$(mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" "$f" 2>&1 | grep -v '^\[INFO\]')
end=$(date +%s.%N)
printf '%s\n' "$out" > "${f%.luau}.out"
python3 - "$f" "${f%.luau}.out" <<'EOF'
import re, sys
src = open(sys.argv[1]).read().splitlines()
out = open(sys.argv[2]).read()
errs = {}
for m in re.finditer(r"\((\d+),(\d+)\): (\w+): ([^\n]*)", out):
    ln = int(m.group(1)); kind = m.group(3)
    if kind in ("SameLineStatement",): continue
    errs.setdefault(ln, []).append(f"{kind}: {m.group(4)[:110]}")
other = [l for l in out.splitlines() if l.strip() and not re.match(r"^.*\(\d+,\d+\):", l)]
for i, line in enumerate(src, 1):
    lab = re.search(r"-- ([PN]\d+)", line)
    if lab:
        e = errs.pop(i, None)
        print(f"{lab.group(1):4} {'ERR ' if e else 'ok  '} {e[0] if e else ''}")
for ln, e in sorted(errs.items()):
    print(f"unlabelled line {ln}: {e[0]}")
for l in other[:10]:
    print("other:", l[:200])
EOF
python3 -c "print('time: %.2fs' % ($end - $start))"
