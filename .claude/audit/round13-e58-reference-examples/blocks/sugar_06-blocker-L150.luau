local hp = q.Source(100)
local blocker = q.Blocker()

-- state:Apply(blocker)와 동등한 수동 배선
local gated: q.State<number> = hp:Gate(function(emit)
	return blocker:Policy(emit)
end)
