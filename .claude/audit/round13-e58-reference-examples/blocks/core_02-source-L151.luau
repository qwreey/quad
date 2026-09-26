local hp = q.Source(100)
local label: q.State<string> = hp:Compute(function(self)
	return `HP {self:Get()}`
end)
