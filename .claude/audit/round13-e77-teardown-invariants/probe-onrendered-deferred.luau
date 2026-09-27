--!nocheck
-- E77 axis: dispose(root) from inside OnRendered of a child being driven into root, with Destroying delivered
-- deferred (Roblox default SignalBehavior) vs immediate.
-- NOTE: `drive(root, { x })` puts x at numeric position 1, which RETRACTS whatever root's own props had there
-- (here: the Effect -> cleanup(false), never a dying cleanup). variants drive/slotAdd/listUpdate show that harness
-- artifact; slotInProps/listInProps are the clean shape (Slot declared in root's props).
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local deferredQ = {}
local DEFERRED = false
local orig = q.Backend.onDestroying
q.Backend.onDestroying = function(inst, fn)
	return orig(inst, function(...) if DEFERRED then table.insert(deferredQ, fn) else fn(...) end end)
end
local function flush() while #deferredQ > 0 do local fn = table.remove(deferredQ, 1); local ok, e = pcall(fn); if not ok then print("  handler err", H.first(e)) end end end
local flag = q.Source(true)
local function case(label, deferred, variant)
	DEFERRED = deferred
	local log = {}
	local root
	local propSlot = q.Slot()
	root = D.Frame({ Name = "root", propSlot,
		q.Effect(function() table.insert(log, "run"); return function(d) table.insert(log, "cleanup(" .. tostring(d) .. ")") end end, flag),
		q.OnDestroyed(function() table.insert(log, "onDestroyed") end),
		D.Frame({ Name = "kid", q.Effect(function() return function(d) table.insert(log, "kidCleanup(" .. tostring(d) .. ")") end end), q.OnDestroyed(function() table.insert(log, "kidOD") end) }),
	})
	local ok, e = pcall(function()
		if variant == "drive" then
			local sub = D.Frame({ Name = "selfClose", q.OnRendered(function() q.dispose(root) end) })
			q.Dispatch.drive(root, { q.Slot({ sub }) })
		elseif variant == "plain" then
			q.dispose(root)
		elseif variant == "slotAdd" then
			local s = q.Slot()
			q.Dispatch.drive(root, { s })
			s:Add(D.Frame({ Name = "selfClose", q.OnRendered(function() q.dispose(root) end) }))
		elseif variant == "slotInProps" then
			propSlot:Add(D.Frame({ Name = "selfClose", q.OnRendered(function() q.dispose(root) end) }))
		elseif variant == "listInProps" then
			local data = q.Source({})
			-- (list must be in props too: use a second root shape) — emulate by Slot holding a :List-bearing frame
			propSlot:Add(D.Frame({ q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.Frame({ q.OnRendered(function() q.dispose(root) end) }) end) }))
			data:Set({ 1 })
		elseif variant == "listUpdate" then
			local data = q.Source({ 1 })
			q.Dispatch.drive(root, { q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.Frame({ q.OnRendered(function() q.dispose(root) end) }) end) })
		end
	end)
	if not ok then table.insert(log, "ERR " .. H.first(e)) end
	table.insert(log, "|flush")
	flush()
	flag:Set(not flag:Get())
	print(string.format("%-8s %-10s destroyed=%s  %s", label, variant, tostring(mock.isDestroyed(root)), table.concat(log, " ")))
end
for _, v in { "plain", "drive", "slotAdd", "listUpdate", "slotInProps", "listInProps" } do
	case("immed", false, v)
	case("deferred", true, v)
end
