--[[
	M3 종합 — mock 대상 테스트 (`ROADMAP.md` M3 마지막 항목). 디스패치 엔진
	전체(process/drive/부기/내장 핸들러 4종 + spec-로컬 소비자)를 mock
	Instance에 대고 end-to-end로 돌린다. 개별 계약의 정본 spec은 각자
	(spec.dispatch/drive/lengthoffset/nonenil/leaf) — 여기는 그 조합이 실제
	트리 하나에서 같이 굴러가는지만 본다.
]]

local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

local Instance = mock.Instance
local newQuad = mock.newQuad
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

-- spec-로컬 소비자 둘 — 해시 키는 mock property에 그대로 쓰는 핸들러,
-- 배열 문자열은 mock 공유 leaf(`H-271` — SpecElement 복사본을 접음).
local function addConsumers(q: any, sources: { any })
	q.Dispatch.addHandler({
		name = "SpecProperty",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "string" and (type(v) == "string" or type(v) == "number" or v == nil)
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_LOW,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			inst[k] = v
			return function(nextValue: any?)
				if nextValue == nil then
					inst[k] = nil
				end
			end
		end,
	} :: QuadTypes.Handler)
	mock.addSpecLeaf(q, sources)
end

print("=== 1. 혼합 drive — 해시 프로퍼티 + 배열(문자열/Observer/None/Effect)이 한 트리에서 ===")
do
	local q = newQuad()
	local sources: { any } = {}
	addConsumers(q, sources)
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local obsRuns, effRuns = 0, 0
	local o = s:Observer(function()
		obsRuns += 1
	end)
	local e = q.Effect(function()
		effRuns += 1
	end, s)

	q.Dispatch.drive(inst, { "a", o, q.None, e, "b", Text = "hello", Value = 42 })

	assert(inst.Text == "hello" and inst.Value == 42, "hash props landed on the mock")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.N == 5, "all five array positions registered")
	-- lengths [1,0,0,0,1] → offsets(0-based): 0,1,1,1,1
	assert(q.Dispatch.getOffsetAt(inst, 1) == 0 and sources[1]:Get() == 0, "position 1")
	assert(q.Dispatch.getOffsetAt(inst, 5) == 1 and sources[5]:Get() == 1, "only 'a' contributes before 'b'")
	assert(bk.sourceList[2] == q.None and bk.sourceList[3] == q.None and bk.sourceList[4] == q.None, "leaf/None positions: no publish channel")

	s:Set(2)
	assert(obsRuns >= 2 and effRuns >= 2, "both leaves live and firing through the same tree")
	print("PASS")
end

print()
print("=== 2. 자리 타입 교대 — Observer 자리에 문자열: 철거(unbind) + 오프셋 이동 ===")
do
	local q = newQuad()
	local sources: { any } = {}
	addConsumers(q, sources)
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local o = s:Observer(function() end)
	q.Dispatch.drive(inst, { "a", o, "b" })
	assert(sources[3]:Get() == 1, "steady state: observer contributes 0")

	q.Dispatch.process(inst, 2, "now-a-string", 1)
	assert(not q.canExecute(o), "descending diff retracted the old occupant (unbound)")
	assert(sources[3]:Get() == 2, "position 3 offset follows the new contribution")

	-- 반대 방향: 문자열 자리에 Observer — 다시 0 기여로
	local o2 = s:Observer(function() end)
	q.Dispatch.process(inst, 2, o2, 1)
	assert(q.canExecute(o2), "restored a leaf occupant")
	assert(sources[3]:Get() == 1, "offset came back down")
	print("PASS")
end

print()
print("=== 3. Destroy — retract는 계약상 안 불린다(메모리 해제지 teardown 아님), 발화만 멎는다 ===")
do
	local q = newQuad()
	local sources: { any } = {}
	addConsumers(q, sources)
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local runs = 0
	local o = s:Observer(function()
		runs += 1
	end)
	q.Dispatch.drive(inst, { o, Text = "hello" })

	inst:Destroy()
	assert(not q.canExecute(o), "gcconn cut — the observer is no longer executable")
	local before = runs
	s:Set(2)
	assert(runs == before, "no fire after Destroy")
	assert(inst.Text == "hello", "no retract ran — the dead mock keeps its bag (memory release, not teardown)")
	print("PASS")
end

print()
print("=== 4. GC — Destroy 후 참조를 놓으면 leaf 값·체인 그래프가 회수된다(H-229 end-to-end) ===")
do
	local q = newQuad()
	local sources: { any } = {}
	addConsumers(q, sources)
	local s = q.Source(1)
	-- 팩토리 패턴 — 인라인로 만들면 죽은 레지스터가 값을 붙잡아 GC가 안 된다
	-- (spec.lengthoffset 7의 같은 관례)
	local function build(): { [string]: any }
		local inst = Instance.new("Frame")
		local o = s:Observer(function() end)
		q.Dispatch.drive(inst, { "a", o })
		inst:Destroy()
		local weak: { [string]: any } = setmetatable({}, { __mode = "v" }) :: any
		weak.observer = o
		weak.inst = inst
		return weak
	end
	local weak = build()
	collectgarbage()
	collectgarbage()
	assert(weak.observer == nil, "leaf-bound observer collected after Destroy (weak chains + gchold anchor)")
	assert(weak.inst == nil, "the mock proxy itself collected")
	print("PASS")
end

print()
print("=== ALL PASS ===")
