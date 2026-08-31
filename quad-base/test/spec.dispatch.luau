--[[
	Dispatch core contract — `.claude/base/dispatch-core-plan.md` "Dispatch 체인" /
	"핸들러 계약" / "우선순위 동률/매치 실패 처리", scoped by
	`.claude/qa-request/m3-implementation-round12-brief.md` §6 (unit 1).
	Test handlers are spec-local (no real handlers exist yet); `inst` is a plain
	table (base treats inst as backend-opaque).
]]

local Quad = require("../src")
local QuadTypes = require("../roblox_packages/quad_types")

type Handler = QuadTypes.Handler

local function makeLeaf(log: { string }, tag: string, match: (any) -> boolean, priority: number): Handler
	return {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return match(v)
		end,
		priority = priority,
		process = function(_inst: any, k: any, v: any, index: number): (any?) -> ()
			table.insert(log, `{tag}:process:{tostring(k)}:{tostring(v)}:{index}`)
			return function(hint: any?)
				table.insert(log, `{tag}:retract:{tostring(k)}:{tostring(hint)}`)
			end
		end,
	}
end

-- Wrapping handler — matches `{ inner = ... }`, unwraps one layer and
-- redelegates with `index + 1` (the StoreBind/NoneHandler shape).
local function makeWrap(dispatch: QuadTypes.Dispatch, log: { string }, tag: string, priority: number): Handler
	return {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "table" and (v :: any).inner ~= nil
		end,
		priority = priority,
		process = function(inst: any, k: any, v: any, index: number): (any?) -> ()
			table.insert(log, `{tag}:process:{index}`)
			dispatch.process(inst, k, (v :: any).inner, index + 1)
			return function(hint: any?)
				table.insert(log, `{tag}:retract:{index}:{if hint == nil then "nil" else "value"}`)
			end
		end,
	}
end

local function isString(v: any): boolean
	return type(v) == "string"
end
local function isNumber(v: any): boolean
	return type(v) == "number"
end

