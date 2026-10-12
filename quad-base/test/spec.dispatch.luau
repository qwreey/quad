--[[
	Dispatch core contract — `.claude/base/dispatch-core-plan.md` "Dispatch 체인" /
	"핸들러 계약" / "우선순위 동률/매치 실패 처리", scoped by
	`.claude/archive/v2-initial-implementation/m3-implementation-round12-brief.md` §6 (unit 1).
	Test handlers are spec-local (no real handlers exist yet); `inst` is a mock
	Instance — `H-229` anchors every chain via bindLifetime, so dispatch needs a
	claimable inst.
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

-- `H-229`: process는 (inst,k) 체인 리스트를 만들 때 `bindLifetime(inst, list)`로
-- gchold에 앵커하므로, 디스패치를 태우는 inst는 전부 mock Instance여야 한다.
local Instance = mock.Instance
-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local newQuad = mock.newQuad -- `H-261`: 공용 헬퍼는 mock이 소유

type Handler = QuadTypes.Handler

local function makeLeaf(log: { string }, tag: string, match: (any) -> boolean, priority: number): Handler
	return {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return match(v)
		end,
		priority = priority,
		process = function(_inst: any, k: any, v: any, index: number): (any?, boolean) -> ()
			table.insert(log, `{tag}:process:{tostring(k)}:{tostring(v)}:{index}`)
			return function(hint: any?)
				table.insert(log, `{tag}:retract:{tostring(k)}:{tostring(hint)}`)
			end
		end,
	}
end

-- Wrapping handler — matches `{ inner = ... }`, unwraps one layer and
-- redelegates with `index + 1` (the StateHandler/NoneHandler shape).
local function makeWrap(dispatch: QuadTypes.Dispatch, log: { string }, tag: string, priority: number): Handler
	return {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "table" and (v :: any).inner ~= nil
		end,
		priority = priority,
		process = function(inst: any, k: any, v: any, index: number): (any?, boolean) -> ()
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
	local q = newQuad()
	local log: { string } = {}
	local low = makeLeaf(log, "low", isString, q.Dispatch.HANDLER_PRIORITY_LOW)
	local high = makeLeaf(log, "high", isString, q.Dispatch.HANDLER_PRIORITY_HIGH)
	q.Dispatch.addHandler(low)
	q.Dispatch.addHandler(high)
	local inst = Instance.new("Frame")
	assert(q.Dispatch.getHandler(inst, "k", "s") == high, "higher priority wins the scan")
	assert(q.Dispatch.getHandler(inst, "k", 42) == nil, "no match -> nil (the error is process's job)")
	assert(#log == 0, "getHandler is a pure scan — no process/retract side effects")
	-- `H-603` (round13 E2): getHandler has no process/retractFrom in front of it, so a
	-- nil inst/key used to fall straight into h.isHandlable and the VM error named a
	-- leaf module (Handlers/Property.luau, Reflection.luau), not quad. Same gate
	-- (checkInst/checkKey), same two Quad ids, as process/retractFrom.
	local okInst, errInst = pcall(q.Dispatch.getHandler, nil, "Size", 1)
	assert(not okInst and string.find(tostring(errInst), "Quad0072") ~= nil, "nil inst -> Quad0072, not a leaf-module VM error")
	local okKey, errKey = pcall(q.Dispatch.getHandler, inst, nil, 1)
	assert(not okKey and string.find(tostring(errKey), "Quad0074") ~= nil, "nil key -> Quad0074, not a leaf-module VM error")
	print("PASS")
end

print()
print("=== 2. process 매치 실패 — 즉시 error, typeof + (있으면) 브랜드 + provider 안내 ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	local ok, err = pcall(function()
		q.Dispatch.process(inst, "Size", 5, 1)
	end)
	assert(not ok, "no registered handler -> error")
	local msg = tostring(err)
	assert(string.find(msg, "no handler matched", 1, true) ~= nil, `message says no handler matched: {msg}`)
	assert(string.find(msg, "number", 1, true) ~= nil, `message carries typeof(v): {msg}`)
	assert(string.find(msg, "provider", 1, true) ~= nil, `message points at provider init: {msg}`)

	-- 브랜드 예시는 Blocker — Source는 M4부터 내장 StateHandler에 항상 매치돼
	-- "핸들러 없는 브랜드 값"이 될 수 없다(언랩된 실제값이 대신 실패한다 —
	-- round13 `H-287` 회귀의 자리)
	local blocker = q.Blocker()
	local ok2, err2 = pcall(function()
		q.Dispatch.process(inst, "Size", blocker, 1)
	end)
	assert(not ok2, "branded value with no handler -> error")
	assert(string.find(tostring(err2), "brand: Blocker", 1, true) ~= nil, `message names the brand: {tostring(err2)}`)
	-- Q27 (2026-09-08): a PROVIDER brand is found by contract — the module-level `is<Brand>`
	-- field (no Dispatch op). round13 Q106 (2026-09-28): the
	-- predicate must also be registered in the module's `BrandPredicates` (unregistered `is*` fields
	-- are ignored — a raising helper below is never even called)
	local spring = setmetatable({}, {})
	local function isSpring(v: any): boolean
		return v == spring
	end
	q.BrandPredicates:Register(isSpring)
	q.isSpring = isSpring
	q.isBroken = function(_v: any): boolean -- a helper that raises must not mask the diagnostic
		error("not a brand predicate")
	end
	local ok3, err3 = pcall(function()
		q.Dispatch.process(inst, "Size", spring, 1)
	end)
	assert(not ok3 and string.find(tostring(err3), "brand: Spring", 1, true) ~= nil, `provider brand named by contract: {tostring(err3)}`)
	-- [2026-10-01 user decision] base predicates take the same registered path (no base list in Dispatch):
	-- every public `is*` field of a fresh module is a registered brand predicate — a base `is*` added
	-- without its `brandPredicate(...)` registration fails here, not silently in a diagnostic
	local qFresh: any = newQuad()
	local baseIs = 0
	for name, predicate in qFresh do
		if type(name) == "string" and string.sub(name, 1, 2) == "is" then
			assert(qFresh.BrandPredicates:Is(predicate), `base {name} is registered in BrandPredicates`)
			baseIs += 1
		end
	end
	assert(baseIs == 18, `the eighteen base brand predicates (got {baseIs})`)
	-- every hit is named, sorted by name: a value answering a base AND a provider predicate names both
	local function isZeta(v: any): boolean
		return v == blocker
	end
	q.BrandPredicates:Register(isZeta)
	q.isZeta = isZeta
	q.isAnything = function(_v: any): boolean -- an UNREGISTERED helper that says yes to everything: ignored
		return true
	end
	local function isFaulty(_v: any): boolean -- a REGISTERED predicate that raises: pcall'd, counts as a miss
		error("buggy brand predicate")
	end
	q.BrandPredicates:Register(isFaulty)
	q.isFaulty = isFaulty
	local ok4, err4 = pcall(function()
		q.Dispatch.process(inst, 2, blocker, 1)
	end)
	assert(not ok4 and string.find(tostring(err4), "(value: table, brand: Blocker, Zeta)", 1, true) ~= nil, `all hits, sorted, unregistered helper ignored: {tostring(err4)}`)
	assert(string.find(tostring(err4), "Anything", 1, true) == nil, `unregistered is* never named: {tostring(err4)}`)
	-- Ref subtypes answer their union predicates too — the whole set, not the most specific one
	local okR, errR = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), q.PreRef())
	end)
	assert(not okR and string.find(tostring(errR), "(got Epoch, PreRef, Ref)", 1, true) ~= nil, `PreRef names every brand it carries: {tostring(errR)}`)
	-- the hint follows the registration: a hit on a registered PROVIDER predicate means its owner is
	-- installed, so the value gets the quad-value hints, never "provider not initialized"
	local okP1, errP1 = pcall(function()
		q.Dispatch.process(inst, "Size", spring, 1)
	end)
	assert(not okP1 and string.find(tostring(errP1), "belongs in a numeric (array) slot", 1, true) ~= nil
		and string.find(tostring(errP1), "provider", 1, true) == nil, `provider brand at a string key: quad-value hint: {tostring(errP1)}`)
	local okP2, errP2 = pcall(function()
		q.Dispatch.process(inst, 3, spring, 1)
	end)
	assert(not okP2 and string.find(tostring(errP2), "no handler at an array position", 1, true) ~= nil
		and string.find(tostring(errP2), "provider", 1, true) == nil, `provider brand at a numeric key: quad-value hint: {tostring(errP2)}`)
	-- no registered brand at all: the typo / provider-not-installed hints (string key / numeric key)
	local okN1, errN1 = pcall(function()
		q.Dispatch.process(inst, "Size", setmetatable({}, {}), 1)
	end)
	assert(not okN1 and string.find(tostring(errN1), "(value: table)", 1, true) ~= nil
		and string.find(tostring(errN1), "a typo, a read-only field", 1, true) ~= nil, `unbranded at a string key: typo/provider hint: {tostring(errN1)}`)
	local okN2, errN2 = pcall(function()
		q.Dispatch.process(inst, 4, setmetatable({}, {}), 1)
	end)
	assert(not okN2 and string.find(tostring(errN2), "check that the provider for this value", 1, true) ~= nil, `unbranded at a numeric key: provider hint: {tostring(errN2)}`)
	print("PASS")
