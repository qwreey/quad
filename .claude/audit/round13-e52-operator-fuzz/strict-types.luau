--!strict
-- E52 (c): result-type surface of q.Operator under the new solver. Lines tagged EXPECT-ERR should be diagnosed.
local q = require("../../../quad-base/src")
local Op = q.Operator
type State<T> = typeof(q.Source(1)) -- placeholder, replaced below
local price = q.Source(1000)
local tax = q.Source(100)
local total = price:Apply(Op.Sum(tax, 500))
local t1: number = total:Get() -- P1 Sum result reads as number
local okN = price:Apply(Op.Not)
local t2: boolean = okN:Get() -- P2 Not result boolean
local c = price:Apply(Op.Clamp(0, tax))
local t3: number = c:Get() -- P3
local sh = price:Apply(Op.Shl(2))
local t4: number = sh:Get() -- P4
local bn = price:Apply(Op.Bnot)
local t5: number = bn:Get() -- P5
local optName = q.Source(nil :: string?)
local safe = optName:Apply(Op.Alternative("Guest"))
local t6: string = safe:Get() -- P6 Alternative<T> strips nil
local optNum = q.Source(nil :: number?)
local safe2 = optNum:Apply(Op.Alternative(tax))
local t7: number = safe2:Get() -- P7 State default
type Palette = { Primary: string, Size: number }
local palette = q.Source({ Primary = "red", Size = 10 } :: Palette)
local primary = palette:Apply(Op.Indexed<<string>>("Primary"))
local t8: string = primary:Get() -- P8 Indexed<<V>>
local size = palette:Apply(Op.Indexed<<number>>("Size"))
local t9: number = size:Get() -- P9
local nest = palette:Apply(Op.Indexed<<Palette>>("x")):Apply(Op.Indexed<<string>>("Primary"))
local t10: string = nest:Get() -- P10 nested
local S = Op.Sum(1)
local r1 = price:Apply(S)
local r2 = tax:Apply(S)
local t11: number = r1:Get() + r2:Get() -- P11 factory reuse

-- negatives
local n1 = Op.Sum("5") -- N1 EXPECT-ERR string arg
local n2 = q.Source("x"):Apply(Op.Sum(1)) -- N2 EXPECT-ERR string target
local n3: string = price:Apply(Op.Sum(1)):Get() -- N3 EXPECT-ERR result is number
local n4 = Op.Clamp(1) -- N4 EXPECT-ERR arity
local n5 = price:Apply(Op.Clamp) -- N5 EXPECT-ERR (doc sugar/02:30: types block Clamp)
local n6 = price:Apply(Op.Alternative) -- N6 EXPECT-ERR (doc sugar/02:30: types block Alternative)
local n7: number = price:Apply(Op.Sum):Get() -- N7 EXPECT-ERR if annotated (doc sugar/02:30)
local n8 = Op.Clamp(0, 1, 2) -- N8 EXPECT-ERR extra arg (runtime ignores it)
local n9 = Op.Shl(1, 2) -- N9 EXPECT-ERR extra arg (runtime ignores it)
local n10: number = optName:Apply(Op.Alternative(5)):Get() -- N10 EXPECT-ERR default type mismatch?
local n11 = Op.Sum(1, nil) -- N11 EXPECT-ERR nil arg
local n12 = q.Source(true):Apply(Op.Bnot) -- N12 EXPECT-ERR boolean target
local n13 = Op.Indexed(q.Source("a")) -- N13 (runtime Quad0126; key: any so no type error expected)
local n14 = optNum:Apply(Op.Sum(1)) -- N14 EXPECT-ERR? number? target (runtime Quad0122 on nil)
local n15 = price:Apply(Op.Sum(optNum)) -- N15 EXPECT-ERR? State<number?> arg (runtime Quad0120 on nil)
return nil
