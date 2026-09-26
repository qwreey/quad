--!strict
-- E58 strict (generated) — core_05-observer-effect-L237
-- ==== page prologue core/05-observer-effect.md (core_05-observer-effect-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/05-observer-effect.md:237 (line offset marker) ====
local hp = q.Source(100)

local effect = q.Effect(function(self)
	local value = hp:Get()
	print("hp:", value)
	return function()
		print("정리:", value) -- 다음 실행 직전 / 해제 / 파괴 때 정확히 한 번
	end
end, hp)
-- 여기서 이미 한 번 돌았다

effect:Subscribe()
hp:Set(80) -- 정리 → 재실행
effect:Unsubscribe() -- 마지막 정리 1회
