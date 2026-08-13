--[[
	검증 대상: process(inst,k,v)/retract(inst,k,v) 기반 재귀 재-dispatch
	모델(.claude/base/dispatch-core-plan.md "확정된 디스패치 모델" 절)이 실제
	Luau 함수 재귀로 자연스럽게 짜이는지, 우선순위 스캔(isHandlable)이
	기대대로 동작하는지에 대한 최소 스파이크.

	배경: ROADMAP.md M0 3번째 항목 "process/retract 재귀 재-process
	디스패치를 실제로 짜보기(store-bind 핸들러 하나 + isHandlable
	우선순위 스캔 포함)".

	여기서는 다단 체인(retractFrom)까지는 다루지 않음 — 그건
	04-dispatch-chain-retractFrom.luau가 별도로 다룸(단일 owner 슬롯
	추적이 왜 깨지는지까지 포함). 이 파일은 "재귀 자체가 도는가", "우선순위
	스캔이 맞는 핸들러를 고르는가", "None -> nil 재디스패치가 다음
	핸들러로 자연히 좁혀지는가"까지만 검증.

	실행: `luau 03-recursive-store-bind-dispatch.luau`

	참고(2026-08-09 세션 갱신 반영): 아래 makeStore의 `subscribe(fn)`은
	이 스파이크 전용으로 단순화한 것 — 실제 base 설계는 StoreBind가
	`state:Observer(fn)` + `bindLifetime(inst, observer)`/
	`unbindLifetime(observer)`(2026-08-14 다섯 번째 세션에 unbind가
	1-인자로 정정됨, `.claude/base/lifecycle-pattern.md`)
	조합으로 구독/해제한다. 여기서 검증하려는 건 그 구독 배관이 아니라
	"우선순위 스캔+재귀 process/retract 자체가 Luau에서 잘 도는가"라서
	영향 없음 — 실제 Handler 구현 짤 때는 subscribe 대신 저 조합을 쓸 것.
]]

local None = setmetatable({}, { __tostring = function()
	return "<None>"
end })

-- 아주 단순화된 "Store" 시늉 — 실제로는 Source/State가 되겠지만 여기선
-- 그냥 값+구독자 리스트를 가진 테이블
local StoreTag = {}
local function isStoreLike(v)
	return type(v) == "table" and v[StoreTag] == true
end
local function makeStore(initial)
	local self = { [StoreTag] = true, value = initial, subscribers = {} }
	function self.get(_self)
		return self.value
	end
	function self.set(_self, v)
		self.value = v
		for _, fn in self.subscribers do
			fn(v)
		end
	end
	function self.subscribe(_self, fn)
		table.insert(self.subscribers, fn)
	end
	return self
end

-- Dispatch 최소 스파이크
local Dispatch = {}
local handlers = {}

function Dispatch.addHandler(handler)
	table.insert(handlers, handler)
	table.sort(handlers, function(a, b)
		return a.priority > b.priority
	end)
end

function Dispatch.getHandler(inst, k, v)
	for _, h in handlers do
		if h.isHandlable(inst, k, v) then
			return h
		end
	end
	return nil
end

function Dispatch.process(inst, k, v)
	local h = Dispatch.getHandler(inst, k, v)
	if h then
		print(string.format("  [Dispatch.process] inst=%s k=%s -> handler=%s", tostring(inst), tostring(k), h.name))
		h.process(inst, k, v)
	else
		print(string.format("  [Dispatch.process] inst=%s k=%s -> 매치되는 핸들러 없음!", tostring(inst), tostring(k)))
	end
end

-- 핸들러 1: NoneHandler (해시 파트 전용, 매우 높은 우선순위)
Dispatch.addHandler({
	name = "NoneHandler",
	priority = 1000,
	isHandlable = function(inst, k, v)
		return v == None
	end,
	process = function(inst, k, v)
		Dispatch.process(inst, k, nil) -- 재귀 재호출
	end,
	retract = function() end,
})

-- 핸들러 2: StoreBind (store-like 값을 잡아 재귀 재-dispatch)
Dispatch.addHandler({
	name = "StoreBind",
	priority = 900,
	isHandlable = function(inst, k, v)
		return isStoreLike(v)
	end,
	process = function(inst, k, store)
		local function reprocess(realv)
			print(
				string.format(
					"  [StoreBind] %s.%s 값 변경 감지 -> 재귀 process(realv=%s)",
					tostring(inst),
					tostring(k),
					tostring(realv)
				)
			)
			Dispatch.process(inst, k, realv)
		end
		store:subscribe(reprocess)
		reprocess(store:get()) -- 최초 1회 적용 (state:Observer의 "등록 즉시 1회 실행"을 흉내)
	end,
	retract = function(inst, k, v)
		print(string.format("  [StoreBind.retract] %s.%s 구독 해제(흉내)", tostring(inst), tostring(k)))
	end,
})

-- 핸들러 3: PropertyHandler (catch-all, 가장 낮은 우선순위)
Dispatch.addHandler({
	name = "PropertyHandler",
	priority = 0,
	isHandlable = function()
		return true
	end,
	process = function(inst, k, v)
		print(string.format("  [PropertyHandler] 실제 세팅: %s.%s = %s", tostring(inst), tostring(k), tostring(v)))
	end,
	retract = function() end,
})

print("=== 1. Store 값을 프로퍼티에 바인드 ===")
local colorStore = makeStore("red")
Dispatch.process("Frame1", "BackgroundColor", colorStore)

print()
print("=== 2. Store 값 변경 -> 재귀 재-dispatch로 실제 값이 다시 세팅되는가 ===")
colorStore:set("blue")

print()
print("=== 3. None 센티널 -> nil로 재귀 재-dispatch되어 PropertyHandler로 흘러가는가 ===")
Dispatch.process("Frame1", "Rotation", None)

print()
print("=== 4. 무한 재귀 없이 종료되는가 ===")
print("위 1~3에서 스택 오버플로/무한 루프 없이 정상 종료됐다면 통과")

--[[
	확인 포인트:
	1. 콘솔에 handler=StoreBind가 먼저 찍히고, 그 다음 재귀로
	   handler=PropertyHandler가 찍히는가?
	2. colorStore:set("blue") 이후 PropertyHandler가 다시(blue로) 불리는가?
	3. None 케이스가 PropertyHandler까지 자연스럽게 흘러가는가(중간에
	   NoneHandler가 한 번만 관여하고 끝나는가)?
	4. table.sort 기반 우선순위 스캔이 매번 안정적으로 같은 순서를 내는가
	   (Luau table.sort는 unstable sort일 수 있음 — 동일 priority 핸들러가
	   여러 개면 순서가 실행마다 바뀔 수 있다는 점 주의. 실제 구현에서는
	   priority를 세밀하게 나누거나 등록 순서를 tie-breaker로 쓰는 걸
	   검토할 가치가 있어 보임 — 지금 base 문서엔 이 tie-break 규칙이
	   명시돼 있지 않음, 실제로 문제가 되면 base/bind-system-plan.md에
	   추가할 것).
]]
