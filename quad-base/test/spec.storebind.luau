--[[
	StoreBind end-to-end contract — the first reactive update through the real
	pipeline. Sources: `ROADMAP.md` M4 checkboxes (both), `.claude/base/
	dispatch-core-plan.md` "Store 바인드는 특수 경우인가" section, scoped by
	`.claude/qa-request/m4-implementation-round13-brief.md` §1.

	Carries the leftover shares of two retired spikes: `04` (deep-index-first
	teardown through the REAL StoreBind + effect-level assertions — old store
	subscriptions actually 0, a dead store's Set never overwrites; `H-215`/
	`H-224`) and `03` (recursion terminates, `None`→`nil` handoff, priority
	scan — round13 §0 Q4 (a) retires the spike in favor of this spec).

	Re-emission is only ever induced through the real path (`src:Set` →
	observer → `Dispatch.process`) — a `drive` re-call is UB (`H-275`).
]]

local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

local Instance = mock.Instance
local newQuad = mock.newQuad
local addSpecLeaf = mock.addSpecLeaf
-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

type Handler = QuadTypes.Handler

-- Spec-local hash-key property leaves — the quad-roblox PropertyHandler
-- approximation: write the value onto the mock property bag so the "did the
-- update actually LAND" assertions are effect-level, not log-only (`H-224`).
-- Plain properties have no unset concept, but these log their retract calls
-- so the (A)/(B) hint contract is observable (spec-local test handler, same
-- idiom as spec.dispatch).
local function addPropLeaf(q: any, log: { string }, tag: string, match: (any) -> boolean, priority: number)
	q.Dispatch.addHandler({
		name = tag,
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return match(v)
		end,
		priority = priority,
		process = function(inst: any, k: any, v: any, index: number): (any?, boolean) -> ()
			inst[k] = v
			table.insert(log, `{tag}:process:{tostring(k)}:{tostring(v)}:{index}`)
			return function(nextValue: any?, retracting: boolean)
				table.insert(log, `{tag}:retract:{tostring(k)}:{tostring(nextValue)}:{tostring(retracting)}`)
			end
		end,
	} :: Handler)
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

local function countSubs(state: any): number
	local n = 0
	for _ in state._subs do
		n += 1
	end
	return n
end

