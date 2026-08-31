--[[
	Gate 계약 — `.claude/base/gate-plan.md` "제안된 모양"(setup 2단) / 2번(`emit(commit) -> boolean`) /
	3번(값은 안 가린다) / 4번(흡수 집합 스냅샷·unfold·`Peek`·flush 순서) / 8번(빈 배치 no-op) /
	"`GateNode` 조립" / "계약 — 게이트는 emit 경로만 미룬다", `.claude/base/state-epoch-plan.md` §4 게이트 예외.
]]

local Quad = require("../src")
local Brand = require("../src/Brand")
local QuadTypes = require("../roblox_packages/quad_types")

type State<T> = QuadTypes.State<T>
type Probe = { count: number, last: any, _receive: (self: Probe, from: any) -> () }

local Source = Quad.Source

local function probe(target: any): Probe
	local p = { count = 0, last = nil :: any } :: Probe
	function p._receive(self: Probe, from: any)
		self.count += 1
		self.last = from
	end
	target._subs[p] = true
	return p
end

-- 켜고 끌 수 있는 최소 정책: 열려 있으면 바로 flush, 닫혀 있으면 쌓아둠
local function switchPolicy()
	local open = true
	local emitRef: any
	local function setup(emit: (boolean?) -> boolean): () -> ()
		emitRef = emit
		return function()
			if open then
				emit()
			end
		end
	end
	local ctl = {
		setup = setup,
		close = function()
			open = false
		end,
		open = function()
			open = true
		end,
		flush = function(commit: boolean?): boolean
			return emitRef(commit)
		end,
	}
	return ctl
end

print("=== 1. 조립 — setup은 생성 시 1회, StateBrand 등록, State 노드로 위임(Get은 pass-through) ===")
do
	local s = Source(1)
	local setups = 0
	local g: State<number> = s:Gate(function(emit)
		setups += 1
		assert(type(emit) == "function", "setup receives the flush handle")
		return function()
			emit()
		end
	end)
	assert(setups == 1, "setup ran once")
	assert(Brand.StateBrand:is(g) and Quad.isState(g) and not Quad.isEpoch(g), "a GateNode is a State (H-152), not an Epoch")
	assert(g:Get() == 1, "value passes through")
	s:Set(2)
	assert(g:Get() == 2, "…and follows the upstream")
	local bad = pcall(function()
		s:Gate(5 :: any)
	end)
	assert(not bad, "setup must be a function")
	local bad2 = pcall(function()
		s:Gate(function()
			return nil :: any
		end)
	end)
	assert(not bad2, "setup must return the onUpstreamEmit function")
	-- [H-200 (b)] the node is DETACHED while setup runs — a THROWING setup must not
	-- leave a zombie subscriber either (H-188 covered only the non-function return).
	local bad3, err3 = pcall(function()
		s:Gate(function()
			error("setup boom")
		end)
	end)
	assert(not bad3 and string.find(tostring(err3), "setup boom", 1, true) ~= nil, "a throwing setup propagates")
	s:Set(3) -- [H-188/H-200] the half-built nodes were never attached — no nil callee, no zombie
	local left = 0
	for sub in pairs((s :: any)._subs) do
		if sub ~= g then
			left += 1
		end
	end
	assert(left == 0, "a failed Gate (throw or bad return) left nothing in the upstream's subscriber set")
	print("PASS")
end

print()
print("=== 2. 열린 게이트 — 통과하되 출처는 게이트의 배치(집합)로 바뀐다 ===")
do
	local s = Source(1)
	local ctl = switchPolicy()
	local g: State<number> = s:Gate(ctl.setup)
	local p = probe(g)
	s:Set(2)
	assert(p.count == 1, "passed through once")
	assert(type(p.last) == "table" and p.last[s] == true and next(p.last, s) == nil, "payload is the detached batch set {[s]=true}, not the source itself")
	print("PASS")
end

print()
print("=== 3. 닫힌 게이트 — 유보: 통지 없음, 값은 Get으로 보인다(3번), 풀면 배치 1회 ===")
do
	local s = Source(1)
	local ctl = switchPolicy()
	local g: State<number> = s:Gate(ctl.setup)
	local p = probe(g)
	ctl.close()
	s:Set(2)
	s:Set(3)
	assert(p.count == 0, "withheld: no downstream notification")
	assert(g:Get() == 3, "…but the value is visible through Get (gate is emit-only)")
	assert(ctl.flush() == true and p.count == 1 and p.last[s] == true, "flush: one batch with the source; returned true")
	assert(ctl.flush() == false and p.count == 1, "empty batch: nothing happens, returns false (8번)")
	print("PASS")
end

print()
print("=== 4. emit(false) — 배치를 버린다: 전파도 Sync도 없음, 다음 진짜 emit이 스스로 낫는다 ===")
do
	local s = Source(1)
	local ctl = switchPolicy()
	local g: State<number> = s:Gate(ctl.setup)
	local p = probe(g)
	ctl.close()
	s:Set(2)
	assert(ctl.flush(false) == true and p.count == 0, "discarded: had something (true) but nothing propagated")
	assert(ctl.flush(false) == false, "…and now it is empty")
	ctl.open()
	s:Set(3)
	assert(p.count == 1, "the next real emit propagates normally")
	print("PASS")
