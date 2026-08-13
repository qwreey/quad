--[[
	검증 대상: 인덱스 기반 `Dispatch` 체인(2026-08-13 다섯 번째 세션 전면
	재설계, `.claude/base/bind-system-plan.md` "Dispatch 체인" 절)이 다단
	재귀 위임에서 실제로 정확한지.

	새 모델의 요점(옛 모델과 뭐가 다른지):
	  - `chains[inst][k]`는 **핸들러 배열이 아니라 `{[index] = retractor}`**.
	    index = 같은 키 안에서의 재귀 깊이(같은 키 재귀는 index+1, 다른
	    키로 위임하면 그 키에서 다시 1부터).
	  - Handler 계약이 `process`/`retract` 2-메소드에서 **`process`가 자기
	    retract 클로저를 반환하는 1-메소드**로 축소.
	  - `Dispatch.retractFrom(inst,k,index,v)` 하나가 옛
	    `retractUnder`/`retractSelfAndUnder` 둘을 대체(자기 포함/미만은
	    호출자가 넘기는 인덱스로 표현).

	**이 파일은 2026-08-13 감사에서 전면 재작성됨.** 이전 버전
	(`04-dispatch-chain-retractUnder.luau`)은 핸들러 **객체 identity**로
	체인을 추적하던 옛 설계와, 그 위에 얹혔던 "같은 (inst,k)에 같은 핸들러
	중복 push면 즉시 error" 가드를 검증하고 있었는데 — 그 가드는 인덱스
	기반 재설계로 **없어졌고**, `State<State<T>>`는 UB가 아니라 정상 지원
	대상으로 재정정됨. 즉 옛 파일은 설계와 정반대를 테스트하고 있었음.

	검증 항목:
	  A. 3단 체인(StoreBind -> StoreBind -> Property)이 인덱스 1/2/3으로
	     안 겹치고 쌓이는가 (= `State<State<T>>` 정상 동작)
	  B. 안쪽 store 재발행 시 index 3만 갈리고 1/2는 유지되는가
	  C. 바깥 store 재발행 시 index 2/3이 **깊은 쪽부터** 정리되는가
	  D. `retractFrom`의 hint(`v`)가 정확히 target index에만 전달되는가
	  E. **[감사 회귀 테스트]** `chains:SetStrong`을 `handler.process`
	     *뒤에* 두면 최초 마운트에서 하위 retractor가 유실되는가
	     (음성 대조군 — 이 버그가 실재함을 증명, 2026-08-13 감사에서 발견)

	실행: `luau 04-dispatch-chain-retractFrom.luau`

	캐비엇: 아래 `subscribe(fn)`은 이 스파이크 전용 단순화 — 실제로는
	`state:Observer(fn)` + `bindLifetime`/`unbindLifetime` 조합
	(`.claude/base/lifecycle-pattern.md`). 다만 **이 스파이크의 retractor는
	no-op 스텁이 아니라 실제로 구독을 끊는다** — 옛 04번이 no-op print
	스텁이라 체인 파손을 못 잡는 사각지대였던 걸 그대로 반복하지 않기 위함.
]]

local log = {}
local function say(fmt, ...)
	local line = string.format(fmt, ...)
	table.insert(log, line)
	print(line)
end

--==========================================================================
-- 아주 작은 Store/State 스텁
--==========================================================================

local StoreMT = {}
StoreMT.__index = StoreMT

local function Store(value, name)
	return setmetatable({ _v = value, _subs = {}, _name = name }, StoreMT)
end

local function isState(v)
	return type(v) == "table" and getmetatable(v) == StoreMT
end

function StoreMT:Get()
	return self._v
end

-- 구독. 반환값 = 구독 해제 함수(실제 구현의 unbindLifetime 자리)
function StoreMT:subscribe(fn)
	local token = {}
	self._subs[token] = fn
	return function()
		self._subs[token] = nil
	end
end

function StoreMT:Set(v)
	self._v = v
	for _, fn in pairs(self._subs) do
		fn()
	end
end

function StoreMT:subCount()
	local n = 0
	for _ in pairs(self._subs) do
		n += 1
	end
	return n
end

--==========================================================================
-- Dispatch — 인덱스 기반. storeFirst 플래그로 올바른 순서/버그 순서를 전환
--==========================================================================

local NOOP = function() end

