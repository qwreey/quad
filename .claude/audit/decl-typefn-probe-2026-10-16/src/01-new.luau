--!strict
-- [P1] 클래스 매개 타입 함수로 만든 요소 생성자 — `local Frame = New<<Frame>>("Frame")`.
-- 지금의 생성 D(`D.Frame { ... }`)를 대신해, 파일 위에서 쓸 클래스를 꺼내 두는 표면(사용자 원문
-- declaration-surface-plan.md 1절). props 타입은 `Lib.Props<C>`(타입 함수 `Build<"props", C, Policy>`)가
-- 클래스 타입의 properties()/readparent()를 걸어 올라가며 만든다.
-- 보고할 것(파일 번호 + 항목, 예: "1-b Back 자동완성 뜸"):
--   (1-a) 아래 만드는 형태 넷 — 어느 줄에 빨간 줄이 뜨는가.
--   (1-b) ★ 자동완성 ★ — 표시된 중괄호 안에서 `Back`/`Mouse`를 쳤을 때 목록(프로퍼티·이벤트)이 뜨는가.
--   (1-c)~(1-e) "에러여야 정상" 줄에 실제로 빨간 줄이 뜨는가, 메시지 원문 한두 개.
--   (1-f) `Frame` 위에 마우스를 올렸을 때(hover) 보이는 타입 모양.
local L = require("./Lib")

-- (1-a) 만드는 형태
local Frame = L.New<<Frame>>("Frame") -- 사용자 원문 꼴(괄호)
local TextLabel = L.New<<TextLabel>> "TextLabel" -- 괄호 없는 문자열 호출 꼴
local Bad = L.New<<Frame>>("TextLabel") -- 에러여야 정상: 클래스 이름 불일치(ClassName<C> 검사)
local Loose: L.Ctor<Frame> = L.NewLoose("Frame") -- 주석만으로 C를 채울 수 있나(명시 인스턴스화 없이)
-- CLI(vsc·pin 같음): Bad 줄 `Expected this to be '"Frame"', but got '"TextLabel"'`.
-- CLI(vsc·sync·pin 같음): Loose 줄 에러 — 기대 타입(주석)에서 C가 추론되지 않는다:
--   `Expected this to be '({ [number]: … }) -> Frame' but got '(Build<"props", unknown, Policy>) -> unknown'` — 명시 `<<Frame>>`가 필요.
--   Frame·TextLabel 두 줄은 무진단(괄호 없는 `New<<C>> "C"` 꼴도 문법·검사 모두 통과).

-- (1-b) ★ 자동완성 자리 ★ — `{ ` 뒤에서 Back / Mouse 를 쳐 볼 것
local ok1 = Frame({ BackgroundColor3 = Color3.new(1, 1, 1), Visible = true, Size = UDim2.fromScale(1, 1) }) -- @c(frame-Back) at='Frame({ ' ins='Back'
local ok2 = Frame({ Size = UDim2.new(), MouseEnter = function(x, y) end }) -- @c(frame-Mouse) at='Frame({ ' ins='Mouse'
local ok3 = TextLabel({ Text = "hi", TextSize = 18, Font = Enum.Font.Arial }) -- @c(label-Te) at='TextLabel({ ' ins='Te'
local ok4 = L.New<<TextLabel>>("TextLabel")({ Text = "inline" }) -- @c(inline-Te) at='("TextLabel")({ ' ins='Te'
-- CLI(하네스 vsc·sync·pin 같음): frame-Back → BackgroundColor3·BackgroundTransparency(키 후보 62개 전체 — 프로퍼티와 이벤트가
--   한 목록, detail에 유니언 전문), frame-Mouse → MouseLeave·MouseMoved·MouseWheelBackward·MouseWheelForward(이미 쓴 MouseEnter는 빠짐),
--   label-Te → Text·TextColor3·TextDirection·TextScaled·TextStrokeColor3·TextStrokeTransparency·…(TextBounds·TextFits는 Deny라 없음),
--   inline-Te(만들자마자 부르는 꼴)도 같은 목록. 응답 0.03~0.06s. 원문 out/lsp-vsc.txt

