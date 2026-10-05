#!/usr/bin/env bash
# Kit test runner: (1) strict type check of src + specs (luau-lsp new solver, the quad test.sh flag set),
# (2) every pure spec (`spec.pure.*.luau`) under the `luau` CLI, (3) every component spec under Lune.
# Optional args: spec paths relative to the repo root (e.g. quad-roblox-devui/test/spec.window.luau) to run only those
# under Lune (the strict pass still covers the whole kit).
# Exit code is the verdict. Run from anywhere; wrap heavy runs per the repo memory rules.
set -uo pipefail
cd "$(dirname "$0")/.."
KIT="$(basename "$(pwd)")"
cd ..
fail=0
echo "=== luau-lsp strict ($KIT)"
out=$(mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" --ignore "$KIT/test/support/**" \
	"$KIT/src" "$KIT/test" 2>&1)
diag=$(printf '%s\n' "$out" | grep -v "^\[INFO\]" | grep -E "\((Type|Syntax)Error|Error\)|: (TypeError|SyntaxError)" || true)
printf '%s\n' "$out" | grep -v "^\[INFO\]" || true
if [ -n "$diag" ]; then echo "FAIL: strict diagnostics"; fail=1; fi
shopt -s nullglob
for f in "$KIT"/test/spec.pure.*.luau; do
	echo "=== luau $f"
	luau "$f" || fail=1
done
# Lune 0.10.5 cannot parse `const` / `f<<T>>(x)` — run the specs on a line-preserving rewritten mirror
# (test/support/mirror.py); error line numbers match the originals.
MIRROR="${TMPDIR:-/tmp}/quad-kit-mirror-$KIT-$$"
python3 "$KIT/test/support/mirror.py" "$KIT" "$MIRROR" >/dev/null || fail=1
specs=("$KIT"/test/spec.*.luau)
if [ "$#" -gt 0 ]; then specs=("$@"); fi
for f in "${specs[@]}"; do
	case "$f" in */spec.pure.*) continue ;; esac
	echo "=== lune $f"
	(cd "$MIRROR" && mise exec 'github:lune-org/lune@0.10.5' -- lune run "$f" 2>&1 | grep -v "^mise WARN" ; exit "${PIPESTATUS[0]}") || fail=1
done
rm -rf "$MIRROR"
exit "$fail"
