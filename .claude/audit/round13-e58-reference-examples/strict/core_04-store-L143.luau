--!strict
-- E58 strict (generated) — core_04-store-L143
-- ==== page prologue core/04-store.md (core_04-store-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/04-store.md:143 (line offset marker) ====
local store = q.Store({ hp = q.Source(100) })
store:Of("mp")

local names = store:Names()
table.sort(names)
print(table.concat(names, ",")) --> hp,mp
