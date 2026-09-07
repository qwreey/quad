--[[
	M11 단위 ③ 계약 — `Animate(info)`(`base/tween-plan.md` "`Animate` 콤비네이터"
	절 의사코드 1:1 / "왜 `:Apply`로 정정됐는가" 절): `:Apply` 전용 factory,
	옵션은 `T | State<T>`를 `:Get()`으로 한 번 풀어 `Tween{...}`에 plain으로,
	`CanAnimate` 생략 = true, false면 plain 값 그대로, 옵션 State의 변경 자체는
	재계산을 트리거하지 않는다(다음 Value 변경 때 최신 옵션 반영). 엔진 전역이
	필요 없어 CLI에서 그대로 돈다(Style 등은 아무 값이나 통과 — 엔진 검증은
	PropertyHandler 몫).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local mock = require("../../quad-base/test/mock")

local q: any = Quad.New():UseProvider(QuadRoblox)
local Animate = q.Animate

print("=== 1. 기본 — :Apply(Animate{…}) → State<Tween<T>>, 옵션은 plain으로 실림, Value는 소스 값 ===")
do
	local src = q.Source(1)
	local styleS = q.Source("Bounce")
	local anim = src:Apply(Animate({ Time = 0.3, Style = styleS, Override = "Finish" }))
	assert(q.isState(anim), "factory returns a State")
	local t = anim:Get()
	assert(q.isTween(t) and t.Value == 1 and t.Time == 0.3 and t.Style == "Bounce" and t.Override == "Finish", "Tween built from resolved options")
	src:Set(2)
	local t2 = anim:Get()
	assert(t2 ~= t and t2.Value == 2 and t2.Time == 0.3, "Value change → new Tween with the same options")
	print("PASS")
end

print()
print("=== 2. CanAnimate — 생략은 true, false면 plain 값 그대로, State<boolean>로 토글(다음 Value 변경 때 반영) ===")
do
	local src = q.Source(1)
	local can = q.Source(false)
	local anim = src:Apply(Animate({ Time = 0.1, CanAnimate = can }))
	assert(anim:Get() == 1, "CanAnimate=false → plain value")
	can:Set(true)
	assert(anim:Get() == 1, "option State change alone does not recompute")
	src:Set(2)
	local t = anim:Get()
	assert(q.isTween(t) and t.Value == 2, "next Value change picks up CanAnimate=true")
	local plain = src:Apply(Animate({}))
	assert(q.isTween(plain:Get()), "omitted CanAnimate = always animate")
	print("PASS")
end

print()
print("=== 3. 옵션 State는 deps가 아니다 — Style State가 바뀌어도 재계산 0, Value 변경 때만 최신 반영 ===")
do
	local src = q.Source(1)
	local styleS = q.Source("A")
	local runs = 0
	local anim = src:Apply(Animate({ Style = styleS }))
	anim:Observer(function()
		runs += 1
	end)
	assert(anim:Get().Style == "A", "compute once so the cache holds the old Style") -- lazy: an uncomputed State would see the latest option at its first Get
	local before = runs
	styleS:Set("B")
	assert(runs == before and anim:Get().Style == "A", "Style change: no recompute, cached Tween keeps the old Style")
	src:Set(2)
	assert(anim:Get().Style == "B", "Value change: latest Style resolved")
	print("PASS")
end

print()
print("=== 4. 검증 — info가 테이블이 아니면 error(blame은 사용자 줄); Tween 검증도 그대로 산다 ===")
do
	local ok, err = pcall(function()
		return Animate(5)
	end)
	assert(not ok and string.find(tostring(err), "expected an options table", 1, true) ~= nil, "non-table info: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.animate.luau", "Animate blame")
	-- `H-464`: literal options are validated at `Animate(info)` (the user's line is on the stack) —
	-- lazily, inside Compute, the raise blamed `Animate.luau`
	local ok2, err2 = pcall(function()
		return Animate({ Time = "x" })
	end)
	assert(not ok2 and string.find(tostring(err2), "Time must be a number", 1, true) ~= nil, "literal option validated eagerly: " .. tostring(err2))
	mock.assertBlamesUser(err2, "spec.animate.luau", "Animate literal option blame")
	local ok3, err3 = pcall(function()
		return Animate({ Override = "Nope" })
	end)
	assert(not ok3 and string.find(tostring(err3), "Override must be", 1, true) ~= nil, "Override validated eagerly: " .. tostring(err3))
	-- a State-valued option is NOT checked at construction (resolved per run) — the lazy
	-- `Tween(opts)` still catches it at the first Get
	local bad = q.Source("x")
	local combinator = Animate({ Time = bad }) -- no raise here
	local src = q.Source(1)
	local ok4, err4 = pcall(function()
		return src:Apply(combinator):Get()
	end)
	assert(not ok4 and string.find(tostring(err4), "Time must be a number", 1, true) ~= nil, "State option validated at run: " .. tostring(err4))
	print("PASS")
end

print()
print("=== ALL PASS ===")
