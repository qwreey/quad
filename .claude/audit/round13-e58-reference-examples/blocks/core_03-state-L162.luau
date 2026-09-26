local raw = q.Source(0)
local blocker = q.Blocker()
local gated: q.State<number> = raw:Apply(blocker)
