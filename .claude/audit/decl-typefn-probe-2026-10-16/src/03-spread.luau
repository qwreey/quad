--!strict
-- [P3] `Spread<<C>>({ ... })` → `SpreadMarker<C>` — component-flatten-sugar-plan.md 5절 (4)(2026-10-16 사용자 회신):
-- 만드는 자리에서는 `New`와 같은 props 타입(자동완성·진단), 결과는 내용 타입이 없는 마커
-- `{ read __quadSpread: "C" }`, 생성자 배열부는 자기 클래스와 조상 이름의 마커를 받는다. 안쪽 Spread는 만들 때 펴짐(런타임).
-- 보고할 것:
--   (3-a) ★ Spread 중괄호 안 자동완성 ★ — `Back`/`Mouse`.
--   (3-b)~(3-d) "에러여야 정상" 줄.
--   (3-e) `sp` hover — 내용이 사라진 마커 모양으로 보이는가.
local L = require("./Lib")

local Frame = L.New<<Frame>>("Frame")
local TextButton = L.New<<TextButton>>("TextButton")

-- (3-a) ★ 자동완성 자리 ★
local sp = L.Spread<<Frame>>({ BackgroundColor3 = Color3.new(), Visible = true }) -- @c(spread-Back) at='Spread<<Frame>>({ ' ins='Back'
local spg = L.Spread<<GuiObject>>({ Size = UDim2.new(), MouseEnter = function(x, y) end }) -- @c(spread-Mouse) at='Spread<<GuiObject>>({ ' ins='Mouse'
-- CLI(하네스): spread-Back → BackgroundColor3·BackgroundTransparency(후보 63), spread-Mouse → MouseLeave·MouseMoved·MouseWheel…(후보 62) —
--   New와 같은 목록·같은 detail. `MouseEnter = function(x, y)`의 x는 number(문자 키 자리는 문맥 타입이 흐른다).

-- (3-b) 만드는 자리의 진단 — 에러여야 정상
local bad1 = L.Spread<<Frame>>({ Visible = 5 })
local bad2 = L.Spread<<GuiObject>>({ Text = "x" }) -- GuiObject엔 Text 없음
local bad3 = L.Spread<<Frame>>({ AbsoluteSize = Vector2.new() }) -- 읽기 전용
-- CLI: bad1 값 에러 한 건, bad2·bad3 키 에러 두 건씩(New와 같은 모양 — `Expected this to be 'number', but got '"Text"'`).

-- (3-c) 생성자 배열부에 놓기
local e1 = Frame({ sp, spg, Size = UDim2.new() }) -- 정상(자기·조상 클래스)
local e2 = TextButton({ spg, Text = "go" }) -- 정상(GuiObject는 TextButton의 조상)
local e3 = TextButton({ sp }) -- 에러여야 정상(Frame 묶음을 TextButton에)
-- CLI: e1·e2 무진단, e3 `Expected this to be 'Instance | … | { read __quadSpread: "GuiBase" | … | "TextButton" } | …', but got '{ read __quadSpread: "Frame" }'`.

-- (3-d) 안쪽 Spread — 만드는 자리 배열부에 Spread 마커
local nested = L.Spread<<Frame>>({ spg, L.Spread<<Instance>>({ Name = "n" }), BackgroundTransparency = 0.5 }) -- 정상
local nestedBad = L.Spread<<GuiObject>>({ sp }) -- 에러여야 정상(하위 Frame 묶음을 GuiObject 묶음 안에)
-- CLI: nested 무진단, nestedBad 에러(같은 모양).

-- (3-e) 내용 타입 포기 — 같은 키가 겹쳐도 타입은 모른다(런타임 규칙: 직접 쓴 키 > Spread > Modifier)
local over = Frame({ sp, BackgroundColor3 = Color3.new(1, 0, 0) }) -- 정상(덮어쓰기는 런타임 규칙)
local hoverSp = sp -- @h(hover-sp) at='sp -- @h'
-- CLI(하네스 hover): `local sp: { read __quadSpread: "Frame" }` — 내용 타입이 사라진 마커 그대로. over 무진단(겹침은 타입이 모른다).

-- (3-f) 팩토리 꼴 — 사용자 예시 `Hoverable(onEnter, onLeave)`
local function Hoverable(onEnter: () -> (), onLeave: () -> ()): L.SpreadMarker<GuiObject>
	return L.Spread<<GuiObject>>({
		L.OnEvent("MouseEnter", function(_x, _y) onEnter() end),
		L.OnEvent("MouseLeave", function(_x, _y) onLeave() end),
	})
end
local h1 = Frame({ Hoverable(function() end, function() end) }) -- 정상
local h2 = TextButton({ Hoverable(function() end, function() end), Text = "x" }) -- 정상
-- CLI: Hoverable 본문·h1·h2 무진단.

return { sp, spg, bad1, bad2, bad3, e1, e2, e3, nested, nestedBad, over, hoverSp, h1, h2 }
