--!strict
--[[
	quad-roblox public types — the single shared file the ROADMAP M5 banner
	requires ("공개 타입은 단일 파일에 몰아둘 것"; a later `quad-roblox-types`
	package split lifts this file wholesale). Roblox globals (TweenInfo, Enum,
	Instance) appear here, so this package is analyzed with the pinned
	`scripts/roblox-defs/globalTypes.d.luau` — quad-base stays defs-free.

	`Tween<T>` — the value-level wrapper `tween-plan.md`'s "확정: `Tween{...}`
	최종 모양" section pins down. M11 implements the runtime (constructor,
	PropertyHandler consumption, `Tween.Cancel`/`Tween.Finish` sentinels);
	M5 needs the TYPE first because the generated `D` prop unions include it
	(round14 `H-298` (a)). `Override` stays `any` until M11 gives the sentinel
	values a type.

	`NewChild` — the children-array element union `D.<Class>Param<E>`
	instantiates (claim-plan §7-12). M5-era union: what actually works through
	`drive` by the end of this milestone — a static child Instance
	(InstanceChildHandler, unit ③) or a reactive one (StoreBind → unwrap).
	Later milestones WIDEN this union as their handlers land (M6 Slot, M8
	Ref/PreRef/PostRef — the round14 `H-298` (a) "Ref류" mention is that
	planned widening, kept out now so the type never promises a runtime path
	that does not exist yet; same false-surface logic as `H-297`).
	`None` joined every union once `H-300` (a) landed (2026-09-02 — the
	sentinel now carries a marker field, `QuadTypes.None`).
	Canonical prose: `bind-system-plan.md` 인스턴스 생성 절의 값 유니언 문단.
]]

local QuadTypes = require("../luau_packages/quad_types")

export type Tween<T> = {
	Value: T,
	Info: TweenInfo?,
	-- convenience fields, used only when Info is absent (defaults are
	-- TweenInfo.new()'s own)
	Time: number?,
	Style: Enum.EasingStyle?,
	Direction: Enum.EasingDirection?,
	RepeatCount: number?,
	Reverses: boolean?,
	DelayTime: number?,
	Override: any?, -- Tween.Cancel (default) | Tween.Finish — sentinels arrive in M11
}

export type NewChild = Instance | QuadTypes.State<Instance> | QuadTypes.None

return {}
