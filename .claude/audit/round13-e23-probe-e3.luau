--!nocheck
-- round13 E23 E3 — stale-branch exposure at a numeric child place: nondeterministic mount error
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1"):sub(1, 110)) end
local dist = {}
for trial = 1, 300 do
	local src = q.Source(1)
	local pad = {}
	for i = 1, trial % 7 do pad[i] = src:Compute(function(s) return s:Get() end) end
	local fX, fY = D.Frame { Name = "X" }, D.Frame { Name = "Y" }
	local fZ = D.Frame { Name = "Z" }
	local other = D.Frame { Name = "other", fZ } -- fZ mounted elsewhere
	-- branch a: while selected shows X; when src becomes 2 it would show Z (never selected then)
	local a = src:Compute(function(s) return if s:Get() == 1 then fX else fZ end)
	local b = src:Compute(function() return fY end)
	local outer = src:Compute(function(s) return if s:Get() == 1 then a else b end)
	local host = D.Frame { Name = "host", outer }
	local ok, err = pcall(function() src:Set(2) end)
	local kids = {}
	for _, c in host:GetChildren() do table.insert(kids, c.Name) end
	local zp = fZ.Parent and fZ.Parent.Name or "nil"
	local key = (ok and "ok" or ("ERR " .. first(err))) .. " | host[" .. table.concat(kids, ",") .. "] Z.Parent=" .. zp
	dist[key] = (dist[key] or 0) + 1
end
for k, v in dist do print(v, k) end
