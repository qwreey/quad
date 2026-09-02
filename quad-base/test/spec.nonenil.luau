--[[
	`None` sentinel + `NoneHandler`/`NilHandler` — `.claude/base/
	dispatch-core-plan.md` "`None` 센티널" / "`NilHandler`" sections (M3 unit 3).
	The pair is pre-registered per module instance by `InitDispatch`; hash-key
	consumers are spec-local stand-ins for property handlers.
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

local Instance = mock.Instance

local newQuad = mock.newQuad -- `H-261`: 공용 헬퍼는 mock이 소유
-- `H-263`: 3·4번이 같은 leaf 등록 계약을 두 벌 들고 있었다 — 한 팩토리로.
-- `H-271`: 그 팩토리가 spec.integration에서 또 복사돼 mock으로 승격됨.
local addSpecLeaf = mock.addSpecLeaf

print("=== 1. None 값 — 단일 센티널, frozen, tostring ===")
do
	local q = newQuad()
	assert(q.None ~= nil and type(q.None) == "table", "None is a real value")
	assert(q.None == Quad.None, "one sentinel across instances (leaf module)")
	assert(tostring(q.None) == "None", "diagnostic name")
	assert(not pcall(function()
		(q.None :: any).x = 1
	end), "frozen — cannot be mutated")
	print("PASS")
end

print()
print("=== 2. 해시 자리 None — NoneHandler가 nil로 재귀(index+1), 키 담당 핸들러가 받는다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler({
		name = "SpecProp",
		isHandlable = function(_inst: any, k: any, _v: any): boolean
			return type(k) == "string" -- 해시 키 전담(진짜 nil 포함 — NilHandler는 숫자 키만)
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_LOW,
		process = function(_inst: any, k: any, v: any, index: number): (any?, boolean) -> ()
			table.insert(log, `prop:{k}:{tostring(v)}@{index}`)
			return Quad.Void
		end,
	} :: QuadTypes.Handler)
	local inst = Instance.new("Frame")
	q.Dispatch.process(inst, "Text", q.None, 1)
	-- NoneHandler(index 1) → nil 재귀(index 2) → SpecProp이 nil을 받는다
	assert(#log == 1 and log[1] == "prop:Text:nil@2", `hash None reaches the key's own handler as nil (got {log[1]})`)
	print("PASS")
end

print()
print("=== 3. 배열 자리 None/nil — NilHandler가 setOffsetSource(None)→setLength(0) 등록 ===")
do
	local q = newQuad()
	local sources: { any } = {}
	addSpecLeaf(q, sources)
	local inst = Instance.new("Frame")
	-- 자리 1 = None(기여 0), 자리 2 = 실요소(기여 1), 자리 3 = 실요소
	q.Dispatch.drive(inst, { q.None, "a", "b" })
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.N == 3, "the None position is registered, not skipped")
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None, "NilHandler registered 0 + None channel")
	assert(sources[2]:Get() == 0, "position 2 offset: the None position contributes 0")
	assert(sources[3]:Get() == 1, "position 3 offset follows")
	assert(q.Dispatch.getOffsetAt(inst, 1) == 0, "the None position's own number is pullable")
	print("PASS")
end

print()
print("=== 4. 전환 — 값 → None(철거+0 등록), None → 값(복원) — 하강 diff가 잇는다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	local sources: { any } = {}
	addSpecLeaf(q, sources, log)
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, { "a", "b" })
	assert(sources[2]:Get() == 1, "steady state")

	-- 자리 1: 값 → None (State<Slot|None>이 None을 내놓는 재발행과 같은 모양)
	table.clear(log)
	q.Dispatch.process(inst, 1, q.None, 1)
	-- (B) 분기: leaf 철거(nil) 후 NoneHandler 설치 → nil 재귀 → NilHandler가 0 등록
	-- (nil, true) — retractFrom 경유 단순 철거 신호(`H-258`; 관측은 `H-281`)
	assert(log[1] == "leaf:retract:1:nil:true", "previous occupant retracted by the descending diff, flagged as teardown")
	assert(sources[2]:Get() == 0, "trailing offset follows the 0 contribution")

	-- 자리 1: None → 값 (복원)
	q.Dispatch.process(inst, 1, "a2", 1)
	assert(sources[2]:Get() == 1, "restoring a value restores the contribution")
	print("PASS")
end

print()
print("=== 5. 매치 경계 — NilHandler는 숫자 키의 nil만, None은 어디서든 NoneHandler ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	-- 해시 키 nil: NilHandler가 아니라 그 키의 핸들러 몫 — 등록이 없으면 매치 실패
	local ok, err = pcall(function()
		q.Dispatch.process(inst, "Text", nil, 1)
	end)
	assert(not ok and string.find(tostring(err), "no handler matched", 1, true) ~= nil, "hash nil is not NilHandler's")
	-- 숫자 키 nil: NilHandler 매치(직접 리액티브 경로 — State<Slot|nil>의 nil)
	q.Dispatch.process(inst, 1, nil, 1)
	local bk = q.Dispatch.getBookkeeping(inst)
	assert(bk.lengthList[1] == 0 and bk.sourceList[1] == q.None, "numeric nil lands on NilHandler")
	print("PASS")
end

print()
print("=== ALL PASS ===")
