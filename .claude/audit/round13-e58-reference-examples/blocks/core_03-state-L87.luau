local width = q.Source(2)
local height = q.Source(10)

local area: q.State<number> = width:Compute(function(self, previous, other: q.StateData<number>)
	return self:Get() * other:Get()
end, height)

print(area:Get()) --> 20
height:Set(20)
print(area:Get()) --> 40
