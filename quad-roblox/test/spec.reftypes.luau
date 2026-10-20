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
local DeclarationModule = require("../src") -- 3.4.0: the root exports the type names
type Ref<T> = QuadTypes.Ref<T>

local q = Quad.NewModule():UseProvider(QuadRoblox)

local function _neverCalled()
	local Frame = q.Elem "Frame"
	local TextLabel = q.Elem "TextLabel"
	-- 자기 클래스 박스(nil 가능·불가능 둘 다), 상위 클래스 박스, 체이닝 뒤, PreRef/PostRef
	local rF = q.Ref(nil :: Frame?)
	local rFixed = q.Ref(Instance.new("Frame"))
	local rG = q.Ref(nil :: GuiObject?)
	local rI = q.Ref(nil :: Instance?)
	local pre = q.PreRef(nil :: Frame?):Callback(function(v) end)
	local post = q.PostRef(nil :: Frame?)
	-- State<Ref>: the State arm is a covariant marker since 2026-09-07 — no cast (the 3.3 `:: FrameRefMarker` was 8.7 caveat 5)
	local reactive = q.Source(rF)
	local f = Frame({
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
	local l = TextLabel({ q.Ref(nil :: TextLabel?), q.Ref(nil :: GuiObject?), q.PostRef(nil :: TextLabel?) })
	local mapped = q.Mapper "Frame"("Body")({ rG, q.PreRef(nil :: Frame?) })
	-- 콜백 시그니처: 두 번째 인자는 Ref 자신(Epoch)
	local withRef = q.Ref(nil :: Frame?):Callback(function(v: Frame?, ref: Ref<Frame?>) end)
	local f2 = Frame({ withRef })
	return f, l, mapped, f2
end

print("=== ALL PASS ===")
