--[[
	Blocker 계약 — `.claude/base/blocker-plan.md` "메커니즘 (확정)"(On/Off/OffWithoutEmit/IsOn/Policy/`__apply`,
	onunblock 핸들 보관 `H-63` 셋) / "재진입(네스팅) — 의도적으로 미지원", `.claude/base/gate-plan.md` 5번·8번.
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")

type State<T> = QuadTypes.State<T>
type Probe = { count: number, last: any, _receive: (self: Probe, from: any) -> () }

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local Source, Blocker = Quad.Source, Quad.Blocker

local function probe(target: any): Probe
	local p = { count = 0, last = nil :: any } :: Probe
	function p._receive(self: Probe, from: any)
		self.count += 1
		self.last = from
	end
	target._subs[p] = true
	return p
end

print("=== 1. 생성·상태 — IsOn/On/Off/OffWithoutEmit은 self 반환, 브랜드, 단순 불리언(카운터 아님) ===")
do
	local b = Blocker()
	assert(Quad.isBlocker(b) and not Quad.isState(b), "brand")
	assert(b:IsOn() == false, "starts open")
	assert(b:On() == b and b:IsOn() == true, "On")
	b:On() -- twice: still just true
	assert(b:Off() == b and b:IsOn() == false, "Off — no counting: one Off closes two Ons")
	assert(b:OffWithoutEmit() == b and b:IsOn() == false, "idempotent")
	print("PASS")
end

print()
print("=== 2. state:Apply(blocker) — __apply 메소드형(H-158)으로 GateNode 하나, 열려 있으면 투명 통과 ===")
do
	local s = Source(1)
	local b = Blocker()
	local g: State<number> = s:Apply(b)
	assert(Quad.isState(g) and g ~= s and g:Get() == 1, "a new gated State (GateNode)")
	local p = probe(g)
	s:Set(2)
	assert(p.count == 1 and p.last[s] == true, "open: passes through as a batch")
	assert(g:Get() == 2, "value follows")
	print("PASS")
end

print()
print("=== 3. On → 유보(HasBlockedEmit = withheld 비어있지 않음), Off → 정확히 1회 flush, 이미 비었으면 no-op ===")
do
	local s = Source(1)
	local b = Blocker()
	local g: State<number> = s:Apply(b)
	local p = probe(g)
	b:On()
	s:Set(2)
	s:Set(3)
	assert(p.count == 0 and g:Get() == 3, "blocked: no notification, value still visible")
	b:Off()
	assert(p.count == 1 and p.last[s] == true, "Off flushed exactly once")
	b:On()
	b:Off()
	assert(p.count == 1, "nothing withheld → Off does nothing (idempotent)")
	print("PASS")
end

print()
print("=== 4. OffWithoutEmit — 밀린 전파를 버리며 끈다, 다음 진짜 emit은 정상 ===")
do
	local s = Source(1)
	local b = Blocker()
	local g: State<number> = s:Apply(b)
	local p = probe(g)
	b:On()
	s:Set(2)
	b:OffWithoutEmit()
	assert(p.count == 0 and next((g :: any)._withheld) == nil, "discarded, set emptied")
	s:Set(3)
	assert(p.count == 1, "next real emit propagates")
	print("PASS")
end

print()
print("=== 5. 하나의 Blocker가 여러 gated state를 — Off가 전부 풀고, 순회는 스냅샷(풀리는 중 새 등록 안전) ===")
do
	local s, t = Source(1), Source(1)
	local b = Blocker()
	local gs: State<number> = s:Apply(b)
	local gt: State<number> = t:Apply(b)
	local ps, pt = probe(gs), probe(gt)
	b:On()
	s:Set(2)
	t:Set(2)
	local newGate: any = nil
	local pn: any = nil
	local sub = {}
	function sub._receive(_self: any, _from: any)
		if newGate == nil then
			newGate = s:Apply(b) -- created mid-Off (mid-walk): must not break the walk
			pn = probe(newGate)
		end
	end
	;(gs :: any)._subs[sub] = true
	b:Off()
	assert(ps.count == 1 and pt.count == 1, "both gated states flushed")
	assert(newGate ~= nil and pn.count == 0, "gate created mid-walk was not visited (snapshot) and had nothing withheld")
	print("PASS")
end

print()
print("=== 6. H-63 — 핸들은 weak-key, 강한 주인은 게이트의 onUpstreamEmit 클로저: 게이트가 죽으면 핸들도 사라진다 ===")
do
	local b = Blocker()
	local s = Source(1)
	local function make()
		local g: State<number> = s:Apply(b)
		g:Get()
	end
	make()
	collectgarbage()
	collectgarbage()
	assert(next((b :: any)._handles) == nil, "dead gate → its handle left the weak set (Blocker does not pin gates)")
	local g2: State<number> = s:Apply(b)
	local n = 0
	for _ in pairs((b :: any)._handles) do
		n += 1
	end
	assert(n == 1 and g2:Get() == 1, "a live gate keeps its handle")
	print("PASS")
end

print()
print("=== 7. Policy(emit)를 직접 Gate에 배선 — Apply와 같은 모양, 여러 노드가 정책을 공유 ===")
do
	local s = Source(1)
	local b = Blocker()
	local g: State<number> = s:Gate(function(emit)
		return b:Policy(emit)
	end)
	local p = probe(g)
	b:On()
	s:Set(2)
	assert(p.count == 0, "withheld via the shared blocker")
	b:Off()
	assert(p.count == 1, "released")
	print("PASS")
end

print()
print("=== 8. H-203 — Off 순회 중 재차단: 남은 핸들은 유보 유지, IsOn true인 채 통지가 새지 않는다 ===")
do
	local b = Blocker()
	local s, t = Source(0), Source(0)
	local gs: State<number> = s:Apply(b)
	local gt: State<number> = t:Apply(b)
	-- 어느 게이트가 먼저 flush되든(스냅샷 순서는 비결정), 먼저 깨어난 쪽이 재차단한다
	local delivered = 0
	local function reblock()
		delivered += 1
		b:On()
	end
	local ps, pt = probe(gs), probe(gt)
	local origPs, origPt = ps._receive, pt._receive
	ps._receive = function(self: any, from: any)
		origPs(self, from)
		reblock()
	end
	pt._receive = function(self: any, from: any)
		origPt(self, from)
		reblock()
	end
	b:On()
	s:Set(1)
	t:Set(1)
	assert(delivered == 0, "both withheld")
	b:Off()
	assert(delivered == 1, "exactly one gate flushed — the re-block stopped the walk")
	assert(b:IsOn() == true, "the mid-walk On() sticks")
	b:Off()
	assert(delivered == 2, "the survivor's withheld batch flushes on the next Off")
	print("PASS")
end

print()
print("=== ALL PASS ===")
