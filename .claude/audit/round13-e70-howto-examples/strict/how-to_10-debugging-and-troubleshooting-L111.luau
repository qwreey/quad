--!strict
-- E70 strict (generated) — how-to_10-debugging-and-troubleshooting-L111
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_10-debugging-and-troubleshooting-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/10-debugging-and-troubleshooting.md:111 ====
-- ✅ 숫자 키 자리에 그대로
local function CustomInput(props: { InputRef: q.Ref<TextBox?>? })
    return D.TextBox {
        props.InputRef or q.None,
        PlaceholderText = "...",
    }
end