end

print()
print("=== 3. (B) 설치·교체 — 다른 핸들러가 오면 그 자리 retract(nil) 후 새로 설치 ===")
do
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.addHandler(makeLeaf(log, "num", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL + 1))
	local inst = Instance.new("Frame")
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
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = Instance.new("Frame")
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
	local q = newQuad()
	local calls = 0
	local bad: Handler = {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_inst: any, _k: any, _v: any, _index: number): (any?, boolean) -> ()
			calls += 1
			if calls == 1 then
				return Quad.Void
			end
			return nil :: any -- contract violation on the 2nd call
		end,
	}
	q.Dispatch.addHandler(bad)
	local inst = Instance.new("Frame")
	q.Dispatch.process(inst, "k", "first", 1) -- fine: returns Void

	local okA, errA = pcall(function()
		q.Dispatch.process(inst, "k", "second", 1) -- (A) branch, returns nil
	end)
	assert(not okA, "(A) branch: nil retractor -> error")
	assert(string.find(tostring(errA), "Quad0077 Dispatch: handler (priority 0) must return a retractor function at key k, index 1 (got nil)", 1, true) ~= nil, tostring(errA))

	local okB, errB = pcall(function()
		q.Dispatch.process(inst, "other", "fresh", 1) -- (B) branch, calls == 3 -> nil
	end)
	assert(not okB, "(B) branch: nil retractor -> error")
	assert(string.find(tostring(errB), "must return a retractor function", 1, true) ~= nil, tostring(errB))
	print("PASS")
end

