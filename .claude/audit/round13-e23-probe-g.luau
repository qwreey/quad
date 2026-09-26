--!nocheck
-- round13 E23 G — blame lines for the nested paths; Modifier-field cycle; Compute->Modifier inside a chain
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local function loc(err) local s = tostring(err):gsub("\n.*", ""); return (s:match("^(.-:%d+):") or "?") .. " | " .. (s:match("(Quad%d%d%d%d)") or s:sub(1, 60)) end
local function t(label, fn) local ok, err = pcall(fn); print(label, ok and "ok" or loc(err)) end

t("G1 Modifier field self-cycle", function()
	local s = q.Source("x")
	local l = D.TextLabel { q.Modifier({ Text = s }) }
	s:Set(s) -- line 12
end)
t("G2 chain inner Compute returns Modifier", function()
	local src = q.Source(1)
	local bad = src:Compute(function(v) if v:Get() == 2 then return q.Modifier({}) end return "ok" end)
	local outer = q.Source(bad)
	local l = D.TextLabel { Text = outer }
	src:Set(2) -- line 19
end)
t("G3 Slot pre-pass gap: Add(Source(Source(a))) with a held elsewhere", function()
	local a = D.Frame { Name = "a" }
	local s1 = q.Slot { a }; local f1 = D.Frame { s1 }
	local s2 = q.Slot {}; local f2 = D.Frame { s2 }
	s2:Add(q.Source(q.Source(a))) -- line 25
end)
t("G4 Slot element self-cycle", function()
	local st = q.Source(D.Frame {})
	local s = q.Slot { st }; local f = D.Frame { s }
	st:Set(st) -- line 30
end)
t("G5 numeric child nested: outer:Set(Source(mounted-elsewhere))", function()
	local c = D.Frame { Name = "c" }
	local other = D.Frame { c }
	local outer = q.Source(q.Source(D.Frame {}))
	local host = D.Frame { outer }
	outer:Set(q.Source(c)) -- line 37
end)
