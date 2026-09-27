#!/usr/bin/env bash
# E80 3.2.0 대조: `git archive 3.2.0`로 만든 트리(스크래치)에 이 폴더를 복사하고 harness의 q.Backend/q.Bookkeeping만
# 3.2.0 표면(q 최상위·q.Dispatch)으로 이어 붙여 같은 프로브를 돌린다 → out/320/<이름>.txt. 인자: 스크래치 경로.
set -e
S=${1:?scratch dir}
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
rm -rf "$S"; mkdir -p "$S"
(cd "$ROOT" && git archive 3.2.0 quad-base quad-roblox quad-types quad-error type-version-check) | tar -x -C "$S"
rm -rf "$S/quad-roblox/luau_packages"; cp -r "$ROOT/quad-roblox/luau_packages" "$S/quad-roblox/luau_packages"
P="$S/quad-roblox/luau_packages/.pesde"
for pair in quad_base:quad-base quad_types:quad-types quad_error:quad-error type_version_check:type-version-check; do
	n=${pair%%:*}; d=${pair##*:}
	chmod -R u+w "$P/qwreey+$n"; rm -rf "$P/qwreey+$n/3.2.0/$n/src"; cp -r "$S/$d/src" "$P/qwreey+$n/3.2.0/$n/src"
done
mkdir -p "$S/quad-base/luau_packages"
for n in quad_types quad_error type_version_check; do
	echo "return require(\"../../quad-roblox/luau_packages/.pesde/qwreey+$n/3.2.0/$n/src\")" > "$S/quad-base/luau_packages/$n.luau"
done
# strict 대조용: 타입 재수출 링크 파일(HEAD 판)을 3.2.0 quad-types의 export 목록으로 다시 쓴다
(cd "$S" && python3 - <<'PY2'
import re, os
src = open('quad-types/src/init.luau').read()
out = ['local module = require("./.pesde/qwreey+quad_types/3.2.0/quad_types/src")']
for m in re.finditer(r'^export type (\w+)(<[^=]*>)?\s*=', src, re.M):
    gen = m.group(2) or ''
    out.append(f'export type {m.group(1)}{gen} = module.{m.group(1)}{re.sub(r"\s*=\s*[^,>]+", "", gen)}')
out.append('return module')
for p, pre in (('quad-roblox/luau_packages/quad_types.luau', './.pesde'), ('quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/luau_packages/quad_types.luau', '../../../..')):
    os.chmod(p, 0o644); open(p, 'w').write('\n'.join(out).replace('"./.pesde/', f'"{pre}/') + '\n')
PY2
)
mkdir -p "$S/scripts"; cp -r "$ROOT/scripts/roblox-defs" "$S/scripts/"
A="$S/.claude/audit/round13-e80-changelog-fixed"; mkdir -p "$A"; cp -r "$(dirname "$0")"/{harness.luau,engine-globals.luau,lib.luau,probes,strict,run-strict.sh} "$A/"
sed -i 's/^const /local /' "$A/strict/Quad.luau"
python3 - "$A/harness.luau" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read()
ADAPT = '''-- [E80 3.2.0 대조] updateFn(ctx)·OwnsElements는 3.2.0 뒤의 BREAKING — 옛 모양(위치 인자·Owned)으로 이어 붙인다
do
	local proto = getmetatable(q.Slot()).__index
	local origList, origSingle = proto.List, proto.Single
	local function fixOpts(opts)
		if type(opts) == "table" and opts.OwnsElements ~= nil then
			opts = table.clone(opts); opts.Owned = opts.OwnsElements; opts.OwnsElements = nil
		end
		return opts
	end
	proto.List = function(self, data, fn, keyFn, opts)
		local w = if type(fn) == "function" then function(item, index, offset, prev, ud) return fn({ Item = item, Index = index, Offset = offset, Prev = prev, UserData = ud }) end else fn
		return origList(self, data, w, keyFn, fixOpts(opts))
	end
	proto.Single = function(self, data, fn, opts)
		local w = if type(fn) == "function" then function(item, offset, prev, ud) return fn({ Item = item, Offset = offset, Prev = prev, UserData = ud }) end else fn
		return origSingle(self, data, w, fixOpts(opts))
	end
end
'''
s=s.replace('q.Backend.isInst = mock.isMockInstance','if q.Backend == nil then q.Backend = q end -- [E80 3.2.0 대조]\nif q.Bookkeeping == nil then q.Bookkeeping = q.Dispatch end\nq.Backend.isInst = mock.isMockInstance\n' + ADAPT)
open(p,'w').write(s)
PY
OUT="$(cd "$(dirname "$0")" && pwd)/out/320"; mkdir -p "$OUT"
"$A/run-strict.sh" strict/f45.luau > "$OUT/strict-f45.txt" 2>&1 || true
echo "strict f45 (3.2.0): $(grep -c 'f45.luau.*TypeError' "$OUT/strict-f45.txt") TypeError in f45"
cd "$S"
for f in .claude/audit/round13-e80-changelog-fixed/probes/*.luau; do
	k=$(basename "$f" .luau)
	timeout 60 mise exec -- luau "$f" > "$OUT/$k.txt" 2>&1 || true
	printf '%-14s %s\n' "$k" "$(grep '<<END>>' "$OUT/$k.txt" || echo 'NO END')"
done
