local posX, maxX = q.Source(150), q.Source(100)
local boundX: State<number> = posX:Apply(Op.Clamp(0, maxX)) -- 100
