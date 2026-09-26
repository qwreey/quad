--!strict
-- E58 strict (generated) — sugar_02-operator-L99
-- ==== page prologue sugar/02-operator.md (sugar_02-operator-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local Op = q.Operator
type State<T> = q.State<T>
-- ==== doc block sugar/02-operator.md:99 (line offset marker) ====
local isVisible = q.Source(true)
local isHidden: State<boolean> = isVisible:Apply(Op.Not) -- false
