--!strict
-- [P4] `OnEvent(name, fn)` — `OnChange`의 짝인 배열부 이벤트 디스크립터(2026-10-16 사용자 결정 (가)).
-- 이름 집합은 OnChange의 `PropTypesRead`처럼 스코프 전체 맵 `Lib.EventMap`(= 타입 함수가 31 클래스의 이벤트를 모은 것,
-- 콜백은 `RBXScriptSignal`의 `Connect` 2번째 인자에서 꺼냄 — 9/16 [P6-4]), `name: K & keyof<EventMap>`,
-- `fn: index<EventMap, K>`(typing-limits 8.7 패턴). 결과는 `{ read __quadEvent: K }` — 클래스 소속은 놓이는 자리(생성자·
-- Spread 배열부)에서 그 클래스의 이벤트 이름 유니언과 대조한다.
-- 보고할 것:
--   (4-a) ★ `OnEvent("` 안에서 문자열 자동완성 ★ — 이벤트 이름 목록이 뜨는가, 몇 개인가(스코프 전체라 클래스와 무관).
--   (4-b) 무주석 콜백 `x` hover가 number인가.
--   (4-c)~(4-e) "에러여야 정상" 줄.
--   (4-f) 클래스를 아는 변형 둘 — 자동완성 목록이 그 클래스로 좁혀지는가.
local L = require("./Lib")

local Frame = L.New<<Frame>>("Frame")
local TextButton = L.New<<TextButton>>("TextButton")

-- (4-a) ★ 자동완성 자리 ★ — 따옴표 안
local ev1 = L.OnEvent("MouseEnter", function(x, y) end) -- @c(onevent-name) at='OnEvent("' ins='Mouse'
local ev0 = L.OnEvent("Activated", function(input, count) end) -- @c(onevent-empty) at='OnEvent("'
-- CLI(하네스 vsc·sync·pin 같음): 따옴표 안 자동완성 — 이벤트 이름 49개(스코프 31 클래스 전체: Activated·DidLoop·FocusLost·PageEnter·
--   Played…까지, 클래스와 무관) kind=Constant. `Mouse`로는 MouseButton1Click…MouseWheelForward.

-- (4-b) 콜백 인자 추론
local ev2 = L.OnEvent("MouseEnter", function(x, y) -- @h(infer-x) at='x, y'
	local s: string = x -- 에러여야 정상(x는 number로 추론돼야)
end)
local ev2b = L.OnEvent("MouseEnter", function(x, y) end) -- @h(infer-x-plain) at='x, y'
-- CLI(하네스 hover): infer-x-plain `local x: unknown` — **무주석 콜백 인자가 문맥 타입을 못 받는다.** ev2의 에러
--   (`Expected this to be 'number', but got 'string'`)는 x가 본문 사용(`local s: string = x`)에서 string으로 굳은 뒤 대조된 것이고
--   (@h(infer-x) `local x: string`), 아래 ev3의 `input.` 자동완성도 본문에서 쓴 이름 하나(unknown)뿐이다. 같은 일이 지금의 생성
--   `OnChangeFn`(`fn: (index<PropTypesRead, K>) -> ()`)에서도 난다(이 환경 1.70.1·1.69.0 실측 — `OnChange("Visible", function(v) … end)`의
--   v가 unknown, 본문에 `local s: string = v`를 두면 "Parameter 'v' has been reduced to never" — typing-limits 8.7 3번 "무주석 추론"
--   서술과 어긋남, 메인 확인 필요). 해법 후보는 (4-g) 커리 꼴.

local ev3 = L.OnEvent("InputBegan", function(input)
	local _ = input.UserInputType -- @c(infer-input-dot) at='input.' ins='User'
end)

-- (4-c) 이름·콜백 진단 — 에러여야 정상
local bad1 = L.OnEvent("MouseEntr", function() end)
local bad2 = L.OnEvent("MouseEnter", function(s: string) end)
-- CLI: bad1 세 건(`Property '"MouseEntr"' does not exist on type 'EventMap'` + 이름 교집합 + fn 자리 never), bad2 한 건
--   (`Expected this to be 'number', but got 'string'`) — 주석 단 콜백은 정확히 잡힌다.

-- (4-d) 놓이는 자리에서 클래스 소속 대조
local p1 = Frame({ ev1 }) -- 정상
local p2 = Frame({ ev0 }) -- 에러여야 정상(Activated는 GuiButton 이벤트 — Frame엔 없음)
local p3 = TextButton({ ev0, ev1 }) -- 정상
local p4 = Frame({ L.OnEvent("MouseLeave", function(_x, _y) end), L.OnEvent("MouseLeave", function() end) }) -- 같은 이름 둘 — 정상(각각 연결)
-- CLI: p2만 에러(`… { read __quadEvent: "AncestryChanged" | … } …', but got 'EventDesc<"Activated">'`). p1·p3·p4 무진단.

