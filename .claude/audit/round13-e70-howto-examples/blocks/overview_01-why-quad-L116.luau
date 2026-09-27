local suffix = q.Source("회")

local both = count:Compute(function(c, previous, s)
    return `{c:Get()}{s:Get()}`
end, suffix)                      -- ← suffix를 적어야 suffix가 움직일 때도 다시 흐른다
