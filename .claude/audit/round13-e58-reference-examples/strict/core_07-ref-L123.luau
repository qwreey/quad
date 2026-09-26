--!strict
-- E58 strict (generated) — core_07-ref-L123
-- ==== page prologue core/07-ref.md (core_07-ref-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/07-ref.md:123 (line offset marker) ====
local inputRef = q.PreRef<<TextBox?>>(nil)
local form = D.Frame {
    D.TextBox { inputRef },
    D.TextButton {
        Text = "지우기",
        Activated = function()
            inputRef:Unwrap().Text = "" -- pre-pass가 이미 채웠다
        end,
    },
}