print()
print("=== 6. retractFrom — 꼬리(깊은 인덱스)부터 역순, 항상 소비, 재설치 가능 ===")
do
	-- 같은 wrap 핸들러가 인덱스 1·2를 차지(State<State<T>> 유사 구조) + leaf가 3.
	-- 최초 마운트에서 재귀 위임이 살아남는 것 자체가 "SetStrong이 h.process보다
	-- 먼저"의 음성 대조다(뒤에 두면 하위 retractor가 유실돼 여기서 안 잡힌다).
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler(makeWrap(q.Dispatch, log, "wrap", q.Dispatch.HANDLER_PRIORITY_HIGH))
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = Instance.new("Frame")
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
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler(makeWrap(q.Dispatch, log, "wrap", q.Dispatch.HANDLER_PRIORITY_HIGH))
	q.Dispatch.addHandler(makeLeaf(log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = Instance.new("Frame")
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
	local q = newQuad()
	local log: { string } = {}
	local cond: Handler = {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "table" and (v :: any).enabled ~= nil
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, v: any, index: number): (any?, boolean) -> ()
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
	local inst = Instance.new("Frame")
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
	local q = newQuad()
	local log: { string } = {}
	local delegator: Handler = {
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "table" and (v :: any).other ~= nil
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, _k: any, v: any, _index: number): (any?, boolean) -> ()
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
	local inst = Instance.new("Frame")
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
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "a", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.addHandler(makeLeaf(log, "b", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL)) -- tie, debug=false: 침묵
	assert(q.debug == false, "debug defaults to false")
	q.debug = true
	print("(아래 quad.Dispatch 동률 경고 한 줄은 의도된 출력이다 — print 캡처가 안 돼 육안 확인)")
	q.Dispatch.addHandler(makeLeaf(log, "c", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL)) -- tie, debug=true: 경고 print
	q.debug = false
	-- 동률이어도 등록 자체는 정상 — 매치가 안 겹치는 핸들러는 그대로 동작
	local inst = Instance.new("Frame")
	q.Dispatch.process(inst, "k", "s", 1)
	assert(log[#log] == "a:process:k:s:1", "tie handlers still dispatch fine when matches don't overlap")
	print("PASS")
end

print()
print("=== 11. listHandlers — 항상 호출 가능, 우선순위순 반환만(출력 없음), 사본 ===")
do
	local q = newQuad()
	local log: { string } = {}
	local low = makeLeaf(log, "low", isString, q.Dispatch.HANDLER_PRIORITY_LOW)
	local high = makeLeaf(log, "high", isNumber, q.Dispatch.HANDLER_PRIORITY_HIGH)
	local fallback = makeLeaf(log, "fb", isNumber, q.Dispatch.HANDLER_PRIORITY_FALLBACK)
	q.Dispatch.addHandler(low)
	q.Dispatch.addHandler(fallback)
	q.Dispatch.addHandler(high)
	high.name = "HighLeaf" -- 선택 진단 필드(`H-214` (a)) — 매치·순서엔 무영향
	local listed = q.Dispatch.listHandlers()
	local ours: { QuadTypes.Handler } = {}
	for _, h in listed do
		if h == high or h == low or h == fallback then
			table.insert(ours, h)
		end
	end
	-- 내장들도 HIGH라 test high와 동률일 수 있다 — 동률 간 순서는 계약상
	-- 미정, 상대 순서(높은 밴드 먼저)만 단언한다(내장 개수는 여기서 안 센다)
	assert(#ours == 3 and ours[1] == high and ours[2] == low and ours[3] == fallback, "scan (priority) order among ours")
	-- 내장 핸들러들(단위 3의 None 쌍, 이후 단위가 더 등록)이 항상 같이 있다 —
	-- 총 개수 하드코딩 없이("개수의 소스는 하나만") 이름으로 쌍을 검출
	local builtin: { [string]: boolean } = {}
	for _, h in listed do
		if h.name ~= nil then
			builtin[h.name :: string] = true
		end
	end
	assert(builtin["NoneHandler"] and builtin["NilHandler"], "the None pair is registered alongside ours")
	assert(ours[1].name == "HighLeaf" and ours[2].name == nil, "optional name rides along through the returned list; absent stays nil")
	table.clear(listed) -- 사본이라 레지스트리에 영향 없음
	assert(q.Dispatch.getHandler(Instance.new("Frame"), "k", 5) == high, "mutating the returned list does not disturb the registry")
	print("PASS")
end

print()
print("=== 12. 인스턴스 격리 — New() 둘은 레지스트리·chains를 공유하지 않음 ===")
do
	local q1 = newQuad()
	local q2 = newQuad()
	local log: { string } = {}
	q1.Dispatch.addHandler(makeLeaf(log, "str", isString, q1.Dispatch.HANDLER_PRIORITY_NORMAL))
	local inst = Instance.new("Frame")
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
print("=== 13. H-229 — 체인은 inst의 bind 수명에 앵커: Destroy 후 GC로 통째로 회수 ===")
do
	-- chains는 리스트를 weak으로만 잡고 강한 앵커는 gchold 하나다. retractor가
	-- inst를 캡처해도(반응형 바인딩의 실제 모양) Destroy가 gchold 섬을 무너뜨리면
	-- 체인 그래프 전체가 수거돼야 한다 — retractor는 호출되지 않는다(계약 유지).
	local q = newQuad()
	local probe: { [number]: any } = setmetatable({}, { __mode = "v" }) :: any
	q.Dispatch.addHandler({
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, _k: any, _v: any, _index: number): (any?, boolean) -> ()
			local retractor = function(_hint: any?)
				local _ = inst -- 실제 반응형 retractor처럼 inst를 캡처
			end
			table.insert(probe, retractor)
			return retractor
		end,
	} :: QuadTypes.Handler)

	local inst: any = Instance.new("Frame")
	q.Dispatch.process(inst, "k", "s", 1)
	collectgarbage()
	collectgarbage()
	assert(probe[1] ~= nil, "while inst lives, the gchold anchor keeps the chain (and its retractor) alive")

	inst:Destroy()
	inst = nil
	collectgarbage()
	collectgarbage()
	assert(probe[1] == nil, "after Destroy the whole chain graph is collectable — no retract call needed")
	print("PASS")
end

print()
print("=== 14. H-258 — retractor 2번째 인자: retractFrom는 (nil, true), (A) 재프로세스는 (v, false) ===")
do
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler({
		name = "FlagProbe",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return type(v) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_inst: any, _k: any, v: any, _index: number): (any?, boolean) -> ()
			return function(nextValue: any?, retracting: boolean)
				log[#log + 1] = `{tostring(v)}:{tostring(nextValue)}:{tostring(retracting)}`
			end
		end,
	} :: QuadTypes.Handler)
	local inst = Instance.new("Frame")
	q.Dispatch.process(inst, "k", "a", 1)
	q.Dispatch.process(inst, "k", "b", 1) -- (A): 같은 핸들러 재프로세스
	assert(log[1] == "a:b:false", `(A) branch hands (newValue, false): {log[1]}`)
	q.Dispatch.retractFrom(inst, "k", 1) -- 단순 철거
	assert(log[2] == "b:nil:true", `retractFrom hands (nil, true): {log[2]}`)
	print("PASS")
end

print()
print("=== 15. H-329 (a) — 순수 철거로 비워진 체인은 chains·gchold에서 놓인다(새 키마다 누적 없음); (B) 재설치 경로는 같은 리스트 유지 ===")
do
	local q = mock.newQuad()
	q.Dispatch.addHandler({
		name = "AnyTableKey",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "table" and type(v) == "string"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_LOW,
		process = function(_inst: any, _k: any, _v: any, _index: number): (any?, boolean) -> ()
			return q.Void
		end,
	} :: QuadTypes.Handler)
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, {})
	local gc: any = (_G :: any).collectgarbage
	gc("collect"); gc("collect")
	local before = gc("count")
	for i = 1, 5000 do
		local key = { i } -- fresh key per cycle — the State<Attr> group-key shape (fable 탐사 X-1)
		q.Dispatch.process(inst, key, "v", 1)
		q.Dispatch.retractFrom(inst, key, 1)
	end
	gc("collect"); gc("collect"); gc("collect")
	local delta = gc("count") - before
	assert(delta < 200, "emptied chains must not accumulate per fresh key (was ~2300 KB before H-329): " .. tostring(delta) .. " KB")
	-- (B) 경로: 같은 키에서 핸들러가 바뀌어도 리스트는 유지돼 재설치가 끊기지 않는다
	local k2 = { "b" }
	q.Dispatch.process(inst, k2, "v", 1)
	q.Dispatch.process(inst, k2, "w", 1) -- same handler, (A)
	q.Dispatch.retractFrom(inst, k2, 1) -- pure retract → released
	q.Dispatch.process(inst, k2, "v", 1) -- fresh list again — must not error
	print("PASS")
end

print()
print()
print("=== 16. H-419 (외부 리뷰 G-07) — drive의 props가 테이블이 아니면 표면 에러(flatten 안 VM 에러가 Dispatch/Modifier/init.luau를 blame하던 것) ===")
do
	local q = newQuad()
	-- 7순회: `{ nil, … }` skipped the nil case under ipairs — spell the three cases out
	for _, thunk in { function() q.Dispatch.drive(mock.Instance.new("Frame"), nil :: any) end, function() q.Dispatch.drive(mock.Instance.new("Frame"), "x" :: any) end, function() q.Dispatch.drive(mock.Instance.new("Frame"), 5 :: any) end } do
		local ok, err = pcall(thunk :: any)
		assert(not ok and string.find(tostring(err), "props must be a table", 1, true) ~= nil, "non-table props rejected: " .. tostring(err))
		mock.assertBlamesUser(err, "spec.dispatch.luau", "drive props blame")
	end
	-- `H-470` (탐사 A): a quad VALUE where the props table is due (braces forgotten) — metatable
	-- brands and the frozen plain-branded ones (AttrKey — `{ Name = "x" }`, a silent rename
	-- under quad-roblox) both refused, brand named, nothing dispatched
	for _, bad in { q.Source(1), q.Tag("a"), q.AttrKey("x"), setmetatable({}, {}) } :: { any } do
		local inst = mock.Instance.new("Frame")
		local ok, err = pcall(function() q.Dispatch.drive(inst, bad) end)
		assert(not ok and string.find(tostring(err), "a quad value needs the braces", 1, true) ~= nil, "quad value props rejected: " .. tostring(err))
		mock.assertBlamesUser(err, "spec.dispatch.luau", "drive quad-value props blame")
		assert(inst.Name == "Frame", "nothing was dispatched before the gate")
	end
	assert(string.find(select(2, pcall(function() q.Dispatch.drive(mock.Instance.new("Frame"), q.AttrKey("x")) end)) :: any, "got AttrKey", 1, true) ~= nil, "brand named")
	-- [2026-10-01 user decision] the every-call half is O(1) (metatable / `Brand.isPlainBranded`); the full
	-- `brandNameOf` scan is debug-only — the one thing only it catches is a PROVIDER brand with no metatable
	local qp: any = newQuad()
	local widgets = setmetatable({}, { __mode = "k" }) :: any
	qp.isWidget = function(x: any): boolean
		return widgets[x] == true
	end
	qp.BrandPredicates:Register(qp.isWidget)
	local widget = { Name = "w" }
	widgets[widget] = true
	local instOff = mock.Instance.new("Frame")
	local okOff, errOff = pcall(function() qp.Dispatch.drive(instOff, widget) end)
	-- debug off: no scan — the plain branded table is dispatched as props, so its `Name` field reaches the
	-- handler scan (no handler for it in this bare quad: the ordinary no-match), not the Quad0083 gate
	assert(not okOff and string.find(tostring(errOff), "Quad0083", 1, true) == nil
		and string.find(tostring(errOff), "Quad0076", 1, true) ~= nil and string.find(tostring(errOff), "key Name", 1, true) ~= nil,
		"debug off: dispatched as props: " .. tostring(errOff))
	qp.debug = true
	local instOn = mock.Instance.new("Frame")
	local okOn, errOn = pcall(function() qp.Dispatch.drive(instOn, widget) end)
	assert(not okOn and string.find(tostring(errOn), "Quad0083", 1, true) ~= nil and string.find(tostring(errOn), "got Widget", 1, true) ~= nil, "debug on: the scan names the provider brand: " .. tostring(errOn))
	mock.assertBlamesUser(errOn, "spec.dispatch.luau", "debug Quad0083 blame")
	assert(instOn.Name == "Frame", "debug on: nothing dispatched before the gate")
	print("PASS")
end

print("=== 17. round3 H-442 (외부 리뷰 G-12) — drive(nil, props)는 표면 에러(Relate의 `table index is nil` 대신), 사용자 줄 blame ===")
do
	local q = newQuad()
	local ok, err = pcall(function()
		q.Dispatch.drive(nil, { mock.Instance.new("Frame") })
	end)
	assert(not ok and string.find(tostring(err), "inst must not be nil", 1, true) ~= nil, "nil inst rejected: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.dispatch.luau", "drive nil inst blame")
	print("PASS")
end

print("=== 18. round3 H-452 (Q7 셋째 (a), H-416 재현) — 디스패치가 lazy Compute를 처음 강제해 Modifier가 나오면 blame은 사용자 drive 줄(outermost), StateHandler 내부가 아니다 ===")
do
	local q = newQuad()
	local inst = mock.Instance.new("Frame")
	local s = q.Source(1)
	local d = s:Compute(function()
		return q.Modifier({})
	end)
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { Name = d })
	end)
	assert(not ok and string.find(tostring(err), "cannot hold Modifiers", 1, true) ~= nil, "Compute-returned Modifier rejected via dispatch: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.dispatch.luau", "outermost — the drive line, not StateHandler.luau")
	print("PASS")
end

print()
print("=== 19. round7 Q37 (a) H-484 — keyType 버킷: 선언한 타입의 키에서만 물어보고, 미선언은 모든 버킷, 버킷 안 순서는 priority, 잘못된 선언은 등록 시 표면 에러 ===")
do
	local q = newQuad()
	local asked: { [string]: number } = {}
	local function counting(tag: string, keyType: any, priority: number): Handler
		local h = makeLeaf({}, tag, function(_v: any) return false end, priority) :: any -- never matches — we count the asks
		local inner = h.isHandlable
		h.isHandlable = function(inst: any, k: any, v: any): boolean
			asked[tag] = (asked[tag] or 0) + 1
			return inner(inst, k, v)
		end
		h.keyType = keyType
		return h
	end
	q.Dispatch.addHandler(counting("num", "number", q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.addHandler(counting("str", "string", q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.addHandler(counting("any", nil, q.Dispatch.HANDLER_PRIORITY_LOW))
	local inst = Instance.new("Frame")
	local before = { num = asked.num or 0, str = asked.str or 0, any = asked.any or 0 }
	assert(q.Dispatch.getHandler(inst, 1, "x") == nil, "no match on purpose")
	assert((asked.num or 0) - before.num == 1 and (asked.str or 0) - before.str == 0, "a number key asks the number-declared handler, never the string-declared one")
	assert(q.Dispatch.getHandler(inst, "Size", "x") == nil, "no match on purpose")
	assert((asked.str or 0) - before.str == 1 and (asked.num or 0) - before.num == 1, "a string key asks only the string-declared one")
	assert(q.Dispatch.getHandler(inst, {}, "x") == nil, "no match on purpose")
	assert((asked.num or 0) - before.num == 1 and (asked.str or 0) - before.str == 1 and (asked.any or 0) - before.any == 3, "a table key asks neither declared handler; the undeclared one is asked in every bucket")

	-- priority order survives inside a bucket: a HIGH string handler that matches beats a NORMAL one
	local log: { string } = {}
	local normal = makeLeaf(log, "normal", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL) :: any
	normal.keyType = "string"
	local high = makeLeaf(log, "high", isString, q.Dispatch.HANDLER_PRIORITY_HIGH) :: any
	high.keyType = "string"
	q.Dispatch.addHandler(normal)
	q.Dispatch.addHandler(high)
	assert(q.Dispatch.getHandler(inst, "k", "s") == high, "priority order inside the string bucket")
	assert(q.Dispatch.getHandler(inst, 1, "s") == nil, "string-declared handlers are invisible to number keys even when isHandlable would accept")

	-- registration gate
	local bad = makeLeaf(log, "bad", isString, q.Dispatch.HANDLER_PRIORITY_LOW) :: any
	bad.keyType = "table"
	local ok, err = pcall(function() q.Dispatch.addHandler(bad) end)
	assert(not ok and string.find(tostring(err), 'keyType must be "number", "string" or nil', 1, true), "bad keyType is a registration error: " .. tostring(err))
	assert(q.Dispatch.getHandler(inst, "k", "s") == high, "the rejected handler was not registered")
	print("PASS")
end

print()
print()
print("=== 20. 2026-09-08 2차 감사 H-493/H-495 — addHandler 모양 게이트, drive 배열 키 도메인([0]/[1.5]/[-1]) ===")
do
	local q = newQuad()
	local never = function(_k: any, _v: any): boolean return false end
	local shapes: { { string | any } } = {
		{ "number", 5 },
		{ "noProcess", { name = "Y", priority = 0, isHandlable = never } },
		{ "noPriority", { isHandlable = never, process = function() end } },
	}
	for _, pair in shapes do
		local label, h = pair[1], pair[2]
		local ok, err = pcall(function() q.Dispatch.addHandler(h) end)
		assert(not ok and string.find(tostring(err), "Dispatch.addHandler: handler must be a table with isHandlable/process functions and a numeric priority", 1, true) ~= nil, label .. ": " .. tostring(err))
		mock.assertBlamesUser(err, "spec.dispatch.luau", "addHandler shape (" .. label .. ")")
	end
	local inst = Instance.new("Frame")
	for _, k in { 0, -1, 1.5 } do
		local ok, err = pcall(function() q.Dispatch.drive(inst, { [k] = q.Slot() }) end)
		assert(not ok and string.find(tostring(err), "Dispatch.drive: array keys must be positive integers (got " .. tostring(k) .. ")", 1, true) ~= nil, "key " .. tostring(k) .. ": " .. tostring(err))
		mock.assertBlamesUser(err, "spec.dispatch.luau", "drive key domain " .. tostring(k))
	end
	-- 2026-10-02: the check rides flatten's hash-part walk (`next(t, #t)`) instead of a
	-- separate `pairs` pass — a bad key next to a real array part, in a literal or
	-- assigned afterwards, is still caught with the same id and blame.
	local mixed: { { any } } = {
		{ "literal", function() return { q.Slot(), q.Slot(), [0] = q.Slot() } end },
		{ "assigned", function()
			local t: { [any]: any } = { q.Slot() }
			t[-1] = q.Slot()
			return t
		end },
		{ "explicit [1]", function() return { [1] = q.Slot(), [1.5] = q.Slot() } end },
	}
	for _, pair in mixed do
		local label, make = pair[1], pair[2]
		local inst2 = Instance.new("Frame")
		local ok, err = pcall(function() q.Dispatch.drive(inst2, make()) end)
		assert(not ok and string.find(tostring(err), "Quad0085 Dispatch.drive: array keys must be positive integers", 1, true) ~= nil, label .. ": " .. tostring(err))
		mock.assertBlamesUser(err, "spec.dispatch.luau", "drive key domain (" .. label .. ")")
	end
	local s = q.Slot()
	q.Dispatch.drive(inst, { s }) -- positive integer keys unaffected
	assert(s.Length:Get() == 0 and #inst:GetChildren() == 0, "normal drive still works")
	print("PASS")
end

print()
print("=== 21. round11 H-563/H-564/H-565/H-567/H-568 (2026-09-17) — 비브랜드 is* 헬퍼 무시·체인 구멍 index 거부·nil 키 게이트·base 브랜드 no-match 안내·priority NaN·addHandler dedup ===")
do
	local q: any = newQuad()
	-- H-563: a module-level `is*` helper that is not a brand predicate must not kill drive
	q.isEmpty = function(t: any): boolean
		return type(t) == "table" and next(t) == nil
	end
	q.isMobile = function(): boolean
		return true
	end
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, {}) -- used to die with "props must be a plain { ... } table (got Empty)"
	-- round13 H-698 / Q106 (2026-09-28): helpers that are false on `{}` and `0` slipped past the old
	-- probe and killed every non-empty props table; only registered predicates count now
	q.isNonEmptyList = function(t: any): boolean
		return type(t) == "table" and next(t) ~= nil
	end
	q.isHasName = function(t: any): boolean
		return type(t) == "table" and t.Name ~= nil
	end
	-- both modes: since 2026-10-01 the module scan runs on every drive only with q.debug on
	for _, debugOn in { false, true } do
		q.debug = debugOn
		q.Dispatch.drive(inst, {})
		local okNE, errNE = pcall(function()
			q.Dispatch.drive(inst, { Name = "x" })
		end)
		assert(okNE or string.find(tostring(errNE), "Quad0083", 1, true) == nil, "a non-empty props table is not mistaken for a quad value: " .. tostring(errNE))
		local okB, errB = pcall(function()
			q.Dispatch.drive(inst, q.Source(1))
		end)
		assert(not okB and string.find(tostring(errB), "props must be a plain", 1, true) ~= nil, "the H-470 gate still refuses a quad value: " .. tostring(errB))
		assert(string.find(tostring(errB), "Mobile", 1, true) == nil and string.find(tostring(errB), "Empty", 1, true) == nil, "diagnostics not polluted by the helpers: " .. tostring(errB))
	end
	q.debug = false
	q.isEmpty, q.isMobile, q.isNonEmptyList, q.isHasName = nil, nil, nil, nil
	-- H-564: an index that would leave a gap in the chain is refused
	q.Dispatch.addHandler({
		name = "OnlyK",
		keyType = "string",
		isHandlable = function(_i: any, k: any): boolean
			return k == "K"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(): (any?, boolean) -> ()
			return Quad.Void
		end,
	})
	local okG, errG = pcall(function()
		q.Dispatch.process(inst, "K", 1, 3)
	end)
	assert(not okG and string.find(tostring(errG), "Dispatch.process: index 3 would leave a gap in the chain", 1, true) ~= nil, tostring(errG))
	q.Dispatch.process(inst, "K", 1, 1)
	q.Dispatch.process(inst, "K", 1, 2) -- #list + 1 is fine (a delegating handler's index + 1)
	-- H-565: nil key fails fast with a Dispatch message, not a Relate leaf line
	local okK, errK = pcall(function()
		q.Dispatch.process(inst, nil, 1, 1)
	end)
	assert(not okK and string.find(tostring(errK), "Dispatch.process: key must not be nil", 1, true) ~= nil, tostring(errK))
	local okR, errR = pcall(function()
		q.Dispatch.retractFrom(inst, nil, 1)
	end)
	assert(not okR and string.find(tostring(errR), "Dispatch.retractFrom: key must not be nil", 1, true) ~= nil, tostring(errR))
	-- H-567: a BASE brand at a string key does not blame the provider. [2026-10-02] The Slot's own
	-- FALLBACK guard (Quad0141) is retired — the no-match message's string-key tail says the same thing.
	local okS, errS = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { Children = q.Slot() })
	end)
	assert(not okS and string.find(tostring(errS), "Quad0076 Dispatch: no handler matched key Children", 1, true) ~= nil and string.find(tostring(errS), "brand: Slot", 1, true) ~= nil and string.find(tostring(errS), "belongs in a numeric (array) slot", 1, true) ~= nil and string.find(tostring(errS), "provider", 1, true) == nil, "Slot at a string key: " .. tostring(errS))
	mock.assertBlamesUser(errS, "spec.dispatch.luau", "Slot at a string key")
	-- negative control: the retired guard's message is gone
	assert(string.find(tostring(errS), "Quad0141", 1, true) == nil, tostring(errS))
	local okT, errT = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { Thing = q.Tag() })
	end)
	assert(not okT and string.find(tostring(errT), "brand: Tag", 1, true) ~= nil and string.find(tostring(errT), "belongs in a numeric (array) slot", 1, true) ~= nil and string.find(tostring(errT), "provider", 1, true) == nil, "base brand hint: " .. tostring(errT))
	-- H-613: Context/Provider are base leaves too — must not get the "provider not initialized" hint
	local okCtx, errCtx = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { Thing = q.Context() })
	end)
	assert(not okCtx and string.find(tostring(errCtx), "brand: Context", 1, true) ~= nil and string.find(tostring(errCtx), "a Context is not a value for any key", 1, true) ~= nil and string.find(tostring(errCtx), "provider", 1, true) == nil, "base brand hint (Context, round13 E80: its own tail — the numeric-slot hint raised again): " .. tostring(errCtx))
	local okU, errU = pcall(function()
		q.Dispatch.drive(Instance.new("Frame"), { q.Store({ x = q.Source(1) }) })
	end)
	assert(not okU and string.find(tostring(errU), "a Store is not a value for any key", 1, true) ~= nil and string.find(tostring(errU), "string key", 1, true) == nil, "Store hint at a numeric key (탐사 I′ 3): " .. tostring(errU))
	-- H-568: NaN/inf priority refused; the same handler table twice registers once
	local okN, errN = pcall(function()
		q.Dispatch.addHandler({ isHandlable = function() return false end, priority = 0 / 0, process = function() return Quad.Void end })
	end)
	assert(not okN and string.find(tostring(errN), "priority must be a finite number", 1, true) ~= nil, tostring(errN))
	local h = { name = "Twice", isHandlable = function() return false end, priority = -5, process = function() return Quad.Void end }
	local before = #q.Dispatch.listHandlers()
	q.Dispatch.addHandler(h)
	q.Dispatch.addHandler(h)
	assert(#q.Dispatch.listHandlers() == before + 1, "identity dedup")
	print("PASS")
end

print("=== 22. round13 Q148 (2026-10-01) — 함수가 아닌 retractor(true·5·{}·__call 테이블)는 q.debug일 때만 그 자리에서 Quad0077; 평소는 지금처럼 nil만 ===")
do
	local callable = setmetatable({}, { __call = function() end })
	for label, ret in { ["true"] = true :: any, five = 5 :: any, table = {} :: any, callable = callable :: any } :: { [string]: any } do
		local q = newQuad()
		-- the first process of each instance returns Void (so the (A) re-process has a real retractor to call),
		-- every later one returns the bad value
		local seen: { [any]: true } = {}
		local h: Handler = {
			isHandlable = function(_inst: any, _k: any, v: any): boolean
				return type(v) == "string"
			end,
			priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
			process = function(inst: any): (any?, boolean) -> ()
				if not seen[inst] then
					seen[inst] = true
					return Quad.Void
				end
				return ret
			end,
		}
		q.Dispatch.addHandler(h)
		-- debug off: only nil is checked (hot path) — the bad value is accepted at process time as before
		local quiet = Instance.new("Frame")
		q.Dispatch.process(quiet, "k", "s", 1)
		q.Dispatch.process(quiet, "k", "t", 1)
		q.debug = true
		local inst = Instance.new("Frame")
		q.Dispatch.process(inst, "k", "s", 1) -- fresh install: Void
		local okA, errA = pcall(function()
			q.Dispatch.process(inst, "k", "t", 1) -- (A) same handler re-processing: bad value
		end)
		assert(not okA and string.find(tostring(errA), `Quad0077 Dispatch: handler (priority 0) must return a retractor function at key k, index 1 (got {typeof(ret)})`, 1, true) ~= nil, label .. " (A): " .. tostring(errA))
		mock.assertBlamesUser(errA, "spec.dispatch.luau", label .. " (A) blame")
		local okB, errB = pcall(function()
			q.Dispatch.process(inst, "other", "s", 1) -- (B) fresh install at another key: bad value
		end)
		assert(not okB and string.find(tostring(errB), "Quad0077", 1, true) ~= nil, label .. " (B): " .. tostring(errB))
	end
	-- a real function (and Void) still passes under debug
	local q = newQuad()
	q.debug = true
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "ok", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL))
	q.Dispatch.process(Instance.new("Frame"), "k", "s", 1)
	assert(log[1] == "ok:process:k:s:1", "function retractor passes under debug")
	print("PASS")
