#!/usr/bin/env bash
# E27 전체 재실행: relink → mock 러너 넷 → strict/nonstrict 검사
set -u
cd "$(dirname "$0")"
( cd ../../.. && ./scripts/relink.sh >/dev/null )
for f in chain-a-ch01-10.luau run-b-ch11.luau chain-c-ch12-18.luau run-d-ch19-21.luau; do
	echo "=== $f"; luau "$f" | grep -E "^(FAIL|==)"
done
for f in probe-11s6-dispose.luau probe-16-step5.luau probe-18-pergate.luau probe-20-handlers.luau; do echo "=== $f"; luau "$f"; done
echo "=== strict (문서가 nonstrict를 전제하므로 참고용)"; ./strict.sh strict-a-ch01-10.luau strict-separate.luau strict-mod/*.luau | grep -cE "^(strict)"
echo "=== nonstrict (문서 전제)"; ./strict.sh nonstrict-a-ch01-10.luau nonstrict-separate.luau nonstrict-mod/*.luau | grep -E "^nonstrict"
echo "=== probes (strict)"; ./strict.sh probe-06s5-out-strict.luau probe-09-inline-hooks-strict.luau probe-14s3/*.luau | grep -E "^probe" | cut -c1-160
