#!/usr/bin/env bash
# E70 재실행: relink → 추출 → 생성 → mock → strict → 프로브 → 표 (레포 루트에서 ./.claude/audit/round13-e70-howto-examples/run.sh)
set -u
cd "$(dirname "$0")"
( cd ../../.. && ./scripts/relink.sh >/dev/null )
rm -f mock/*.luau; find strict -name '*.luau' ! -name Quad.luau -delete
python3 extract.py && python3 gen.py
./run-mock.sh
./run-strict.sh $(ls strict/*.luau | grep -v '/Quad.luau') > out/strict.txt
for p in howto06-noprovider-set howto10-ref-wait howto10-slot-fixed; do mise exec -- luau probes/$p.luau 2>&1 | grep -v "^\.\./\|^\[C\]\|^stacktrace" > out/probe-$p.txt; done
./run-strict.sh probes/strict-variants.luau > out/probe-strict-variants.txt
./run-strict.sh probes/strict-useprovider.luau > out/probe-strict-useprovider.txt
python3 report.py
