--!strict
--[[
	Modifier 타이핑(M7 단위 ③·④) — 생성 `<Class>Modifier`(스코프 클래스 + 그 조상 전부)/
	`D.Modifier.<Class>()`/`Field<V>`/검사형 `As<Class>()`/무검사 `As<<T>>()`/
	`Into<Class>` 인터페이스/조상 체인 마커 children 유니언이 실물 규모(D 스코프
	전체)에서 strict를 통과하는가. 양성만 담고 본문은 실행하지 않는다
	(spec.onchangetypes 관례). 음성(다른 클래스 Modifier를 자식 자리에 / 하위가
	아닌 클래스로 As / Into 불만족 / As 뒤 오타 setter)은 luau-test `31`이
	소형으로 고정하고, 실물 규모 음성은 단위 ④ 착수 전 스크래치에서 실측
	(round17 `H-314`~).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
local DModule = require("../src/D")
local Types = require("../src/types")
type State<T> = QuadTypes.State<T>
type None = QuadTypes.None
type Tween<T> = Types.Tween<T>

local q = Quad.New():UseProvider(QuadRoblox)

-- D에 없는 커스텀 Modifier 클래스(컴포넌트 몫) — 타입 별칭 + `Into` 구현만으로
-- D의 클래스와 같은 지위(modifier-plan 11절). 런타임은 `TypedFactory<<T>>(name)` +
-- `DefineSubtype(parent, name)`(spec.modifier 9절).
type MaterialButtonModifier = {
	read __quadModifier: "MaterialButton",
	Elevation: (self: MaterialButtonModifier, value: DModule.Field<number>) -> MaterialButtonModifier,
	AsMaterialButton: (self: MaterialButtonModifier) -> MaterialButtonModifier,
	AsTextButton: (self: MaterialButtonModifier) -> DModule.TextButtonModifier,
}

local function _neverCalled(custom: MaterialButtonModifier)
	local D = q.D
	-- 사용자 정의 클래스의 타입드 생성자 — T는 호출자가 명시(`As<<T>>()`와 같은 관례)
	local MaterialButton = q.Modifier.TypedFactory<<MaterialButtonModifier>>("MaterialButton")
	q.Modifier.DefineSubtype("TextButton", "MaterialButton")
	local made = MaterialButton({ Text = "m" }):Elevation(1):AsMaterialButton()
	-- 클래스별 setter: 리터럴 / State / None / 변환 함수(old는 저장된 그대로)
	-- State 필드: [2026-09-06 M11 `H-327`] plain `Source(T)`가 그대로 들어간다 — [2026-09-07 마커]
	-- `Field<T>`의 State 팔은 공변 `StateMarker<T | Tween<T>>` 하나(옛 "각각 나열"은 소멸), 옛
	-- `UDim2 | Tween<UDim2>` 캐스트(8.7 캐비엇 5 우회)는 이제 그냥 들어간다.
	local size = q.Source(UDim2.new())
	local sizeTween: State<Tween<UDim2>> = size:Compute(function(h: QuadTypes.StateData<UDim2>): Tween<UDim2>
		return q.Tween({ Value = h:Get(), Time = 0.2 })
	end)
	local m = D.Modifier.Frame():Size(UDim2.new()):Visible(true):BackgroundColor3(q.None):ZIndex(function(old)
		local _: number | Tween<number> | State<number> | State<Tween<number>> | None | nil = old
		return 3
	end)
	local m2 = m:Size(size):Size(sizeTween) -- State 필드(4-1: 리터럴 State는 통째 교체) — 둘 다
	-- Peek<<T>>: 호출부가 T를 명시(정본 9절), 반환은 raw 유니언 그대로
	local peeked: UDim2 | State<UDim2> | None | nil = m2:Peek<<UDim2>>("Size")
	-- Apply: 팩토리에 주석을 달면 그대로 타입드(any 인자 — 8.9절); 상위 클래스
	-- 팩토리도 그냥 들어간다(Q5의 Boldify 요구)
	local Boldify = function(mod: DModule.TextButtonModifier): DModule.TextButtonModifier
		return mod:TextSize(20)
	end
	local Raise = function(mod: DModule.GuiObjectModifier): DModule.GuiObjectModifier
		return mod:ZIndex(5)
	end
	local b = D.Modifier.TextButton():Text("x"):Apply(Boldify)
	local b2 = D.Modifier.TextButton():Text("x"):Apply(Raise)
	-- Overridden은 any(스파이크 09) — 닷·콜론 둘 다
	local merged = q.Modifier.Overridden(m, m2)
	local merged2 = m:Overridden(m2)

	-- ── 단위 ④: 상위 클래스 Modifier + As + Into ─────────────────────────
	local g = D.Modifier.GuiObject():Visible(true):Size(UDim2.new()):Archivable(true)
	local inst = D.Modifier.Instance():Name("n")
	-- 검사형 하강: 하위 클래스만 메소드로 존재(자동완성이 곧 목록), 2단도
	local t = g:AsTextLabel():Text("x"):TextSize(20)
	local fr = g:AsFrame():Style(Enum.FrameStyle.Custom)
	local btn = inst:AsGuiObject():Visible(false):AsTextButton():Text("go")
	-- 항등 As<Self> + 무검사 As<<T>>()(D 밖 타입으로도)
	local same = t:AsTextLabel()
	local forced = g:As<<DModule.TextLabelModifier>>():Text("z")
	local toCustom = D.Modifier.TextButton():As<<MaterialButtonModifier>>("MaterialButton"):Elevation(2)
	-- Into<Class>: 상위·자기·커스텀 구현체 전부 받는 인터페이스
	local function Bold(mod: DModule.IntoTextButton): DModule.TextButtonModifier
		return mod:AsTextButton():TextSize(20)
	end
	local i1 = Bold(D.Modifier.GuiButton():AutoButtonColor(true)) -- 상위
	local i2 = Bold(D.Modifier.TextButton():Text("a")) -- 자기(항등)
	local i3 = Bold(custom) -- 커스텀
	local i4 = Bold(g):AsTextButton():Text("chain") -- Into → As 연쇄

	-- children: 조상 체인 마커 — 자기 클래스와 조상 클래스의 Modifier만 들어간다
	-- (다른 클래스는 태그 불일치로 거부 — 되찾은 클래스 소속 검사, H-313 닫힘)
	local f = D.Frame({ m2, Name = "typed", D.Modifier.Frame():Visible(false), g, inst })
	local l = D.TextLabel({ g, t, inst, Text = "hi" })
	local tb = D.TextButton({ btn, g, D.Modifier.GuiButton():Modal(true), i1 })
	local baseMod = q.Modifier() -- base 무타입 Modifier는 `true` 마커로 명시 허용
	local f2 = D.Frame({ baseMod })
	local mapped = D.Mapper.TextLabel("Body")({ g, t })
	return peeked, b, b2, merged, merged2, same, forced, toCustom, fr, i2, i3, i4, f, l, tb, f2, mapped, made
end

print("=== ALL PASS ===")
