--!strict
-- E58 strict (generated) — sugar_02-operator-L160
-- ==== page prologue sugar/02-operator.md (sugar_02-operator-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local Op = q.Operator
type State<T> = q.State<T>
-- ==== doc block sugar/02-operator.md:160 (line offset marker) ====
local posX, maxX = q.Source(150), q.Source(100)
local boundX: State<number> = posX:Apply(Op.Clamp(0, maxX)) -- 100
