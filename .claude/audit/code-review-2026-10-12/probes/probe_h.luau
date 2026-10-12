--!nocheck
local mock = require("./mock")
local H = {}
function H.new()
	local q = mock.newQuad()
	-- simulated layout per host: array of names; record offset-based ops
	local sim = setmetatable({}, { __mode = "k" })
	local oi, oe, orm = q.Backend.nativeInsert, q.Backend.nativeExtract, q.Backend.nativeRemove
	local function L(t) sim[t] = sim[t] or {}; return sim[t] end
	q.Backend.nativeInsert = function(t, off, els)
		local l = L(t)
		for k, e in ipairs(els) do table.insert(l, off + k, e.Name) end
		return oi(t, off, els)
	end
	local function rm(orig)
		return function(t, off, els, new)
			local l = L(t)
			for _ = 1, #els do table.remove(l, off + 1) end
			if new then for k, e in ipairs(new) do table.insert(l, off + k, e.Name) end end
			return orig(t, off, els, new)
		end
	end
	q.Backend.nativeExtract = rm(oe)
	q.Backend.nativeRemove = rm(orm)
	return q, function(t) return table.concat(L(t), ",") end
end
function H.F(name) local f = mock.Instance.new("Frame"); f.Name = name; return f end
function H.names(inst)
	local t = {}
	for _, c in inst:GetChildren() do table.insert(t, c.Name) end
	table.sort(t); return table.concat(t, ",")
end
function H.leaves(q, slot, acc)
	local out = acc or {}
	for _, e in slot._elements do
		if q.isSlot(e) then H.leaves(q, e, out) else table.insert(out, e.Name) end
	end
	return out
end
function H.on(inst, when, fn)
	local fired = false
	inst:GetPropertyChangedSignal("Parent"):Connect(function()
		if fired or (inst.Parent ~= nil) ~= (when == "in") then return end
		fired = true
		fn()
	end)
end
H.mock = mock
return H