print("=== 1. 첫 end-to-end — store 값 변경이 process를 다시 부르고, 첫 재발행에서 인덱스 2 retractor가 실제로 불린다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	addPropLeaf(q, log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL)
	local inst = Instance.new("Frame")
	local src = q.Source("a")
	q.Dispatch.drive(inst, { Title = src })
	-- 등록 즉시 1회 발화 — 최초 마운트와 재발행이 같은 경로(인덱스 2 위임)
	assert(inst.Title == "a", "initial mount lands the real value")
	expectLog(log, { "str:process:Title:a:2" })
	table.clear(log)

	-- 최초 마운트 직후 첫 재발행 — `SetStrong` 순서 버그의 증상 자리: 점유
	-- 마커가 h.process 뒤였다면 마운트 재귀의 인덱스 2 슬롯이 유실돼 여기서
	-- (A) retract 대신 (B) 신규 설치가 보인다
	src:Set("b")
	assert(inst.Title == "b", "re-emission re-runs the delegated process")
	expectLog(log, { "str:retract:Title:b:false", "str:process:Title:b:2" })
	print("PASS")
end

print()
print("=== 2. 타입 교대 — 이전 process가 반환했던 retractor가 (nil, true)로 정확히 불리고 새 핸들러 설치 ===")
do
	local q = newQuad()
	local log: { string } = {}
	addPropLeaf(q, log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL)
	addPropLeaf(q, log, "num", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL + 1)
	local inst = Instance.new("Frame")
	local src = q.Source("a")
	q.Dispatch.drive(inst, { Title = src })
	table.clear(log)

	src:Set(42) -- (B) at index 2: the sitting str retractor is torn down first
	assert(inst.Title == 42, "new type landed")
	expectLog(log, { "str:retract:Title:nil:true", "num:process:Title:42:2" })
	table.clear(log)

	src:Set("c") -- and back — the num retractor is consumed the same way
	assert(inst.Title == "c", "alternating back lands too")
	expectLog(log, { "num:retract:Title:nil:true", "str:process:Title:c:2" })
	print("PASS")
end

print()
print("=== 3. State<State<T>> — 인덱스 N/N+1 비충돌: 안쪽 재발행은 안쪽 슬롯만, 바깥 재발행은 구독을 갈아탄다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	addPropLeaf(q, log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL)
	local inst = Instance.new("Frame")
	local inner = q.Source("x")
	local outer = q.Source(inner)
	q.Dispatch.drive(inst, { Label = outer })
	-- 체인: StoreBind@1(outer) → StoreBind@2(inner) → str@3 — 같은 핸들러가
	-- 별개 슬롯(1·2)이라 identity 충돌 없음
	assert(inst.Label == "x", "double-wrapped value unwraps to the leaf")
	expectLog(log, { "str:process:Label:x:3" })
	table.clear(log)

	inner:Set("y") -- 안쪽만 — 인덱스 3의 (A)로 끝나야 하고 바깥 슬롯은 무접촉
	assert(inst.Label == "y", "inner emission flows through slot 3 only")
	expectLog(log, { "str:retract:Label:y:false", "str:process:Label:y:3" })
	table.clear(log)

	outer:Set(inner) -- 바깥 재발행, realv는 같은 inner — (A)@2: 옛 구독을
	-- 무르고 같은 state에 새 Observer로 갈아탄다(확정 모양 — dedup 없음)
	assert(inst.Label == "y", "same inner re-subscription re-lands the leaf value")
	expectLog(log, { "str:retract:Label:y:false", "str:process:Label:y:3" })
	collectgarbage()
	collectgarbage()
	assert(countSubs(inner) == 1, "exactly the fresh observer remains on inner — the replaced one is gone")
	assert(inst.Label == "y", "post-GC value untouched")
	print("PASS")
end

print()
print("=== 4. 실제 StoreBind 경유 (B) — 깊은 인덱스부터 정리 + 효과 수준: 옛 구독 0, 죽은 store가 값을 못 덮는다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	addPropLeaf(q, log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL)
	addPropLeaf(q, log, "num", isNumber, q.Dispatch.HANDLER_PRIORITY_NORMAL + 1)
	-- unbindLifetime 호출 시점을 관측 — StoreBind는 생명주기 넷을 발화 시점에
	-- `module.xxx`로 늦게 읽으므로(`H-174`) 스펙의 래퍼가 실제로 잡힌다
	local origUnbind = q.unbindLifetime
	q.unbindLifetime = function(value: any)
		table.insert(log, "unbind")
		origUnbind(value)
	end

	local inst = Instance.new("Frame")
	local inner = q.Source("x")
	local outer = q.Source(inner)
	q.Dispatch.drive(inst, { Label = outer })
	table.clear(log)

	outer:Set(999) -- realv 타입 교대 — (B)@2: 꼬리(3, leaf)부터 물러난 뒤에야
	-- 2의 StoreBind retractor(unbind)가 돈다(스파이크 04 잔여 몫의 순서 단언)
	assert(inst.Label == 999, "type change through the real StoreBind lands")
	expectLog(log, { "str:retract:Label:nil:true", "unbind", "num:process:Label:999:2" })
	table.clear(log)

	-- 효과 수준(`H-224` — 순서 로그만으로 닫지 말 것): retractor가 실제로 옛
	-- store 구독을 끊었는가
	inner:Set("dead")
	assert(inst.Label == 999, "a dead store's Set never overwrites the live value")
	expectLog(log, {})
	collectgarbage()
	collectgarbage()
	assert(countSubs(inner) == 0, "old store subscriptions are 0 after the re-emission tore slot 2 down")

	outer:Set("alive") -- 바깥 구독은 그대로 살아 있다
	assert(inst.Label == "alive", "outer subscription survived the inner teardown")
	print("PASS")
end

print()
print("=== 5. 스파이크 03 몫 — 배열 자리에서 None→nil 핸드오프, 재귀 종료, 부기까지 반응형으로 움직인다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	local sources: { any } = {}
	addSpecLeaf(q, sources, log) -- 배열 자리 문자열 leaf(자리 기여 1, `H-271` 공용)
	local inst = Instance.new("Frame")
	local src = q.Source("a")
	q.Dispatch.drive(inst, { src, "static" })
	-- 자리 1: StoreBind@1 → SpecLeaf@2(길이 1), 자리 2: SpecLeaf@1
	assert(q.Dispatch.getOffsetAt(inst, 2) == 1, "position 1 contributes length 1 while holding a string")
	table.clear(log)

	src:Set(q.None) -- StoreBind 재귀 → NoneHandler@2 → nil@3 → NilHandler(길이 0)
	expectLog(log, { "leaf:retract:1:nil:true" }) -- (B)@2 — leaf가 먼저 물러난다
	assert(q.Dispatch.getOffsetAt(inst, 2) == 0, "None collapses position 1's length — the sibling offset moved reactively")
	table.clear(log)

	src:Set("b") -- 다시 좁혀진다 — None 체인(2·3, retract는 둘 다 `Void`)이
	-- 물러나고 leaf가 재설치된다. addSpecLeaf는 retract만 기록하므로 로그 0
	assert(q.Dispatch.getOffsetAt(inst, 2) == 1, "back to a real value restores the length")
	expectLog(log, {})
	print("PASS")
end

print()
print("=== 6. 단순 철거와 사후 발화 — retractFrom이 구독을 끊고, Destroy된 inst로는 발화가 무시된다 ===")
do
	local q = newQuad()
	local log: { string } = {}
	addPropLeaf(q, log, "str", isString, q.Dispatch.HANDLER_PRIORITY_NORMAL)
	local inst = Instance.new("Frame")
	local src = q.Source("a")
	q.Dispatch.drive(inst, { Title = src })
	table.clear(log)

	q.Dispatch.retractFrom(inst, "Title", 1) -- 꼬리부터: leaf@2 → StoreBind@1
	expectLog(log, { "str:retract:Title:nil:true" })
	table.clear(log)
	src:Set("zzz")
	assert(inst.Title == "a", "after a plain retract the store no longer drives the property")
	expectLog(log, {})
	collectgarbage()
	collectgarbage()
	assert(countSubs(src) == 0, "plain retract released the subscription too")

	-- Destroy 경로: 계약상 retract는 안 불리고, 이후 발화는 canExecute가 무시
	-- (핸들러가 liveness를 재구현하지 않는다 — Observer 게이팅이 그 자리)
	local inst2 = Instance.new("Frame")
	local src2 = q.Source("v1")
	q.Dispatch.drive(inst2, { Title = src2 })
	table.clear(log)
	inst2:Destroy()
	src2:Set("v2") -- gcconn이 끊겨 canExecute=false — no-op이어야 한다
	expectLog(log, {})
	print("PASS")
end

print()
print("=== ALL PASS ===")
