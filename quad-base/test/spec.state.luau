--[[
	State 계약 — `.claude/base/source-state-plan.md` "전파 루프 — 확정 의사코드" / "`:With`도 새 State
	노드로 확정" / "self 인자도 lazy 핸들로 통일" / "`:Compute(fn, ...)`" / "trailing deps를 `fn`에 lazy
	positional 인자로도 노출" / "`:Compute(fn)`의 선택적 두 번째 인자 — `previous`" /
	"`state:Apply(factory)`" / "`_hold`로 살아남는다", `.claude/base/state-epoch-plan.md` §4.
	Observer/Effect(단위 3)는 여기 없고, 구독자는 `_receive`를 가진 가짜 EmitReceive로 관측한다.
]]

local Quad = require("../src")
local Brand = require("../src/Brand")
local QuadTypes = require("../roblox_packages/quad_types")

type State<T> = QuadTypes.State<T>
type StateData<T> = QuadTypes.StateData<T>

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local Source = Quad.Source

-- 전파 루프가 부르는 유일한 인터페이스 `sub:_receive(from)`을 흉내내는 관측자.
-- 구독자 집합은 weak-key라 호출부가 강하게 들고 있어야 한다.
type Probe = { count: number, last: any, _receive: (self: Probe, from: any) -> () }
local function probe(target: any): Probe
	local p = { count = 0, last = nil :: any } :: Probe
	function p._receive(self: Probe, from: any)
		self.count += 1
		self.last = from
	end
	target._subs[p] = true
	return p
end

print("=== 1. Compute — lazy: 아무도 Get 안 하면 fn이 안 돈다, Get마다 재계산 안 함 ===")
do
	local s = Source(2)
	local runs = 0
	local d: State<number> = s:Compute(function(x)
		runs += 1
		return x:Get() * 10
	end)
	assert(runs == 0, "creation does not compute")
	assert(d:Get() == 20 and runs == 1, "first Get computes")
	assert(d:Get() == 20 and runs == 1, "second Get is cached")
	s:Set(3)
	assert(runs == 1, "Set alone does not recompute (push-invalidate, pull-recompute)")
	assert(d:Get() == 30 and runs == 2, "next Get recomputes once")
	print("PASS")
end

print()
print("=== 2. 전파 루프 — 출처(Source 자신)를 그대로 넘긴다, 스냅샷 순회 (H-23), 브랜드 ===")
do
	local s = Source(1)
	local d: State<number> = s:Compute(function(x)
		return x:Get()
	end)
	assert(Brand.StateBrand:is(d) and Quad.isState(d) and not Quad.isSource(d) and not Quad.isEpoch(d), "a derived node is a State, not a Source/Epoch")
	local p = probe(d)
	s:Set(2)
	assert(p.count == 1 and p.last == s, "downstream receives the SAME source epoch, not the node")
	-- 파동 중 붙은 구독자는 다음 파동부터
	local late: any = nil
	local joiner = { count = 0 } :: { count: number, _receive: (self: any, from: any) -> () }
	function joiner._receive(self: any, _from: any)
		self.count += 1
		if late == nil then
			late = probe(d)
		end
	end
	(d :: any)._subs[joiner] = true
	s:Set(3)
	assert(joiner.count == 1 and late ~= nil and (late :: any).count == 0, "a subscriber added mid-wave is not visited in that wave")
	s:Set(4)
	assert((late :: any).count == 1, "…but from the next wave on")
	print("PASS")
end

print()
print("=== 3. 다이아몬드 — 같은 리비전이 두 경로로 와도 두 번째는 삼킨다 (규칙 3) ===")
do
	local s = Source(1)
	local a: State<number> = s:Compute(function(x)
		return x:Get() + 1
	end)
	local b: State<number> = s:Compute(function(x)
		return x:Get() + 2
	end)
	local joinRuns = 0
	local j: State<number> = a:Compute(function(x, _, bb: StateData<number>): number
		joinRuns += 1
		return x:Get() + bb:Get()
	end, b)
	local p = probe(j)
	s:Set(5)
	assert(p.count == 1, "the join node forwarded exactly once for one Set (second arrival swallowed)")
	assert(j:Get() == (5 + 1) + (5 + 2) and joinRuns == 1, "value correct, computed once")
	print("PASS")
