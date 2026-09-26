--!strict
-- E58 strict (generated) — core_03-state-L87
-- ==== page prologue core/03-state.md (core_03-state-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/03-state.md:87 (line offset marker) ====
local width = q.Source(2)
local height = q.Source(10)

local area: q.State<number> = width:Compute(function(self, previous, other: q.StateData<number>)
	return self:Get() * other:Get()
end, height)

print(area:Get()) --> 20
height:Set(20)
print(area:Get()) --> 40