local function expectLog(log: { string }, expected: { string })
	assert(#log == #expected, `log length {#log} ~= expected {#expected} — got [{table.concat(log, " | ")}]`)
	for i, want in expected do
		assert(log[i] == want, `log[{i}] = "{log[i]}", want "{want}"`)
	end
end

print("=== 1. getHandler — 우선순위 스캔·첫 매치, 매치 없으면 nil (순수 조회) ===")
do
	local q = Quad.New()
	local log: { string } = {}
	local low = makeLeaf(log, "low", isString, q.Dispatch.HANDLER_PRIORITY_LOW)
	local high = makeLeaf(log, "high", isString, q.Dispatch.HANDLER_PRIORITY_HIGH)
	q.Dispatch.addHandler(low)
	q.Dispatch.addHandler(high)
	local inst = {}
	assert(q.Dispatch.getHandler(inst, "k", "s") == high, "higher priority wins the scan")
	assert(q.Dispatch.getHandler(inst, "k", 42) == nil, "no match -> nil (the error is process's job)")
	assert(#log == 0, "getHandler is a pure scan — no process/retract side effects")
	print("PASS")
end

print()
print("=== 2. process 매치 실패 — 즉시 error, typeof + (있으면) 브랜드 + provider 안내 ===")
do
	local q = Quad.New()
	local inst = {}
	local ok, err = pcall(function()
		q.Dispatch.process(inst, "Size", 5, 1)
	end)
	assert(not ok, "no registered handler -> error")
	local msg = tostring(err)
	assert(string.find(msg, "no handler matched", 1, true) ~= nil, `message says no handler matched: {msg}`)
	assert(string.find(msg, "number", 1, true) ~= nil, `message carries typeof(v): {msg}`)
	assert(string.find(msg, "provider", 1, true) ~= nil, `message points at provider init: {msg}`)

	local src = q.Source(1)
	local ok2, err2 = pcall(function()
		q.Dispatch.process(inst, "Size", src, 1)
	end)
	assert(not ok2, "branded value with no handler -> error")
	assert(string.find(tostring(err2), "brand: Source", 1, true) ~= nil, `message names the brand: {tostring(err2)}`)
	print("PASS")
end

print()
print("=== 3. (B) 설치·교체 — 다른 핸들러가 오면 그 자리 retract(nil) 후 새로 설치 ===")
do
	local q = Quad.New()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.addHandler(makeLeaf(log, "num", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL + 1))
	local inst = {}
	q.Dispatch.process(inst, "k", "hello", 1)
	expectLog(log, { "str:process:k:hello:1" })
	table.clear(log)
	q.Dispatch.process(inst, "k", 42, 1)
	expectLog(log, { "str:retract:k:nil", "num:process:k:42:1" })
	print("PASS")
end

print()
print("=== 4. (A) 같은 핸들러 재프로세스 — retractor가 **새 값**을 받고, 그 다음 process ===")
do
	local q = Quad.New()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = {}
	q.Dispatch.process(inst, "k", "a", 1)
	table.clear(log)
	q.Dispatch.process(inst, "k", "b", 1)
	-- 인자는 nil이 아니라 대체하는 새 값 그 자체(하강 diff의 타입 보장)
	expectLog(log, { "str:retract:k:b", "str:process:k:b:1" })
	print("PASS")
end

print()
print("=== 5. retractor 반환 생략 — (B) 신규 설치·(A) 재프로세스 양쪽에서 즉시 error ===")
do
	local q = Quad.New()
	local calls = 0
	local bad: Handler = {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_inst: any, _k: any, _v: any, _index: number): (any?) -> ()
			calls += 1
			if calls == 1 then
				return Quad.Void
			end
			return nil :: any -- contract violation on the 2nd call
		end,
	}
	q.Dispatch.addHandler(bad)
	local inst = {}
	q.Dispatch.process(inst, "k", "first", 1) -- fine: returns Void

	local okA, errA = pcall(function()
		q.Dispatch.process(inst, "k", "second", 1) -- (A) branch, returns nil
	end)
	assert(not okA, "(A) branch: nil retractor -> error")
	assert(string.find(tostring(errA), "returned no retractor", 1, true) ~= nil, tostring(errA))

	local okB, errB = pcall(function()
		q.Dispatch.process(inst, "other", "fresh", 1) -- (B) branch, calls == 3 -> nil
	end)
	assert(not okB, "(B) branch: nil retractor -> error")
	assert(string.find(tostring(errB), "returned no retractor", 1, true) ~= nil, tostring(errB))
	print("PASS")
end

print()
print("=== 6. retractFrom — 꼬리(깊은 인덱스)부터 역순, 항상 소비, 재설치 가능 ===")
do
	-- 같은 wrap 핸들러가 인덱스 1·2를 차지(State<State<T>> 유사 구조) + leaf가 3.
	-- 최초 마운트에서 재귀 위임이 살아남는 것 자체가 "SetStrong이 h.process보다
	-- 먼저"의 음성 대조다(뒤에 두면 하위 retractor가 유실돼 여기서 안 잡힌다).
	local q = Quad.New()
	local log: { string } = {}
	q.Dispatch.addHandler(makeWrap(q.Dispatch, log, "wrap", q.Dispatch.HANDLER_PRIORITY_HIGH))
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = {}
	q.Dispatch.process(inst, "k", { inner = { inner = "s" } }, 1)
	expectLog(log, { "wrap:process:1", "wrap:process:2", "str:process:k:s:3" })
	table.clear(log)
	q.Dispatch.retractFrom(inst, "k", 1)
	expectLog(log, { "str:retract:k:nil", "wrap:retract:2:nil", "wrap:retract:1:nil" })
	table.clear(log)
	-- 자리가 전부 소비됐으니(list[i] = nil) 새 값이 1번부터 새로 선다
	q.Dispatch.process(inst, "k", "fresh", 1)
	expectLog(log, { "str:process:k:fresh:1" })
	print("PASS")
end

print()
print("=== 7. 깊은 체인의 (A) 연쇄 — 아무것도 철거되지 않고 각 레벨이 자기 힌트를 받음 ===")
do
	local q = Quad.New()
	local log: { string } = {}
	q.Dispatch.addHandler(makeWrap(q.Dispatch, log, "wrap", q.Dispatch.HANDLER_PRIORITY_HIGH))
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = {}
	q.Dispatch.process(inst, "k", { inner = { inner = "old" } }, 1)
	table.clear(log)
	q.Dispatch.process(inst, "k", { inner = { inner = "new" } }, 1)
	expectLog(log, {
		"wrap:retract:1:value", -- (A): 새 값을 받음, 아래는 안 건드림
		"wrap:process:1",
		"wrap:retract:2:value",
		"wrap:process:2",
		"str:retract:k:new", -- leaf도 진짜 값("new")을 힌트로 받음 — nil 아님
		"str:process:k:new:3",
	})
	print("PASS")
end

print()
print("=== 8. 조건부 재위임 핸들러 — 재위임을 건너뛰는 자리에서 retractFrom(index+1) 직접 호출 ===")
do
	-- Handler 작성 체크리스트 8번의 가상 위반 사례를 "올바른 쪽"으로 구현.
	local q = Quad.New()
	local log: { string } = {}
	local cond: Handler = {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "table" and (v :: any).enabled ~= nil
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, v: any, index: number): (any?) -> ()
			if (v :: any).enabled then
				q.Dispatch.process(inst, k, (v :: any).inner, index + 1)
			else
				q.Dispatch.retractFrom(inst, k, index + 1)
			end
			return Quad.Void
		end,
	}
	q.Dispatch.addHandler(cond)
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = {}
	q.Dispatch.process(inst, "k", { enabled = true, inner = "s" }, 1)
	expectLog(log, { "str:process:k:s:2" })
	table.clear(log)
	q.Dispatch.process(inst, "k", { enabled = false }, 1)
	expectLog(log, { "str:retract:k:nil" }) -- 아래가 고아로 남지 않는다
	print("PASS")
