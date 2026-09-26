--!strict
-- E58 strict (generated) — roblox_05-onchange-L56
-- ==== page prologue roblox/05-onchange.md (roblox_05-onchange-L19.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") --[[E58: 문서의 자리표시 <quad-roblox 모듈>]] -- 디스크립터 타입 `OnChangeDescriptor`의 공개 경로(루트 재수출)
local D = q.Declaration
-- ==== doc block roblox/05-onchange.md:56 (line offset marker) ====
local size = q.Source(UDim2.fromScale(1, 0))

local box = D.Frame({
	Size = size,
	q.OnChange("AbsoluteSize", function(v: Vector2) -- 읽기 전용 프로퍼티도 된다
		print(v.X, v.Y)
	end),
	q.OnChange("Visible", function(v)               -- 주석을 생략해도 boolean으로 추론된다
		local _: boolean = v
	end),
})
