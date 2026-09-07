--!strict
--[[
	M9 컴포넌트 합성 — strict 양성(round21). props 타입에 생성 `<Class>Modifier`·
	`Into<Class>`(커스텀 클래스 Modifier를 인터페이스로 받는 정본 11절 관례)·
	`Ref<Class?>`가 실리고, 컴포넌트가 `or None`으로 되꽂는 관용구가 `<Class>Elem`
	유니언(마커·RefMarker·None)을 통과하는가. 본문은 실행하지 않는다.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
local DModule = require("../src/D")

local q = Quad.New():UseProvider(QuadRoblox)

type ButtonProps = {
	read Text: string?,
	read Modifier: DModule.IntoTextButton?, -- 인터페이스 `Into<TextButton>`: TextButtonModifier·상위 클래스·커스텀 구현체 전부
	read Ref: QuadTypes.Ref<TextButton?>?,
	read Content: Instance?,
}

local function MaterialButton(props: ButtonProps): TextButton
	return q.D.TextButton({
		if props.Modifier then props.Modifier:AsTextButton() else q.None,
		props.Ref or q.None,
		props.Content or q.None,
		Text = props.Text or "",
		UICorner = 4,
	})
end

type MaterialModifier = {
	read __quadModifier: "MaterialButtonTyped",
	AsTextButton: (self: MaterialModifier) -> DModule.TextButtonModifier,
	AsMaterialButtonTyped: (self: MaterialModifier) -> MaterialModifier,
}

-- `H-351`: children 자리의 Slot(정본 bind-system-plan "children 원소" 확장 규칙의 M6 팔)
local function _slotChild()
	local slot = q.Slot() :: QuadTypes.Slot<Instance> -- 생성자 제네릭 추론은 캐스트로(`H-354`)
	return q.D.Frame({ slot }), q.D.ScrollingFrame({ q.D.Frame({}), slot, q.None })
end

-- `H-355` / Q2 (a): children 자리의 Observer·EffectHandle(정본 leaf 관용구 — strict 유니언 팔)
local function _observerChild()
	local s = q.Source(1)
	local o = s:Observer(function() end)
	local e = q.Effect(function() end)
	return q.D.Frame({ o, e }), q.D.TextLabel({ q.None, o, q.D.Frame({}), e })
end

-- [2026-09-07 마커, 사용자 결정 — 공변/불변] 옛 전체형 `State<Instance>`·`Slot<Instance>` 팔이 거부하던
-- 것들이 마커 팔(`StateMarker`/`SlotMarker`, typing-limits 8.11)에 든다. 음성(State<number> 자식·형제 Ref의
-- State·State<Modifier>·`Slot<Frame>`에 State<TextLabel> 요소 등 아홉)은 2026-09-07 tmp 프로브로 전부 거부 확인
-- (원장 round1 §16). `q.Slot()` 캐스트 없는 생성(`H-354`)은 그대로 안 된다 — 생성자 `T` 추론 문제라 별개.
local function _markerChildren()
	local frameState = q.Source(q.D.Frame({})) -- Source<Frame> — 옛 State<Instance> 불변 팔은 거부했다
	local maybe = q.Source(nil :: Frame?) -- State<Instance?> — NilHandler 팔(`State<Slot|nil>` 계약)
	local slot = q.Slot() :: QuadTypes.Slot<Frame> -- Slot<Frame>이 SlotMarker<Instance>에(공변)
	local slotState = q.Source(slot) -- State<Slot<Frame>> — Q1의 원래 팔, 팔 추가 없이 든다
	local ref = q.Ref(nil :: Frame?)
	local refState = q.Source(ref) -- State<Ref<Frame?>> — 8.7 캐비엇 5의 `:: FrameRefMarker` 캐스트 불필요
	local outer = q.Slot() :: QuadTypes.Slot<Instance>
	outer:Add(slot) -- Slot 요소 자리도 마커: Slot<Frame> → Slot<Instance>
	outer:Add(frameState)
	local got: QuadTypes.SlotItem<Instance>? = outer:Get(1) -- 출력은 전체형(SlotItem)
	return q.D.Frame({ frameState, maybe, slot, slotState, refState, got :: any }), q.D.ScrollingFrame({ outer })
end

local function _neverCalled()
	local ref = q.Ref(nil :: TextButton?)
	local a: TextButton = MaterialButton({ Text = "a", Modifier = q.D.Modifier.TextButton():BackgroundTransparency(0.5), Ref = ref, Content = q.D.TextLabel({}) })
	local b: TextButton = MaterialButton({ Modifier = q.D.Modifier.GuiObject():ZIndex(2) }) -- 상위 클래스 Modifier도 Into<TextButton>
	local Material = q.Modifier.TypedFactory<<MaterialModifier>>("MaterialButtonTyped")
	q.Modifier.DefineSubtype("TextButton", "MaterialButtonTyped")
	local c: TextButton = MaterialButton({ Modifier = Material({}) }) -- 커스텀 클래스 구현체
	local d: TextButton = MaterialButton({})
	local parent = q.D.Frame({ a, b, c, d })
	return parent
end

print("=== ALL PASS ===")
