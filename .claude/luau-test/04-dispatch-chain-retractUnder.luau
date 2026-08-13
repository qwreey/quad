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

	**[2026-08-13 세션 정정]** 바로 위 문단의 마지막 문장은 3단계~4단계
	(store-in-store, 즉 `State<State<T>>`에 대응하는 시나리오)에 대해서는
	틀렸음이 드러남 — 이 스파이크의 `retract`는 print만 하는 완전 no-op이라
	"자기 자신을 스스로 retract하는" 버그가 실제로 일어나도 아무 부작용
	없이 넘어가버려서, 겉보기엔(체인 길이만 보면) 3~4단계가 정상으로
	보임. 실제로는 같은 싱글톤 `StoreBindA` 핸들러가 같은 `(inst,k)`에
	두 번 push되고(`list={StoreBindA,StoreBindA}`), `retractUnder`의
	457행 "첫 매치 cutoff" 로직이 안쪽 재계산 시점에도 항상 **바깥쪽**
	인덱스를 cutoff로 잡아버려 안쪽 자기 자신이 잘못 retract되는 게
	`.claude/base/bind-system-plan.md` "확정된 디스패치 모델" 절
	2026-08-13 항목에서 손으로 트레이싱해 확인됨 — 실제 `bindLifetime`
	기반 구현이었다면 안쪽 State 구독이 등록 직후 끊겨 이후 갱신이
	조용히 무시됐을 것. 이 파일이 "다단 체인이 정상"이라고 결론 내린 건
	이 스텁의 사각지대 때문이었지 실제로 검증된 게 아니었음 — 그래서
	아래에 같은 `(inst,k)`에 같은 핸들러가 중복 push되면 즉시 error하는
	가드(같은 세션에 base 문서 pseudocode에도 추가됨)를 넣고, 3단계에서
	이 가드가 실제로 걸리는지 확인하는 걸로 대체.
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
	-- [2026-08-13 세션 신설] 같은 (inst,k)에 같은 핸들러 객체가 이미 체인에
	-- 있으면 error — State<State<T>>류 재진입 디스패치를 조용히 깨지게
	-- 두지 않고 즉시 실패시킴 (base/bind-system-plan.md 동시 반영)
	for _, existing in list do
		if existing == h then
			error(
				string.format(
					"Dispatch: handler '%s' already active for %s.%s — re-entrant dispatch (e.g. State<State<T>>) is not supported",
					h.name,
					tostring(inst),
					tostring(k)
				)
			)
		end
	end
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
print("=== 3단계 [2026-08-13 세션 재작성]: StoreA 값을 store로 다시 바꿔서")
print("    (State<State<T>>에 대응) 재진입 디스패치를 유도 — 이제 가드가")
print("    즉시 error해야 정상 ===")
local storeB = makeStore("nested")
local ok, err = pcall(function()
	storeA:set(storeB)
end)
print("  error로 막혔는가:", not ok)
print("  에러 메시지:", tostring(err))
print(
	"  현재 체인 길이:",
	#chainFor("Frame1", "Text"),
	"(가드가 push 전에 error하므로 1이어야 정상 — StoreBindA만 남고 오염 없음)"
)

print()
print("=== 4단계: 가드가 걸린 뒤에도 같은 자리에 정상 값으로 다시 바인드하면")
print("    문제없이 복구되는가(에러가 체인을 영구 오염시키지 않는가) ===")
storeA:set(42)
print("  현재 체인 길이:", #chainFor("Frame1", "Text"), "(A->Property 2개로 정상 복구되어야 함)")

--[[
	확인 포인트 (이게 이 파일의 핵심 목적):
	1. 2단계에서 storeA:set("world") 이후 체인 길이가 정확히 2(A, Property)로
	   돌아오는가 — retractUnder가 이전 PropertyHandler를 정리하고 새로
	   push했는가, 아니면 계속 누적돼서 체인이 무한정 길어지는가?
	   (누적되면 버그 — 체인이 GC 안 되는 메모리 누수이자 논리 오류)
	2. **[2026-08-13 세션 정정]** 3단계는 원래 "A(StoreBindA) 자신은 살아남고
	   그 밑만 정리되는가"를 확인하려 했으나, 이 스파이크의 `retract`가
	   print만 하는 no-op이라 실제 자기-retract 버그(같은 싱글톤 핸들러가
	   같은 (inst,k)에 중복 push되고, retractUnder의 첫-매치 cutoff가 안쪽
	   재계산 시점에 바깥쪽 인덱스를 잡아 안쪽이 스스로를 retract하는 것 —
	   상세 트레이싱은 `.claude/base/bind-system-plan.md` "확정된 디스패치
	   모델" 절 2026-08-13 항목)를 이 스텁으로는 절대 못 잡는다는 게 드러남.
	   그래서 이제 3단계는 "같은 핸들러 중복 push를 Dispatch.process가
	   push 전에 잡아 즉시 error하는가"를 확인 — `ok`가 `false`고 체인
	   길이가 오염 없이 1로 남는 게 정상.
	3. 4단계: 가드가 발동한 뒤에도 같은 (inst,k)에 정상적으로 새 값을
	   바인드할 수 있는가(에러가 chains 자료구조를 영구히 깨뜨리지
	   않는가) — 체인 길이가 다시 2(A, Property)로 정상 복구돼야 함.
	4. 스택 오버플로 없이 전부 정상 종료되는가.
]]
