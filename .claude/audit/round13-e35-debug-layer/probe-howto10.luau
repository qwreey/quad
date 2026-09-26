--!nocheck
-- E35 step 4: follow how-to 10 §1 on five errors. For each: (1) raw message with blame prefix (pcall(function) form, the doc's advice),
-- (2) pcall(quadFn, ...) direct form (doc's known limit 1), (3) under q.debug=true (should be identical), (4) q.Traceback onError(err, trace).
local H = require("./harness")
local mock = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
UDim2 = H.EG.UDim2

local function run(label, fn)
	print(`=== {label}`)
	for _, dbg in { false, true } do
		q.debug = dbg
		local ok, err = pcall(fn)
		print(`  debug={dbg} ok={ok} :: {if ok then "-" else H.first(err)}`)
	end
	q.debug = false
	local wrapped = q.Traceback(fn, function(err, trace)
		local lines = {}
		for l in string.gmatch(trace, "[^\n]+") do table.insert(lines, l) end
		print(`  Traceback err=: {H.first(err)}`)
		print(`  Traceback trace ({#lines} lines):`)
		for i = 1, math.min(#lines, 8) do print("    " .. lines[i]) end
		return "fallback"
	end)
	print("  Traceback returned:", wrapped())
end

-- 1. Slot 미claim (foreign instance as element)
run("E1 Slot unclaimed element", function()
	local s = q.Slot()
	s:Add(mock.Instance.foreign("Frame"))            -- user line
end)
-- 2. Slot at a string key
run("E2 Slot at string key", function()
	local f = D.Frame { Children = q.Slot() }          -- user line
end)
-- 3. Compute re-entry (fn reads itself)
run("E3 Compute re-entry", function()
	local src = q.Source(1)
	local c
	c = src:Compute(function(s) local v = s:Get(); if c then return c:Get() + v end return v end)
	print("    first get:", c:Get())
	src:Set(2)                                           -- user line
	print("    after set:", c:Get())
end)
-- 4. Tween option error
run("E4 Tween option type", function()
	local t = q.Tween({ Value = 1, Time = "fast" })    -- user line
end)
-- 5. Attr value type
run("E5 Attr bad value", function()
	local f = D.Frame { q.Attr { Hp = {} } }           -- user line
end)

print("=== limit 1: pcall(quadFn, ...) direct")
print("  ", pcall(q.Tween, { Value = 1, Time = "fast" }))
print("  ", pcall(q.Slot().Add, q.Slot(), mock.Instance.foreign("Frame")))