end

print()
print("=== 5. 규칙 3 — 같은 리비전이 두 경로로 와도 정책은 한 번(다이아몬드), 유보 중엔 Peek이라 재도착은 정책 재실행(무해) ===")
do
	local s = Source(1)
	local a: State<number> = s:Compute(function(x): number
		return x:Get()
	end)
	local b: State<number> = s:Compute(function(x): number
		return x:Get()
	end)
	local w: State<number> = a:With(b)
	local policyRuns = 0
	local g: State<number> = w:Gate(function(emit)
		return function()
			policyRuns += 1
			emit()
		end
	end)
	local p = probe(g)
	s:Set(2)
	assert(policyRuns == 1 and p.count == 1, "one Set through a diamond → policy once, downstream once")
	-- 유보 중 같은 리비전 재도착: emitEpochMap을 Peek만 하므로 규칙 2로 정책이 한 번 더 돈다(집합엔 이미 있어 무해)
	local runs2 = 0
	local held: any
	local g2: State<number> = s:Gate(function(emit)
		held = emit
		return function()
			runs2 += 1
		end
	end)
	local p2 = probe(g2)
	s:Set(3)
	;(g2 :: any):_receive(s) -- 같은 리비전이 다른 경로로 또 옴
	assert(runs2 == 2, "while withheld, the same revision re-arriving runs the policy again (Peek, not Update)")
	assert(held() == true and p2.count == 1 and p2.last[s] == true, "…but the batch still carries the source once (set)")
	print("PASS")
end

print()
print("=== 6. flush 순서 — 스왑 → Sync(배치) → 전파: 전파 중 재진입 flush는 새 테이블에 쌓인다 ===")
do
	local s = Source(1)
	local ctl = switchPolicy()
	local g: State<number> = s:Gate(ctl.setup)
	local seen: { any } = {}
	local reenter = true
	local sub = {}
	function sub._receive(_self: any, from: any)
		table.insert(seen, from)
		if reenter then
			reenter = false
			s:Set(99) -- downstream sets upstream while the outer propagation is on the stack
		end
	end
	;(g :: any)._subs[sub] = true
	s:Set(2)
	assert(#seen == 2, "outer batch and the nested batch each arrived once")
	assert(seen[1] ~= seen[2], "the nested wave used a NEW withheld table — the outer batch was not cleared under it")
	assert(next((g :: any)._withheld) == nil, "nothing left withheld")
	print("PASS")
end

print()
print("=== 7. 게이트 안 게이트 — 받은 배치를 풀어 자기 집합에 합친다(참조를 들고 있지 않는다) ===")
do
	local s, t = Source(1), Source(1)
	local outerCtl, innerCtl = switchPolicy(), switchPolicy()
	local outer: State<number> = s:With(t):Gate(outerCtl.setup)
	local inner: State<number> = outer:Gate(innerCtl.setup)
	local p = probe(inner)
	innerCtl.close()
	s:Set(2) -- outer passes {s}; inner withholds
	t:Set(2) -- outer passes {t}; inner withholds
	assert(p.count == 0, "inner withheld both")
	local w = (inner :: any)._withheld
	assert(w[s] == true and w[t] == true, "inner unfolded both batches into its own set")
	innerCtl.flush()
	assert(p.count == 1 and p.last[s] == true and p.last[t] == true, "one merged batch downstream")
	print("PASS")
end

print()
print("=== 8. 유보 중 Get으로 앞당겨 읽은 하류 — 풀릴 때 통지만 오고 재계산 없음(규칙 2) ===")
do
	local s = Source(1)
	local ctl = switchPolicy()
	local g: State<number> = s:Gate(ctl.setup)
	local runs = 0
	local d: State<number> = g:Compute(function(x): number
		runs += 1
		return x:Get() * 10
	end)
	local p = probe(d)
	assert(d:Get() == 10 and runs == 1, "seed")
	ctl.close()
	s:Set(2)
	assert(d:Get() == 20 and runs == 2, "Get walks through the gate (value not gated)")
	ctl.flush()
	assert(p.count == 1, "the released batch notifies downstream (rule 2)")
	assert(d:Get() == 20 and runs == 2, "…without recomputing — value was already current")
	print("PASS")
end

print()
print("=== 9. 흡수 집합은 weak-key, 스왑된 새 테이블도 weak (H-9) ===")
do
	local ctl = switchPolicy()
	local root = Source(1)
	local g: State<number> = root:Gate(ctl.setup)
	ctl.close()
	root:Set(2)
	ctl.flush(false)
	assert(getmetatable((g :: any)._withheld).__mode == "k", "swapped-in table is weak-keyed too")
	print("PASS")
end

print()
print("=== ALL PASS ===")
