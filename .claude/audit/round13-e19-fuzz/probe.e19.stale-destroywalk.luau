--!nocheck
-- E19 — minimal repro: a destroy walk (Remove/Clear/Replace/dispose of a mounted manual Slot) disposes the
-- walked Slot's earlier elements one by one, then UNMOUNTS a later non-owning sub-Slot (a State element's
-- wrapper, or an OwnsElements=false :Single) with `nativeExtract(inst, sub.Offset:Get(), …)` — an Offset that
-- still counts the siblings the same walk already disposed. Ordered-backend oracle from fuzz.e19.luau.
local mock = require("./mock")
local Instance = mock.Instance
local function nm(e) return if e == nil then "nil" elseif type(e) == "table" and e.Name then e.Name else tostring(e) end
local function newEnv()
	local q = mock.newQuad()
	local phys = setmetatable({}, { __mode = "k" })
	local env = { q = q, phys = phys, violations = {}, known = {} }
	local function P(t) local l = phys[t]; if not l then l = {}; phys[t] = l end; return l end
	env.P = P
	local function viol(msg) table.insert(env.violations, msg) end
	local function checkBlock(t, off, els, op)
		local l = P(t)
		for k, e in ipairs(els) do
			if l[off + k] ~= e then viol(`{op}: expected {nm(e)} at phys[{off + k}] got {nm(l[off + k])}`); return false end
		end
		return true
	end
	local function removeBlock(t, off, els, op)
		local l = P(t)
		local first = els[1] and table.find(l, els[1])
		if first and first - 1 ~= off then
			local contiguous = true
			for k, e in ipairs(els) do if l[first + k - 1] ~= e then contiguous = false end end
			if contiguous then
				table.insert(env.known, `stale {op}: passed {off}, actual {first - 1} ({nm(els[1])})`)
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
	B.nativeMove = function(t, fo, els, to) removeBlock(t, fo, els, "move"); insertBlock(t, to, els, "move/to") end
	B.nativeSwap = function(t, oa, ea, ob, eb)
		local okA = checkBlock(t, oa, ea, "swapA"); local okB = checkBlock(t, ob, eb, "swapB")
		local l = P(t)
		if not (okA and okB) then return end
		local out = {}
		for i = 1, oa do table.insert(out, l[i]) end
		for _, x in eb do table.insert(out, x) end
		for i = oa + #ea + 1, ob do table.insert(out, l[i]) end
		for _, x in ea do table.insert(out, x) end
		for i = ob + #eb + 1, #l do table.insert(out, l[i]) end
		phys[t] = out
	end
	B.nativeDispose = function(e)
		for _, l in pairs(phys) do local i = table.find(l, e); if i then table.remove(l, i) end end
		e:Destroy()
	end
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
	q._pc = { reindexCalls = 0, reindexIters = 0, spliceArr = 0, getOffsetAt = 0, getOffsetIters = 0, recompute = 0, recomputeIters = 0 }
	return env
end


local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function case(label, build, act)
	local env = newEnv()
	local q = env.q
	local host = Instance.new("Folder")
	local root = build(q)
	q.Dispatch.drive(host, { "L", root, "T" })
	act(q, root)
	local ph = {}
	for i, e in ipairs(env.P(host)) do ph[i] = e.Name end
	print(`{label}: stale={#env.known} {env.known[1] or ""} | viol={#env.violations} | phys=[{table.concat(ph, ",")}]`)
end
case("A Remove(nested [f1 f2 State(g)])", function(q) return q.Slot({ F("a"), q.Slot({ F("f1"), F("f2"), q.Source(F("g")) }) }) end, function(q, r) r:Remove(2) end)
case("B Clear(root [f1 State(g)])  (root walk is batched, not a destroy walk)", function(q) return q.Slot({ F("f1"), q.Source(F("g")) }) end, function(q, r) r:Clear() end)
case("C Remove(nested [f1 Single(noown)])", function(q)
	local ss = q.Slot():Single(q.Source("x"), function(ctx) if ctx.Item == q.KeyGone then return nil end; return F("s") end, { OwnsElements = false })
	return q.Slot({ F("a"), q.Slot({ F("f1"), ss }) }) end, function(q, r) r:Remove(2) end)
case("D Replace(nested [f1 State(g)], new)", function(q) return q.Slot({ q.Slot({ F("f1"), q.Source(F("g")) }) }) end, function(q, r) r:Replace(1, F("n")) end)
case("E Remove(nested [State(g) f1]) — wrapper first: no stale", function(q) return q.Slot({ q.Slot({ q.Source(F("g")), F("f1") }) }) end, function(q, r) r:Remove(1) end)
case("F Remove(nested [f1 nested2[State(g)]])", function(q) return q.Slot({ q.Slot({ F("f1"), q.Slot({ q.Source(F("g")) }) }) }) end, function(q, r) r:Remove(1) end)
