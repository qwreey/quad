--!strict
-- E58 strict (generated) — core_07-ref-L331
-- ==== page prologue core/07-ref.md (core_07-ref-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/07-ref.md:331 (line offset marker) ====
local ref = q.Ref<<string?>>(nil)
task.spawn(function()
    local value = ref:Wait().Value -- 다음 :Set 까지 여기서 멈춘다
    print("도착", value)
end)
ref:Set("hello")
