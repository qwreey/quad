--[[
	State 계약 — `.claude/base/source-state-plan.md` "전파 루프 — 확정 의사코드" / "`:With`도 새 State
	노드로 확정" / "self 인자도 lazy 핸들로 통일" / "`:Compute(fn, ...)`" / "trailing deps를 `fn`에 lazy
	positional 인자로도 노출" / "`:Compute(fn)`의 선택적 두 번째 인자 — `previous`" /
	"`state:Apply(factory)`" / "`_hold`로 살아남는다", `.claude/base/state-epoch-plan.md` §4.
	Observer/Effect(단위 3)는 여기 없고, 구독자는 `_receive`를 가진 가짜 EmitReceive로 관측한다.
]]

local Quad = require("../src")
local Brand = require("../src/Brand")
local QuadTypes = require("../luau_packages/quad_types")

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
	assert(Brand.StateBrand:Is(d) and Quad.isState(d) and not Quad.isSource(d) and not Quad.isEpoch(d), "a derived node is a State, not a Source/Epoch")
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
	local d: State<number> = s:Compute(function(x: any): number
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
print("=== 6. 캐시 카운터 쌍 (H-85) + Get 한 번 통과 (2026-10-01 — H-198 재시작 루프 제거) ===")
do
	-- 정의된 경로: Get 한 번 = 재계산 최대 한 번
	local s = Source(1)
	local runs = 0
	local d: any = s:Compute(function(x)
		runs += 1
		return x:Get()
	end)
	assert(d:Get() == 1 and runs == 1, "one Get, one recompute")
	s:Set(2)
	assert(d:Get() == 2 and runs == 2, "an upstream Set: the next Get recomputes once")
	assert(d:Get() == 2 and runs == 2, "then stable")
	-- 관측 — 계약 아님: fn 도중의 Set은 UB("Compute 순수성"). 지금은 그 Get이 fn이 계산한 값(한 파동 뒤처짐)을
	-- 돌려주고, 카운터 쌍(H-85)이 그 무효화를 기억해 다음 Get이 따라잡는다. 옛 루프(H-198)는 같은 Get 안에서
	-- 재시작했다 — 사용자 결정 2026-10-01 "compute 재시작 루프는 확인, 걷어내고".
	local s2 = Source(1)
	local runs2 = 0
	local d2: any = s2:Compute(function(x)
		runs2 += 1
		local v = x:Get()
		if v == 1 then
			s2:Set(2) -- upstream write DURING recompute (UB)
		end
		return v
	end)
	assert(d2:Get() == 1 and runs2 == 1, "observation: the Get returned what fn computed, no restart")
	assert(d2:Get() == 2 and runs2 == 2, "observation: the next Get caught up (the counter pair kept the invalidation)")
	assert(d2:Get() == 2 and runs2 == 2, "then stable")
	-- 관측 — 계약 아님(round14 Q160, 2026-10-06): 던진 fn의 새 세대 재실행은 구현의 부수효과다.
	-- fn이 던지면 cacheCurrCount가 안 갱신된다 — [round10 Q50 (a), 2026-09-17] 다만 같은 세대의
	-- 다음 Get은 재진입 에러(스탬프가 남아 있다)이고, 상류가 바뀐 새 세대에서 다시 시도한다
	-- (옛 계약 "다음 Get이 다시 시도한다"에서 좁힘 — 세부는 spec 14)
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
	local okSame, errSame = pcall(function()
		e:Get()
	end)
	assert(not okSame and string.find(tostring(errSame), "an earlier read that threw", 1, true) ~= nil, "same generation: the stamp stays")
	s:Set(3)
	assert(e:Get() == 3, "a thrown fn never marked the cache valid — recomputed on the next generation")
	print("PASS")
end

print()
print("=== 7. :Depend — pass-through 새 노드, 구독만 넓힘; :Compute(fn, ...deps) — 노드 1개, positional lazy deps ===")
do
	local a, b = Source(1), Source(10)
	local w: State<number> = a:Depend(b)
	assert(w:Get() == 1, "Depend's value is self's")
	assert(Brand.StateBrand:Is(w) and w ~= a, "a new node")
	local pw = probe(w)
	b:Set(20)
	assert(pw.count == 1 and pw.last == b, "Depend subscribes to the extra dep")
	assert(w:Get() == 1, "…but still passes self through")

	local runs = 0
	local c: State<number> = a:Compute(function(x, _prev, dep: StateData<number>): number
		runs += 1
		return x:Get() + dep:Get()
	end, b)
	assert(c:Get() == 21 and runs == 1, "trailing dep arrives as a lazy positional after previous")
	assert(#(c :: any)._hold == 2, "one node with two edges — no combining Depend node")
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
		local mid: State<number> = root:Depend(Source(0))
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
	Brand.ModifierBrand:Register(mod)
	local s = Source(1)
	local d: State<any> = s:Compute(function()
		return mod
	end)
	local ok, err = pcall(function()
		d:Get()
	end)
	assert(not ok and string.find(tostring(err), "Modifier", 1, true) ~= nil, "rejected: " .. tostring(err))
	-- [H-205, 사용자 확정 2026-08-31] 직접 Get이면 사용자 호출부를 가리킨다. [2026-09-07 Q7 셋째 (a)]
	-- 방향은 outermost — 디스패치가 lazy recompute를 처음 강제하는 경로(`H-416`)에선 nearest가
	-- StateHandler의 내부 프레임에 걸리므로; 그 경로의 검사는 `spec.dispatch` 18절
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
		s:Depend(nil :: any)
	end)
	assert(not ok3, "Depend rejects nil deps through the same collector")
	-- H-202: non-function fn errors at Compute, not at the first Get deep in _recompute.
	local ok4, err4 = pcall(function()
		(s :: any):Compute(42)
	end)
	assert(not ok4 and string.find(tostring(err4), "Compute fn must be a function", 1, true) ~= nil, "non-function fn: " .. tostring(err4))
	assert(string.find(tostring(err4), "spec.state.luau", 1, true) ~= nil, "points at the caller")
	print("PASS")
end

print()
print("=== 14. round10 Q50 (a) (2026-09-17) — Compute 재진입 가드: 순환은 사용자 줄 blame으로 즉시 error; fn이 던지면 같은 세대의 재읽기도 error, 상류가 바뀌면 다시 돈다 ===")
do
	-- (1) direct cycle: fn reads the result node through an upvalue
	local src = Source(1)
	local cyc: any
	cyc = src:Compute(function(self: any)
		return self:Get() + cyc:Get()
	end)
	local ok, err = pcall(function() return cyc:Get() end)
	assert(not ok and string.find(tostring(err), "State: Compute fn is already running for this value", 1, true) ~= nil, "cycle detected: " .. tostring(err))
	assert(string.find(tostring(err), "spec.state.luau", 1, true) ~= nil and string.find(tostring(err), "EpochMap", 1, true) == nil, "blames the user's Get line, not EpochMap: " .. tostring(err))
	-- (2) indirect cycle through a downstream State
	local a: any
	local b: any
	a = src:Compute(function(self: any) return self:Get() + b:Get() end)
	b = a:Compute(function(self: any) return self:Get() * 2 end)
	local ok2, err2 = pcall(function() return b:Get() end)
	assert(not ok2 and string.find(tostring(err2), "already running", 1, true) ~= nil, "indirect cycle detected: " .. tostring(err2))
	-- (3) the cyclic node keeps raising while its generation stands (the stamp was never cleared)
	local ok3 = pcall(function() return cyc:Get() end)
	assert(not ok3, "still raises on the next read (fn never returned — stamp stays)")
	-- (4) a normal Compute is unaffected: same-generation re-reads and Set-driven recompute
	local n = src:Compute(function(self: any) return self:Get() * 10 end)
	assert(n:Get() == 10, "plain Compute reads")
	assert(n:Get() == 10, "same-generation re-read is cached, not re-entrant")
	src:Set(2)
	assert(n:Get() == 20, "recompute after Set")
	-- (5) observation, not a contract (round14 Q160, 2026-10-06 — the new-generation re-run is a side
	-- effect of the implementation): a throwing fn: the first read raises the fn's own error; a re-read of the same generation
	-- says the fn never returned; an upstream change (new generation) runs fn again — so a
	-- transient validation raise (Operator's nil/wrong-type value) does not kill the node
	local bad = false
	local boom = src:Compute(function(self: any)
		if bad then
			error("boom")
		end
		return self:Get()
	end)
	assert(boom:Get() == 2, "sane before")
	bad = true
	src:Set(3)
	local ok4, err4 = pcall(function() return boom:Get() end)
	assert(not ok4 and string.find(tostring(err4), "boom", 1, true) ~= nil, "fn's own error first")
	local ok5, err5 = pcall(function() return boom:Get() end)
	assert(not ok5 and string.find(tostring(err5), "an earlier read that threw", 1, true) ~= nil, "same generation re-read: " .. tostring(err5))
	bad = false
	src:Set(4)
	assert(boom:Get() == 4, "runs again after an upstream change")
	print("PASS")
end

print()
print("=== 15. round11 H-540 (2026-09-17) — fn이 던진 뒤 닫힌 게이트 너머의 상류 변경(드리프트)도 새 세대: 고친 값으로 다시 돈다 (관측 — 계약 아님, round14 Q160) ===")
do
	local s = Source(1)
	local open = true
	local g = s:Gate(function(emit)
		return function()
			if open then
				emit()
			end
		end
	end)
	local throwOnce = true
	local c = g:Compute(function(self)
		local v = self:Get()
		if throwOnce then
			throwOnce = false
			error("transient", 0)
		end
		return v * 10
	end)
	local ok1, err1 = pcall(function()
		return c:Get()
	end)
	assert(not ok1 and string.find(tostring(err1), "transient", 1, true), "first read throws the fn's own error: " .. tostring(err1))
	open = false -- the gate withholds: no _receive, no new generation for c
	s:Set(2)
	assert(c:Get() == 20, "the withheld upstream change is drift — fn runs again with the corrected value")
	assert(c:Get() == 20, "and the cache is valid afterwards")
	-- a real cycle is still caught (drift check must not open the door)
	local cyc: any
	cyc = Source(1):Compute(function(): number
		return (cyc :: any):Get() :: number
	end)
	local ok2, err2 = pcall(function()
		return cyc:Get()
	end)
	assert(not ok2 and string.find(tostring(err2), "already running", 1, true), "cycle still raises: " .. tostring(err2))
	print("PASS")
end

print()
-- [2026-10-01] 16절(round13 Q93·Q98 yield 가드 회귀 검사)은 가드와 함께 지웠다 — 사용자 결정 "yield 쪽 가드는
-- 드러낸다 동의해". 계산 함수 안의 yield는 UB이고, debug 감지기 (a)가 알린다(17절).
print()
print()
print("=== 17. round13 2026-10-01 — Compute debug 감지기 두 신호(q.debug일 때만 print, 던지지 않음): (b) 계산 함수 도중의 Source:Set/Emit, (a) 옛 실행이 안 돌아왔는데 새 실행 시작; 정상 경로는 0줄 ===")
do
	-- Observer/Effect need a lifetime backend — this section uses the mock provider's instance
	local mock: any = require("./mock")
	local q: any = mock.newQuad()
	local Src = q.Source
	local host = mock.Instance.new("Frame") -- Observer/Effect fire only while bound (canExecute)
	-- the two prints live in State.luau (a) and Source.luau (b) — capture both envs
	local probeSrc = Src(0)
	local probeState = probeSrc:Compute(function(x)
		return x:Get()
	end)
	local envs = { getfenv((probeSrc :: any).Set) :: any, getfenv((probeState :: any).Get) :: any }
	local lines: { string } = {}
	local olds = {}
	for i, env in envs do
		olds[i] = rawget(env, "print")
		env.print = function(...: any)
			table.insert(lines, table.concat({ ... }, " "))
		end
	end
	local function countOf(needle: string): number
		local n = 0
		for _, l in lines do
			if string.find(l, needle, 1, true) ~= nil then
				n += 1
			end
		end
		return n
	end
	local SET = "Source: Set/Emit inside a Compute fn - a Compute only reads and combines (undefined)"
	local RUN = "State: Compute fn entered while an earlier run of this node has not returned - the fn yielded or re-entered (undefined)"

	-- (b1) debug off: a Set inside the fn prints nothing (behavior as before)
	q.debug = false
	local up = Src(1)
	local side = Src(0)
	local bad = up:Compute(function(x)
		side:Set(x:Get())
		return x:Get()
	end)
	assert(bad:Get() == 1 and #lines == 0, "off: silent")
	-- (b2) debug on: one line; the same Source again on later runs: suppressed; another Source: its own line
	q.debug = true
	up:Set(2)
	assert(bad:Get() == 2 and countOf(SET) == 1, "on: one line for the Set inside the fn")
	up:Set(3)
	assert(bad:Get() == 3 and countOf(SET) == 1, "same Source again: suppressed")
	local side2 = Src(0)
	local bad2 = up:Compute(function(x)
		side2:Emit()
		return x:Get()
	end)
	assert(bad2:Get() == 3 and countOf(SET) == 2, "Emit counts too, a different Source gets its own line")
	-- (b3) through a nested pull: the outer fn reads an inner Compute whose fn writes — still inside a fn
	local side3 = Src(0)
	local inner = up:Compute(function(x)
		side3:Set(1)
		return x:Get()
	end)
	local outer = inner:Compute(function(x: any): number
		return x:Get() + 1
	end)
	assert(outer:Get() == 4 and countOf(SET) == 3, "a write anywhere under a running fn")

	-- normal paths with debug on: 0 lines
	local before = #lines
	local a = Src(1)
	local mirror = Src(0)
	local doubled = a:Compute(function(x: any): number
		return x:Get() * 2
	end)
	local sum = doubled:Compute(function(x: any): number
		return x:Get() + 1
	end)
	-- an Observer that writes another Source (its job), woken by a Set outside any fn
	local o = sum:Observer(function(x)
		mirror:Set(x:Get())
	end)
	q.Backend.bindLifetime(host, o)
	a:Set(5)
	assert(mirror:Get() == 11, "Observer wrote")
	-- an Effect that writes its own dependency until it settles (the deferred re-run is the defined untangler)
	local count = Src(0)
	local e = q.Effect(function()
		if count:Get() < 3 then
			count:Set(count:Get() + 1)
		end
		return nil
	end, count)
	q.Backend.bindLifetime(host, e)
	assert(count:Get() == 3, "Effect settled: " .. tostring(count:Get()))
	-- a Compute that THROWS: no counter is left raised, a later Set outside any fn stays silent
	local flaky = a:Compute(function(x)
		if x:Get() == 5 then
			error("boom")
		end
		return x:Get()
	end)
	assert(not pcall(function()
		return flaky:Get()
	end), "threw")
	a:Set(6) -- recovery path: a new generation (observation, not a contract — round14 Q160)
	assert(flaky:Get() == 6, "recovered")
	mirror:Set(0)
	assert(#lines == before, `normal paths: no line (got [{table.concat(lines, " | ", before + 1)}])`)
	host:Destroy()

	-- (a) an earlier run parked in a coroutine (a yield inside the fn), upstream moves, a new run starts: one line
	local ysrc = Src(0)
	local park = true
	local yc = ysrc:Compute(function(x)
		local v = x:Get()
		if park and coroutine.isyieldable() then
			coroutine.yield()
		end
		return v
	end)
	local A = coroutine.create(function()
		return yc:Get()
	end)
	coroutine.resume(A)
	ysrc:Set(1)
	park = false
	assert(yc:Get() == 1 and countOf(RUN) == 1, "(a) on: one line when the new run starts over the parked one")
	coroutine.resume(A) -- let it return (Quad0184 or a value — UB; not asserted here)
	-- a thrown earlier run is not an overlap (its new-generation re-run is an observation, not a contract — round14 Q160): silent
	local tsrc = Src(0)
	local tc = tsrc:Compute(function(x)
		if x:Get() == 0 then
			error("first gen throws")
		end
		return x:Get()
	end)
	assert(not pcall(function()
		return tc:Get()
	end), "threw")
	tsrc:Set(1)
	assert(tc:Get() == 1 and countOf(RUN) == 1, "(a) after a throw: silent")
	-- (a) with debug off: silent
	q.debug = false
	local ysrc2 = Src(0)
	park = true
	local yc2 = ysrc2:Compute(function(x)
		local v = x:Get()
		if park and coroutine.isyieldable() then
			coroutine.yield()
		end
		return v
	end)
	local B = coroutine.create(function()
		return yc2:Get()
	end)
	coroutine.resume(B)
	ysrc2:Set(1)
	park = false
	assert(yc2:Get() == 1 and countOf(RUN) == 1, "(a) off: silent")
	coroutine.resume(B)

	for i, env in envs do
		env.print = olds[i]
	end
	q.debug = false
	print("PASS")
end

print("=== ALL PASS ===")
