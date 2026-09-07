--!strict
--[[
	InstanceShorthand 타입 표면 — strict 양성(round20 단위 ②, `H-336`). 생성 D의
	GuiObject 계열 `<Class>Param`·`<Class>Modifier`에 `UICorner`(number | UDim)/
	`UIPadding`(UDim)/`UIPaddingOffset`(number)/`UIScale`(number)가 실프로퍼티와
	같은 값 유니언(`PVn` — T | TweenData<T> | StateMarker<T | Tween<T>> | None; [2026-09-07 마커]
	유니언 T도 같은 네 팔 — 옛 멤버별 팔(`PV73` 11팔)·setter `SHF0`(`H-353`/`H-362`/`H-363`)는
	공변 마커로 소멸, `typing-limits.md` 8.11)으로
	들어가고, GuiObject가 아닌 클래스(ScreenGui 등)엔 없다. 음성은 스크래치 실측.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
local Types = require("../src/types")

local q = Quad.New():UseProvider(QuadRoblox)

local function _types()
	local radius = q.Source(8)
	local f = q.D.Frame({
		UICorner = 8,
		UIPadding = UDim.new(0, 4),
		UIPaddingOffset = 4,
		UIScale = radius:Apply(q.Animate({ Time = 0.2 })),
	})
	local f2 = q.D.TextLabel({ UICorner = UDim.new(0.5, 0), UIScale = q.Source(1.5) })
	-- 7순회 `H-420`: `ContentId` props are strings (asset ids) — the generator used to map them
	-- to the unrelated `Content` userdata class and rejected the only value the engine takes
	local il = q.D.ImageLabel({ Image = "rbxassetid://123" })
	local ib = q.D.ImageButton({ Image = q.Source("rbxassetid://1"), HoverImage = "rbxassetid://2" })
	local _, _ = il, ib
	local f3 = q.D.ImageButton({ UICorner = q.Tween({ Value = 12, Time = 0.3 }) })
	local m = q.D.Modifier.Frame():UICorner(8):UIPadding(UDim.new(0, 2)):UIPaddingOffset(radius):UIScale(q.Tween({ Value = 1 }))
	local mAbove = q.D.Modifier.GuiObject():UICorner(4) -- 상위 클래스 Modifier에도
	-- `H-353`: 유니언 타입 숏핸드(`number | UDim`)에 State<number>·State<UDim>이 각각 들어간다
	-- (State<X> 불변 — `State<number | UDim>` 하나로는 `Source(8)`이 거부됐다, 핸드오버 리뷰)
	local udim = q.Source(UDim.new(0, 8))
	local f4 = q.D.Frame({ UICorner = radius })
	local f5 = q.D.Frame({ UICorner = udim })
	local m2 = q.D.Modifier.Frame():UICorner(radius):UICorner(udim)
	local f6 = q.D.Frame({ UICorner = radius:Apply(q.Animate({ Time = 0.2 })) })
	-- 0순회 `H-362`/`H-363`: 변환 함수는 전체 유니언 하나로(modifier-plan 4절 `old` 관용구 — UDim을
	-- 돌려주거나 `old`를 UDim으로 좁힌다), 전체 유니언 값의 Tween도 그대로
	local m3 = q.D.Modifier.Frame():UICorner(function(old)
		if typeof(old) == "UDim" then return old end
		return UDim.new(0, 8)
	end)
	local v: number | UDim = 8
	local f7 = q.D.Frame({ UICorner = q.Tween({ Value = v }) })
	local m4 = q.D.Modifier.Frame():UICorner(q.Tween({ Value = v }))
	return f, f2, f3, m, mAbove, f4, f5, m2, f6, m3, f7, m4
end

print("=== 1. 런타임 대응 — 생성 D의 숏핸드 키가 실제 핸들러에 닿는다(mock 없이 타입만 — 본문은 실행하지 않음) ===")
print("PASS")
print()
-- [2026-09-07 마커, 사용자 결정] 유니언 T 자리에 `State<number | UDim>` 하나가 든다(옛 멤버별 11팔 `PV73`·
-- 숏핸드 setter `SHF0` 불필요), 정직한 `State<T | Tween<T>>`(`H-334`가 "too complex"로 포기한 팔)도 든다.
local function _markerUnion()
	local radius = q.Source(8)
	local either = q.Source((8 :: any) :: number | UDim)
	local f8 = q.D.Frame({ UICorner = either })
	local m5 = q.D.Modifier.Frame():UICorner(either):UIScale(q.Source((nil :: any) :: number | Types.Tween<number>))
	local honest: QuadTypes.State<number | Types.Tween<number>> = radius:Compute(function(h: QuadTypes.StateData<number>): number | Types.Tween<number>
		return h:Get()
	end)
	local f9 = q.D.Frame({ UICorner = honest, ZIndex = honest })
	-- round3 Q23 (a): 변환 함수의 old는 State 팔 하나(`State<T | Tween<T>>`) — 캐스트 뒤 :Get()이 선다
	local m6 = q.D.Modifier.Frame():UICorner(function(old)
		if q.isState(old) then
			return (old :: QuadTypes.State<number | UDim | Types.Tween<number | UDim>>):Get()
		end
		return old
	end)
	return f8, m5, f9, m6
end

print("=== ALL PASS ===")
