--!nocheck
local E = require("./env")
local S = E.S
S.reset("def")
local q = E.newProv()
local D = q.Declaration
local function best(n, fn)
	local b = math.huge
	for _ = 1, n do
		local prep = fn(nil)
		collectgarbage()
		local t = os.clock(); fn(prep); local dt = os.clock() - t
		if dt < b then b = dt end
		S.flush()
	end
	return b * 1000
end
-- 1. mount a flat Slot of 2000 plain elements, then destroy
local t1 = best(15, function(prep)
	if prep == nil then
		local els = table.create(2000)
		for i = 1, 2000 do els[i] = D.Frame({}) end
		return q.Slot(els)
	end
	local host = D.Frame({ prep })
	q.dispose(host)
end)
-- 2. mount 200 nested Slots x 10 elements
local t2 = best(15, function(prep)
	if prep == nil then
		local inners = table.create(200)
		for i = 1, 200 do
			local els = table.create(10)
			for j = 1, 10 do els[j] = D.Frame({}) end
			inners[i] = q.Slot(els)
		end
		return q.Slot(inners)
	end
	local host = D.Frame({ prep })
	q.dispose(host)
end)
-- 3. Add + Remove 20000 times on a mounted Slot of 100
local slot = q.Slot({})
for i = 1, 100 do slot:Add(D.Frame({})) end
local host = D.Frame({ slot })
local t3 = best(7, function(prep)
	if prep == nil then return true end
	for i = 1, 20000 do
		slot:Add(D.Frame({}), 50)
		slot:Remove(50)
	end
end)
-- 4. Replace 20000 times
local t4 = best(7, function(prep)
	if prep == nil then return true end
	for i = 1, 20000 do slot:Replace(50, D.Frame({})) end
end)
print(("mount flat 2000: %.2f ms | mount nested 200x10: %.2f ms | add+remove x20000: %.1f ms | replace x20000: %.1f ms"):format(t1, t2, t3, t4))
