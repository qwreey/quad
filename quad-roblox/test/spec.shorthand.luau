--[[
	InstanceShorthand 계약 (M10 잔여, round20) — `base/ui-shorthand-plan.md`
	"메커니즘"·"`v`가 `nil`인 경우"·"Tween 지원" 절. CLI 실주행 심(spec.handlers
	관용구): Reflection 심(부모·자식 클래스의 프로퍼티), `getfenv(D.New).Instance`,
	`q.isInst`, `getfenv(installShorthand).UDim`(엔진 전역 — 테이블로 대체),
	Property 모듈엔 `TweenInfo`/`TweenService` 심(mock).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
	UIScale = { { Name = "Name", Permits = W }, { Name = "Scale", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.D.New) :: any).Instance = { new = mock.Instance.new }
q.isInst = mock.isMockInstance
-- UDim 심 — 엔진 전역이 없는 CLI에서 `UDim.new(0, n)`을 테이블로
local function UDimNew(scale: number, offset: number): any
	return { Scale = scale, Offset = offset, __udim = true }
end
;(getfenv(installShorthand) :: any).UDim = { new = UDimNew }

local Tween = q.Tween
local function childNamed(inst: any, name: string): any
	for _, c in inst:GetChildren() do
		if c.Name == name then
			return c
		end
	end
	return nil
end

print("=== 1. UICorner = 8 — 관리 자식 _quad_round 생성·부착, CornerRadius = UDim(0, 8); UDim은 그대로 ===")
do
	local f = q.D.Frame({ UICorner = 8 }) :: any
	local c = childNamed(f, "_quad_round")
	assert(c ~= nil and c.ClassName == "UICorner" and c.Parent == f, "managed child created and parented")
	assert(c.CornerRadius.Offset == 8 and c.CornerRadius.Scale == 0, "number → offset UDim")
	local f2 = q.D.Frame({ UICorner = UDimNew(0.5, 0) }) :: any
	assert(childNamed(f2, "_quad_round").CornerRadius.Scale == 0.5, "UDim passes through")
	print("PASS")
end

print()
print("=== 2. 반응형 — State<number> 변경은 자식을 재생성하지 않고 프로퍼티만 갱신(Relate 조회) ===")
do
	local s = q.Source(4)
	local f = q.D.Frame({ UICorner = s }) :: any
	local c = childNamed(f, "_quad_round")
	s:Set(12)
	assert(childNamed(f, "_quad_round") == c and c.CornerRadius.Offset == 12, "same child, property updated")
	assert(#f:GetChildren() == 1, "exactly one managed child")
	print("PASS")
end

print()
print("=== 3. nil — 자식 파괴(retractFrom 뒤), 다시 숫자면 재생성(첫 값 스냅); None 경유도 같은 경로 ===")
do
	local s = q.Source(4 :: any)
	local f = q.D.Frame({ UICorner = s }) :: any
	local c1 = childNamed(f, "_quad_round")
	s:Set(nil)
	assert(childNamed(f, "_quad_round") == nil and mock.isDestroyed(c1), "child destroyed on nil")
	s:Set(6)
	local c2 = childNamed(f, "_quad_round")
	assert(c2 ~= nil and c2 ~= c1 and c2.CornerRadius.Offset == 6, "recreated with the new value")
	s:Set(q.None)
	assert(childNamed(f, "_quad_round") == nil, "None → nil → destroyed")
	print("PASS")
end

print()
print("=== 4. Tween — Tween<number>이 Mapped로 UDim Tween이 되어 (child, CornerRadius) 슬롯에서 애니메이션(첫 값은 스냅) ===")
do
	mock.resetTweenLog()
	local s = q.Source(4 :: any)
	local f = q.D.Frame({ UICorner = s }) :: any
	local c = childNamed(f, "_quad_round")
	s:Set(Tween({ Value = 10, Time = 0.2 }))
	local log = mock.tweenLog
	assert(#log == 1 and log[1].inst == c and log[1].props.CornerRadius.Offset == 10 and log[1].info.args[1] == 0.2, "engine tween on the managed child with the wrapped Value")
	assert(c.CornerRadius.Offset == 4, "mock does not interpolate — first value was snapped, second animates")
	print("PASS")
end

print()
print("=== 5. UIPadding(UDim)·UIPaddingOffset(number) — 같은 _quad_padding 자식, 네 프로퍼티; UIScale ===")
do
	local f = q.D.Frame({ UIPadding = UDimNew(0, 4) }) :: any
	local p = childNamed(f, "_quad_padding")
	assert(p ~= nil and p.PaddingLeft.Offset == 4 and p.PaddingRight.Offset == 4 and p.PaddingTop.Offset == 4 and p.PaddingBottom.Offset == 4, "all four paddings")
	local f2 = q.D.Frame({ UIPaddingOffset = 6 }) :: any
	assert(childNamed(f2, "_quad_padding").PaddingTop.Offset == 6, "offset form")
	local f3 = q.D.Frame({ UIScale = 1.5 }) :: any
	assert(childNamed(f3, "_quad_scale").Scale == 1.5, "UIScale")
	-- 두 키가 한 인스턴스에 같이 — 자식 하나, 나중 process가 이김(H-335)
	local f4 = q.D.Frame({ UIPadding = UDimNew(0, 1), UIPaddingOffset = 2 }) :: any
	local kids = 0
	for _, c in f4:GetChildren() do if c.Name == "_quad_padding" then kids += 1 end end
	assert(kids == 1, "shared managed child")
	print("PASS")
end

print()
print("=== 6. 우선순위가 Property보다 높다 (Q17 (a), 2026-09-07: 옛 `numberOnly` 값 게이트는 제거 — 타입이 1차 방어, 최종 프로퍼티 대입이 다른 프로퍼티처럼 raise) ===")
do
	local h = q.Dispatch.getHandler(mock.Instance.new("Frame"), "UICorner", 8)
	assert(h ~= nil and h.name == "InstanceShorthand", "shorthand wins the key")
	print("PASS")
end

print()
print("=== ALL PASS ===")
