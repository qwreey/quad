--!strict
-- E58 strict (generated) — sugar_06-blocker-L166
-- ==== page prologue sugar/06-blocker.md (sugar_06-blocker-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
--[[E58 보강 pre]]
local state = q.Source(0)
local blocker = q.Blocker()
-- ==== doc block sugar/06-blocker.md:166 (line offset marker) ====
state:Apply(blocker)
-- ≡
state:Gate(function(emit)
	return blocker:Policy(emit)
end)