-- (4-e) 클래스를 모르는 자리(Spread 안)
local s1 = L.Spread<<GuiObject>>({ L.OnEvent("MouseEnter", function(_x, _y) end) }) -- 정상
local s2 = L.Spread<<GuiObject>>({ L.OnEvent("Activated", function() end) }) -- 에러여야 정상(GuiObject엔 없음)
local s3 = L.Spread<<Instance>>({ L.OnEvent("Destroying", function() end) }) -- 정상(Instance 이벤트)
local s4 = L.Spread<<Instance>>({ L.OnEvent("MouseEnter", function() end) }) -- 에러여야 정상
local s5 = L.Spread<<GuiButton>>({ L.OnEvent("Activated", function(input, count) end) }) -- 정상(추상 클래스 GuiButton)
-- CLI: s2·s4 에러, s1·s3·s5 무진단 — 클래스를 모르는 OnEvent가 Spread<<C>>의 배열부에서 C의 이벤트 이름으로 걸러진다.

-- (4-f) 클래스를 아는 변형 — 이름 목록을 클래스로 좁힐 수 있나
local f1 = L.OnEventIn<<Frame>>("MouseEnter", function(x, y) end) -- @c(onevent-in) at='OnEventIn<<Frame>>("' ins='Mouse'
local f2 = L.OnEventIn<<Frame>>("Activated", function() end) -- 에러여야 정상(부분 명시 타입 인자 <<C>>만, K는 추론)
local FrameEvent = L.OnEventFor<<Frame>>() -- 파일 위에서 꺼내 두는 꼴
local f3 = FrameEvent("MouseLeave", function(x, y) end) -- @c(onevent-for) at='FrameEvent("' ins='Mouse'
local f4 = FrameEvent("Activated", function() end) -- 에러여야 정상
-- CLI: 부분 명시 타입 인자 `OnEventIn<<Frame>>(…)`(C만 주고 K는 추론)가 문법·검사 모두 된다. f2·f4 각 세 건
--   (`Property '"Activated"' does not exist on type '{ read AncestryChanged: …, ... 25 more ... }'` 등). 하네스: onevent-in·onevent-for
--   자동완성이 Frame 이벤트 26개로 좁혀진다. 단 두 꼴 모두 무주석 콜백 인자는 unknown(위와 같은 이유).

-- (4-g) 커리 꼴 `OnEventC("이름")(fn)` — 첫 호출이 K를 정하므로 둘째 호출의 fn 자리는 구체 함수 타입이 된다.
-- 무주석 콜백 인자가 문맥으로 타입을 받는가(hover·`input.` 자동완성) — (4-b)와 비교할 것.
local c1 = L.OnEventC("MouseEnter")(function(x, y) -- @h(curry-x) at='x, y'
	local s: string = x -- 에러여야 정상
end)
local c2 = L.OnEventC("InputBegan")(function(input)
	local _ = input.UserInputType -- @c(curry-input-dot) at='input.' ins='User'
end)
local c3 = L.OnEventC("MouseMoved")(function(_x, _y) end) -- @c(curry-name) at='OnEventC("' ins='Mouse'
local c4 = Frame({ c1, c2, L.OnEventC("MouseLeave")(function(x, y) end) }) -- 정상
local c5 = Frame({ L.OnEventC("Activated")(function() end) }) -- 에러여야 정상
-- CLI(하네스): curry-x `local x: number`, curry-input-dot → InputObject 필드 64개(UserInputState·UserInputType: Enum.UserInputType …),
--   curry-name 이름 자동완성 49개(비커리와 같음). c1 본문 `Expected this to be 'string', but got 'number'`(문맥 타입이 흘러 본문에서 바로 잡힘),
--   c5 에러, c4 무진단. 즉 첫 호출이 K를 정하면 둘째 호출의 fn 자리가 구체 함수 타입이 돼 문자 키 자리(`MouseEnter = function(x, y)`)와 같아진다.

-- (4-h) 고정 4인자 꼴 `OnEventP` — fn: (index<index<EventArgs,K>,"a1">, …a4) -> (). 인자 수는 보이지만 문맥 타입은?
local p5 = L.OnEventP("MouseEnter", function(x, y) end) -- @h(fixed-x) at='x, y'
-- CLI(하네스): fixed-x `local x: unknown` — 인자 수를 함수 타입 모양으로 박아도 K가 같은 호출에서 정해지는 한 문맥 타입은 안 흐른다.
--   (주석 단 오용은 `Expected this to be '(number, number, nil, nil) -> ()'`로 잡힘.)

return { ev1, ev0, ev2, ev2b, ev3, bad1, bad2, p1, p2, p3, p4, s1, s2, s3, s4, s5, f1, f2, f3, f4, c1, c2, c3, c4, c5, p5 }
