--!strict
--[[
	OnChange 타이핑 — 클래스 먼저 커리(3.4.0 `q.OnChange "Frame" "Size" (fn)`; 3.3은 생성 `OnChangeFn`)가 실물
	규모에서 strict를 통과하는가(luau-test `30`의 승격판). 양성만 담는다(음성은 스파이크 30이 소스); 본문은
	실행하지 않는다(CLI엔 Roblox 전역이 없음 — 타입 검사만이 이 파일의 몫).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox

local q = Quad.NewModule():UseProvider(QuadRoblox)

local function _neverCalled()
	local Frame = q.Elem "Frame"
	local TextBox = q.Elem "TextBox"
	local UIGradient = q.Elem "UIGradient"
	local UIStroke = q.Elem "UIStroke"
	local OnFrame = q.OnChange "Frame"
	-- 주석 콜백 + 무주석 추론 + 같은 이름 둘 + 변수 경유 + State<디스크립터>
	local pre = OnFrame "Size" (function(v: UDim2) end)
	-- [3.4.0] a descriptor's State goes in as is (the array arm is a covariant marker — 3.3 needed a class-union cast)
	local reactive = q.Source(OnFrame "Visible" (function(v: boolean) end))
	local f = Frame({
		Name = "typed",
		OnFrame "Position" (function(v: UDim2) end),
		OnFrame "Position" (function(v)
			local _: UDim2 = v -- the class's read surface types the parameter
		end),
		OnFrame "BackgroundColor3" (function(v: Color3) end),
		pre,
		reactive,
	})
	-- the same name on two classes with different types: the class picks the type (3.3's scope-wide map made it `any`)
	local s = UIStroke({ q.OnChange "UIStroke" "Color" (function(v: Color3) end) })
	local g = UIGradient({ q.OnChange "UIGradient" "Color" (function(v: ColorSequence) end) })
	-- Out — 되쓰기 슈거: Source는 통과, 이름에서 값 타입 추론(2026-09-21)
	local textSrc = q.Source("")
	local _outBox = TextBox({ Text = textSrc, q.Out "TextBox" "Text" (textSrc) })
	local visSrc = q.Source(true)
	local _outVis = Frame({ Visible = visSrc, q.Out "Frame" "Visible" (visSrc) })
	-- Mapper 쪽 배열부에도 같은 디스크립터
	local m = q.Mapper "Frame"("Body")({ OnFrame "Visible" (function(v: boolean) end) })
	-- NewChild 확장(2026-09-03): quad-base 배열부 값 — Tag / Attr 그룹 /
	-- 타입드 스칼라 슈가(Attr를 돌려줌) / 그 State 형태
	local tagState = q.Source(q.Tag("a", "b"))
	local a = Frame({
		q.Tag("x"),
		tagState,
		q.Attr({ Hp = 3 }),
		q.StringAttr("Title", "quad"),
		q.NumberAttr("Hp", q.Source(1)),
		q.BooleanAttr("Alive", q.None),
	})
	return f, s, g, m, a
end

-- [2026-09-07 Q19 (a)] 읽기 전용 프로퍼티(AbsoluteSize/AbsolutePosition/TextBounds)가 OnChange의 읽기 표면
-- 에 든다(3.4.0: 클래스의 읽기 표면 — 3.3은 `PropTypesRead`) — 옛 쓰기 표면에선 strict TypeError였다(`H-414`)
local function _readSurface()
	local a = q.OnChange "Frame" "AbsoluteSize" (function(v: Vector2) end)
	local b = q.OnChange "Frame" "AbsolutePosition" (function(v: Vector2) end)
	local c = q.OnChange "TextLabel" "TextBounds" (function(v: Vector2) end)
	return q.Elem "Frame"({ a, b }), q.Elem "TextLabel"({ c })
end

print("=== ALL PASS ===")
