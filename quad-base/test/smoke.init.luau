--[[ 임시 스모크 테스트 — New()/RunInit의 멱등 가드가 기대대로 동작하는지 확인 ]]

local Quad = require("../src")

print("=== 1. New()가 만든 module엔 InitDebug가 이미 반영돼 있음 ===")
assert(Quad.debug == false, "top-level require(quad-base)도 New()를 거쳐야 함")
print("PASS")

print()
print("=== 2. RunInit은 같은 함수를 다시 넘겨도 재실행하지 않음 ===")
do
	local runCount = 0
	local function initFn(module)
		runCount += 1
		module.marker = true
	end

	Quad:RunInit(initFn)
	Quad:RunInit(initFn)
	Quad:RunInit(initFn)

	assert(runCount == 1, "같은 initFn을 여러 번 RunInit해도 실제 실행은 1회여야 함")
	assert(Quad.marker == true, "실행됐다면 마커가 세팅돼 있어야 함")
	print("PASS: " .. runCount .. "회 호출 중 실제 실행 " .. runCount .. "회")
end

print()
print("=== 3. New()로 만든 서로 다른 module은 RunInit 기록을 공유하지 않음 ===")
do
	local runCount = 0
	local function initFn(_module)
		runCount += 1
	end

	local a = Quad.New()
	local b = Quad.New()
	assert(a ~= b, "New()는 매번 독립된 module을 만들어야 함")

	a:RunInit(initFn)
	b:RunInit(initFn)

	assert(runCount == 2, "서로 다른 module 인스턴스는 각자 한 번씩 실행돼야 함(총 2회)")
	print("PASS: 독립 인스턴스 2개 각각 1회씩, 총 " .. runCount .. "회")
end

print()
print("=== 4. 서로 다른 initFn은 서로의 실행 여부에 영향을 안 줌 ===")
do
	local m = Quad.New()
	local aRan, bRan = false, false
	local function initA(_module)
		aRan = true
	end
	local function initB(_module)
		bRan = true
	end

	m:RunInit(initA)
	assert(aRan == true and bRan == false, "initA만 돌았어야 함")
	m:RunInit(initB)
	assert(aRan == true and bRan == true, "이제 둘 다 돌았어야 함")
	m:RunInit(initA) -- no-op이어야 함, 에러 없이 통과하면 충분
	print("PASS")
end

print()
print("=== 5. [2026-08-28 M2 첫 단위] 탑레벨 값이 New()마다 실려 있음 ===")
do
	local m = Quad.New()
	assert(type(m.Relate) == "function" and type(m.Void) == "function" and type(m.Ref) == "function", "Relate/Void/Ref constructors")
	for _, name in { "isEpoch", "isSource", "isState", "isStore", "isObserver", "isEffect", "isBlocker", "isModifier", "isRef", "isPreRef", "isPostRef" } do
		assert(type((m :: any)[name]) == "function", name .. " must be a function")
	end
	for _, name in { "bindLifetime", "unbindLifetime", "canBound", "canExecute" } do
		assert(type((m :: any)[name]) == "function", name .. " stub must be installed")
	end
	assert(m.Void == Quad.Void and m.Ref == Quad.Ref, "leaf modules are shared across instances")
	print("PASS")
end

print()
print("=== ALL PASS ===")