local function makeDispatch(opts)
	local storeChainBeforeProcess = opts.storeChainBeforeProcess
	local chains = {} -- {[inst] = {[k] = {[index] = retractor}}}
	local D = {}
	local handlers = {}

	function D.addHandler(h)
		table.insert(handlers, h)
		table.sort(handlers, function(a, b)
			return a.priority > b.priority
		end)
	end

	function D.getHandler(inst, k, v)
		for _, h in ipairs(handlers) do
			if h.isHandlable(inst, k, v) then
				return h
			end
		end
		error(string.format("Dispatch: 매치되는 핸들러 없음 (k=%s, v=%s)", tostring(k), tostring(v)))
	end

	function D.process(inst, k, v, index)
		local byKey = chains[inst]
		if not byKey then
			byKey = {}
			chains[inst] = byKey
		end
		local list = byKey[k]
		if not list then
			list = {}
			if storeChainBeforeProcess then
				byKey[k] = list -- 올바른 순서: handler.process 호출 전에 등록
			end
		end
		if list[index] ~= nil then
			error(string.format("Dispatch: (inst,%s) 인덱스 %d는 이미 점유됨", tostring(k), index))
		end
		list[index] = NOOP -- 점유 마커(재귀 중 hole 방지 + 같은 index 재진입 가드)
		local h = D.getHandler(inst, k, v)
		list[index] = h.process(inst, k, v, index)
		if not storeChainBeforeProcess then
			byKey[k] = list -- 버그 순서: 재귀가 만든 별도 테이블을 덮어씀
		end
	end

	function D.retractFrom(inst, k, index, v)
		local byKey = chains[inst]
		local list = byKey and byKey[k]
		if not list then
			return
		end
		for i = #list, index, -1 do
			local retractor = list[i]
			if retractor then
				retractor(if i == index then v else nil)
			end
			list[i] = nil
		end
	end

	function D.depth(inst, k)
		local byKey = chains[inst]
		local list = byKey and byKey[k]
		return if list then #list else 0
	end

	return D
end

--==========================================================================
-- 핸들러 두 개 — StoreBind(재귀 위임) / Property(말단)
--==========================================================================

local applied = {} -- inst.k -> 마지막으로 실제 세팅된 값
local hintSeen = {} -- 각 핸들러가 자기 클로저에서 받은 hintValue 기록

local function makeHandlers(D)
	local StoreBind = {
		priority = 100,
		isHandlable = function(_, _, v)
			return isState(v)
		end,
	}

	function StoreBind.process(inst, k, state, index)
		local unsubscribe = state:subscribe(function()
			local realv = state:Get()
			say("    [StoreBind idx=%d] %s 재발행 -> retractFrom(idx=%d) 후 재위임", index, state._name, index + 1)
			D.retractFrom(inst, k, index + 1, realv)
			D.process(inst, k, realv, index + 1)
		end)
		-- 등록 즉시 1회(실제 Observer 계약과 동일)
		local realv = state:Get()
		D.retractFrom(inst, k, index + 1, realv)
		D.process(inst, k, realv, index + 1)

		return function(hintValue)
			table.insert(hintSeen, string.format("StoreBind(%s)@%d hint=%s", state._name, index, tostring(hintValue)))
			say("    [StoreBind idx=%d] retractor 호출 — %s 구독 해제 (hint=%s)", index, state._name, tostring(hintValue))
			unsubscribe()
		end
	end

	local Property = {
		priority = 1,
		isHandlable = function()
			return true -- 최하위 폴백
		end,
	}

	function Property.process(inst, k, v, index)
		applied[inst .. "." .. k] = v
		say("    [Property idx=%d] %s.%s = %s", index, inst, k, tostring(v))
		return function(hintValue)
			table.insert(hintSeen, string.format("Property@%d hint=%s", index, tostring(hintValue)))
			say("    [Property idx=%d] retractor 호출 (hint=%s)", index, tostring(hintValue))
		end
	end

	D.addHandler(StoreBind)
	D.addHandler(Property)
end

--==========================================================================
-- 시나리오 실행기
--==========================================================================

