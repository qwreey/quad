--!nocheck
-- E72 environment: one install (quad-roblox/luau_packages — typing-limits 8.34), base + mock backend,
-- plus an ORDER-KEEPING physical oracle over the native* seam (the mock's own native ops ignore offsets —
-- Roblox shape). Oracle idea from E19 (`audit/round13-e19-fuzz/fuzz.e19.luau` newEnv): insert strictly at the
-- passed offset; removal finds the block and, if it sits elsewhere contiguously, records a "stale offset"
-- (Q75 family, known) instead of a divergence.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local mock = require("../../../quad-base/test/mock")
local E = { Quad = Quad, mock = mock }
function E.id(err)
	local s = tostring(err)
	return s:match("Quad%d%d%d%d") or ("RAW:" .. (s:gsub("\n.*", "")))
end
local function nm(e) return if e == nil then "nil" elseif type(e) == "table" and e.Name then e.Name else tostring(e) end
E.nm = nm
function E.newBase(opts)
	opts = opts or {}
	local q = Quad.New()
	q:UseProvider(mock.mockProvider)
	local env = { q = q, phys = setmetatable({}, { __mode = "k" }), viol = {}, stale = {}, nOps = 0 }
	if opts.plainNative then return q, env end
	local phys = env.phys
	local function P(t) local l = phys[t]; if not l then l = {}; phys[t] = l end; return l end
	env.P = P
	local function viol(m) if #env.viol < 20 then table.insert(env.viol, m) end; env.violCount = (env.violCount or 0) + 1 end
	local function removeBlock(t, off, els, op)
		local l = P(t)
		local ok = true
		for k, e in ipairs(els) do if l[off + k] ~= e then ok = false break end end
		if ok then for _ = 1, #els do table.remove(l, off + 1) end return end
		local first = els[1] and table.find(l, els[1])
		if first then
			local contiguous = true
			for k, e in ipairs(els) do if l[first + k - 1] ~= e then contiguous = false end end
			if contiguous then
				table.insert(env.stale, `{op}: passed {off}, actual {first - 1}`)
				for _ = 1, #els do table.remove(l, first) end
				return
			end
		end
		viol(`{op}: block not found at {off} ({nm(els[1])})`)
		for _, e in ipairs(els) do local i = table.find(l, e); if i then table.remove(l, i) end end
	end
	local function insertBlock(t, off, els, op)
		local l = P(t)
		if off < 0 or off > #l then viol(`{op}: offset {off} out of [0,{#l}]`); off = math.clamp(off, 0, #l) end
		for k, e in ipairs(els) do table.insert(l, off + k, e) end
	end
	local B = q.Backend
	B.nativeInsert = function(t, off, els) env.nOps += 1; insertBlock(t, off, els, "insert"); for _, e in els do e.Parent = t end end
	B.nativeExtract = function(t, off, els, new)
		env.nOps += 1
		removeBlock(t, off, els, "extract"); for _, e in els do e.Parent = nil end
		if new then insertBlock(t, off, new, "extract/new"); for _, e in new do e.Parent = t end end
	end
	B.nativeRemove = function(t, off, els, new)
		env.nOps += 1
		removeBlock(t, off, els, "remove"); for _, e in els do e:Destroy() end
		if new then insertBlock(t, off, new, "remove/new"); for _, e in new do e.Parent = t end end
	end
	B.nativeMove = function(t, fo, els, to) env.nOps += 1; removeBlock(t, fo, els, "move"); insertBlock(t, to, els, "move/to") end
	B.nativeSwap = function(t, oa, ea, ob, eb)
		env.nOps += 1
		local l = P(t)
		local okA, okB = true, true
		for k, e in ipairs(ea) do if l[oa + k] ~= e then okA = false end end
		for k, e in ipairs(eb) do if l[ob + k] ~= e then okB = false end end
		if not (okA and okB) then viol(`swap: blocks not at {oa}/{ob}`) return end
		local out = {}
		for i = 1, oa do table.insert(out, l[i]) end
		for _, x in eb do table.insert(out, x) end
		for i = oa + #ea + 1, ob do table.insert(out, l[i]) end
		for _, x in ea do table.insert(out, x) end
		for i = ob + #eb + 1, #l do table.insert(out, l[i]) end
		phys[t] = out
	end
	B.nativeDispose = function(e)
		env.nOps += 1
		for _, l in pairs(phys) do local i = table.find(l, e); if i then table.remove(l, i) end end
		e:Destroy()
	end
	-- ProbeLeaf (E19 idiom): a string at a numeric key = one physical Frame at a PHYSICAL owner, constant length 1
	env.seatLeaf = {}
	q.Dispatch.addHandler({
		name = "E72ProbeLeaf",
		keyType = "number",
		isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "string" end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst, k, v, _index)
			local f = mock.Instance.new("Frame"); f.Name = v
			env.seatLeaf[v] = f
			q.Bookkeeping.setOffsetSource(inst, k, q.None)
			B.nativeInsert(inst, q.Bookkeeping.getOffsetAt(inst, k), { f })
			q.Bookkeeping.setLength(inst, k, 1)
			return q.Void
		end,
	})
	return q, env
end
return E
