--[[
	검증 대상: Dispatch가 (inst,k)별 핸들러 체인을 배열로 소유하고,
	retractUnder(inst,k,keep,v)가 꼬리부터 keep 앞까지 정리하는 설계
	(.claude/base/bind-system-plan.md "Dispatch 체인" 절)가 다단 체인
	(A->B->C)에서 실제로 정확한지 검증.

	배경: 2026-08-08 세 번째 세션 — "전역 소유자 슬롯 하나"로 추적하는
	1차 설계가 재귀/래핑 핸들러(A가 B로 위임하는데 A 자신도 나중에
	재계산되는 경우)에서 깨지는 걸 반례로 확인하고 체인 방식으로 교체함.
	CLAUDE.md는 "M2/M4 스파이크 검증 목록에 chains/retractUnder가 다단
	체인에서 실제로 정확히 동작하는지가 새로 추가됨(추론만으로 확정된 것)"
	이라고 명시 — 아직 실제 Luau로 돌려본 적 없음. 이 파일이 그 검증.

	시나리오: StoreA(바깥 store) -> StoreBind가 잡아서 그 값을 다시
	Dispatch.process로 재귀 -> 그 값이 또 다른 Store(StoreB, "이중 store"
	케이스를 흉내)일 때 두 번째 StoreBind가 또 잡아서 재귀 -> 최종적으로
	PropertyHandler가 실제 세팅. 즉 A(StoreBind)->B(StoreBind again)->C(Property)
	3단 체인. ("Store가 Store를 담지 않는다"가 설계상 확정이라 이 자체는
	UB에 가까운 입력이지만, 체인 메커니즘이 다단에서 실제로 버티는지는
	그것과 별개로 확인해둘 가치가 있어 일부러 스트레스 테스트로 씀.)

	실행: `luau 04-dispatch-chain-retractUnder.luau`

	참고(2026-08-09 세션 갱신 반영): 03번과 동일하게 아래 `subscribe(fn)`은
	이 스파이크 전용 단순화 — 실제로는 `state:Observer(fn)` +
	`bindLifetime`/`unbindLifetime` 조합(`.claude/base/lifecycle-pattern.md`)을
	쓴다. `retract`가 할 일이 "구독 해제"라는 본질은 같아서 체인/
	retractUnder 로직 검증엔 영향 없음.
]]

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

-- Relate 대용 (weak-key까지는 이 스파이크에서 안 다룸, 순수 로직 검증이 목적 —
-- weak-key/GC 쪽은 07-relate-weak-table-gc.luau가 따로 다룸)
local chains = {} -- [inst] = { [k] = { handler, handler, ... } }
local function chainFor(inst, k)
	chains[inst] = chains[inst] or {}
	chains[inst][k] = chains[inst][k] or {}
	return chains[inst][k]
end

local Dispatch = {}
local handlers = {}

function Dispatch.addHandler(h)
	table.insert(handlers, h)
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
	if not h then
		print(string.format("    (매치 없음: %s.%s = %s)", tostring(inst), tostring(k), tostring(v)))
		return
	end
	local list = chainFor(inst, k)
	table.insert(list, h)
	print(string.format("    [chain push] %s.%s <- %s (체인 길이=%d)", tostring(inst), tostring(k), h.name, #list))
	h.process(inst, k, v)
end

-- .claude/base/bind-system-plan.md의 pseudo code 그대로 옮김
function Dispatch.retractUnder(inst, k, keep, v)
	local list = chainFor(inst, k)
	local cutoff = 0
	if keep then
		for i, h in list do
			if h == keep then
				cutoff = i
				break
			end
		end
	end
	for i = #list, cutoff + 1, -1 do
		local retractedHandler = list[i]
		local passedValue = (i == cutoff + 1) and v or nil
		print(
			string.format(
				"    [retractUnder] %s.%s: %s.retract(v=%s) 호출, 체인에서 제거",
				tostring(inst),
				tostring(k),
				retractedHandler.name,
				tostring(passedValue)
			)
		)
		retractedHandler.retract(inst, k, passedValue)
		list[i] = nil
	end
end

-- 핸들러: StoreBind (self 식별을 위해 핸들러 테이블 자기 자신을 process 안에서 캡처)
local function makeStoreBindHandler(name, priority)
	local self
	self = {
		name = name,
		priority = priority,
		isHandlable = function(inst, k, v)
			return isStoreLike(v)
		end,
		process = function(inst, k, store)
			local function reprocess(realv)
				print(
					string.format(
						"  [%s] %s.%s 재계산 -> retractUnder(keep=self) 먼저, 그 다음 재귀 process",
						name,
						tostring(inst),
						tostring(k)
					)
				)
				Dispatch.retractUnder(inst, k, self, realv)
				Dispatch.process(inst, k, realv)
			end
			store:subscribe(reprocess)
			reprocess(store:get())
		end,
		retract = function(inst, k, v)
			print(string.format("  [%s.retract] 나 자신(구독) 정리", name))
		end,
	}
	return self
end

Dispatch.addHandler(makeStoreBindHandler("StoreBindA", 900))
Dispatch.addHandler({
	name = "PropertyHandler",
	priority = 0,
	isHandlable = function()
		return true
	end,
	process = function(inst, k, v)
		print(string.format("  [PropertyHandler] 실제 세팅: %s.%s = %s", tostring(inst), tostring(k), tostring(v)))
	end,
	retract = function(inst, k, v)
		print(string.format("  [PropertyHandler.retract] 이전 값 무름"))
	end,
})

print('=== 1단계: StoreA(값="hello") 바인드 ===')
local storeA = makeStore("hello")
Dispatch.process("Frame1", "Text", storeA)
print("  현재 체인 길이:", #chainFor("Frame1", "Text"))

print()
print("=== 2단계: StoreA 값을 다른 일반 값으로 바꿈(체인이 A 밑을 정확히 정리하는가) ===")
storeA:set("world")
print("  현재 체인 길이:", #chainFor("Frame1", "Text"), "(A->Property 2개여야 정상)")

print()
print("=== 3단계: StoreA 값을 store로 다시 바꿔서(다단 체인 유도) 스트레스 테스트 ===")
local storeB = makeStore("nested")
storeA:set(storeB)
print("  현재 체인 길이:", #chainFor("Frame1", "Text"))

print()
print("=== 4단계: 안쪽 StoreB 값을 바꿔서, retractUnder(keep=StoreBindA 자신)가")
print("    바깥 A는 안 건드리고 그 밑(B 이후)만 정리하는지 확인 ===")
storeB:set("nested-changed")

--[[
	확인 포인트 (이게 이 파일의 핵심 목적):
	1. 2단계에서 storeA:set("world") 이후 체인 길이가 정확히 2(A, Property)로
	   돌아오는가 — retractUnder가 이전 PropertyHandler를 정리하고 새로
	   push했는가, 아니면 계속 누적돼서 체인이 무한정 길어지는가?
	   (누적되면 버그 — 체인이 GC 안 되는 메모리 누수이자 논리 오류)
	2. 3단계~4단계에서 A(StoreBindA) 자신은 살아남고, 그 밑(구 PropertyHandler
	   또는 구 중첩 핸들러)만 정리되는가 — "A가 자길 엉뚱하게 retract하는"
	   버그(CLAUDE.md가 기각한 1차 설계의 실패 모드)가 재현되지 않는가?
	3. 체인 길이가 각 단계마다 예상한 값과 정확히 일치하는가(주석에 적어둔
	   기대값과 실제 print 결과를 비교).
	4. 스택 오버플로 없이 전부 정상 종료되는가.
]]
