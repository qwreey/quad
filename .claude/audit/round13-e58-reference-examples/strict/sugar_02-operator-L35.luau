--!strict
-- E58 strict (generated) — sugar_02-operator-L35
-- ==== page prologue sugar/02-operator.md (sugar_02-operator-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local Op = q.Operator
type State<T> = q.State<T>
-- ==== doc block sugar/02-operator.md:35 (line offset marker) ====
local tax, shipping = q.Source(2), q.Source(3)
local basePrice, otherPrice = q.Source(10), q.Source(100)

local addTaxAndShipping = Op.Sum(tax, shipping) -- 한 번 이름 붙이고
local a: State<number> = basePrice:Apply(addTaxAndShipping) -- 15
local b: State<number> = otherPrice:Apply(addTaxAndShipping) -- 105
tax:Set(5) -- 재사용한 쪽까지 같이 갱신된다: 18 / 108
