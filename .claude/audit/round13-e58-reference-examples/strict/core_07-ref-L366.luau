--!strict
-- E58 strict (generated) — core_07-ref-L366
-- ==== page prologue core/07-ref.md (core_07-ref-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/07-ref.md:366 (line offset marker) ====
local btnRef = q.PreRef<<TextButton?>>(nil)
local button = D.TextButton {
    btnRef,
    Text = "보내기",
    Activated = function()
        btnRef:Unwrap().BackgroundTransparency = 0.5 -- 가드 없이
    end,
}