local function runScenario(label, storeChainBeforeProcess)
	say("")
	say("=====================================================")
	say("%s (chains 저장 순서: %s)", label, if storeChainBeforeProcess then "process 前(올바름)" else "process 後(버그 재현)")
	say("=====================================================")

	applied, hintSeen = {}, {}
	local D = makeDispatch({ storeChainBeforeProcess = storeChainBeforeProcess })
	makeHandlers(D)

	local inner = Store("v1", "inner")
	local outer = Store(inner, "outer")

	say("")
	say("[1] 최초 마운트 — outer(State<State<string>>)를 인덱스 1로 진입")
	D.process("Frame", "Text", outer, 1)
	say("  -> 체인 깊이 = %d (기대: 3 — StoreBind/StoreBind/Property)", D.depth("Frame", "Text"))
	say("  -> Frame.Text = %s (기대: v1)", tostring(applied["Frame.Text"]))
	say("  -> outer 구독 %d개 / inner 구독 %d개 (기대: 1 / 1)", outer:subCount(), inner:subCount())

	say("")
	say("[2] 안쪽 store 재발행 — index 3만 갈리고 1/2는 유지돼야 함")
	inner:Set("v2")
	say("  -> 체인 깊이 = %d (기대: 3)", D.depth("Frame", "Text"))
	say("  -> Frame.Text = %s (기대: v2)", tostring(applied["Frame.Text"]))
	say("  -> outer 구독 %d개 / inner 구독 %d개 (기대: 1 / 1 — 둘 다 살아있어야)", outer:subCount(), inner:subCount())

	say("")
	say("[3] 바깥 store 재발행(새 inner2) — index 2/3이 깊은 쪽부터 정리돼야 함")
	local inner2 = Store("w1", "inner2")
	outer:Set(inner2)
	say("  -> 체인 깊이 = %d (기대: 3)", D.depth("Frame", "Text"))
	say("  -> Frame.Text = %s (기대: w1)", tostring(applied["Frame.Text"]))
	say(
		"  -> outer %d / inner(옛) %d / inner2 %d (기대: 1 / 0 / 1 — 옛 inner 구독이 끊겨야)",
		outer:subCount(),
		inner:subCount(),
		inner2:subCount()
	)

	say("")
	say("[4] 옛 inner를 다시 건드려도 아무 일도 없어야 함(구독이 끊겼으므로)")
	inner:Set("STALE")
	say("  -> Frame.Text = %s (기대: w1 — STALE로 안 바뀌어야)", tostring(applied["Frame.Text"]))

	say("")
	say("[5] 전체 철거 — retractFrom(index=1)")
	D.retractFrom("Frame", "Text", 1, nil)
	say("  -> 체인 깊이 = %d (기대: 0)", D.depth("Frame", "Text"))
	say("  -> outer %d / inner2 %d (기대: 0 / 0)", outer:subCount(), inner2:subCount())

	say("")
	say("[hint 전달 기록] retractFrom(idx,v)의 v가 target index에만 가는지:")
	for _, l in ipairs(hintSeen) do
		say("    %s", l)
	end
end

runScenario("A~D. 정상 설계", true)
runScenario("E. 음성 대조군 — chains 저장을 process 뒤로 옮기면", false)

say("")
say("=====================================================")
say("판정 가이드")
say("=====================================================")
say([[
  * 첫 번째(정상) 시나리오에서 [1]의 체인 깊이가 3이 아니면 — 인덱스
    누적 자체가 틀린 것. base 문서의 index+1 규칙부터 다시 볼 것.
  * [3]에서 "inner(옛) 구독 0"이 안 나오면 — 깊은 인덱스부터 정리하는
    retractFrom 순회가 깨진 것. [4]에서 STALE이 반영되는 것으로도 같은
    증상이 드러남.
  * 두 번째(음성 대조군) 시나리오에서 [1]의 체인 깊이가 **1**로 나오면 —
    2026-08-13 감사가 지적한 버그가 재현된 것: 재귀 위임이 자기만의
    list 테이블을 만들어 저장했다가 바깥 process가 그걸 덮어써서 index
    2/3의 retractor가 통째로 유실됨. 이어서 [3]에서 옛 inner 구독이
    안 끊기고 [4]에서 STALE이 반영되면 그 유실이 실제 동작 차이로
    이어진다는 확인.
  * 대조군이 정상 시나리오와 똑같이 나온다면(= 버그가 재현 안 되면)
    이 스파이크의 모델링이 실제 구현과 어긋난 것이니, 결론을 내리기
    전에 스파이크 쪽을 먼저 의심할 것.
]])
