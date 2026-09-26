--!strict
-- E58 strict (generated) — core_04-store-L115
-- ==== page prologue core/04-store.md (core_04-store-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/04-store.md:115 (line offset marker) ====
local store = q.Store({ hp = q.Source(100) })

local mp = store:Of<<number>>("mp") -- 결과 타입은 호출자가 직접 준다
mp:Set(50) -- 갓 만들어진 Source의 값은 nil이므로 먼저 채운다
print(store:Of<<number>>("mp") == mp) --> true (같은 객체)
