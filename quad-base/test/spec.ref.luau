--[[
	Ref 최소형 계약 — `.claude/base/ref-plan.md` "API 모양" / "`.Callbacks`는 배열이 아니라" /
	"`:WeakCallback(fn)`" / "`:Set(value)`의 순서" / "`Ref`는 `Epoch`를 만족한다",
	`.claude/base/state-epoch-plan.md` §2(리비전 랩).
]]

local Quad = require("../src")
local Ref = Quad.Ref

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

print("=== 1. 생성 — Value/Revision 초기값, 브랜드(isRef + isEpoch), Callback 테이블 둘 ===")
do
	local r = Ref(5)
	assert(r.Value == 5, "default lands in .Value")
	assert(r.Revision == 0, "initial revision is 0")
	assert(Quad.isRef(r) and Quad.isEpoch(r), "a Ref is both Ref and Epoch (multi-tagging)")
	assert(not Quad.isPreRef(r) and not Quad.isPostRef(r) and not Quad.isState(r), "plain Ref only")
	assert((getmetatable(r.WeakCallbacks :: any) :: any).__mode == "k", "WeakCallbacks is weak-keyed")
	assert(getmetatable(r.Callbacks) == nil, "Callbacks is a plain strong set")
	local empty = Ref(nil :: number?) -- nil이 올 수 있는 자리는 호출자가 `T?`로 넓힌다(`ref-plan.md` "제네릭 시그니처")
	assert(empty.Value == nil, "Ref(nil) has no value")
	print("PASS")
end