end

print()
print("=== 4. 순회(Refresh) — 놓친 emit을 Get에서 값만 앞당기고 통지는 안 한다 ===")
do
	local s = Source(1)
	local d: State<number> = s:Compute(function(x): number
		return x:Get() * 2
	end)
	assert(d:Get() == 2, "seed")
	-- 전파 없이 리비전만 움직인 상황을 흉내: 구독 끊고 Set
	local subs = (s :: any)._subs
	subs[d] = nil -- detach the edge so no emit reaches d
	s:Set(10)
	local p = probe(d)
	assert(d:Get() == 20, "Get walks valueEpochMap, sees the moved revision, recomputes")
	assert(p.count == 0, "…and does NOT notify downstream (notification waits for the real emit)")
	subs[d] = true
	s:Set(11)
	assert(p.count == 1 and d:Get() == 22, "the real emit propagates normally afterwards")
	print("PASS")
end

print()
print("=== 5. 규칙 2 — 값은 이미 최신(앞당겨 읽음)인데 emit이 오면 통지만 하고 재계산 없음 ===")
do
	local s = Source(1)
	local runs = 0
	local d: State<number> = s:Compute(function(x)
		runs += 1
		return x:Get()
	end)
	d:Get()
	local subs = (s :: any)._subs
	subs[d] = nil
	s:Set(2)
	assert(d:Get() == 2 and runs == 2, "advanced the value via Refresh")
	local p = probe(d)
	subs[d] = true;
	(d :: any):_receive(s) -- the late emit for the same revision arrives
	assert(p.count == 1, "rule 2: notify downstream")
	assert(d:Get() == 2 and runs == 2, "…without recomputing (value was already current)")
	print("PASS")
end

print()
print("=== 6. 캐시 카운터 쌍 (H-85) + Get 재시작 루프 (H-198) — 재계산 도중 온 무효화는 같은 Get이 수렴할 때까지 다시 계산 ===")
do
	local s = Source(1)
	local runs = 0
	local d: any
	d = s:Compute(function(x)
		runs += 1
		local v = x:Get()
		if v == 1 then
			s:Set(2) -- upstream write DURING recompute
		end
		return v
	end)
	-- [H-198, 사용자 확정 2026-08-31] 옛 계약("다음 Get이 다시 계산")에서 강화 —
	-- Get이 루프라 같은 호출 안에서 재시작해 항상 최신으로 수렴한 값을 돌려준다.
	assert(d:Get() == 2 and runs == 2, "the same Get restarted and returned the converged value")
	assert(d:Get() == 2 and runs == 2, "then stable")
	-- fn이 던지면 cacheCurrCount가 안 갱신돼 다음 Get이 다시 시도한다
	local boom = true
	local e: State<number> = s:Compute(function(x)
		if boom then
			error("boom")
		end
		return x:Get()
	end)
	assert(not pcall(function()
		e:Get()
	end), "fn threw")
	boom = false
	assert(e:Get() == 2, "a thrown fn never marked the cache valid — recomputed on the next Get")
	print("PASS")
end

