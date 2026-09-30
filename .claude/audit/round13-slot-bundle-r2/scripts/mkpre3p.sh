#!/usr/bin/env bash
# pre-3′ control: quad-base/src at bc8c8329 (parent of 682e2301), hooks applied, probes from fz/base/test
set -e
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
cd "$S"
mkdir -p pre3p_src
tar -xf bc8c.tar -C pre3p_src
cp -r fz/base/.. /dev/null 2>/dev/null || true
mkdir -p fz/pre3p
cp -r base/quad-base/. fz/pre3p/
rm -r fz/pre3p/src
cp -r pre3p_src/quad-base/src fz/pre3p/src
cp fz/base/test/*.luau fz/pre3p/test/
(cd fz/pre3p && patch -p1 --no-backup-if-mismatch < ../../base/.claude/audit/round13-q111-proto/HOOKS.scratch-probe.diff)
for p in probe.bundle.interact probe.bundle.interact2; do
	echo "######## pre3p" > "probes/$p.pre3p.out.txt"
	(cd fz/pre3p && luau "test/$p.luau" < /dev/null >> "../../probes/$p.pre3p.out.txt" 2>&1)
done
