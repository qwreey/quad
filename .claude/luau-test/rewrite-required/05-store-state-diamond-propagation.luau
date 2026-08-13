--[[
	!!! [2026-08-14] 재작성 대기 — 아래 코드는 폐기된 모델을 검증 중 !!!

	이 파일은 "이미 dirty로 표시된 노드는 더 아래로 전파하지 않는다"를
	assert하는데, 그 규칙이 확정된 Observer 계약(fn이 :Get()을 안 불러도
	됨)과 모순돼 역전됐음. 통과했다고 해서 현행 설계를 검증한 게 아님.
	  - 역전 근거/영향 범위: archive/invalidate-dedup-propagation-reversed.md
	  - 현행 모델: base/bind-system-plan.md "전파 모델 확정" /
	    "다이아몬드 의존성은 무엇이 푸는가"

	재작성 방향(STATUS.md와 동일):
	  1. emit은 자기 invalid 상태와 무관하게 *항상* 전파되는가
	  2. 중복 재계산은 :Get() 시점 캐시로만 막히는가 (재계산 1회는 그대로 유효)
	  3. :Get()을 안 부르는 Observer가 매 변경마다 계속 울리는가
	     — 옛 모델에선 두 번째부터 침묵했으므로 이게 딱 맞는 음성 대조군

	--- 이하 원문(옛 모델) ---

	검증 대상: Store/State의 push-invalidate(신호만) / pull-recompute(Get()
	시점 재계산) 전파 모델이 다이아몬드 의존성에서 정확히 동작하는지.

	배경: ROADMAP.md M0 1번째 항목 "Store/State push-invalidate ->
	pull-recompute propagation을 실제로 짜보기(다이아몬드 의존성 케이스
	포함 — 이미 invalid면 전파 중단되는지)".

	다이아몬드 구조:
	    source
	   /      \
	stateA    stateB
	   \      /
	   stateC (:With(stateA, stateB):Compute(...))

	검증할 것 두 가지:
	1. source가 바뀌면 invalidate 신호가 stateA/stateB를 거쳐 stateC까지
	   전파되는데, "이미 dirty로 표시된 노드는 더 이상 아래로 전파하지
	   않는다"는 방어가 있어야 다이아몬드에서 stateC가 두 경로로 두 번
	   invalidate 신호를 받아도 문제없이 처리됨(도달 자체는 두 번 일어나되,
	   두 번째는 즉시 조기 종료돼야 함).
	2. stateC:Get()을 실제로 호출했을 때, compute 함수가 정확히 1번만
	   실행되는가(다이아몬드 때문에 stateA 경로/stateB 경로 각각 한 번씩
	   총 2번 이상 실행되면 버그).

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
		-- source 자신은 dirty 개념이 없음(항상 최신) — 그냥 리스너에게 신호만 쏨
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
		if self.dirty then
			-- 핵심: 이미 dirty면 더 아래로 전파하지 않음(다이아몬드 방어)
			print(string.format("  [%s] 이미 dirty -> 전파 중단", name))
			return
		end
		print(string.format("  [%s] dirty로 표시, 아래로 전파", name))
		self.dirty = true
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
print("=== 3. source:Set() -> 다이아몬드 invalidate 전파 ===")
source:Set(2)
print(
	"invalidate 호출 횟수(stateC):",
	invalidateCallCount.stateC,
	"(stateA 경로 1번 + stateB 경로 1번 = 2번 호출은 정상, 단 2번째는 즉시 'already dirty'로 중단돼야 함)"
)

print()
print("=== 4. invalidate 이후 Get() — 정확히 1번만 재계산되는가 ===")
print("stateC:Get() =", stateC:Get())
print(
	"compute 호출 횟수(stateC):",
	computeCallCount.stateC,
	"(2여야 함 — 1차 계산 + 이번 재계산, 3 이상이면 다이아몬드 중복 재계산 버그)"
)
assert(computeCallCount.stateC == 2, "다이아몬드 의존성 때문에 stateC가 여러 번 재계산됨 (버그)")

print()
print("모든 assert 통과 — 다이아몬드 전파/재계산 모델이 예상대로 동작함")

--[[
	확인 포인트:
	1. 위 assert들이 전부 통과하는가(하나라도 실패하면 error로 죽고 스택
	   트레이스가 찍힘 — 그대로 알려줄 것).
	2. invalidateCallCount.stateC가 정확히 2(stateA 경로, stateB 경로 각각
	   1번씩 도달)이지만, 그 중 두 번째 호출은 "이미 dirty" 로그로 조기
	   종료되는지 눈으로 확인.
	3. 이 스파이크는 실제 :With/:Compute API 모양이 아니라 최소 골격만
	   흉내낸 것 — 실제 구현 시 self/deps를 State 핸들로 lazy하게 넘기는
	   부분(.claude/base/bind-system-plan.md "Store/State/Source 온톨로지"
	   절)은 여기 반영 안 돼 있음, 이 파일은 오직 "전파 알고리즘 자체의
	   정확성"만 검증 대상.
]]
