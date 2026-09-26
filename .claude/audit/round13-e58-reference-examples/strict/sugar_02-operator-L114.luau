--!strict
-- E58 strict (generated) — sugar_02-operator-L114
-- ==== page prologue sugar/02-operator.md (sugar_02-operator-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local Op = q.Operator
type State<T> = q.State<T>
-- ==== doc block sugar/02-operator.md:114 (line offset marker) ====
local basePrice, tax, shipping = q.Source(1000), q.Source(100), q.Source(50)
local total: State<number> = basePrice:Apply(Op.Sum(tax, shipping, 500)) -- 1650
tax:Set(200) -- total:Get() == 1750
