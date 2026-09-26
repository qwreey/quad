--!strict
-- E58 strict (generated) — sugar_06-blocker-L47
-- ==== page prologue sugar/06-blocker.md (sugar_06-blocker-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
--[[E58 보강 pre]]
local __log = {}
-- ==== doc block sugar/06-blocker.md:47 (line offset marker) ====
local hp = q.Source(100)
local mp = q.Source(50)
local blocker = q.Blocker()

local shownHp: q.State<number> = hp:Apply(blocker)
local shownMp: q.State<number> = mp:Apply(blocker)

blocker:On()
hp:Set(80)
mp:Set(40) -- 아직 아무도 통지받지 않았다
blocker:Off() -- 두 게이트가 각각 한 번씩 통지
