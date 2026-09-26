--!nocheck
local H = require("./harness")
local q, None = H.q, H.None
local function probe(label, init, setter)
	local s = q.Source(init); local n = 0; local o = s:Observer(function() n += 1 end); o:Subscribe()
	local n0 = n; setter(s); print(label, `init-fires={n0} after={n - n0}`)
end
probe("1 -> Set(1) x2", 1, function(s) s:Set(1); s:Set(1) end)
probe("nil -> Set(nil) x2", nil, function(s) s:Set(nil); s:Set(nil) end)
probe("None -> Set(None) x2", None, function(s) s:Set(None); s:Set(None) end)
probe("1 -> Set(nil) x2", 1, function(s) s:Set(nil); s:Set(nil) end)
