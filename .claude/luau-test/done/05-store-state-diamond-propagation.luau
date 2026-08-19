--[[
	검증 대상: Store/State의 push-invalidate(신호만) / pull-recompute(Get()
	시점 재계산) 전파 모델이 다이아몬드 의존성에서 정확히 동작하는지.

	배경: ROADMAP.md M0 1번째 항목. **[재작성, 2026-08-19]** 옛 버전은
	"이미 dirty면 더 아래로 전파하지 않는다"를 검증했는데, 그 규칙은
	확정된 Observer 계약(fn이 :Get()을 안 불러도 됨)과 모순돼 역전됨
	(`archive/invalidate-dedup-propagation-reversed.md`). 이 버전은
	현행 모델을 검증:
	  1. emit(invalidate 신호)은 자기 invalid 상태와 무관하게 *항상*
	     전파된다 — 이미 dirty인 노드도 다시 전파를 계속함(early-stop 없음)
	  2. 중복 **재계산**은 오직 :Get() 시점 캐시로만 막힌다(dirty 플래그가
	     "내 캐시가 낡았다" 표시일 뿐, 전파 게이트가 아님)
	  3. :Get()을 안 부르는 Observer는 다이아몬드에서 한 번의 source 변경마다
	     경로 수만큼(여기선 2번) 계속 운다 — 옛 모델처럼 두 번째부터
	     침묵하면 안 됨(핵심 음성 대조군)

	다이아몬드 구조:
	    source
	   /      \
	stateA    stateB
	   \      /
	   stateC (:With(stateA, stateB):Compute(...))

	실행: `luau 05-store-state-diamond-propagation.luau`
]]

local function makeSource(initial)
	local self = { value = initial, listeners = {} }
	function self:Get()
		return self.value
	end
	function self:Set(v)
		self.value = v
		self:Invalidate()
	end
	function self:Invalidate()
		-- source 자신은 dirty 개념이 없음(항상 최신) — 리스너에게 신호만 쏨
		for _, fn in self.listeners do
			fn()
		end
	end
	function self:OnInvalidate(fn)
		table.insert(self.listeners, fn)
	end
	return self
end

local invalidateCallCount = { stateA = 0, stateB = 0, stateC = 0 }
local computeCallCount = { stateA = 0, stateB = 0, stateC = 0 }

local function makeState(name, deps, computeFn)
	local self = {
		name = name,
		dirty = true, -- 처음엔 아직 계산 안 됐으니 dirty
		cached = nil,
		listeners = {},
	}
	function self:Invalidate()
		invalidateCallCount[name] += 1
		-- 핵심: invalid는 "내 캐시가 낡았다"는 표시일 뿐 전파 게이트가 아님
		-- — 이미 dirty였어도 무조건 다시 세팅하고 무조건 아래로 전파한다.
		self.dirty = true
		print(string.format("  [%s] invalidate #%d — 항상 전파", name, invalidateCallCount[name]))
		for _, fn in self.listeners do
			fn()
		end
	end
	function self:OnInvalidate(fn)
		table.insert(self.listeners, fn)
	end
	function self:Get()
		if self.dirty then
			computeCallCount[name] += 1
			print(string.format("  [%s] pull-recompute 실행 (총 %d번째)", name, computeCallCount[name]))
			local args = {}
			for i, d in deps do
				args[i] = d:Get()
			end
			self.cached = computeFn(table.unpack(args))
			self.dirty = false
		else
			print(string.format("  [%s] 캐시된 값 그대로 반환(재계산 없음)", name))
		end
		return self.cached
	end
	for _, d in deps do
		d:OnInvalidate(function()
			self:Invalidate()
		end)
	end
	return self
end

local source = makeSource(1)
local stateA = makeState("stateA", { source }, function(v)
	return v + 10
end)
local stateB = makeState("stateB", { source }, function(v)
	return v + 100
end)
local stateC = makeState("stateC", { stateA, stateB }, function(a, b)
	return a + b
end)

