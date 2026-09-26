--!strict
-- E58 strict (generated) — core_02-source-L51
-- ==== page prologue core/02-source.md (core_02-source-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/02-source.md:51 (line offset marker) ====
local hp = q.Source(100)
print(hp:Get()) --> 100
