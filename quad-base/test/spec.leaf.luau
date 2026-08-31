--[[
	ObserverEffectLeafHandler + dynamic-path guards — `.claude/base/
	source-state-plan.md` "Observer/Effect Leaf dedup" / "동적 경로 가드",
	`.claude/base/effect-plan.md` "동적 경로 가드" (M3 unit 4).
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

local Instance = mock.Instance
local newQuad = mock.newQuad

print("=== 1. Observer leaf — 배열 자리 바인딩: H-39 부기(None/0) + gchold로 실행 가능해진다 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local runs = 0
	local o = s:Observer(function()
		runs += 1
	end)
	assert(runs == 1, "creation runs fn once (force)")
	s:Set(2)
	assert(runs == 1, "unbound observer holds — canExecute gate")

	q.Dispatch.drive(inst, { o })
	assert(runs == 2, "binding replays the held emit once (_catchUp)")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None, "H-39: leaf registered None/0")
	assert(q.canExecute(o), "bound via gchold")
	s:Set(3)
	assert(runs == 3, "bound observer fires per change")
	print("PASS")
end

print()
print("=== 2. Effect leaf — 바인딩 후 dep 변경마다 재실행 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local runs = 0
	local e = q.Effect(function()
		runs += 1
	end, s)
	assert(runs == 1, "installed once on creation")

	q.Dispatch.drive(inst, { e })
	assert(q.canExecute(e), "bound via gchold")
	s:Set(2)
	assert(runs == 2, "bound effect reruns per dep change")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None, "H-39 for the effect position too")
	print("PASS")
end

print()
print("=== 3. dedup — 같은 값 재발행에 bindLifetime 재호출 없음(있으면 already-bound error가 난다) ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local o = s:Observer(function() end)
	q.Dispatch.drive(inst, { o })
	-- (A) 분기: retractor(nextValue == v)는 unbind를 건너뛰므로, process 쪽
	-- dedup이 없다면 여기서 bindLifetime이 "already bound"로 죽는다 — 통과
	-- 자체가 dedup의 증거.
	q.Dispatch.drive(inst, { o })
	assert(q.canExecute(o), "still bound after spurious re-dispatch")
	print("PASS")
end

print()
print("=== 4. 값 교체 — 옛 값 unbind(발화 중단), Effect는 cleanup 소진(H-57) ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local runsA, runsB = 0, 0
	local oA = s:Observer(function()
		runsA += 1
	end)
	local oB = s:Observer(function()
		runsB += 1
	end)
	q.Dispatch.drive(inst, { oA })
	q.Dispatch.process(inst, 1, oB, 1)
	assert(not q.canExecute(oA) and q.canExecute(oB), "swap moved the binding")
	local beforeA = runsA
	s:Set(2)
	assert(runsA == beforeA and runsB >= 2, "only the new occupant fires")

	-- Effect 교체: cleanup은 값 교체 retract에서 소진된다(파괴에 준함)
	local cleanups = 0
	local e1 = q.Effect(function()
		return function()
			cleanups += 1
		end
	end, s)
	local e2 = q.Effect(function() end, s)
	local inst2 = Instance.new("Frame")
	q.Dispatch.drive(inst2, { e1 })
	q.Dispatch.process(inst2, 1, e2, 1)
	assert(cleanups == 1, "swap retract consumed e1's cleanup")
	assert(not q.canExecute(e1) and q.canExecute(e2), "binding moved")
	print("PASS")
end

print()
print("=== 5. nil로 철거 — (B) 분기: NilHandler로 교대, leaf retractor가 unbind+cleanup ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local cleanups = 0
	local e = q.Effect(function()
		return function()
			cleanups += 1
		end
	end, s)
	q.Dispatch.drive(inst, { e })
	q.Dispatch.process(inst, 1, nil, 1)
	assert(not q.canExecute(e), "retracted: unbound")
	assert(cleanups == 1, "plain retract (nil) also consumes cleanup via the swap branch")
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None, "NilHandler re-registered the position")
	print("PASS")
end

print()
print("=== 6. 동적 경로 가드 — named 자리로 흘러온 Observer/Effect는 typeof(k)를 실은 error ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local o = s:Observer(function() end)
	local e = q.Effect(function() end, s)

	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { MyThing = o })
	end)
	assert(
		not ok and string.find(tostring(err), "Ref/Observer binding should be array index item, but got string", 1, true) ~= nil,
		`observer guard message: {tostring(err)}`
	)
	-- errorBefore(최외곽 표면)라 drive를 뚫고 사용자 호출부(이 파일)를 blame
	assert(string.find(tostring(err), "spec.leaf.luau", 1, true) ~= nil, `blame reaches user code: {tostring(err)}`)

	local ok2, err2 = pcall(function()
		q.Dispatch.drive(inst, { OtherThing = e })
	end)
	assert(
		not ok2 and string.find(tostring(err2), "Effect binding should be array index item, but got string", 1, true) ~= nil,
		`effect guard message: {tostring(err2)}`
	)
	print("PASS")
end

print()
print("=== 7. FALLBACK 의미론 — 평범한 우선순위 핸들러가 가드를 덮어쓴다 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local s = q.Source(1)
	local o = s:Observer(function() end)
	local log: { string } = {}
	q.Dispatch.addHandler({
		name = "NamedObserverOverride",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "string" and q.isObserver(v)
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_inst: any, k: any, _v: any, _index: number): (any?) -> ()
			table.insert(log, `named:{k}`)
			return Quad.Void
		end,
	} :: QuadTypes.Handler)
	q.Dispatch.drive(inst, { MyThing = o })
	assert(#log == 1 and log[1] == "named:MyThing", "the NORMAL handler wins over the FALLBACK guard")
	print("PASS")
end

print()
print("=== ALL PASS ===")