end

print()
print("=== 9. 다른 키로 위임 — 그 키에선 항상 인덱스 1, 정리는 위임한 클로저 몫 ===")
do
	local q = Quad.New()
	local log: { string } = {}
	local delegator: Handler = {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "table" and (v :: any).other ~= nil
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, _k: any, v: any, _index: number): (any?) -> ()
			q.Dispatch.process(inst, "otherKey", (v :: any).other, 1)
			return function(hint: any?)
				if hint == nil then
					-- 다른 키의 정리는 그 키를 등록했던 클로저가 자기 철거 시점에
					-- 한다("`retractFrom`은 다른 키에 대해서만 허용")
					q.Dispatch.retractFrom(inst, "otherKey", 1)
				end
			end
		end,
	}
	q.Dispatch.addHandler(delegator)
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = {}
	q.Dispatch.process(inst, "orig", { other = "s" }, 1)
	expectLog(log, { "str:process:otherKey:s:1" }) -- 다른 키는 재귀 깊이와 무관하게 1부터
	table.clear(log)
	q.Dispatch.retractFrom(inst, "orig", 1)
	expectLog(log, { "str:retract:otherKey:nil" })
	print("PASS")
end

print()
print("=== 10. addHandler 동률 — 규칙 없음(에러 아님), 경고 print는 debug일 때만 ===")
do
	local q = Quad.New()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "a", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.addHandler(makeLeaf(log, "b", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL)) -- tie, debug=false: 침묵
	assert(q.debug == false, "debug defaults to false")
	q.debug = true
	print("(아래 quad.Dispatch 동률 경고 한 줄은 의도된 출력이다 — print 캡처가 안 돼 육안 확인)")
	q.Dispatch.addHandler(makeLeaf(log, "c", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL)) -- tie, debug=true: 경고 print
	q.debug = false
	-- 동률이어도 등록 자체는 정상 — 매치가 안 겹치는 핸들러는 그대로 동작
	local inst = {}
	q.Dispatch.process(inst, "k", "s", 1)
	assert(log[#log] == "a:process:k:s:1", "tie handlers still dispatch fine when matches don't overlap")
	print("PASS")
end

print()
print("=== 11. listHandlers — 항상 호출 가능, 우선순위순 반환만(출력 없음), 사본 ===")
do
	local q = Quad.New()
	local log: { string } = {}
	local low = makeLeaf(log, "low", isString, q.Dispatch.HANDLER_PRIORITY_LOW)
	local high = makeLeaf(log, "high", isNumber, q.Dispatch.HANDLER_PRIORITY_HIGH)
	local fallback = makeLeaf(log, "fb", isNumber, q.Dispatch.HANDLER_PRIORITY_FALLBACK)
	q.Dispatch.addHandler(low)
	q.Dispatch.addHandler(fallback)
	q.Dispatch.addHandler(high)
	high.name = "HighLeaf" -- 선택 진단 필드(`H-214` (a)) — 매치·순서엔 무영향
	local listed = q.Dispatch.listHandlers()
	assert(#listed == 3, "returns every registered handler")
	assert(listed[1] == high and listed[2] == low and listed[3] == fallback, "scan (priority) order")
	assert(listed[1].name == "HighLeaf" and listed[2].name == nil, "optional name rides along; absent stays nil")
	table.clear(listed) -- 사본이라 레지스트리에 영향 없음
	assert(q.Dispatch.getHandler({}, "k", 5) == high, "mutating the returned list does not disturb the registry")
	print("PASS")
end

print()
print("=== 12. 인스턴스 격리 — New() 둘은 레지스트리·chains를 공유하지 않음 ===")
do
	local q1 = Quad.New()
	local q2 = Quad.New()
	local log: { string } = {}
	q1.Dispatch.addHandler(makeLeaf(log, "str", isString, q1.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = {}
	assert(q1.Dispatch.getHandler(inst, "k", "s") ~= nil, "registered in q1")
	assert(q2.Dispatch.getHandler(inst, "k", "s") == nil, "invisible in q2")
	q1.Dispatch.process(inst, "k", "s", 1)
	q2.Dispatch.retractFrom(inst, "k", 1) -- q2의 chains엔 이 (inst,k)가 없음 — no-op
	table.clear(log)
	q1.Dispatch.retractFrom(inst, "k", 1) -- q1의 체인은 그대로 살아 있다
	expectLog(log, { "str:retract:k:nil" })
	print("PASS")
end

print()
print("=== ALL PASS ===")
