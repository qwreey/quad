--!strict
-- E58 strict (generated) — core_07-ref-L252
-- ==== page prologue core/07-ref.md (core_07-ref-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/07-ref.md:252 (line offset marker) ====
local ref = q.Ref(0)
ref:Callback(function(v) print("값", v) end) -- 등록 즉시 0으로 한 번 불린다
ref:Set(1):Set(2)                            -- 체이닝