print()
print("=== 2. :Set 순서 — 콜백이 볼 때 .Value와 .Revision이 이미 새 것, fn(value, ref) ===")
do
	local r = Ref(1)
	local seen: { any } = {}
	r:Callback(function(value, ref)
		table.insert(seen, { value = value, refValue = ref.Value, rev = ref.Revision, ref = ref })
	end)
	assert(#seen == 1 and seen[1].value == 1 and seen[1].ref == r, "registration calls once with the current value + the Ref itself")
	local rev0 = r.Revision
	local ret = r:Set(2)
	assert(ret == r, ":Set returns self")
	assert(#seen == 2, "one fire per Set")
	assert(seen[2].value == 2 and seen[2].refValue == 2, ".Value is settled before callbacks")
	assert(seen[2].rev ~= rev0 and seen[2].rev == r.Revision, ".Revision is bumped before callbacks")
	print("PASS")
end

print()
print("=== 3. 리비전 — bit32.bnot(-rev) 랩어라운드 감소: 0 → 4294967295 → 4294967294, 매번 다름 ===")
do
	local r = Ref(nil :: number?)
	r:Set(1)
	assert(r.Revision == 4294967295, "0 wraps to 4294967295, got " .. r.Revision)
	r:Set(2)
	assert(r.Revision == 4294967294, "then decrements, got " .. r.Revision)
	local last = r.Revision
	for _ = 1, 100 do
		r:Set(0)
		assert(r.Revision ~= last, "every Set changes the revision")
		last = r.Revision
	end
	print("PASS")
end

print()
print("=== 4. 즉시 1회 호출 — nil/미설정이어도 그 상태 그대로 (H-120), Weak도 동일 ===")
do
	local r = Ref(nil :: number?)
	local calls = 0
	local weakCalls = 0
	r:Callback(function(value)
		calls += 1
		assert(value == nil, "nil is passed as-is")
	end)
	r:WeakCallback(function(value)
		weakCalls += 1
		assert(value == nil, "nil is passed as-is")
	end)
	assert(calls == 1 and weakCalls == 1, "both registrations fire once immediately")
	print("PASS")
end

print()
print("=== 5. 중복 등록은 dedup — 같은 fn을 여러 번/양쪽에 걸어도 Set당 1회 ===")
do
	local r = Ref(0)
	local calls = 0
	local function fn()
		calls += 1
	end
	r:Callback(fn):Callback(fn):WeakCallback(fn)
	calls = 0
	r:Set(1)
	assert(calls == 1, "same fn registered strongly + weakly fires once per Set, got " .. calls)
	print("PASS")
end

print()
print("=== 6. :Uncallback — 양쪽 테이블에서 뗌, self 반환, 안 걸린 fn은 no-op ===")
do
	local r = Ref(0)
	local strong, weak = 0, 0
	local function s()
		strong += 1
	end
	local function w()
		weak += 1
	end
	r:Callback(s):WeakCallback(w)
	strong, weak = 0, 0
	assert(r:Uncallback(s) == r, "Uncallback returns self")
	r:Uncallback(w)
	r:Uncallback(function() end)
	r:Set(1)
	assert(strong == 0 and weak == 0, "detached callbacks do not fire")
	assert(r.Callbacks[s] == nil and r.WeakCallbacks[w] == nil, "entries are removed from both tables")
	print("PASS")
end

print()
print("=== 7. WeakCallback — 다른 곳에서 안 잡으면 GC 뒤 침묵, Callback은 살아남음 ===")
do
	local r = Ref(0)
	local strongCalls, weakCalls = 0, 0
	-- ⚠️ 두 가지 GC 함정을 피한 모양: (1) 별도 함수 안에서 등록 — 같은 프레임의
	-- 죽은 레지스터가 클로저를 붙잡는 스택 잔재를 피한다. (2) 클로저가 업밸류를
	-- **직접 변경**한다 — 업밸류가 없거나 전부 톱레벨 불변 로컬인 클로저는 Luau가
	-- 프로토에 캐시해 강참조로 붙들어 영영 GC되지 않는다(이 테스트 파일의 탑레벨이
	-- 정확히 그 자리; `lifecycle-pattern.md`의 `false or` 트릭이 막는 것과 같은 최적화.
	-- 함수 인자·지역을 잡는 클로저는 해당 없음 — `H-175`).
	local function register()
		r:Callback(function()
			strongCalls += 1
		end)
		r:WeakCallback(function()
			weakCalls += 1
		end)
	end
	register()
	collectgarbage()
	collectgarbage()
	strongCalls, weakCalls = 0, 0
	r:Set(1)
	assert(strongCalls == 1, "strongly registered callback survives GC")
	assert(weakCalls == 0, "weakly registered callback is collected and silent")
	assert(next(r.WeakCallbacks) == nil, "WeakCallbacks entry is gone")
	print("PASS")
end

print()
print("=== 8. 발화 중 Uncallback/Callback 안전 — 스냅샷 순회, 순회 중 해제된 건 skip ===")
do
	local r = Ref(0)
	local order: { string } = {}
	local walking = false -- 등록 즉시 1회 호출과 Set 순회를 구분
	local a: (number?, any) -> ()
	local b: (number?, any) -> ()
	-- a와 b가 서로를 떼므로 pairs 순서와 무관하게 정확히 하나만 돈다
	a = function()
		if not walking then
			return
		end
		table.insert(order, "a")
		r:Uncallback(b)
		r:Callback(function()
			if walking then
				table.insert(order, "late") -- 등록 즉시 1회만, 이번 파동의 순회엔 안 낌
			end
		end)
	end
	b = function()
		if not walking then
			return
		end
		table.insert(order, "b")
		r:Uncallback(a)
	end
	r:Callback(a):Callback(b)
	walking = true
	r:Set(1)
	walking = false
	local counts: { [string]: number } = { a = 0, b = 0, late = 0 }
	for _, v in order do
		counts[v] = (counts[v] or 0) + 1
	end
	assert(counts.a + counts.b == 1, "exactly one of a/b runs — the other was released mid-walk and skipped, got " .. table.concat(order, ","))
	assert(counts.late == counts.a, "a callback registered mid-walk fires its registration call only, got " .. table.concat(order, ","))
	print("PASS")
end

print()
print("=== 9. thread 키 — 대기자는 1회 소진, resume 인자는 Ref 자신 (M8 :Wait의 기반) ===")
do
	local r = Ref(0)
	local got: any = nil
	local co = coroutine.create(function()
		got = coroutine.yield()
	end)
	coroutine.resume(co)
	r.Callbacks[co] = true -- :Wait()가 M8에서 할 등록을 직접 흉내
	r:Set(1)
	assert(got == r, "waiter is resumed with the Ref itself")
	assert(r.Callbacks[co] == nil, "waiter is consumed")
	assert(coroutine.status(co) == "dead", "waiter ran to completion")
	r:Set(2) -- 소진 확인은 위 Callbacks[co] == nil로 충분 — coroutine.resume은 에러를 올리지 않아
	-- 죽은 코루틴을 다시 resume해도 여기서 티가 안 난다(리뷰 `H-170`, §4 문항)
	print("PASS")
end

print()
print("=== ALL PASS ===")
