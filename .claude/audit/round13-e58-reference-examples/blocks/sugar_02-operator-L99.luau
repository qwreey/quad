local isVisible = q.Source(true)
local isHidden: State<boolean> = isVisible:Apply(Op.Not) -- false
