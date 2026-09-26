--!strict
-- E58 strict (generated) — core_07-ref-L97
-- ==== page prologue core/07-ref.md (core_07-ref-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/07-ref.md:97 (line offset marker) ====
local boxRef = q.Ref<<Frame?>>(nil)
local panel = D.Frame {
    boxRef,                       -- 숫자 키: 만들어진 Frame이 여기 담긴다
    D.TextLabel { Text = "제목" },
}
