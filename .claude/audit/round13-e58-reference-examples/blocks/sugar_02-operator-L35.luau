local tax, shipping = q.Source(2), q.Source(3)
local basePrice, otherPrice = q.Source(10), q.Source(100)

local addTaxAndShipping = Op.Sum(tax, shipping) -- 한 번 이름 붙이고
local a: State<number> = basePrice:Apply(addTaxAndShipping) -- 15
local b: State<number> = otherPrice:Apply(addTaxAndShipping) -- 105
tax:Set(5) -- 재사용한 쪽까지 같이 갱신된다: 18 / 108
