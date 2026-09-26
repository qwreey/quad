--!strict
-- E58 strict (generated) — core_02-source-L85
-- ==== page prologue core/02-source.md (core_02-source-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
-- ==== doc block core/02-source.md:85 (line offset marker) ====
local hp = q.Source(100)
hp:Set(80):Set(60) -- self를 돌려주므로 이어 쓸 수 있다
print(hp:Get()) --> 60
