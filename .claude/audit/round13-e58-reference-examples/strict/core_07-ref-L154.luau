--!strict
-- E58 strict (generated) — core_07-ref-L154
-- ==== page prologue core/07-ref.md (core_07-ref-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/07-ref.md:154 (line offset marker) ====
local doneRef = q.PostRef<<Frame?>>(nil)
local card = D.Frame {
    doneRef,
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
}
doneRef:Callback(function(inst)
    if inst then
        -- 자식 둘이 이미 다 붙어 있다
    end
end)
