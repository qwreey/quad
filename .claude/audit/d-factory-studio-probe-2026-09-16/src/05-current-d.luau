--!strict
-- [P5] 오늘의 **생성 D**(5250줄)가 Studio에서 어떻게 동작하는지 — 04번과 나란히 비교하기 위한 대조군.
-- 이 파일은 default.project.json이 ReplicatedStorage에 싱크한 quad-roblox를 쓴다.
-- 보고할 것:
--   (5-a) 자동완성: 아래 중괄호 안에서 `Back`까지 쳤을 때 목록이 뜨는가, 04번과 견줘 얼마나 빠른가/느린가.
--   (5-b) 스크립트 분석 창에 "Code is too complex to typecheck"가 뜨는가.
--         (리눅스에선 생성 D가 한도 플래그 셋 없이는 100군데쯤에서 too complex가 난다 —
--          Studio는 그 플래그를 사용자가 못 켜므로 여기가 실제 사용자 환경의 하한선이다.)
--   (5-c) 아래 "에러여야 정상" 줄들이 실제로 잡히는가.
--   (5-d) 파일을 열고부터 빨간 줄·자동완성이 뜨기까지 체감 지연.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local D = require(ReplicatedStorage["quad-roblox"].src.Declaration)

type Elem = Instance | string
type FrameParam = D.FrameParam<Elem>
type TextButtonParam = D.TextButtonParam<Elem>

local function makeFrame(p: FrameParam): Frame
	return nil :: any
end
local function makeTextButton(p: TextButtonParam): TextButton
	return nil :: any
end

-- (5-a) ★ 자동완성 자리 ★
local ok1 = makeFrame({ --[[Active]] BackgroundColor3 = Color3.new(1, 1, 1), Visible = true, Size = UDim2.fromScale(1, 1) })
local ok2 = makeTextButton({ --[[Active]] --[[AncestryChanged]] Text = "hi", TextSize = 18, Activated = function() end })

-- 에러여야 정상
-- Vscode(5): TypeError: Expected this to be '(Color3 | None | StateMarker<(TweenData<Color3> & t1) | Color3> | TweenData<Color3>)? where t1 = { Mapped: <T, U>({ read Dedup: boolean?, read DelayTime: number?, ... 9 more ... }, (T) -> U) -> t1 & { read Dedup: boolean?, read DelayTime: number?, ... 9 more ... } }', but got 'number'
local bad1 = makeFrame({ BackgroundColor3 = 5 })
-- Vscode(Bogus, 1): TypeError: Expected this to be 'number', but got '"Bogus"'
--  TypeError: Expected this to be 'Instance | string', but got 'number'
local bad2 = makeFrame({ Bogus = 1 })
-- Vscode(AbsoluteSize, Vector2.new(1, 1)): TypeError: Expected this to be 'number', but got '"AbsoluteSize"'
--  TypeError: Expected this to be 'Instance | string', but got 'Vector2'
local bad3 = makeFrame({ AbsoluteSize = Vector2.new(1, 1) })
-- Studio 진단도 같다.

-- (5-e) Modifier 체이닝 대조군
-- 멀쩡, Vscode/Studio 둘 다 뜬다. 타입 깨짐이 없다는것으로 간주가능한듯
local m: D.FrameModifier = nil :: any
local chained = m:BackgroundTransparency(0.5):Visible(true):Active(true):Active(true):Active(true):Active(true) -- 자동완성 성공 :AnchorPoint()

return { ok1, ok2, bad1, bad2, bad3, chained }
