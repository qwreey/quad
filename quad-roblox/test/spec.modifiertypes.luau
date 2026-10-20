--!strict
--[[
	Modifier 타이핑(M7 단위 ③·④) — 생성 `<Class>Modifier`(스코프 클래스 + 그 조상 전부)/
	`D.Modifier.<Class>()`/`Field<V>`/검사형 `As<Class>()`/무검사 `As<<T>>()`/
	`Into<Class>` 인터페이스/조상 체인 마커 children 유니언이 실물 규모(Declaration 스코프
	전체)에서 strict를 통과하는가. 양성만 담고 본문은 실행하지 않는다
	(spec.onchangetypes 관례). 음성(다른 클래스 Modifier를 자식 자리에 / 하위가
	아닌 클래스로 As / Into 불만족 / As 뒤 오타 setter)은 luau-test `31`이
	소형으로 고정하고, 실물 규모 음성은 단위 ④ 착수 전 스크래치에서 실측
	(round17 `H-314`~).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
local DeclarationModule = require("../src") -- 3.4.0: the root exports the type names
local Types = require("../src/types")
type State<T> = QuadTypes.State<T>
type None = QuadTypes.None
type Tween<T> = Types.Tween<T>

local q = Quad.NewModule():UseProvider(QuadRoblox)

-- Declaration에 없는 커스텀 Modifier 클래스(컴포넌트 몫) — 타입 별칭 + `Into` 구현만으로
-- Declaration의 클래스와 같은 지위(modifier-plan 11절). 런타임은 `TypedFactory<<T>>(name)` +
-- `DefineSubtype(parent, name)`(spec.modifier 9절).
type MaterialButtonModifier = {
	read __quadModifier: "MaterialButton",
	Elevation: (self: MaterialButtonModifier, value: DeclarationModule.ModifierField<number>) -> MaterialButtonModifier,
	AsMaterialButton: (self: MaterialButtonModifier) -> MaterialButtonModifier,
	AsTextButton: (self: MaterialButtonModifier) -> DeclarationModule.Modifier<TextButton>,
}

local function _neverCalled(custom: MaterialButtonModifier)
	local Frame = q.Elem "Frame"
	local TextButton = q.Elem "TextButton"
	local TextLabel = q.Elem "TextLabel"
	local FrameModifier = q.Modifier "Frame"
	local GuiButtonModifier = q.Modifier "GuiButton"
	local GuiObjectModifier = q.Modifier "GuiObject"
	local InstanceModifier = q.Modifier "Instance"
	local TextButtonModifier = q.Modifier "TextButton"
	-- 사용자 정의 클래스의 타입드 생성자 — T는 호출자가 명시(`As<<T>>()`와 같은 관례)
	local MaterialButton = q.Raw.Modifier.TypedFactory<<MaterialButtonModifier>>("MaterialButton")
	q.Raw.Modifier.DefineSubtype("TextButton", "MaterialButton")
	local made = MaterialButton({ Text = "m" }):Elevation(1):AsMaterialButton()
	-- 클래스별 setter: 리터럴 / State / None / 변환 함수(old는 저장된 그대로)
	-- State 필드: [2026-09-06 M11 `H-327`] plain `Source(T)`가 그대로 들어간다 — [2026-09-07 마커]
	-- `Field<T>`의 State 팔은 공변 `StateMarker<T | Tween<T>>` 하나(옛 "각각 나열"은 소멸), 옛
	-- `UDim2 | Tween<UDim2>` 캐스트(8.7 캐비엇 5 우회)는 이제 그냥 들어간다.
	local size = q.Source(UDim2.new())
	local sizeTween: State<Tween<UDim2>> = size:Compute(function(h: QuadTypes.StateData<UDim2>): Tween<UDim2>
		return q.Tween({ Value = h:Get(), Time = 0.2 })
	end)
	local m = FrameModifier():Size(UDim2.new()):Visible(true):BackgroundColor3(q.None):ZIndex(function(old)
		local _: DeclarationModule.ModifierFieldOut<number>? = old -- round3 Q23 (a): 저장된 그대로(3.4.0: Tween·State는 읽기 뷰)
		return 3
	end)
	-- round13 Q103 (a) (user decision 2026-09-28): `nil` is a documented setter arm — "this Modifier
	-- has no such field" (modifier-plan M-5), same as the constructor table's optional field. Before,
	-- the generated `Field<T>`/`FieldP<T>` lacked it and these three were strict TypeErrors.
	local maybeOrder: number? = nil
	local _nilArms = m:LayoutOrder(nil):LayoutOrder(maybeOrder):LayoutOrder(if maybeOrder then 1 else nil):Style(nil)
	local m2 = m:Size(size):Size(sizeTween) -- State 필드(4-1: 리터럴 State는 통째 교체) — 둘 다
	-- Peek<<T>>: 호출부가 T를 명시(정본 9절), 반환은 raw 유니언 그대로
	local peeked: DeclarationModule.ModifierFieldOut<UDim2>? = m2:Peek<<UDim2>>("Size") -- Q24 후속: old와 같은 FieldOut(Tween 팔 포함)
	-- Apply: 팩토리에 주석을 달면 그대로 타입드(any 인자 — 8.9절); 상위 클래스
	-- 팩토리도 그냥 들어간다(Q5의 Boldify 요구)
	local Boldify = function(mod: DeclarationModule.Modifier<TextButton>): DeclarationModule.Modifier<TextButton>
		return mod:TextSize(20)
	end
	local Raise = function(mod: DeclarationModule.Modifier<GuiObject>): DeclarationModule.Modifier<GuiObject>
		return mod:ZIndex(5)
	end
	local b = TextButtonModifier():Text("x"):Apply(Boldify)
	local b2 = TextButtonModifier():Text("x"):Apply(Raise)
	-- Overridden은 any(스파이크 09) — 닷·콜론 둘 다
	local merged = q.Raw.Modifier.Overridden(m, m2)
	local merged2 = m:Overridden(m2)

	-- ── 단위 ④: 상위 클래스 Modifier + As + Into ─────────────────────────
	local g = GuiObjectModifier():Visible(true):Size(UDim2.new()):Archivable(true)
	local inst = InstanceModifier():Name("n")
	-- 검사형 하강: 하위 클래스만 메소드로 존재(자동완성이 곧 목록), 2단도
	local t = g:AsTextLabel():Text("x"):TextSize(20)
	local fr = g:AsFrame():Style(Enum.FrameStyle.Custom)
	local btn = inst:AsGuiObject():Visible(false):AsTextButton():Text("go")
	-- 항등 As<Self> + 무검사 As<<T>>()(Declaration 밖 타입으로도)
	local same = t:AsTextLabel()
	local forced = g:As<<DeclarationModule.Modifier<TextLabel>>>():Text("z")
	local toCustom = TextButtonModifier():As<<MaterialButtonModifier>>("MaterialButton"):Elevation(2)
	-- [3.4.0] the 3.3 `Into<Class>` interface (any value with `AsTextButton`) is gone — an input position is the tag
	-- marker `ModifierInto<C>` (no methods); a function that calls setters takes the full `Modifier<C>` and callers
	-- narrow with the checked As (custom classes through their own As)
	local function Bold(mod: DeclarationModule.Modifier<TextButton>): DeclarationModule.Modifier<TextButton>
		return mod:TextSize(20)
	end
	local i1 = Bold(GuiButtonModifier():AutoButtonColor(true):AsTextButton()) -- 상위 → 하강
	local i2 = Bold(TextButtonModifier():Text("a")) -- 자기
	local i3 = Bold(custom:AsTextButton()) -- 커스텀 → 자기 As
	local i4 = Bold(g:AsTextButton()):Text("chain")

	-- children: 조상 체인 마커 — 자기 클래스와 조상 클래스의 Modifier만 들어간다
	-- (다른 클래스는 태그 불일치로 거부 — 되찾은 클래스 소속 검사, H-313 닫힘)
	local f = Frame({ m2, Name = "typed", FrameModifier():Visible(false), g, inst })
	local l = TextLabel({ g, t, inst, Text = "hi" })
	local tb = TextButton({ btn, g, GuiButtonModifier():Modal(true), i1 })
	local baseMod = q.Raw.Modifier() -- base 무타입 Modifier는 `true` 마커로 명시 허용
	local f2 = Frame({ baseMod })
	local mapped = q.Mapper "TextLabel"("Body")({ g, t })
	return peeked, b, b2, merged, merged2, same, forced, toCustom, fr, i2, i3, i4, f, l, tb, f2, mapped, made
end

print("=== ALL PASS ===")
