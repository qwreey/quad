--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch

-- ── physical-order simulating backend ──
local phys = setmetatable({}, { __mode = "k" })
local violations = {}
local function P(t) local l = phys[t]; if not l then l = {}; phys[t] = l end; return l end
local function nm(e) return e and e.Name or "nil" end
local function viol(msg) table.insert(violations, msg) end
local function checkBlock(t, off, els, op)
	local l = P(t)
	for k, e in ipairs(els) do
		if l[off + k] ~= e then
			viol(`{op}: expected {nm(e)} at phys[{off + k}] got {nm(l[off + k])}`)
			return false
		end
	end
	return true
end
local known = {}
local function removeBlock(t, off, els, op)
	local l = P(t)
	local first = els[1] and table.find(l, els[1])
	if first and first - 1 ~= off then
		local contiguous = true
		for k, e in ipairs(els) do if l[first + k - 1] ~= e then contiguous = false end end
		if contiguous and op == "extract" then
			table.insert(known, `K1 stale offset {op}: passed {off}, actual {first - 1} ({nm(els[1])})`)
			for _ = 1, #els do table.remove(l, first) end
			return
		end
	end
	if not checkBlock(t, off, els, op) then
		for _, e in ipairs(els) do local i = table.find(l, e); if i then table.remove(l, i) end end
		return
	end
	for _ = 1, #els do table.remove(l, off + 1) end
end
local function insertBlock(t, off, els, op)
	local l = P(t)
	if off < 0 or off > #l then viol(`{op}: offset {off} out of [0,{#l}]`); off = math.clamp(off, 0, #l) end
	for k, e in ipairs(els) do table.insert(l, off + k, e) end
end
local B = q.Backend
B.nativeInsert = function(t, off, els) insertBlock(t, off, els, "insert"); for _, e in els do e.Parent = t end end
B.nativeExtract = function(t, off, els, new)
	removeBlock(t, off, els, "extract"); for _, e in els do e.Parent = nil end
	if new then insertBlock(t, off, new, "extract/new"); for _, e in new do e.Parent = t end end
end
B.nativeRemove = function(t, off, els, new)
	removeBlock(t, off, els, "remove"); for _, e in els do e:Destroy() end
	if new then insertBlock(t, off, new, "remove/new"); for _, e in new do e.Parent = t end end
end
B.nativeMove = function(t, fo, els, to)
	removeBlock(t, fo, els, "move"); insertBlock(t, to, els, "move/to")
end
B.nativeSwap = function(t, oa, ea, ob, eb)
	-- a before b
	local okA = checkBlock(t, oa, ea, "swapA"); local okB = checkBlock(t, ob, eb, "swapB")
	local l = P(t)
	if not (okA and okB) then return end
	local before = table.move(l, 1, oa, 1, {})
	local mid = table.move(l, oa + #ea + 1, ob, 1, {})
	local after = table.move(l, ob + #eb + 1, #l, 1, {})
	local out = {}
	for _, x in before do table.insert(out, x) end
	for _, x in eb do table.insert(out, x) end
	for _, x in mid do table.insert(out, x) end
	for _, x in ea do table.insert(out, x) end
	for _, x in after do table.insert(out, x) end
	phys[t] = out
end
local function dropEverywhere(e) for _, l in pairs(phys) do local i = table.find(l, e); if i then table.remove(l, i) end end end
B.nativeDispose = function(e) dropEverywhere(e); e:Destroy() end

-- leaf handler for string items: a Frame named by the string
q.Dispatch.addHandler({
	name = "ProbeLeaf",
	isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "string" end,
	priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
	process = function(inst, k, v, _index)
		local f = Instance.new("Frame"); f.Name = v
		q.Bookkeeping.setOffsetSource(inst, k, q.None)
		B.nativeInsert(inst, q.Bookkeeping.getOffsetAt(inst, k), { f })
		q.Bookkeeping.setLength(inst, k, 1)
		return q.Void
	end,
})

-- expected flatten
local function leaves(s, out)
	out = out or {}
	for _, e in ipairs(s._elements) do
		if q.isSlot(e) then leaves(e, out) else table.insert(out, e) end
	end
	return out
end
local function names(list) local o = {}; for i, e in ipairs(list) do o[i] = nm(e) end; return table.concat(o, ",") end

return {
	q = q, mock = mock, Instance = Instance, Slot = Slot, dispatch = dispatch,
	phys = phys, P = P, known = known, violations = violations, leaves = leaves, names = names, nm = nm,
}
