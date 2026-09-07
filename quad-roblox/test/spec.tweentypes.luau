--!strict
--[[
	Tween 타입 표면 — strict 양성(M11 단위 ①, round19 Q3·`H-326`). quad-types의
	엔진 무관 `Tween<T>` 값이 quad-roblox `Types.Tween<T>`(quad-types 별칭 그대로 —
	정밀화는 포기) 자리 — 생성 `D`의 스칼라 유니언
	`T | TweenData<T> | StateMarker<T | Tween<T>> | None`(타입별 별칭 PVn; [2026-09-07 마커] State 팔은 공변 마커 하나) — 에 들어가고,
	`Mapped`의 U 전환·`State<Tween<T>>`·센티널 필드가 UseProvider 교집합을
	거쳐도 정확히 타이핑되는지. 음성(다른 T의 Tween·옵션 타입·문자열 Override·
	Mapped 결과 오타입·State<Tween<number>>)은 `luau-test/done/33`이 실측 —
	순수 제네릭 함수 `TweenConstructor`(`H-343` — 옛 교집합 형·8.6절 예외 `H-324`는 소멸)가 잡는다.
]]

local Quad = require("../luau_packages/quad_base")
local QuadTypes = require("../luau_packages/quad_types")
local QuadRoblox = require("../src").QuadRoblox
local Types = require("../src/types")

local q = Quad.New():UseProvider(QuadRoblox)

local function _types()
	-- 생성자 제네릭 추론(리터럴·엔진 타입 필드 포함)
	local t: QuadTypes.Tween<UDim2> = q.Tween({ Value = UDim2.new(0, 10, 0, 10), Time = 0.3, Style = Enum.EasingStyle.Bounce })
	local refined: Types.Tween<UDim2> = t -- quad-roblox 별칭은 quad-types 그대로(정밀판 포기 — H-326) — 항등 대입
	-- D 슬롯: Tween 직접 / Info 우선 + Override 센티널 / State<Tween<T>> / Mapped 결과
	local f1 = q.D.Frame({
		Position = t,
		Size = q.Tween({ Value = UDim2.new(), Info = TweenInfo.new(0.2), Override = "Finish" }),
		BackgroundTransparency = q.Tween({ Value = 0 }):Mapped(function(v: number): number
			return v * 0.5
		end),
	})
	local src = q.Source(UDim2.new())
	local anim: QuadTypes.State<QuadTypes.Tween<UDim2>> = src:Compute(function(h: QuadTypes.StateData<UDim2>): QuadTypes.Tween<UDim2>
		return q.Tween({ Value = h:Get(), Time = 0.3 })
	end)
	local f2 = q.D.Frame({ Position = anim })
	-- Animate(단위 ③, H-334): factory 결과는 State<Tween<T>>로 선언 — D 슬롯·setter에 들어간다
	local animated: QuadTypes.State<QuadTypes.Tween<UDim2>> = src:Apply(q.Animate({ Time = 0.3, Style = Enum.EasingStyle.Bounce, CanAnimate = q.Source(true) }))
	local f3 = q.D.Frame({ Position = animated })
	local m3 = q.D.Modifier.Frame():Position(animated)
	-- 센티널·옵션 타입
	local o: QuadTypes.TweenOverride = "Cancel"
	local opts: QuadTypes.TweenOptions<number> = { Value = 1, Reverses = true }
	local t2: QuadTypes.Tween<number> = q.Tween(opts)
	return refined, f1, f2, f3, m3, o, t2
end

print("=== 1. 런타임 대응 — 타입이 약속한 값이 실제로 있다(H-300) ===")
do
	local t = q.Tween({ Value = 1, Override = "Finish" })
	assert(q.isTween(t) and t.Override == "Finish" and (t :: any).__quadTween == true, "value matches the type")
	assert("Cancel" ~= "Finish", "sentinels distinct")
	print("PASS")
end

print()
print("=== ALL PASS ===")
