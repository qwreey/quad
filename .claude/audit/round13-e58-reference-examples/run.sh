#!/usr/bin/env bash
# E58 재실행: relink → 추출 → 생성 → mock → strict → 표
set -u
cd "$(dirname "$0")"
( cd ../../.. && ./scripts/relink.sh >/dev/null )
python3 extract.py && python3 gen.py
./run-mock.sh
./run-strict.sh $(ls strict/*.luau | grep -v Quad.luau) > out/strict.txt
./run-strict.sh probes/*.luau > out/probes-strict.txt
for p in probes/extend02-retract-sequence probes/extend02-none probes/extend02-retractfrom probes/sugar05-error-path; do luau "$p.luau" > "out/$(basename $p).txt" 2>&1; done
python3 report.py
