--!nocheck
--[[
	flatten + `ProcessedModifier` + `ProcessedModifierHandler` (M7 단위 ②,
	round17) — `base/modifier-plan.md` "flatten의 정확한 형태"(역순 for·`~= nil`
	건너뛰기·in-place·센티널 소진·`H-35` 핸들러 의사코드)와 2절(배열 순서상
	나중 modifier 우선 / 인라인 무조건 우선 / 인라인 `None`도 인라인) as-is.
	호출 주체는 `Dispatch.drive`(round17 §0 Q4 (a)) — `drive`가 첫 pre-pass로
	flatten을 돌리므로 여기선 순수 flatten과 drive 경유 둘 다 본다.
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")
local ModifierModule = require("../src/Dispatch/Modifier")
local flatten = ModifierModule.flatten
local ProcessedModifier = ModifierModule.ProcessedModifier

local q = mock.newQuad()
local Instance = mock.Instance
local Modifier = q.Modifier
local None = q.None

print("=== 1. 순수 flatten — in-place, 나중 modifier 우선, 인라인(None 포함) 무조건 우선, 비Modifier 항목 통과 ===")
do
	local m1 = Modifier():A(1):B(1):C(1)
	local m2 = Modifier():B(2):D(2)
	local child = "child"
	local props = { m1, child, m2, C = "inline", D = None }
	local out = flatten(props)
	assert(out == props, "flatten mutates and returns the SAME table (no clone)")
	assert(props[1] == ProcessedModifier and props[3] == ProcessedModifier, "consumed slots become the sentinel (no holes)")
	assert(props[2] == child and #props == 3, "non-Modifier items untouched, array length kept")
	assert(props.A == 1, "field only m1 had")
	assert(props.B == 2, "later modifier wins (m2 over m1)")
	assert(props.C == "inline", "inline key beats every modifier")
	assert(props.D == None, "inline None is a real value — it wins too")
	assert(tostring(ProcessedModifier) == "ProcessedModifier", "named sentinel")
	-- Modifier 없는 props는 그대로(같은 테이블, 변경 0)
	local plain = { "x", Size = 1 }
	assert(flatten(plain) == plain and plain[1] == "x" and plain.Size == 1, "no-op without modifiers")
	print("PASS")
end

print()
print("=== 2. drive 경유 — 센티널 자리는 길이 0(H-39), 형제 오프셋 무영향, 병합 필드는 해시 핸들러로 ===")
do
	local sources = {}
	local leafLog: { string } = {}
	mock.addSpecLeaf(q, sources, leafLog)
	local hashLog: { string } = {}
	q.Dispatch.addHandler({
		name = "SpecHash",
		isHandlable = function(_inst, k, _v)
			return type(k) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_LOW,
		process = function(_inst, k, v, _index)
			table.insert(hashLog, `{k}={tostring(v)}`)
			return Quad.Void
		end,
	} :: QuadTypes.Handler)

	local inst = Instance.new("Frame")
	local mod = Modifier():Size(10):Text("t")
	q.Dispatch.drive(inst, { "a", mod, "b", Text = "inline" })
	assert(q.Dispatch.getOffsetAt(inst, 2) == 1, "leaf a contributes 1")
	assert(q.Dispatch.getOffsetAt(inst, 3) == 1, "the consumed modifier slot contributes 0 — b sits right after a")
	table.sort(hashLog)
	assert(table.concat(hashLog, ",") == "Size=10,Text=inline", "merged field dispatched as a hash key; inline Text won: " .. table.concat(hashLog, ","))

	-- State 필드는 StoreBind가 언랩해 같은 해시 핸들러로(반응형 유지)
	table.clear(hashLog)
	local src = q.Source(5)
	local inst2 = Instance.new("Frame")
	q.Dispatch.drive(inst2, { Modifier():Size(src) })
	assert(hashLog[1] == "Size=5", "State field unwrapped by StoreBind: " .. tostring(hashLog[1]))
	src:Set(6)
	assert(hashLog[#hashLog] == "Size=6", "still reactive after flatten")
	-- None 필드(mod:X(None))는 NoneHandler → nil 재귀 → 해시 키 핸들러에 nil로
	table.clear(hashLog)
	q.Dispatch.drive(Instance.new("Frame"), { Modifier():Size(None) })
	assert(hashLog[1] == "Size=nil", "None field reaches the key's handler as nil: " .. tostring(hashLog[1]))
	print("PASS")
end

print()
print("=== 3. 센티널 핸들러 — 등록됨(HIGH), 철거는 Void(no-op), 배열 밖 값은 안 잡음 ===")
do
	local names = {}
	for _, h in q.Dispatch.listHandlers() do
		table.insert(names, h.name)
	end
	assert(table.find(names, "ProcessedModifierHandler") ~= nil, "handler registered by InitDispatch: " .. table.concat(names, ","))
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, { Modifier():X(1), "leaf" })
	assert(q.Dispatch.getOffsetAt(inst, 2) == 0, "sentinel slot length 0")
	q.Dispatch.retractFrom(inst, 1, 1) -- Void retractor — 에러 없이 통과
	assert(q.Dispatch.getOffsetAt(inst, 2) == 0, "retraction leaves bookkeeping at 0")
	print("PASS")
end

print()
print("=== 4. H-312(사용자 확정) — 해시 키 자리의 Modifier는 flatten이 즉시 error(사용자 줄 blame), 슬롯 소진 전 ===")
do
	local inst = Instance.new("Frame")
	local mod = Modifier():Size(1)
	local props = { mod, Size = Modifier():X(1) }
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, props)
	end)
	assert(not ok, "Modifier at a hash key must error")
	assert(string.find(tostring(err), "array part", 1, true) ~= nil, "message names the rule: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.flatten.luau", "hash-key Modifier")
	assert(props[1] == mod, "rejected before any array slot was consumed")
	-- 희소 숫자 키(배열부 밖)도 해시 파트라 같이 잡힌다(리뷰 반영)
	local ok2, err2 = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { [5] = Modifier():X(1) })
	end)
	assert(not ok2 and string.find(tostring(err2), "array part", 1, true) ~= nil, "sparse numeric key rejected too: " .. tostring(err2))
	-- Modifier 없는 props도 해시 파트 순회만 한 번(배열부 이중 순회 없음)은 구현 주석이 소스
	print("PASS")
end

print()
print("=== ALL PASS ===")
