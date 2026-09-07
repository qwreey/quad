--!strict
--[[
	OnChange 타이핑 — 생성 `OnChangeFn`/클래스별 유니언이 실물 규모(D 스코프
	전체)에서 strict를 통과하는가(luau-test `30`의 승격판 — 그 스파이크는
	자리표시자 3필드였다). 양성만 담는다(음성은 스파이크 30이 소스); 본문은
	실행하지 않는다(CLI엔 Roblox 전역이 없음 — 타입 검사만이 이 파일의 몫).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local DModule = require("../src/D")

local q = Quad.New():UseProvider(QuadRoblox)

local function _neverCalled()
	local D = q.D
	local OnChange = q.OnChange
	-- 주석 콜백 + 무주석 추론 + 같은 이름 둘 + 변수 경유 + State<디스크립터>
	local pre = OnChange("Size", function(v: UDim2) end)
	-- State<T>는 Set 파라미터 때문에 불변 — Source<단일 디스크립터>는 State<클래스 유니언>에
	-- 안 맞으므로 클래스 유니언으로 캐스트해 만든다(반응형 자식 State<Instance>도 같은 규칙)
	local reactive = q.Source(OnChange("Visible", function(v: boolean) end) :: DModule.FrameOnChange)
	local f = D.Frame({
		Name = "typed",
		OnChange("Position", function(v: UDim2) end),
		OnChange("Position", function(v)
			local _: UDim2 = v -- index<PropTypes, K>가 파라미터를 추론한다
		end),
		OnChange("BackgroundColor3", function(v: Color3) end),
		pre,
		reactive,
	})
	-- 충돌 이름(클래스 간 타입이 다름 — PropTypes에선 any): 어느 주석이든 통과
	local s = D.UIStroke({ OnChange("Color", function(v: Color3) end) })
	local g = D.UIGradient({ OnChange("Color", function(v: ColorSequence) end) })
	-- Mapper 쪽 E에도 같은 유니언
	local m = D.Mapper.Frame("Body")({ OnChange("Visible", function(v: boolean) end) })
	-- NewChild 확장(2026-09-03): quad-base 배열부 값 — Tag / Attribute 그룹 /
	-- 타입드 스칼라 슈가(Attribute를 돌려줌) / 그 State 형태
	local tagState = q.Source(q.Tag("a", "b"))
	local a = D.Frame({
		q.Tag("x"),
		tagState,
		q.Attribute({ Hp = 3 }),
		q.StringAttribute("Title", "quad"),
		q.NumberAttribute("Hp", q.Source(1)),
		q.BooleanAttribute("Alive", q.None),
	})
	return f, s, g, m, a
end

-- [2026-09-07 Q19 (a)] 읽기 전용 프로퍼티(AbsoluteSize/AbsolutePosition/TextBounds)가 OnChange의 읽기 표면
-- `PropTypesRead`에 든다 — 옛 쓰기 표면 `PropTypes`에선 strict TypeError였다(`H-414`)
local function _readSurface()
	local a = q.OnChange("AbsoluteSize", function(v: Vector2) end)
	local b = q.OnChange("AbsolutePosition", function(v: Vector2) end)
	local c = q.OnChange("TextBounds", function(v: Vector2) end)
	return q.D.Frame({ a, b }), q.D.TextLabel({ c })
end

print("=== ALL PASS ===")
