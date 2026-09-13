--!strict
--[[
	Ref/PreRef/PostRef children 타이핑(M8 단위 ③, round18 `H-321`) — 생성
	`<Class>RefMarker`(반공변 팬텀 `__quadRefAccepts`)가 실물 규모에서 strict를
	통과하는가. 양성만 담고 본문은 실행하지 않는다(spec.onchangetypes 관례). 음성
	(형제 클래스 Ref·`Ref<nil>`·`State<Ref>` 직접)은 luau-test `32` + 착수 전
	스크래치 실측(round18 `H-321`).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
local DeclarationModule = require("../src/Declaration")
type Ref<T> = QuadTypes.Ref<T>

local q = Quad.New():UseProvider(QuadRoblox)

local function _neverCalled()
	local D = q.Declaration
	-- 자기 클래스 박스(nil 가능·불가능 둘 다), 상위 클래스 박스, 체이닝 뒤, PreRef/PostRef
	local rF = q.Ref(nil :: Frame?)
	local rFixed = q.Ref(Instance.new("Frame"))
	local rG = q.Ref(nil :: GuiObject?)
	local rI = q.Ref(nil :: Instance?)
	local pre = q.PreRef(nil :: Frame?):Callback(function(v) end)
	local post = q.PostRef(nil :: Frame?)
	-- State<Ref>: `State<T>` 불변성 — 마커로 캐스트해 만든다(8.7 캐비엇 5, OnChange·Modifier와 같은 규칙)
	local reactive = q.Source(rF :: DeclarationModule.FrameRefMarker)
	local f = D.Frame({
		rF,
		rFixed,
		rG,
		rI,
		pre,
		post,
		rF:Callback(function(v) end), -- <Self> 체이닝은 타입을 유지(H-317)
		reactive,
		Name = "typed",
	})
	local l = D.TextLabel({ q.Ref(nil :: TextLabel?), q.Ref(nil :: GuiObject?), q.PostRef(nil :: TextLabel?) })
	local mapped = D.Mapper.Frame("Body")({ rG, q.PreRef(nil :: Frame?) })
	-- 콜백 시그니처: 두 번째 인자는 Ref 자신(Epoch)
	local withRef = q.Ref(nil :: Frame?):Callback(function(v: Frame?, ref: Ref<Frame?>) end)
	local f2 = D.Frame({ withRef })
	return f, l, mapped, f2
end

print("=== ALL PASS ===")
