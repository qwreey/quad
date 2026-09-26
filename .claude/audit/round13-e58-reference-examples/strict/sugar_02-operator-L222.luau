--!strict
-- E58 strict (generated) — sugar_02-operator-L222
-- ==== page prologue sugar/02-operator.md (sugar_02-operator-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local Op = q.Operator
type State<T> = q.State<T>
-- ==== doc block sugar/02-operator.md:222 (line offset marker) ====
local flags = q.Source(0b1100)
local shifted: State<number> = flags:Apply(Op.Shl(2)) -- 0b110000
