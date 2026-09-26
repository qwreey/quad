--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local Instance, Slot, dispatch = mock.Instance, q.Slot, q.Dispatch
local function F() return Instance.new("Frame") end
for _, depth in { 1, 10, 100 } do
	local parent = Instance.new("Folder")
	local root = Slot()
	local deepest = root
	for _ = 2, depth do local s = Slot(); deepest:Add(s); deepest = s end
	dispatch.drive(parent, { root })
	local N = 2000
	-- warm
	for _ = 1, 50 do deepest:Add(Slot({ F() })); deepest:Remove(1) end
	local best = math.huge
	for rep = 1, 5 do
		local t0 = os.clock()
		for _ = 1, N do deepest:Add(Slot({ F() })); deepest:Extract(1) end
		local t1 = os.clock()
		best = math.min(best, (t1 - t0) / N)
	end
	-- isolated cost of just walking the chain (what raiseChain adds), measured by a Relate walk
	print(`depth {depth}: Add+Extract pair best {string.format("%.2f", best * 1e6)} us/attach`)
end

local PR = rawget(q, "PATCH_RAW")
if PR then print("attaches", PR.attaches, "avg chain", PR.chainTotal / PR.attaches) end
