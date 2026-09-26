local flags = q.Source(0b1100)
local shifted: State<number> = flags:Apply(Op.Shl(2)) -- 0b110000
