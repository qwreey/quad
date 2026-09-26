--!nocheck
--[[
	E46 reference model — the Modifier composition algebra as PURE functions over a
	"field -> model value" map + a class tag. Every rule cites the contract line it
	transcribes (HEAD 836b5e7f). The model never calls quad.

	Model value (MV):
	  { k = "lit",   v = <plain> }        literal (number here)
	  { k = "state", s = <State> }        a State/Source handle stored as-is
	  { k = "derived", base = MV(state|derived), fn = spec }   old:Compute(fn)
	  { k = "tween", t = <Tween> }        a Tween literal stored as-is
	  { k = "none" }                      q.None
	  nil                                 field ABSENT
]]

local M = {}

-- R1  core/08:10  every op returns a NEW value; the original is untouched (clone + freeze)
-- R2  core/08:80,249,324  q.Modifier(...) / Overridden: field-wise merge, later argument wins
-- R3  core/08:82  q.Modifier(...) → tag true;  core/08:359 TypedFactory ctor → tag = name
-- R4  core/08:247,322  Overridden → tag true (untyped) whatever the inputs
-- R5  core/08:128  setter literal: overwrite
-- R6  core/08:129  setter State/Source: the handle itself is stored
-- R7  core/08:130,136 + roblox/03:127-128  setter function: plain old → fn(old) called NOW;
--                                          State old → old:Compute(fn) (fn gets the HANDLE)
-- R8  core/08:131  setter nil → field absent
-- R9  core/08:132  transform returns nil: plain → absent; State → State<nil> field (writes nil)
-- R10 core/08:134  setter None → field = None (explicit unset)
-- R11 core/08:140 + roblox/03:96  setters keep the tag
-- R12 core/08:188-190  Peek returns the stored value raw (State stays handle, None stays None, absent → nil)
-- R13 core/08:52-53  flatten: inline string key always wins (inline None too); later array Modifier wins
-- R14 core/08:271  As() → value as-is (tag untouched)
-- R15 core/08:272 + roblox/03:213  As(name) → retag, existence check only (Quad0052), non-string Quad0051
-- R16 core/08:289-292 + roblox/03:192  As<Class>(): target known (else Quad0055) and tag ∈ {true, target, ancestor of target} (else Quad0056)
-- R17 core/08:225  Apply(factory) = factory(self)
-- R18 roblox/03:103 + roblox/06 (first set snaps — Property.luau header "first set = snap")
--     a Tween field: first write snaps to Value; a later Tween emission animates (tween Create)
-- R19 roblox/03:165  tostring → Modifier<Class>(n fields) / Modifier(n fields)
-- R20 (E37 M2b, roblox/02:115) a None field writes nil to the property

M.RULES = 20

-- class registry (data, not rules): quad-roblox Declaration/init.luau DefineSubtype lines
local PARENTS = {
	GuiBase = { Instance = true },
	GuiBase2d = { GuiBase = true },
	GuiObject = { GuiBase2d = true },
	GuiButton = { GuiObject = true },
	GuiLabel = { GuiObject = true },
	Frame = { GuiObject = true },
	TextButton = { GuiButton = true },
	TextLabel = { GuiLabel = true },
}
M.KNOWN = { Instance = true, GuiBase = true, GuiBase2d = true, GuiObject = true, GuiButton = true, GuiLabel = true, Frame = true, TextButton = true, TextLabel = true }

local function isAncestorOrSelf(anc, name)
	if anc == name then return true end
	local stack, seen = { name }, {}
	while #stack > 0 do
		local n = table.remove(stack)
		for p in PARENTS[n] or {} do
			if p == anc then return true end
			if not seen[p] then seen[p] = true; table.insert(stack, p) end
		end
	end
	return false
end

-- a model Modifier: { tag = true|string, f = { [field] = MV } }
function M.new(tag, fields)
	return { tag = tag, f = fields or {} }
end

local function clone(m, tag)
	return { tag = if tag == nil then m.tag else tag, f = table.clone(m.f) }
end

-- R5/R6/R8/R10 (+R11)
function M.set(m, field, mv)
	local n = clone(m)
	n.f[field] = mv
	return n
end

-- R7/R9: spec is a model transform description; `apply(spec, rawOld)` is the pure function
function M.transform(m, field, spec, apply)
	local old = m.f[field]
	local n = clone(m)
	if old ~= nil and (old.k == "state" or old.k == "derived") then
		n.f[field] = { k = "derived", base = old, fn = spec }
	else
		local out = apply(spec, old) -- apply(spec, oldMV) -> MV | nil
		n.f[field] = out -- MV or nil (absent — R9 plain arm)
	end
	return n
end

-- R2/R3/R4: args = list of model modifiers or plain-table MVs ({ f = ..., plain = true })
function M.merge(tag, args)
	local f = {}
	for _, a in args do
		for k, v in a.f do f[k] = v end
	end
	return M.new(tag, f)
end

-- R14/R15/R16 — returns (newModel | nil, expectedErrorId | nil)
function M.cast(m, how, name)
	if how == "As" then
		if name == nil then return m, nil end
		if type(name) ~= "string" then return nil, "Quad0051" end
		if not M.KNOWN[name] then return nil, "Quad0052" end
		return clone(m, name), nil
	end
	-- checked
	if not M.KNOWN[name] then return nil, "Quad0055" end
	if m.tag ~= true and m.tag ~= name and not isAncestorOrSelf(m.tag, name) then return nil, "Quad0056" end
	return clone(m, name), nil
end

-- R19
function M.tostring(m)
	local n = 0
	for _ in m.f do n += 1 end
	return `Modifier{if m.tag == true then "" else `<{m.tag}>`}({n} fields)`
end

-- R13: array = list of model modifiers (in order), inline = { [field] = MV }
function M.flatten(array, inline)
	local out = {}
	for k, v in inline do out[k] = v end
	for i = #array, 1, -1 do
		for k, v in array[i].f do
			if out[k] == nil then out[k] = v end
		end
	end
	return out
end

return M
