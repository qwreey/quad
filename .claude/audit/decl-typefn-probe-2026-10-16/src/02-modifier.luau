--!strict
-- [P2] `Modifier<Frame>` 타입 함수 — 지금의 생성 `<Class>Modifier`(예: FrameModifier, 클래스마다 50줄 안팎 복제)를
-- 대신할 수 있는가. 타입은 `Lib.Modifier<C>`(= `Build<"modifier", C, Policy>`): setter마다 `(self, 값 | 변환 함수) -> self`인
-- 재귀 테이블 + 태그 `__quadModifier: "Frame"` + 예약 제네릭 메소드 `Peek`/`Apply`.
-- 보고할 것:
--   (2-a) ★ `m:` 뒤 메소드 자동완성 ★ — `Back`, 그리고 체인 중간(`):`) 뒤 `Vis`.
--   (2-b)~(2-e) "에러여야 정상" 줄의 빨간 줄과 메시지.
--   (2-f) `m`/`chained` hover 모양.
local L = require("./Lib")

local Frame = L.New<<Frame>>("Frame")
local TextLabel = L.New<<TextLabel>>("TextLabel")
type FrameModifier = L.Modifier<Frame> -- 사용자가 파일 위에서 꺼내 쓰는 꼴(사용자 원문 "local FrameModifier ...")
type GuiObjectModifier = L.Modifier<GuiObject>

-- (2-a) ★ 자동완성 자리 ★
local m = L.Modifier<<Frame>>()
local c1 = m:BackgroundTransparency(0.5) -- @c(mod-Back) at='m:' ins='Back'
local chained = m:Size(UDim2.fromScale(1, 1)):Visible(true):BackgroundColor3(Color3.new()) -- @c(chain-Vis) at='m:Size(UDim2.fromScale(1, 1)):' ins='Vis'
-- CLI(하네스 vsc·sync·pin 같음): mod-Back → BackgroundColor3·BackgroundTransparency, chain-Vis → Visible. 메소드 후보 40개
--   (setter + Apply·Peek; 이벤트·읽기 전용 없음). 단 각 후보의 detail이 `t2 where t1 = { Active: (t1, …) -> t1, ... 40 more ... }`
--   꼴의 재귀 전개라 길다(생성 D는 `(FrameModifier, …) -> FrameModifier`로 별칭 이름이 보인다 — out/lsp-gend-compare.txt).

-- (2-b) 값 진단 — 에러여야 정상
local b1 = m:BackgroundTransparency("nope")
local b2 = m:Visible(5)
local b3 = m:AbsoluteSize(Vector2.new()) -- 읽기 전용 — setter 자체가 없어야 함
local b4 = m:MouseEnter(function() end) -- 이벤트는 Modifier에 없음(생성 D와 같은 정책)
local ok1 = m:Size(function(old) return old end) -- 변환 함수 — 정상(old: UDim2?)
local ok2 = m:Size(L.Tween(UDim2.new())):Visible(L.None) -- 정상
-- CLI: b1·b2 값 에러(기대 타입은 `((number?) -> (…)?) | number | { read Value: number, read __quadTween: true } | …` 전개),
--   b3·b4 `Key 'AbsoluteSize' not found in table 't1 where t1 = { Active: … }'`·`Key 'MouseEnter' not found …`. ok1·ok2 무진단.

-- (2-c) 태그
local tag: "Frame" = chained.__quadModifier -- 정상
local tagBad: "GuiObject" = chained.__quadModifier -- 에러여야 정상
-- CLI: tagBad `Expected this to be '"GuiObject"', but got '"Frame"'` — 체인 뒤에도 태그 리터럴 유지.

-- (2-d) 예약 제네릭 메소드(§6·8.29 — 타입 함수를 거친 테이블에서 제네릭 메소드가 살아 있나)
local peeked = m:Peek<<UDim2>>("Size") -- @h(peek) at='peeked'
local applied = m:Apply(function(_x) return 1 end) -- @h(apply) at='applied'
local afterPeek = m:Size(UDim2.new()):Peek<<number>>("Rotation")
-- CLI(하네스 hover): peeked `UDim2?`, applied `any`(팩토리가 `(any) -> number`인데 U가 number로 안 묶임 — typing-limits 8.29가
--   생성 D의 Apply에서 본 "U가 결과를 제약하지 않는다"와 같은 증상으로 보임, 생성 D와 직접 대조는 안 함). afterPeek 무진단. 타입 함수가 만든 제네릭 메소드(types.generic)는 체인 뒤에도 쓸 수 있었다(§6 증상 없음).

-- (2-e) 요소에 넣기(배열부 마커) — 상위 클래스 Modifier는 하위 요소에 들어가고 형제는 거부
local gm = L.Modifier<<GuiObject>>():Visible(false)
local e1 = Frame({ m, gm }) -- 정상
local e2 = TextLabel({ gm }) -- 정상
local e3 = TextLabel({ m }) -- 에러여야 정상(Frame Modifier를 TextLabel에)
-- CLI: e1·e2 무진단, e3 에러(배열부 유니언 대 Modifier 전개 — 메시지는 Modifier 전체가 펼쳐져 길다).

-- (2-f) 사용자 별칭으로 받는 함수
local function styled(mod: FrameModifier): FrameModifier
	return mod:ZIndex(2)
end
local s1 = styled(L.Modifier<<Frame>>()) -- 정상
local s2 = styled(gm) -- 상위 Modifier를 하위 별칭 자리에 — 무엇이 뜨는가(구조가 달라 에러 예상)
local hoverM = m -- @h(hover-m) at='m -- @h'
-- CLI: s1 무진단, s2 에러 — `Expected this to be 'FrameModifier' but got 't1 where t1 = { … }'`, 이유 줄
--   `Expected property __quadModifier … to be exactly "Frame", but got "GuiObject"`. hover-m은 `t1 where t1 = { Active: …, ... 40 more ... }`.
--   생성 FrameModifier와 서로 대입은 안 된다(harness/compare/coexist.luau — setter 값 팔이 달라 재귀 메소드 불변성); 배열부 마커로는 서로의
--   요소에 들어간다.

return { c1, chained, b1, b2, b3, b4, ok1, ok2, tag, tagBad, peeked, applied, afterPeek, e1, e2, e3, s1, s2, hoverM }
