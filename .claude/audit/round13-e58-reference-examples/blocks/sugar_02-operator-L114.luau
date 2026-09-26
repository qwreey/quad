local basePrice, tax, shipping = q.Source(1000), q.Source(100), q.Source(50)
local total: State<number> = basePrice:Apply(Op.Sum(tax, shipping, 500)) -- 1650
tax:Set(200) -- total:Get() == 1750
