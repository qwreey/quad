--!strict
-- E58 strict (generated) — sugar_06-blocker-L111
-- ==== page prologue sugar/06-blocker.md (sugar_06-blocker-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block sugar/06-blocker.md:111 (line offset marker) ====
local hp = q.Source(100)
local blocker = q.Blocker()
local shown: q.State<number> = hp:Apply(blocker)

blocker:On()
hp:Set(80)
blocker:OffWithoutEmit() -- 80이라는 통지는 나가지 않는다
print(shown:Get()) --> 80 (값은 언제나 최신)