print("=== 1. 최초 Get() — 전부 계산돼야 함 ===")
print("stateC:Get() =", stateC:Get())
print("compute 호출 횟수:", computeCallCount.stateA, computeCallCount.stateB, computeCallCount.stateC)
assert(
	computeCallCount.stateA == 1 and computeCallCount.stateB == 1 and computeCallCount.stateC == 1,
	"최초 계산 횟수가 예상과 다름"
)

print()
print("=== 2. 재차 Get() — 캐시만 반환, 재계산 없어야 함 ===")
print("stateC:Get() =", stateC:Get())
assert(computeCallCount.stateC == 1, "invalidate 안 했는데 재계산이 일어남 (버그)")

print()
print("=== 3. source:Set() -> 다이아몬드 invalidate 전파(항상 전파, early-stop 없음) ===")
source:Set(2)
print(
	"invalidate 호출 횟수(stateC):",
	invalidateCallCount.stateC,
	"(stateA 경로 1번 + stateB 경로 1번 = 2번이어야 함 — 두 번 다 끝까지 실행돼야 함, 조기 종료 없음)"
)
assert(invalidateCallCount.stateC == 2, "다이아몬드 두 경로 모두 stateC까지 끝까지 전파돼야 함(early-stop 없음)")

print()
print("=== 4. invalidate 이후 Get() — 재계산은 딱 1번(중복 재계산 방지는 캐시 몫) ===")
print("stateC:Get() =", stateC:Get())
print(
	"compute 호출 횟수(stateC):",
	computeCallCount.stateC,
	"(2여야 함 — 1차 계산 + 이번 재계산 1번. invalidate가 2번 왔다고 재계산도 2번이면 버그)"
)
assert(computeCallCount.stateC == 2, "invalidate가 2번 와도 재계산은 캐시로 1번만 막혀야 함")

print()
print("=== 5. :Get()을 안 부르는 Observer — 매 source 변경마다 계속 울어야 함(옛 모델 음성 대조군) ===")
do
	local observerFireCount = 0
	-- state:Observer(fn)을 흉내: :Get()을 절대 호출하지 않는 순수 리스너
	stateC:OnInvalidate(function()
		observerFireCount += 1
	end)

	for i = 1, 3 do
		source:Set(2 + i)
	end

	print("3번의 source:Set() 이후 Observer 발화 횟수:", observerFireCount, "(다이아몬드라 회당 2번씩, 6이어야 함)")
	assert(
		observerFireCount == 6,
		"Get()을 안 부르는 Observer가 계속 안 울면(예: 2 근처에서 멈추면) 옛 '이미 dirty면 전파 중단' 모델로 회귀한 것"
	)
end

print()
print("모든 assert 통과 — '항상 전파 + Get() 시점 캐시 dedup' 모델이 예상대로 동작함")

--[[
	확인 포인트:
	1. 위 assert들이 전부 통과하는가.
	2. 3번 절에서 stateC의 invalidate 로그가 "이미 dirty" 같은 조기 종료
	   문구 없이 매번 "항상 전파"로 끝까지 도는지 눈으로 확인.
	3. 5번 절이 이 파일에서 가장 중요한 회귀 방지 장치 — 옛(역전된) 모델을
	   그대로 되돌려 넣으면(Invalidate 안에 `if self.dirty then return end`를
	   부활시키면) observerFireCount가 6이 아니라 2에서 멈추고 이 assert가
	   실패해야 정상.
	4. 이 스파이크는 실제 :With/:Compute API 모양이 아니라 최소 골격만
	   흉내낸 것 — 실제 구현 시 self/deps를 State 핸들로 lazy하게 넘기는
	   부분은 여기 반영 안 돼 있음, 이 파일은 오직 "전파 알고리즘 자체의
	   정확성"만 검증 대상.
]]