-- (1-c) 값 타입 진단 — 전부 에러여야 정상
local bad1 = Frame({ Visible = 5 })
local bad2 = Frame({ BackgroundColor3 = "red" })
local bad3 = Frame({ MouseEnter = function(s: string) end }) -- 콜백 인자 타입 불일치
local bad4 = Frame({ Style = L.Tween(Enum.FrameStyle.Custom) }) -- Enum은 Tween 팔이 없다(보간 불가)
local ok5 = Frame({ Size = L.Tween(UDim2.new()), BackgroundTransparency = L.None }) -- 정상
-- CLI: bad1 `Expected this to be '(boolean | { read Value: boolean, read __quadTween: true } | { read __quadNone: true } |
--   { read __quadState: true, read __quadStateValue: boolean })?', but got 'number'` — 생성 D와 같은 자리·같은 뜻(생성 D는 별칭 이름
--   `None`/`StateMarker<…>`/`TweenData<…>`로 보이고, 여기선 구조가 펼쳐져 보인다). bad2·bad3·bad4 각각 한 건(bad4는
--   `… but got 'TweenData<Enum.FrameStyle>'`). ok5 무진단.

-- (1-d) 읽기 전용·폐기 이름 — Policy.Deny로 키에서 뺐다. 에러여야 정상
local ro1 = Frame({ AbsoluteSize = Vector2.new(1, 1) })
local ro2 = Frame({ ClassName = "x" })
local ro3 = Frame({ BackgroundColor = BrickColor.Red() }) -- Studio에만 있는 deprecated 이름(9/16 [P3-d])
-- CLI: 셋 다 에러 두 건씩 — 9/16 4번과 같은 모양: 키가 없으니 숫자 인덱서로 대조돼
--   `Expected this to be 'number', but got '"AbsoluteSize"'` + 값 쪽 `Expected this to be 'Instance | …Elem…', but got 'Vector2'`.
--   읽기 전용이라는 말은 메시지에 없다(생성 D도 같다 — 키가 없는 것이 처리 방식).

-- (1-e) 상위 클래스 공통(GuiObject) — 상속 프로퍼티와 GuiObject props를 받는 컴포넌트
local inh = Frame({ Name = "x", Archivable = false, ZIndex = 2 }) -- Instance·GuiObject 레벨 이름도 키로
local function Card(props: L.Props<GuiObject>): Frame
	return Frame(props) -- GuiObject props 값을 Frame 생성자로 그대로 넘길 수 있나
end
local card = Card({ Visible = true, Size = UDim2.new() })
local Abstract = L.New<<GuiObject>>("GuiObject") -- 타입으로는 통과(런타임은 Instance.new 실패) — 무엇이 뜨는가
-- CLI: inh 무진단. Card 본문 `Frame(props)`는 에러 — 배열부 인덱서가 GuiObject 꼴과 Frame 꼴로 달라 인덱서 불변성에 걸린다
--   (`Expected the indexer result to be exactly '{ read __quadModifier: "Frame" | … }', but got …`). 즉 `Props<GuiObject>` 값을
--   하위 생성자로 그대로 넘길 수는 없다 — 상위 공통은 Spread<<GuiObject>>(03번)·Modifier<GuiObject>(02번) 마커로 흡수된다.
--   Abstract(`New<<GuiObject>>`) 무진단 — 타입은 추상 클래스를 막지 않는다(런타임 몫).

-- (1-f) hover — `Frame` 위에 마우스
local hoverMe = Frame -- @h(hover-Frame) at='Frame -- @h'
-- CLI(하네스): hover는 별칭 이름이 아니라 `function Frame({ [number]: Instance | { read __quadState: … } | … , Active: …, … }): Frame`
--   처럼 **구조가 통째로 전개**된다(생성 D는 `function Declaration.Frame(DM.FrameParam<…>): Frame`로 별칭 이름이 남는다 —
--   out/lsp-gend-compare.txt).

-- (1-g) 배열부(자식) — Instance 자식은 정상, 숫자는 에러여야 정상
local child = Frame({ Instance.new("Frame"), 42 })
-- CLI: 42 자리만 에러(`Expected this to be 'Instance | { read __quadState: … } | … ', but got 'number'`).

return { Frame, TextLabel, Bad, Loose, ok1, ok2, ok3, ok4, bad1, bad2, bad3, bad4, ok5, ro1, ro2, ro3, inh, card, Abstract, hoverMe, child }