end

print()
print("=== 23. round13 Q135 후속 (2026-10-01) — debugOnly 핸들러: q.debug가 참인 스캔에서만 후보(호출 시점에 읽음), 꺼지면 조용히 빠짐; 평소 핸들러 순서 불변; Quad0266 모양 검사; listHandlers는 늘 포함 ===")
do
	local q = newQuad()
	local P = q.Dispatch.HANDLER_PRIORITY_NORMAL
	local log: { string } = {}
	local normal = makeLeaf(log, "normal", isString, P)
	local dbg = makeLeaf(log, "dbg", isString, P + 5)
	dbg.debugOnly = true
	q.Dispatch.addHandler(normal)
	q.Dispatch.addHandler(dbg)
	local inst = Instance.new("Frame")
	-- (1) toggled at call time: off -> the debug handler is not a candidate at all (no error), on -> it wins, off again
	assert(q.Dispatch.getHandler(inst, "k", "s") == normal, "debug off: debugOnly handler silently skipped")
	q.debug = true
	assert(q.Dispatch.getHandler(inst, "k", "s") == dbg, "debug on: debugOnly handler is scanned (higher priority wins)")
	q.debug = false
	assert(q.Dispatch.getHandler(inst, "k", "s") == normal, "debug off again: back to the production scan")
	-- a debugOnly handler that is the ONLY match: off -> no match (Quad0076 from process), on -> handled
	local only = makeLeaf(log, "only", isNumber, P + 6)
	only.debugOnly = true
	only.keyType = "string"
	q.Dispatch.addHandler(only)
	local okOff, errOff = pcall(function()
		q.Dispatch.process(inst, "n", 1, 1)
	end)
	assert(not okOff and string.find(tostring(errOff), "Quad0076", 1, true) ~= nil, "debug off: no candidate -> ordinary no-match: " .. tostring(errOff))
	q.debug = true
	q.Dispatch.process(inst, "n", 1, 1)
	assert(log[#log] == "only:process:n:1:1", "debug on: the debugOnly handler takes the key")
	q.Dispatch.retractFrom(inst, "n", 1)
	q.debug = false
	-- (2) debugOnly = false is an ordinary handler
	local plain = makeLeaf(log, "plain", isNumber, P + 7)
	plain.debugOnly = false
	q.Dispatch.addHandler(plain)
	assert(q.Dispatch.getHandler(inst, "x", 2) == plain, "debugOnly = false scans in production")
	-- (3) shape gate: a truthy non-boolean would silently stay in the production buckets
	for _, bad in { "yes" :: any, 1, {} } do
		local h = makeLeaf(log, "bad", isString, P)
		;(h :: any).debugOnly = bad
		local ok, err = pcall(function()
			q.Dispatch.addHandler(h)
		end)
		assert(not ok and string.find(tostring(err), `Quad0266 Dispatch.addHandler: debugOnly must be a boolean or nil (got {typeof(bad)})`, 1, true) ~= nil, "Quad0266: " .. tostring(err))
		mock.assertBlamesUser(err, "spec.dispatch.luau", "Quad0266 blame")
	end
	-- (4) listHandlers always lists them (with the field), whatever q.debug says; identity dedup covers them too
	q.Dispatch.addHandler(dbg)
	local seen = 0
	for _, h in q.Dispatch.listHandlers() do
		if h == dbg or h == only then
			assert(h.debugOnly == true, "field visible")
			seen += 1
		end
	end
	assert(seen == 2, `listHandlers lists each debugOnly handler once (got {seen})`)
	print("PASS")
end
do
	-- (5) production order is untouched: two tied production handlers keep the same winner after any number
	-- of debugOnly registrations, with debug off AND on (separate array + stable merge; the prototype's first
	-- cut shared one array and the unstable sort flipped a FALLBACK tie with debug off)
	local q = newQuad()
	local P = q.Dispatch.HANDLER_PRIORITY_NORMAL + 40
	local log: { string } = {}
	local t1 = makeLeaf(log, "t1", isString, P)
	local t2 = makeLeaf(log, "t2", isString, P)
	q.Dispatch.addHandler(t1)
	q.Dispatch.addHandler(t2)
	local inst = Instance.new("Frame")
	local winner = q.Dispatch.getHandler(inst, "k", "s")
	assert(winner == t1 or winner == t2, "one of the tied pair")
	local function never(): boolean
		return false
	end
	for i = 1, 12 do
		q.Dispatch.addHandler({
			debugOnly = true,
			priority = P + (i % 3) - 1, -- below, tied with, and above the pair
			isHandlable = never,
			process = function(): (any?, boolean) -> ()
				return q.Void
			end,
		})
		assert(q.Dispatch.getHandler(inst, "k", "s") == winner, `debug off: tie winner unchanged after {i} debugOnly registrations`)
		q.debug = true
		assert(q.Dispatch.getHandler(inst, "k", "s") == winner, `debug on: tie winner unchanged after {i} debugOnly registrations`)
		q.debug = false
	end
	print("PASS")
end

print("=== 24. 2026-10-01 사용자 결정 — 값의 핸들러는 그 값을 선언한 모듈이 등록(NoneHandler ← None.luau, StateHandler ← State.luau); Dispatch는 자기 말단(NilHandler·Processed* 셋)만; HIGH 밴드 술어는 서로 배타(등록 순서가 바뀌어도 동률 순서 무관) ===")
do
	local NoneModule = require("../src/None")
	local StateModule = require("../src/State")
	local q: any = newQuad()
	local function counts(): { [string]: number }
		local c = {}
		for _, h in q.Dispatch.listHandlers() do
			if h.name ~= nil then c[h.name] = (c[h.name] or 0) + 1 end
		end
		return c
	end
	local c = counts()
	for _, name in { "NoneHandler", "NilHandler", "StateHandler", "ProcessedModifierHandler", "ProcessedPreRefHandler", "ProcessedPostRefHandler" } do
		assert(c[name] == 1, `{name} registered exactly once (got {tostring(c[name])})`)
	end
	-- the owning modules' Init is the registration site: running it again is the RunInit no-op
	q:RunInit(NoneModule.Init)
	q:RunInit(StateModule.Init)
	local c2 = counts()
	assert(c2.NoneHandler == 1 and c2.StateHandler == 1, "RunInit of the owning Init is idempotent")
	assert(q.None == NoneModule.None, "the top-level re-export is the None module's value")
	-- HIGH band: every pair of predicates is disjoint over a sample of keys × values, so the unstable
	-- sort's tie order (which changes with registration order) never decides a match
	local inst = Instance.new("Frame")
	local src = q.Source(1)
	local samples: { any } = {
		q.None, src, src:Compute(function(s: any) return s end), src:Observer(function() end), q.Effect(function() end),
		q.Ref(), q.PreRef(), q.PostRef(), q.Slot(), q.Tag("t"), q.Attr({ a = 1 }), q.AttrKey("k"), q.Blocker(), "s", 5, {},
	}
	local high = {}
	for _, h in q.Dispatch.listHandlers() do
		if h.priority == q.Dispatch.HANDLER_PRIORITY_HIGH then table.insert(high, h) end
	end
	assert(#high >= 10, `HIGH band populated (got {#high})`)
	for _, k in { 1 :: any, "x" } do
		for i = 1, #samples + 1 do
			local v = samples[i] -- i = #samples + 1: nil
			local hits = {}
			for _, h in high do
				if h.isHandlable(inst, k, v) then table.insert(hits, h.name or "?") end
			end
			assert(#hits <= 1, `HIGH predicates overlap at key {tostring(k)}, value #{i}: {table.concat(hits, ", ")}`)
		end
	end
	print("PASS")
end

print()
print("=== round14 Q161·Q182 (2026-10-06) — q.Protocols.DispatchHint: 능력 브랜드에 속한 값은 매치 실패 때 자기 __dispatchHint(key)로 원인 문장을 준다(nil이면 일반 꼬리); Dispatch의 이름 분기(Store·Context/Provider)는 없다 ===")
do
	local q = newQuad()
	local DH = q.Protocols.DispatchHint
	assert(q.BrandPredicates ~= DH, "a separate table member, not inside BrandPredicates")
	-- registration: the base members, and nothing else
	local store, ctx, provider, blocker, key = q.Store({}), q.Context(), q.Context.Provider("P"), q.Blocker(), q.AttrKey("k")
	for label, v in { Store = store, Context = ctx, Provider = provider, Blocker = blocker, AttrKey = key } :: { [string]: any } do
		assert(DH:Is(v), label .. " is a DispatchHint member")
	end
	for label, v in { Slot = q.Slot(), Tag = q.Tag("t"), Source = q.Source(1), plain = {} } :: { [string]: any } do
		assert(not DH:Is(v), label .. " is not")
	end
	local function noMatch(k: any, v: any): string
		local ok, err = pcall(function() q.Dispatch.drive(Instance.new("Frame"), { [k] = v }) end)
		assert(not ok and string.find(tostring(err), "Quad0076", 1, true) ~= nil, tostring(err))
		return tostring(err)
	end
	-- each brand's own sentence (Q182 (a): Blocker / AttrKey were "belongs in a numeric slot" — which raised again there)
	local cases: { { any } } = {
		{ "Thing", blocker, "a Blocker is not a value for any key: apply it to a State (state:Apply(blocker))" },
		{ "Thing", key, "an AttrKey is a key, not a value: use it as the key ([q.AttrKey(name)] = value)" },
		{ "Thing", provider, "a Provider is not a value for any key" },
		{ "Thing", store, "a Store is not a value for any key" },
	}
	for _, c in cases do
		local err = noMatch(c[1], c[2])
		assert(string.find(err, c[3], 1, true) ~= nil and string.find(err, "belongs in a numeric (array) slot", 1, true) == nil, "own hint: " .. err)
	end
	local errBn = noMatch(1, blocker) -- the same hook at a numeric key
	assert(string.find(errBn, "a Blocker is not a value for any key", 1, true) ~= nil, errBn)
	-- a third-party member: the returned sentence follows " - "; nil falls back to the generic tail
	local Thing = {}
	Thing.__index = Thing
	function Thing.__dispatchHint(self: any, k: any): string?
		return if self.say then `custom sentence for {tostring(k)}` else nil
	end
	local loud, quiet = setmetatable({ say = true }, Thing), setmetatable({ say = false }, Thing)
	DH:Register(loud)
	DH:Register(quiet)
	local errLoud = noMatch("Thing", loud)
	assert(string.find(errLoud, " - custom sentence for Thing", 1, true) ~= nil, errLoud)
	local errQuiet = noMatch("Thing", quiet)
	assert(string.find(errQuiet, "this key may not be a field of this element", 1, true) ~= nil, "nil → the generic tail (unbranded, string key): " .. errQuiet)
	-- an unregistered value with the same method is not asked (membership is the test, not the method)
	local stray = setmetatable({ say = true }, Thing)
	assert(string.find(noMatch("Thing", stray), "custom sentence", 1, true) == nil, "not a member → not asked")
	-- the name branches are gone from Dispatch: a Store's and a Context's sentence is exactly what their own hook
	-- returns (the brand asks the value). round14 확인 패스 code-review 3: Dispatch reads the brand object itself
	-- (`Brand.luau`), not the public `q.Protocols` table — a user who overwrites that table entry (here: the whole
	-- table with an empty one, then nil) still gets `Quad0076` with the hook's sentence, not a nil-index crash
	local q2 = newQuad()
	for _, replaced in { { DispatchHint = QuadTypes.Brand() }, false } :: { any } do
		local q2any: any = q2
		q2any.Protocols = if replaced then replaced else nil
		for label, v in { Store = q2.Store({}), Context = q2.Context() } :: { [string]: any } do
			local ok, err = pcall(function() q2.Dispatch.drive(Instance.new("Frame"), { Thing = v }) end)
			assert(not ok and string.find(tostring(err), "Quad0076", 1, true) ~= nil
				and string.find(tostring(err), " - " .. (v :: any):__dispatchHint("Thing"), 1, true) ~= nil
				and string.find(tostring(err), "a quad value at a string key: it belongs in a numeric (array) slot", 1, true) == nil, label .. ": the hook's own sentence: " .. tostring(err))
		end
	end
	-- the nil-value tail (`H-257`) stays in Dispatch
	local okNil, errNil = pcall(function() q.Dispatch.process(Instance.new("Frame"), "Thing", nil, 1) end)
	assert(not okNil and string.find(tostring(errNil), "may be an unwrapped None", 1, true) ~= nil, tostring(errNil))
	print("PASS")
end

print()
print("=== round14 debug 감지기 3 (2026-10-06) — q.debug일 때 Dispatch.process 입구에서 claim되지 않은(파괴됐거나 quad가 만들지 않은) 인스턴스면 한 줄; drive도 지난다; 꺼져 있으면 0줄, 살아 있는 인스턴스는 0줄 ===")
do
	local LINE = "Dispatch: process on an instance that is not claimed by quad"
	local q = newQuad()
	local env: any = getfenv(q.Dispatch.process)
	local lines: { string } = {}
	local function capture(f: () -> ())
		table.clear(lines)
		local old = rawget(env, "print")
		env.print = function(...: any) table.insert(lines, table.concat({ ... }, " ")) end
		local ok, err = pcall(f)
		env.print = old
		assert(ok, tostring(err))
	end
	local function count(): number
		local n = 0
		for _, l in lines do if string.find(l, LINE, 1, true) ~= nil then n += 1 end end
		return n
	end
	q.Dispatch.addHandler({ name = "AnyK", isHandlable = function(_i: any, k: any) return k == "K" end, priority = 0,
		process = function() return Quad.Void end })
	local dead = Instance.new("Frame")
	dead:Destroy()
	q.debug = true
	capture(function() q.Dispatch.process(dead, "K", 1, 1) end)
	assert(count() == 1 and string.find(lines[1], "at key K", 1, true) ~= nil, "debug: one line for a destroyed instance: " .. table.concat(lines, " | "))
	capture(function() q.Dispatch.drive(dead, { K = 1 }) end)
	assert(count() == 1, "drive reaches it through process: " .. table.concat(lines, " | "))
	local foreign = Instance.foreign("Frame")
	capture(function() pcall(function() q.Dispatch.process(foreign, "K", 1, 1) end) end)
	assert(count() == 1, "never claimed by quad: one line")
	capture(function() q.Dispatch.drive(Instance.new("Frame"), { K = 1 }) end)
	assert(count() == 0, "a live claimed instance: 0 lines")
	-- round14 확인 패스 code-review 2: once per key — the delegating handlers (StateHandler, NoneHandler) re-dispatch
	-- the same key at index + 1; only the chain's index 1 asks (`Source(Source(None))` printed four lines before)
	q.Dispatch.addHandler({ name = "NilN", isHandlable = function(_i: any, k: any, v: any) return k == "N" and v == nil end, priority = 1,
		process = function() return Quad.Void end })
	capture(function() q.Dispatch.drive(dead, { N = q.Source(q.Source(q.None)) }) end)
	assert(count() == 1 and string.find(lines[1], "at key N", 1, true) ~= nil, "nested re-dispatch: one line per key: " .. table.concat(lines, " | "))
	q.debug = false
	capture(function() q.Dispatch.process(dead, "K", 2, 1) end)
	assert(count() == 0, "debug off: 0 lines")
	print("PASS")
end

print()
print("=== round14 Q154 — Dispatch.process의 index는 그 자리 체인의 다음 깊이(#list + 1)까지: 건너뛰면 핸들러가 불리기 전에 Quad0075(빈 체인의 2, 한 층짜리 체인의 3) ===")
-- Contract: errors/02 Quad0075 ("`index`가 그 자리 체인의 다음 자연스러운 깊이(`#list + 1`)보다 클 때"),
-- `.claude/base/dispatch-core-plan.md` (the chain list is a sequence without holes). Mutant (E69 DI07):
-- the gate one slot late (`#list + 2`) — a hole no unwind ever visits.
do
	local q = newQuad()
	local log: { string } = {}
	q.Dispatch.addHandler(makeLeaf(log, "L", isString, 0))
	local inst = Instance.new("Frame")
	local ok, err = pcall(function()
		q.Dispatch.process(inst, "K", "v", 2)
	end)
	assert(not ok and string.find(tostring(err), "Quad0075", 1, true) ~= nil, "index 2 on an empty chain: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.dispatch.luau", "Quad0075 blames the process line")
	assert(#log == 0, "refused before any handler ran: " .. table.concat(log, " | "))
	q.Dispatch.process(inst, "K", "v", 1)
	assert(#log == 1, "depth 1 seats the value")
	local ok2, err2 = pcall(function()
		q.Dispatch.process(inst, "K", "w", 3)
	end)
	assert(not ok2 and string.find(tostring(err2), "Quad0075", 1, true) ~= nil, "index 3 on a chain of one: " .. tostring(err2))
	assert(#log == 1, "the seated value was not touched: " .. table.concat(log, " | "))
	q.Dispatch.retractFrom(inst, "K", 1)
	assert(#log == 2 and string.find(log[2], "L:retract", 1, true) ~= nil, "the chain still unwinds as one layer: " .. table.concat(log, " | "))
	print("PASS")
end

print("=== ALL PASS ===")
