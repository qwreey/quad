--!strict
--[[
	quad-roblox package entry. `QuadRoblox` is the PROVIDER FUNCTION for
	`quad:UseProvider(QuadRoblox)` (`H-305` (d′), 2026-09-02 사용자 확정 —
	스파이크 23이 2026-08-19에 예정해뒀던 그 모양): it version-checks the
	injected quad-base instance AT RUNTIME (`H-306` (a), 사용자 확정 — the
	compile-time `CheckedQuad` wiring here was silently inert: a
	generic-body local annotation is never re-evaluated per call site
	(quad-types-plan trap 2, measured), and NO type position forces the
	check through the `UseProvider` indirection (candidate matrix measured
	same day; presumably a type-system limit separate from the 2026-09-16
	FFlag finding in `typing-limits.md` 8.18 — that matrix was never re-run
	with `LuauDoNotExportBrokenTypeFunction=false`, so treat this as an
	unverified assumption). One string compare at install — the monorepo pins the exact
	version "0.0.0"; independently published backends would pick a looser
	pattern), lets RobloxFactory mutate the module (ops/handlers), and
	returns the typed extension `RobloxExtension` — so `q.Elem "Frame"` and the rest of the class-first surface
	are fully typed through the `Self & P` intersection with zero casts (3.4.0: the type functions in
	`Surface/init.luau` replaced the generated `Declaration`). The
	one-slot/identity guard lives in `UseProvider` itself, not here.

	Runtime dependencies are quad-types + type-version-check only (both
	small and engine-free) — the module instance arrives as an argument, so
	quad-base is never required here (round14 Q3 (a); tests use it as a dev
	dependency instead).
]]

local QuadTypes = require("./luau_packages/quad_types")
local TypeVersionCheck = require("./luau_packages/type_version_check")
local RobloxFactory = require("@self/RobloxFactory")
local Types = require("@self/types")
local Surface = require("@self/Surface")

-- 독립 게시 백엔드는 여기만 느슨한 패턴("0.*.*"류)으로 바꾸면 된다
-- [2026-09-15 사용자 결정] floor within the current major — base minors/patches at or above this release pass
-- (major has no `^`: a post-release BREAKING bumps it for real). `check-version.py bump` rewrites the floor.
local VERSION_PATTERN = "3.4^.0^"
-- this package's own version, written into `Backend.provider` for `q:AssertProvider` (kept equal to pesde.toml by check-version.py)
local VERSION = "3.4.0"

-- [2026-10-20 3.4.0] the public type names (`research/declaration-naming-table.md` 5절): one generic per axis, the
-- class is the type argument (`Modifier<Frame>`), computed by the type functions in `Surface/init.luau` from the
-- checker's own class types + the policy data `Surface/Data.luau` (`scripts/gen-d.py emit`). The 3.3 per-class names
-- (`FrameModifier`, `IntoFrame`, `FrameElem`, `Declaration`, `PropTypes`, `OnChangeFn`, `OutFn`, `Field`) are gone.
export type Props<C> = Surface.Props<C>
export type PropsHashPart<C> = Surface.PropsHashPart<C>
export type PropsArrayItem<C> = Surface.PropsArrayItem<C>
export type MapperProps<C> = Surface.MapperProps<C>
export type Modifier<C> = Surface.Modifier<C>
export type ModifierInto<C> = Surface.ModifierInto<C>
export type ModifierField<T> = Surface.ModifierField<T>
export type ModifierFieldOut<T> = Surface.ModifierFieldOut<T>
export type Spread<C> = Surface.Spread<C>
export type SpreadInto<C> = Surface.SpreadInto<C>
export type ElemCtor<C> = Surface.ElemCtor<C>
export type PropertyMap<C> = Surface.PropertyMap<C>
export type OnChangeDescriptor<K> = Surface.OnChangeDescriptor<K>
export type OnEventDescriptor<K> = Surface.OnEventDescriptor<K>

export type Tween<T> = Types.Tween<T>
export type TweenData<T> = Types.TweenData<T>
export type TweenOptions<T> = Types.TweenOptions<T>
export type TweenOverride = Types.TweenOverride
export type TweenConstructor = Types.TweenConstructor
export type AnimateInfo = Types.AnimateInfo
export type AnimateFn = Types.AnimateFn
-- M11 단위 ③: `Animate`(tween-plan "`Animate` 콤비네이터" 절)도 같은 병합 —
-- `q.Source(v):Apply(q.Animate{ Time = 0.3 })` → 선언 타입 `State<Tween<any>>`(`H-334` — 정직한
-- `State<T | Tween<T>>`는 슬롯 유니언에서 too complex, `types.luau` 주석)
-- `Tween`/`isTween`(2026-09-07): 백엔드 값 타입은 백엔드 표면 — 같은 병합으로 실린다
-- (런타임은 `Tween.luau` install이 모듈에 직접도 놓는다 — 형제 설치자와 base 진단 프로브가 본다).
-- [2026-10-20 3.4.0] the class-first surface fields are read off `Surface.BuiltinSurface` one by one (a literal field
-- list keeps this the one place `scripts/doc-coverage.py` reads the extension's names from).
-- `Out`'s source stays the full `Source<T>` (writable input — a marker + `Set` did not accept a real Source in the new
-- solver, typing-limits 8.25; rejects a `:Compute` State, which has no `Set`).
export type RobloxExtension = {
	Elem: index<Surface.BuiltinSurface, "Elem">,
	Modifier: index<Surface.BuiltinSurface, "Modifier">,
	Spread: index<Surface.BuiltinSurface, "Spread">,
	Mapper: index<Surface.BuiltinSurface, "Mapper">,
	OnChange: index<Surface.BuiltinSurface, "OnChange">,
	OnEvent: index<Surface.BuiltinSurface, "OnEvent">,
	Out: index<Surface.BuiltinSurface, "Out">,
	ForClasses: Surface.ForClasses,
	Animate: AnimateFn,
	Tween: Types.TweenConstructor,
	isTween: (x: any) -> boolean,
}

local function QuadRoblox<T>(quad: T): RobloxExtension
	local q = quad :: any
	-- surface tag so raises below blame the caller's line (`H-238`)
	q.errorNamespace.setFuncLevel(QuadTypes.ERROR_LEVEL_SURFACE, QuadRoblox)
	-- `H-306` (a): runtime version gate — errors climb to the consumer's
	-- UseProvider line (UseProvider is the outermost tagged frame)
	if type(q.Version) ~= "string" or not TypeVersionCheck.matchesPattern(q.Version, VERSION_PATTERN) then
		q.errorNamespace.errorBefore(
			`Quad0228 quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')`,
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	local extension = RobloxFactory(q)
	-- written after the factory succeeded, like UseProvider's own mark (a provider that threw is not installed)
	q.Backend.provider = table.freeze({ name = "quad-roblox", version = VERSION })
	return extension
end

return {
	QuadRoblox = QuadRoblox,
}
