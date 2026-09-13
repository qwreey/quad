--[[
	M9 컴포넌트 합성 관례 (round21) — `base/component-composition-plan.md`
	"최종 결론" 절의 정식화: 컴포넌트 = 플레인 함수, 경계는 named parameter
	`props.Modifier`/`props.Ref`(Q2 가칭 — 회신 전), 저작자가 `or None`으로 되꽂음,
	여러 modifier는 `Modifier.Overridden`, Slot 반환 컴포넌트는 그 파라미터가 없다.
	스파이크 `06`(nil-hole)의 정식화. CLI 심은 spec.handlers 관용구.
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
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "BackgroundTransparency", Permits = W }, { Name = "Size", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(installShorthand) :: any).UDim = { new = function(s: number, o: number) return { Scale = s, Offset = o } end }
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.isInst = mock.isMockInstance

local D, None, Modifier = q.Declaration, q.None, q.Modifier

-- ── 예제 ① 단일 루트 컴포넌트 — 정본 관용구 그대로 ─────────────────────────
-- props: { Text: string?, Corner: number?, Modifier: TextButtonModifier?, Ref: Ref<TextButton?>?, Content: Instance? }
local function MaterialButton(props: any): any
	return D.TextButton({
		props.Modifier or None, -- ⭐ 필수 관용구: nil-hole 방지(정본 "최종 결론" 1)
		props.Ref or None,
		props.Content or None,
		Text = props.Text or "",
		UICorner = props.Corner or 4,
	})
end

-- ── 예제 ② Slot 반환 컴포넌트 — Modifier/Ref 파라미터가 없다(정본 "최종 결론" 2) ──
local function ItemList(props: any): any
	local slot = q.Slot()
	for _, name in props.Items do
		slot:Add(D.TextLabel({ Text = name }))
	end
	return slot
end

print("=== 1. 단일 루트 — Modifier/Ref/자식이 named parameter로 경계를 넘어 내부 루트에 꽂힌다 ===")
do
	local ref = q.Ref()
	local content = D.TextLabel({ Text = "icon" })
	local btn = MaterialButton({
		Text = "OK",
		Corner = 8,
		Modifier = D.Modifier.TextButton():BackgroundTransparency(0.5),
		Ref = ref,
		Content = content,
	})
	assert(btn.ClassName == "TextButton" and btn.Text == "OK", "root built")
	assert(btn.BackgroundTransparency == 0.5, "modifier applied to the root")
	assert(ref.Value == btn, "ref bound to the root")
	assert(content.Parent == btn, "child forwarded")
	local corner = nil
	for _, c in btn:GetChildren() do if c.Name == "_quad_round" then corner = c end end
	assert(corner ~= nil and corner.CornerRadius.Offset == 8, "shorthand inside the component")
	print("PASS")
end

print()
print("=== 2. 생략 — Modifier/Ref/Content를 안 넘겨도 `or None`이 그 자리를 기여 0으로 만든다(nil-hole 없음) ===")
do
	local btn = MaterialButton({ Text = "bare" })
	assert(btn.Text == "bare", "root built without forwarded values")
	local n = 0
	for _, c in btn:GetChildren() do if c.Name ~= "_quad_round" then n += 1 end end
	assert(n == 0, "no stray children from None slots")
	-- Ref만 넘겨도(Modifier nil) 위치가 밀리지 않는다 — None이 자리를 지킨다
	local ref = q.Ref()
	local btn2 = MaterialButton({ Ref = ref, Content = D.TextLabel({ Text = "x" }) })
	assert(ref.Value == btn2, "ref still binds with a None before it")
	print("PASS")
end

print()
print("=== 3. Modifier.Overridden — caller가 여러 modifier를 한 슬롯에 밀어넣는다(뒤가 이김) ===")
do
	local theme = D.Modifier.TextButton():BackgroundTransparency(0.2):Text("theme")
	local override = D.Modifier.TextButton():BackgroundTransparency(0.9)
	local btn = MaterialButton({ Text = "merged", Modifier = Modifier.Overridden(theme, override) })
	assert(btn.BackgroundTransparency == 0.9, "later modifier wins per field")
	assert(btn.Text == "merged", "props의 Text(해시 키)가 modifier의 Text보다 뒤 — 해시 파트 순서(정본 flatten 규칙)")
	print("PASS")
end

print()
print("=== 4. Slot 반환 컴포넌트 — 형제 레벨에 래퍼 없이 펼쳐지고, 추가 항목이 그 자리에 끼어든다 ===")
do
	local header = D.TextLabel({ Text = "H" })
	local footer = D.TextLabel({ Text = "F" })
	local list = ItemList({ Items = { "a", "b" } })
	local frame = D.Frame({ header, list, footer })
	local names = {}
	for _, c in frame:GetChildren() do table.insert(names, c.Text) end
	assert(table.concat(names, ",") == "H,a,b,F", "flattened between siblings: " .. table.concat(names, ","))
	-- 논리 순서는 Length/Offset 부기(정본 slot-plan) — 물리 자식 순서는 백엔드 몫이라
	-- mock의 GetChildren은 부착 순서일 뿐(ROADMAP 백로그 "Slot 형제 순서 보장")
	assert(q.Dispatch.getOffsetAt(frame, 3) == 3, "footer sits after header(1) + list(2)")
	list:Add(D.TextLabel({ Text = "c" }))
	assert(q.Dispatch.getOffsetAt(frame, 3) == 4, "later Add shifts the footer's logical offset")
	local found = false
	for _, c in frame:GetChildren() do if c.Text == "c" then found = c.Parent == frame end end
	assert(found, "added item is a physical child of the parent")
	print("PASS")
end

print()
print("=== 5. 커스텀 클래스 Modifier — 컴포넌트가 자기 필드를 소비한 뒤 무검사 As(name)로 부모 클래스에 꽂는다(11절: 검사형 As는 하강만) ===")
do
	local Material = Modifier.TypedFactory("MaterialButtonSpec")
	Modifier.DefineSubtype("TextButton", "MaterialButtonSpec")
	local mod = Material({ BackgroundTransparency = 0.3 })
	-- 검사형 상향은 정본대로 거부된다(11절 — 하강 전용); 상향은 무검사 As(name)
	assert(not pcall(function() return mod:AsTextButton() end), "checked upcast is rejected by design")
	local function MaterialButtonComp(props: any): any
		local forwarded = if props.Modifier then props.Modifier:As("TextButton") else None
		return D.TextButton({ forwarded, Text = "m" })
	end
	local btn = MaterialButtonComp({ Modifier = mod })
	assert(btn.BackgroundTransparency == 0.3 and btn.Text == "m", "subtype modifier forwarded as a TextButton modifier")
	-- `H-340`(§4 문항): 커스텀 필드는 벗겨낼 길이 없다 — `:Elevation(None)`은 키를 지우는 게
	-- 아니라 None을 디스패치하고(정본 `None` 센티널), TextButton엔 Elevation 핸들러가 없어 error.
	local withField = Material({ Elevation = 2 })
	local ok, err = pcall(function()
		return D.TextButton({ withField:Elevation(None):As("TextButton") })
	end)
	assert(not ok and string.find(tostring(err), "no handler matched key Elevation", 1, true) ~= nil, "observed gap (H-340): " .. tostring(err))
	print("PASS")
end

print()
print("=== ALL PASS ===")
