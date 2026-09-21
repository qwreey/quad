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
	returns the typed extension `RobloxExtension` — so `q.Declaration` is fully typed
	through the `Self & P` intersection with zero casts. The
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
local DeclarationModule = require("@self/Declaration")

-- 독립 게시 백엔드는 여기만 느슨한 패턴("0.*.*"류)으로 바꾸면 된다
-- [2026-09-15 사용자 결정] floor within major 3 — base minors/patches at or above this release pass
-- (major has no `^`: a post-release BREAKING bumps it for real). `check-version.py bump` rewrites the floor.
local VERSION_PATTERN = "3.2^.0^"

-- 공개 타입 재익스포트(ROADMAP M5 배너 — 몰아두는 단일 파일은 types.luau).
-- `Declaration`/`DeclarationMapper`/`<Class>Param<E>` 전량은 생성 파일(src/Declaration)이 소스라 여기선
-- 네임스페이스 타입 둘만 손으로 재익스포트한다(손 나열은 "전량 생성" 계약과 충돌, `H-305`).
-- [2026-09-15 공개 표면 (28) 잠정 — 사용자] 생성 모듈에서 사용자가 쓰는 타입은 아래 GENERATED 블록이
-- `scripts/gen-d.py emit`으로 이 파일에 직접 찍는다(pesde 설치에선 생성 모듈 경로가 `.pesde/…` 밑뿐이라
-- 루트 재수출이 유일한 공개 경로). **공개 계약은 이 루트가 내보내는 이름뿐** — 생성 모듈의 구조와 그 안의
-- 나머지 export는 바뀔 수 있다. **[2026-09-16 사용자 결정]** 생성 D가 stable 표면으로 확정돼(타입 함수 경로는
-- 별도 unstable 백로그) 클래스별 `<Class>Modifier`/`Into<Class>`/`<Class>Elem`도 이 블록에 싣는다 —
-- `<Class>Param<E>`·`FieldP`류·`OnChange`/`RefMarker`/`MapperElem`은 생성 모듈 직접 require에 남긴다.

