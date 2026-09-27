#!/usr/bin/env bash
# E80: 모든 프로브를 HEAD에서 돌려 out/<이름>.txt, 그리고 3.2.0 대조(t320 트리가 있으면) out/320/<이름>.txt
cd "$(dirname "$0")"
ROOT=$(cd ../../.. && pwd)
mkdir -p out
for f in probes/*.luau; do
	k=$(basename "$f" .luau)
	(cd "$ROOT" && timeout 60 mise exec -- luau ".claude/audit/round13-e80-changelog-fixed/$f") > "out/$k.txt" 2>&1
	printf '%-14s %s\n' "$k" "$(grep '<<END>>' "out/$k.txt" || echo 'NO END (crashed)')"
done
./run-strict.sh strict/f45.luau > out/strict-f45.txt 2>&1
echo "strict f45: $(grep -c TypeError out/strict-f45.txt) TypeError (기대 4)"
python3 check-ids.py > out/ids.txt; tail -3 out/ids.txt
