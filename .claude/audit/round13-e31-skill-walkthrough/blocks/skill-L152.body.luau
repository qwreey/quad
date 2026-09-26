-- source: SKILL.md:152-164
local Op = q.Operator
local isVisible, price, tax, shipping = q.Source(true), q.Source(100), q.Source(5), q.Source(3)
local rawPos, maxBound = q.Source(150), q.Source(100)
local optionalName = q.Source<<string?>>(nil)
local theme = q.Source({ Primary = "red" })

local isHidden   = isVisible:Apply(Op.Not)                     -- unary
local totalPrice = price:Apply(Op.Sum(tax, shipping))          -- n-ary, plain numbers or States
local clamped    = rawPos:Apply(Op.Clamp(0, maxBound))
local safeName   = optionalName:Apply(Op.Alternative("Guest")) -- State<T?> -> State<T>
local primary    = theme:Apply(Op.Indexed<<string>>("Primary"))  -- caller supplies the result type
