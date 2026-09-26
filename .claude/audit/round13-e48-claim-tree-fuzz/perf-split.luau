--!nocheck
-- (h) split: pass 1 alone (all keys resolve, last one missing → Quad0032 after the full walk) vs full Claim
local H = require("./harness")
local q = H.newQ()
local M = q.Declaration.Mapper
for _, n in { 1000, 2000, 4000 } do
	local function mk(missingLast)
		local root = H.Instance.new("Frame")
		local items = {}
		for i = 1, n do
			local c = H.Instance.new("TextLabel"); c.Name = "c" .. i; c.Parent = root
			items[i] = M.TextLabel("c" .. i)({ Text = "t" })
		end
		if missingLast then items[n + 1] = M.TextLabel("missing")({}) end
		return root, M.Frame(M.Root)(items)
	end
	local r1, d1 = mk(true)
	local t = os.clock(); local ok = pcall(q.Claim, r1, d1); local p1 = os.clock() - t
	local r2, d2 = mk(false)
	t = os.clock(); q.Claim(r2, d2); local full = os.clock() - t
	print(string.format("n=%d pass1-only %.1f ms (ok=%s) full %.1f ms", n, p1 * 1000, tostring(ok), full * 1000))
end
