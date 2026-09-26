--!strict
-- E58 strict (generated) — sugar_06-blocker-L150
-- ==== page prologue sugar/06-blocker.md (sugar_06-blocker-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block sugar/06-blocker.md:150 (line offset marker) ====
local hp = q.Source(100)
local blocker = q.Blocker()

-- state:Apply(blocker)와 동등한 수동 배선
local gated: q.State<number> = hp:Gate(function(emit)
	return blocker:Policy(emit)
end)
