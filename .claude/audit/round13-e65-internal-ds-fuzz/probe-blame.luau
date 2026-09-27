--!nocheck
-- Relate nil-arg blame: which file:line prefixes the Quad0138/0139 message (relate-plan API block says "level-2 error — 호출 줄 blame")
local E = require("./env")
local q = E.newBase()
local r = q.Relate()
local ok, e = pcall(function()
	r:SetStrong(nil, "k", 1) -- line 7
end)
print(e)
ok, e = pcall(function()
	r:GetWeak({}, nil) -- line 11
end)
print(e)