print()
print("=== 7. :With — pass-through 새 노드, 구독만 넓힘; :Compute(fn, ...deps) — 노드 1개, positional lazy deps ===")
do
	local a, b = Source(1), Source(10)
	local w: State<number> = a:With(b)
	assert(w:Get() == 1, "With's value is self's")
	assert(Brand.StateBrand:is(w) and w ~= a, "a new node")
	local pw = probe(w)
	b:Set(20)
	assert(pw.count == 1 and pw.last == b, "With subscribes to the extra dep")
	assert(w:Get() == 1, "…but still passes self through")

	local runs = 0
	local c: State<number> = a:Compute(function(x, _prev, dep: StateData<number>): number
		runs += 1
		return x:Get() + dep:Get()
	end, b)
	assert(c:Get() == 21 and runs == 1, "trailing dep arrives as a lazy positional after previous")
	assert(#(c :: any)._hold == 2, "one node with two edges — no combining With node")
	b:Set(30)
	assert(c:Get() == 31 and runs == 2, "dep change invalidates")
	print("PASS")
end

print()
print("=== 8. previous — 직전 결과가 두 번째 인자로, 노드마다 독립 ===")
do
	local s = Source(1)
	local seen: { any } = {}
	local d: State<{ n: number }> = s:Compute(function(x, previous: { n: number }?): { n: number }
		table.insert(seen, previous :: any)
		if previous then
			previous.n = x:Get()
			return previous
		end
		return { n = x:Get() }
	end)
	local first = d:Get()
	assert(seen[1] == nil, "first run has no previous")
	s:Set(2)
	assert(d:Get() == first and first.n == 2, "second run received the first result and reused it")
	-- 팬아웃: 형제 노드의 previous는 섞이지 않는다
	local other: State<any> = s:Compute(function(_x, previous)
		return previous
	end)
	assert(other:Get() == nil, "a sibling node starts with its own nil previous")
	print("PASS")
end

print()
print("=== 9. self는 리시버의 lazy 핸들 — 결과 노드가 아니다; 조건부로 self:Get을 건너뛰면 계산 안 됨 ===")
do
	local runs = 0
	local s = Source(1)
	local mid: State<number> = s:Compute(function(x)
		runs += 1
		return x:Get()
	end)
	local skip = Source(true)
	local top: State<number> = mid:Compute(function(x, _, sk: StateData<boolean>): number
		if sk:Get() then
			return -1
		end
		return x:Get()
	end, skip)
	assert(top:Get() == -1 and runs == 0, "self was never read → mid never computed")
	skip:Set(false)
	assert(top:Get() == 1 and runs == 1, "now it is")
	print("PASS")
end

print()
print("=== 10. Apply — 함수 / 메소드형 __apply, 반환은 열려 있음 ===")
do
	local s = Source(2)
	local viaFn = s:Apply(function(st: StateData<number>): number
		return st:Get() * 3
	end)
	assert(viaFn == 6, "function factory")
	local factory = { calls = 0 } :: { calls: number, __apply: (self: any, st: any) -> any }
	function factory.__apply(self: any, st: any)
		self.calls += 1
		return st
	end
	local viaObj = s:Apply(factory) -- 객체 오버로드: 추가 필드(`calls`)가 있어도 통과해야 한다
	assert(viaObj == s and factory.calls == 1, "__apply is called as a METHOD on the factory object (H-158)")
	for _, bad in { {} :: any, 5 :: any, nil :: any } do
		local ok, err = pcall(function()
			(s :: any):Apply(bad) -- `any` 인자는 오버로드를 못 고르므로 리시버 쪽을 캐스트
		end)
		assert(not ok and string.find(tostring(err), "__apply", 1, true) ~= nil, "non-factory rejected with level 2: " .. tostring(err))
		assert(string.find(tostring(err), "spec.state.luau", 1, true) ~= nil, "points at the caller")
	end
	print("PASS")
end

print()
print("=== 11. _hold — 하류가 상류를 강하게, 상류는 하류를 weak로 ===")
do
	local weakNodes = setmetatable({}, { __mode = "v" }) :: { any }
	local leaf: any
	local function build()
		local root = Source(1)
		local mid: State<number> = root:With(Source(0))
		weakNodes[1] = root
		weakNodes[2] = mid
		leaf = mid:Compute(function(x)
			return x:Get()
		end)
	end
	build()
	collectgarbage()
	collectgarbage()
	assert(weakNodes[1] ~= nil and weakNodes[2] ~= nil, "root and mid survive while the leaf is held (_hold chain)")
	assert(leaf:Get() == 1, "and the chain still works")
	-- 반대 방향: 하류를 놓으면 상류 혼자 살아도 하류는 수거된다
	local root2 = Source(1)
	local weakLeaf = setmetatable({}, { __mode = "v" }) :: { any }
	local function attach()
		weakLeaf[1] = root2:Compute(function(x)
			return x:Get()
		end)
	end
	attach()
	collectgarbage()
	collectgarbage()
	assert(weakLeaf[1] == nil, "upstream holds downstream only weakly")
	assert(next((root2 :: any)._subs) == nil, "…and the dead subscriber left the set")
	print("PASS")
end

print()
print("=== 12. 가드 — Compute 결과가 Modifier면 캐싱 전에 error(level 3, H-205); dep이 State가 아니면 error ===")
do
	local mod = {}
	Brand.ModifierBrand:register(mod)
	local s = Source(1)
	local d: State<any> = s:Compute(function()
		return mod
	end)
	local ok, err = pcall(function()
		d:Get()
	end)
	assert(not ok and string.find(tostring(err), "Modifier", 1, true) ~= nil, "rejected: " .. tostring(err))
	-- [H-205, 사용자 확정 2026-08-31] level 3 — 직접 Get이면 사용자 호출부를 가리킨다
	-- (체인 경유면 상류 Get의 내부 프레임 — 어떤 고정 level도 거기선 유저 코드에 못 닿음)
	assert(string.find(tostring(err), "spec.state.luau", 1, true) ~= nil, "direct Get: blames the caller, not quad internals")
	assert((d :: any)._cache == nil, "nothing was cached")
	local ok2, err2 = pcall(function()
		s:Compute(function(x)
			return x:Get()
		end, {} :: any)
	end)
	assert(not ok2 and string.find(tostring(err2), "dep #2", 1, true) ~= nil, "non-State dep: " .. tostring(err2))
	assert(string.find(tostring(err2), "spec.state.luau", 1, true) ~= nil, "points at the caller")
	print("PASS")
end

print()
print("=== 13. 가드 (H-199/H-202) — nil dep은 조용히 사라지지 않고 error, Compute fn은 함수여야 ===")
do
	local s = Source(1)
	-- H-199: a nil mid-list used to shift later deps left (fn's positional args
	-- landed in the wrong slots); a single trailing nil used to vanish entirely.
	local ok, err = pcall(function()
		s:Compute(function(x)
			return x:Get()
		end, nil :: any)
	end)
	assert(not ok and string.find(tostring(err), "dep #2 is nil", 1, true) ~= nil, "trailing nil dep: " .. tostring(err))
	assert(string.find(tostring(err), "spec.state.luau", 1, true) ~= nil, "points at the caller")
	local other = Source(2)
	local ok2, err2 = pcall(function()
		s:Compute(function(x)
			return x:Get()
		end, other, nil :: any, other)
	end)
	assert(not ok2 and string.find(tostring(err2), "dep #3 is nil", 1, true) ~= nil, "mid-list nil dep: " .. tostring(err2))
	local ok3 = pcall(function()
		s:With(nil :: any)
	end)
	assert(not ok3, "With rejects nil deps through the same collector")
	-- H-202: non-function fn errors at Compute, not at the first Get deep in _recompute.
	local ok4, err4 = pcall(function()
		(s :: any):Compute(42)
	end)
	assert(not ok4 and string.find(tostring(err4), "Compute fn must be a function", 1, true) ~= nil, "non-function fn: " .. tostring(err4))
	assert(string.find(tostring(err4), "spec.state.luau", 1, true) ~= nil, "points at the caller")
	print("PASS")
end

print()
print("=== ALL PASS ===")
