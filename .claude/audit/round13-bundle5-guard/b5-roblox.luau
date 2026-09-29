-- bundle5 guard probe — quad-roblox internal reader (Animate's Compute reads the racing node).
-- Copy into <tree>/quad-roblox/test/ and run `luau b5-roblox.luau` there.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local q: any = Quad.New():UseProvider(QuadRoblox)
local MAIN = coroutine.running()

local function short(ok, v): string
	if ok then
		if type(v) == "table" and q.isTween(v) then return `ok Tween({tostring(v.Value)})` end
		return `ok {tostring(v)}`
	end
	local s = tostring(v)
	-- keep the blame prefix (file:line) + code, drop the long tail
	local blame = s:match("^([^:]+:%d+):") or "?"
	return `ERR {blame} {s:match("(Quad%d+)") or s:sub(1, 60)}`
end
local function resume(co): string
	local ok, v = coroutine.resume(co)
	if coroutine.status(co) == "suspended" then return "PARKED" end
	return short(ok, v)
end

do
	local src = q.Source(0)
	local ctl = { park = true, runs = 0 }
	local c = src:Compute(function(h)
		local v = h:Get(); ctl.runs += 1
		if ctl.park and coroutine.running() ~= MAIN then coroutine.yield() end
		return v * 10
	end)
	local anim = c:Apply(q.Animate({ Time = 0.1 }))
	local A = coroutine.create(function() return anim:Get() end)
	print(" A1 (anim)", resume(A))
	src:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	print(" B1 (c)   ", resume(B))
	ctl.park = false
	print(" A2 (anim)", resume(A), "runs", ctl.runs)
	print(" M1 (anim)", short(pcall(function() return anim:Get() end)), "runs", ctl.runs)
	print(" B2 (c)   ", resume(B), "runs", ctl.runs)
	print(" M2 (anim)", short(pcall(function() return anim:Get() end)), "runs", ctl.runs)
	print("--- R1 Animate internal reader, A (via anim) returns late while B parked in c: done")
end

do -- defined path: Animate over a node that throws once, no yield
	local src = q.Source(0)
	local runs = 0
	local c = src:Compute(function(h)
		local v = h:Get(); runs += 1
		if v == 1 then error("boom") end
		return v
	end)
	local anim = c:Apply(q.Animate({ Time = 0.1 }))
	print(" G0", short(pcall(function() return anim:Get() end)), runs)
	src:Set(1)
	print(" G1", short(pcall(function() return anim:Get() end)), runs)
	print(" G1b", short(pcall(function() return anim:Get() end)), runs)
	src:Set(2)
	print(" G2", short(pcall(function() return anim:Get() end)), runs)
	print("--- R2 defined path: Animate over a throwing node: done")
end