-- BEGIN GENERATED ROOT EXPORTS (scripts/gen-d.py emit — do not edit by hand)
export type Field<T> = DeclarationModule.Field<T>
export type FieldOut<T> = DeclarationModule.FieldOut<T>
export type BillboardGuiModifier = DeclarationModule.BillboardGuiModifier
export type IntoBillboardGui = DeclarationModule.IntoBillboardGui
export type CameraModifier = DeclarationModule.CameraModifier
export type IntoCamera = DeclarationModule.IntoCamera
export type CanvasGroupModifier = DeclarationModule.CanvasGroupModifier
export type IntoCanvasGroup = DeclarationModule.IntoCanvasGroup
export type FolderModifier = DeclarationModule.FolderModifier
export type IntoFolder = DeclarationModule.IntoFolder
export type FrameModifier = DeclarationModule.FrameModifier
export type IntoFrame = DeclarationModule.IntoFrame
export type GuiBaseModifier = DeclarationModule.GuiBaseModifier
export type IntoGuiBase = DeclarationModule.IntoGuiBase
export type GuiBase2dModifier = DeclarationModule.GuiBase2dModifier
export type IntoGuiBase2d = DeclarationModule.IntoGuiBase2d
export type GuiButtonModifier = DeclarationModule.GuiButtonModifier
export type IntoGuiButton = DeclarationModule.IntoGuiButton
export type GuiLabelModifier = DeclarationModule.GuiLabelModifier
export type IntoGuiLabel = DeclarationModule.IntoGuiLabel
export type GuiObjectModifier = DeclarationModule.GuiObjectModifier
export type IntoGuiObject = DeclarationModule.IntoGuiObject
export type ImageButtonModifier = DeclarationModule.ImageButtonModifier
export type IntoImageButton = DeclarationModule.IntoImageButton
export type ImageLabelModifier = DeclarationModule.ImageLabelModifier
export type IntoImageLabel = DeclarationModule.IntoImageLabel
export type InstanceModifier = DeclarationModule.InstanceModifier
export type IntoInstance = DeclarationModule.IntoInstance
export type LayerCollectorModifier = DeclarationModule.LayerCollectorModifier
export type IntoLayerCollector = DeclarationModule.IntoLayerCollector
export type ModelModifier = DeclarationModule.ModelModifier
export type IntoModel = DeclarationModule.IntoModel
export type PVInstanceModifier = DeclarationModule.PVInstanceModifier
export type IntoPVInstance = DeclarationModule.IntoPVInstance
export type ScreenGuiModifier = DeclarationModule.ScreenGuiModifier
export type IntoScreenGui = DeclarationModule.IntoScreenGui
export type ScrollingFrameModifier = DeclarationModule.ScrollingFrameModifier
export type IntoScrollingFrame = DeclarationModule.IntoScrollingFrame
export type SurfaceGuiModifier = DeclarationModule.SurfaceGuiModifier
export type IntoSurfaceGui = DeclarationModule.IntoSurfaceGui
export type SurfaceGuiBaseModifier = DeclarationModule.SurfaceGuiBaseModifier
export type IntoSurfaceGuiBase = DeclarationModule.IntoSurfaceGuiBase
export type TextBoxModifier = DeclarationModule.TextBoxModifier
export type IntoTextBox = DeclarationModule.IntoTextBox
export type TextButtonModifier = DeclarationModule.TextButtonModifier
export type IntoTextButton = DeclarationModule.IntoTextButton
export type TextLabelModifier = DeclarationModule.TextLabelModifier
export type IntoTextLabel = DeclarationModule.IntoTextLabel
export type UIAspectRatioConstraintModifier = DeclarationModule.UIAspectRatioConstraintModifier
export type IntoUIAspectRatioConstraint = DeclarationModule.IntoUIAspectRatioConstraint
export type UIBaseModifier = DeclarationModule.UIBaseModifier
export type IntoUIBase = DeclarationModule.IntoUIBase
export type UIComponentModifier = DeclarationModule.UIComponentModifier
export type IntoUIComponent = DeclarationModule.IntoUIComponent
export type UIConstraintModifier = DeclarationModule.UIConstraintModifier
export type IntoUIConstraint = DeclarationModule.IntoUIConstraint
export type UICornerModifier = DeclarationModule.UICornerModifier
export type IntoUICorner = DeclarationModule.IntoUICorner
export type UIDragDetectorModifier = DeclarationModule.UIDragDetectorModifier
export type IntoUIDragDetector = DeclarationModule.IntoUIDragDetector
export type UIFlexItemModifier = DeclarationModule.UIFlexItemModifier
export type IntoUIFlexItem = DeclarationModule.IntoUIFlexItem
export type UIGradientModifier = DeclarationModule.UIGradientModifier
export type IntoUIGradient = DeclarationModule.IntoUIGradient
export type UIGridLayoutModifier = DeclarationModule.UIGridLayoutModifier
export type IntoUIGridLayout = DeclarationModule.IntoUIGridLayout
export type UIGridStyleLayoutModifier = DeclarationModule.UIGridStyleLayoutModifier
export type IntoUIGridStyleLayout = DeclarationModule.IntoUIGridStyleLayout
export type UILayoutModifier = DeclarationModule.UILayoutModifier
export type IntoUILayout = DeclarationModule.IntoUILayout
export type UIListLayoutModifier = DeclarationModule.UIListLayoutModifier
export type IntoUIListLayout = DeclarationModule.IntoUIListLayout
export type UIPaddingModifier = DeclarationModule.UIPaddingModifier
export type IntoUIPadding = DeclarationModule.IntoUIPadding
export type UIPageLayoutModifier = DeclarationModule.UIPageLayoutModifier
export type IntoUIPageLayout = DeclarationModule.IntoUIPageLayout
export type UIScaleModifier = DeclarationModule.UIScaleModifier
export type IntoUIScale = DeclarationModule.IntoUIScale
export type UIShadowModifier = DeclarationModule.UIShadowModifier
export type IntoUIShadow = DeclarationModule.IntoUIShadow
export type UISizeConstraintModifier = DeclarationModule.UISizeConstraintModifier
export type IntoUISizeConstraint = DeclarationModule.IntoUISizeConstraint
export type UIStrokeModifier = DeclarationModule.UIStrokeModifier
export type IntoUIStroke = DeclarationModule.IntoUIStroke
export type UITableLayoutModifier = DeclarationModule.UITableLayoutModifier
export type IntoUITableLayout = DeclarationModule.IntoUITableLayout
export type UITextSizeConstraintModifier = DeclarationModule.UITextSizeConstraintModifier
export type IntoUITextSizeConstraint = DeclarationModule.IntoUITextSizeConstraint
export type VideoFrameModifier = DeclarationModule.VideoFrameModifier
export type IntoVideoFrame = DeclarationModule.IntoVideoFrame
export type ViewportFrameModifier = DeclarationModule.ViewportFrameModifier
export type IntoViewportFrame = DeclarationModule.IntoViewportFrame
export type WorldModelModifier = DeclarationModule.WorldModelModifier
export type IntoWorldModel = DeclarationModule.IntoWorldModel
export type WorldRootModifier = DeclarationModule.WorldRootModifier
export type IntoWorldRoot = DeclarationModule.IntoWorldRoot
export type BillboardGuiElem = DeclarationModule.BillboardGuiElem
export type CameraElem = DeclarationModule.CameraElem
export type CanvasGroupElem = DeclarationModule.CanvasGroupElem
export type FolderElem = DeclarationModule.FolderElem
export type FrameElem = DeclarationModule.FrameElem
export type ImageButtonElem = DeclarationModule.ImageButtonElem
export type ImageLabelElem = DeclarationModule.ImageLabelElem
export type ScreenGuiElem = DeclarationModule.ScreenGuiElem
export type ScrollingFrameElem = DeclarationModule.ScrollingFrameElem
export type SurfaceGuiElem = DeclarationModule.SurfaceGuiElem
export type TextBoxElem = DeclarationModule.TextBoxElem
export type TextButtonElem = DeclarationModule.TextButtonElem
export type TextLabelElem = DeclarationModule.TextLabelElem
export type UIAspectRatioConstraintElem = DeclarationModule.UIAspectRatioConstraintElem
export type UICornerElem = DeclarationModule.UICornerElem
export type UIDragDetectorElem = DeclarationModule.UIDragDetectorElem
export type UIFlexItemElem = DeclarationModule.UIFlexItemElem
export type UIGradientElem = DeclarationModule.UIGradientElem
export type UIGridLayoutElem = DeclarationModule.UIGridLayoutElem
export type UIListLayoutElem = DeclarationModule.UIListLayoutElem
export type UIPaddingElem = DeclarationModule.UIPaddingElem
export type UIPageLayoutElem = DeclarationModule.UIPageLayoutElem
export type UIScaleElem = DeclarationModule.UIScaleElem
export type UIShadowElem = DeclarationModule.UIShadowElem
export type UISizeConstraintElem = DeclarationModule.UISizeConstraintElem
export type UIStrokeElem = DeclarationModule.UIStrokeElem
export type UITableLayoutElem = DeclarationModule.UITableLayoutElem
export type UITextSizeConstraintElem = DeclarationModule.UITextSizeConstraintElem
export type VideoFrameElem = DeclarationModule.VideoFrameElem
export type ViewportFrameElem = DeclarationModule.ViewportFrameElem
export type WorldModelElem = DeclarationModule.WorldModelElem
-- END GENERATED ROOT EXPORTS
-- `Tween` 값 타입 일가(2026-09-07 — quad-types에서 이곳으로, `types.luau` 주석)
export type Tween<T> = Types.Tween<T>
export type TweenData<T> = Types.TweenData<T>
export type TweenOptions<T> = Types.TweenOptions<T>
export type TweenOverride = Types.TweenOverride
export type TweenConstructor = Types.TweenConstructor
export type NewChild = Types.NewChild
export type Declaration = DeclarationModule.Declaration
export type DeclarationMapper = DeclarationModule.DeclarationMapper
export type OnChangeDescriptor = Types.OnChangeDescriptor
export type PropTypes = DeclarationModule.PropTypes
export type OnChangeFn = DeclarationModule.OnChangeFn
-- `Out(name, src)` (2026-09-21 사용자 결정 — `research/upward-flow-plan.md` 8절): write-back sugar over `OnChange`.
-- The Source parameter is an INPUT position, which by 8.11 should be a marker — but the sugar needs a WRITABLE
-- value, and "marker + `{ read Set }`" cannot be expressed: the new solver decomposes the left-hand intersection
-- (`Source<T>` = StateData & State-part & { Set, … }) and demands EVERY component satisfy the target, so even a
-- lone `{ read Set: … }` target rejects a real Source (typing-limits 8.25, scratch 2026-09-21). The full
-- `Source<T>` is the one shape that accepts a Source, rejects a `:Compute` State (no `Set`) and checks the value
-- type — the user caveat "compute 해서 in 을 넣으면 안 된다" is enforced here. Cost is bounded: the argument is
-- always a `Source<T>` alias instance, never a structural expansion.
export type OutFn = <K>(
	name: K & keyof<DeclarationModule.PropTypesRead>,
	src: QuadTypes.Source<index<DeclarationModule.PropTypesRead, K>> -- type-surface: allow — writable input, marker+Set fails under the new solver (8.25)
) -> DeclarationModule.OnChangeDescriptor<K>
-- M10: `OnChange(name, fn)` rides the same extension merge as `Declaration` — the
-- runtime (Handlers/OnChange.luau) is untyped, the GENERATED `OnChangeFn`
-- (name → callback parameter type via `index<PropTypesRead, K>` — 읽기 표면, Q19; luau-test `30`)
-- is what `q.OnChange` carries through `Self & P`
export type AnimateInfo = Types.AnimateInfo
export type AnimateFn = Types.AnimateFn
-- M11 단위 ③: `Animate`(tween-plan "`Animate` 콤비네이터" 절)도 같은 병합 —
-- `q.Source(v):Apply(q.Animate{ Time = 0.3 })` → 선언 타입 `State<Tween<any>>`(`H-334` — 정직한
-- `State<T | Tween<T>>`는 슬롯 유니언에서 too complex, `types.luau` 주석)
-- `Tween`/`isTween`(2026-09-07): 백엔드 값 타입은 백엔드 표면 — 같은 병합으로 실린다
-- (런타임은 `Tween.luau` install이 모듈에 직접도 놓는다 — 형제 설치자와 base 진단 프로브가 본다).
export type RobloxExtension = {
	Declaration: DeclarationModule.Declaration,
	OnChange: OnChangeFn,
	Out: OutFn,
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
			`quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')`,
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	return RobloxFactory(q)
end

return {
	QuadRoblox = QuadRoblox,
}
