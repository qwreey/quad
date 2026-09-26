local flags = q.Source(0b1100)
local masked: State<number> = flags:Apply(Op.Band(0b1010)) -- 8
