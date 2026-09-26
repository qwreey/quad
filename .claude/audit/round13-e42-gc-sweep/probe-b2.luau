--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
G.measure("b3 unique Tag names + unique AttrKey names, Destroy", function(N, track)
	for i = 1, N do
		local t = q.Tag("Tag" .. i .. "_" .. math.random(1, 1e9))
		local k = q.AttrKey("A" .. i .. "_" .. math.random(1, 1e9))
		local f = D.Frame { t, [k] = i, q.Attr({ ["B" .. i] = q.Source(i) }) }
		track(t, "tag"); track(k, "attrkey"); track(f, "inst")
		f:Destroy()
	end
end)
G.rounds("b3 rounds", function(N, track)
	for i = 1, N do local f = D.Frame { q.Tag("Tag" .. math.random(1, 1e9)), [q.AttrKey("A" .. math.random(1, 1e9))] = i }; f:Destroy() end
end, 1000, 4)
local live = D.Frame {}
local tagSeat = q.Source(nil)
local host = D.Frame { tagSeat }
G.measure("b4 State<Tag?> seat swapped with unique tag names on a live inst", function(N, track)
	for i = 1, N do local t = q.Tag("S" .. i .. "_" .. math.random(1, 1e9)); track(t, "tag"); tagSeat:Set(t) end
	tagSeat:Set(nil)
end)
