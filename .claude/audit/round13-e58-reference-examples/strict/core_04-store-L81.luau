--!strict
-- E58 strict (generated) — core_04-store-L81
-- ==== page prologue core/04-store.md (core_04-store-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/04-store.md:81 (line offset marker) ====
local store = q.Store({ hp = q.Source(100) })
print(store.hp:Get()) --> 100
print((store :: any).mp) --> nil (선언 안 한 이름 — 만들어지지 않는다)
