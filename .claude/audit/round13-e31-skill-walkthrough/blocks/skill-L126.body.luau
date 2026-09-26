-- source: SKILL.md:126-133
local firstName, lastName = q.Source("Ada"), q.Source("Lovelace")

-- 1 compute node, deps passed as trailing arguments
local fullName = firstName:Compute(function(self, prev, last)
    return `{self:Get()} {last:Get()}`
end, lastName)
