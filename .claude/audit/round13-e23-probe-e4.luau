--!nocheck
-- round13 E23 E4 — same stale-branch race at the Slot element place, and recovery after the throw
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1"):sub(1, 90)) end
local function run(place)
	local dist = {}
	for trial = 1, 300 do
		local src = q.Source(1)
		local pad = {}
		for i = 1, trial % 7 do pad[i] = src:Compute(function(s) return s:Get() end) end
		local fX, fY, fZ = D.Frame { Name = "X" }, D.Frame { Name = "Y" }, D.Frame { Name = "Z" }
		local other = D.Frame { Name = "other", fZ }
		local a = src:Compute(function(s) return if s:Get() == 1 then fX else fZ end)
		local b = src:Compute(function() return fY end)
		local outer = src:Compute(function(s) return if s:Get() == 1 then a else b end)
		local host, sl
		if place == "slot" then sl = q.Slot { outer }; host = D.Frame { Name = "host", sl }
		else host = D.Frame { Name = "host", outer } end
		local ok, err = pcall(function() src:Set(2) end)
		local kids = {}
		for _, c in host:GetChildren() do table.insert(kids, c.Name) end
		-- recovery: flip back and forth
		local ok2, err2 = pcall(function() src:Set(1) end)
		local k2 = {}
		for _, c in host:GetChildren() do table.insert(k2, c.Name) end
		local ok3, err3 = pcall(function() src:Set(4) end)
		local k3 = {}
		for _, c in host:GetChildren() do table.insert(k3, c.Name) end
		local key = (ok and "ok" or first(err)) .. " [" .. table.concat(kids, ",") .. "]"
			.. (sl and (" len=" .. sl.Length:Get()) or "")
			.. " || back: " .. (ok2 and "ok" or first(err2)) .. " [" .. table.concat(k2, ",") .. "]"
			.. " || again: " .. (ok3 and "ok" or first(err3)) .. " [" .. table.concat(k3, ",") .. "]"
		dist[key] = (dist[key] or 0) + 1
	end
	print("--- " .. place)
	for k, v in dist do print(v, k) end
end
run("child")
run("slot")
