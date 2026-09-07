--!strict
--[[
	검증 대상: Tween 옵션의 엔진 타입 필드가 정밀하다는 것 — `Info: TweenInfo?`,
	`Style: Enum.EasingStyle?`, `Direction: Enum.EasingDirection?`(2026-09-07 Tween이
	quad-roblox로 이동하며 얻은 것 — quad-types 시절엔 엔진 무관이라 `any`였다,
	`base/tween-plan.md` "패키지 경계" 절). 스펙(`quad-roblox/test/spec.*`)은 분석이
	클린해야 하는 그룹이라 음성을 둘 수 없고(`spec.tween.luau` 3절의 잘못된 엔진
	값은 `:: any`로 캐스트돼 있다), 이 스파이크가 그 음성의 자리다(round3 §9 `H-458`).

	실행(Roblox 전역이 필요하다 — defs 필수):
	  mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	    --definitions=scripts/roblox-defs/globalTypes.d.luau \
	    .claude/luau-test/done/36-type-tween-engine-fields-precise.luau
	기대: L-N1·L-N2·L-N3 세 줄에 정확히 TypeError, 양성 P 블록은 진단 없음.
	실측(2026-09-07, luau 0.734 새 솔버): 정확히 L-N1(40,38 `TweenInfo?` ← string)·L-N2(41,39
	`Enum.EasingStyle?` ← number)·L-N3(42,43 `Enum.EasingDirection?` ← `Enum.EasingStyle`) 셋, P 블록 진단 0.
]]

-- quad-roblox/src/types.luau의 정의 그대로(자립 재현 — 패키지 require 없음)
type TweenOverride = "Cancel" | "Finish"
type TweenOptions<T> = {
	read Value: T,
	read Info: TweenInfo?,
	read Time: number?,
	read Style: Enum.EasingStyle?,
	read Direction: Enum.EasingDirection?,
	read RepeatCount: number?,
	read Reverses: boolean?,
	read DelayTime: number?,
	read Override: TweenOverride?,
}
local function Tween<T>(opts: TweenOptions<T>): T
	return opts.Value
end

-- P. 양성 — 진단 없어야 한다
local p1 = Tween({ Value = 1, Info = TweenInfo.new(0.2), Style = Enum.EasingStyle.Bounce, Direction = Enum.EasingDirection.In })
local p2 = Tween({ Value = UDim2.new(), Time = 0.3, Override = "Finish" })

-- N. 음성 — 각 줄이 TypeError여야 한다
local n1 = Tween({ Value = 1, Info = "not a TweenInfo" }) -- L-N1: string → TweenInfo?
local n2 = Tween({ Value = 1, Style = 3 }) -- L-N2: number → Enum.EasingStyle?
local n3 = Tween({ Value = 1, Direction = Enum.EasingStyle.Quad }) -- L-N3: 다른 Enum → Enum.EasingDirection?

return { p1, p2, n1, n2, n3 }
