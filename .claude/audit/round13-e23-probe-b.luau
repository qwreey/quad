--!nocheck
-- round13 E23 B — numeric-key place: State value kind transitions (pairwise matrix)
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1")) end
local function nsubs(s) for _ = 1, 3 do collectgarbage("collect") end local n = 0 for _ in s._subs do n += 1 end return n end

-- each kind: make() -> value, desc(f, v) -> observable string
local kinds = {}
local order = {}
local function kind(name, make) kinds[name] = make; table.insert(order, name) end
local CTX = {}
kind("inst", function() local c = D.Frame { Name = "child" }; CTX.inst = c; return c end)
kind("slot", function() local c = D.Frame { Name = "slotEl" }; CTX.slotEl = c; local s = q.Slot { c }; CTX.slot = s; return s end)
kind("tag", function() return q.Tag("T1") end)
kind("ref", function() local r = q.Ref(); CTX.ref = r; return r end)
kind("attr", function() return q.Attr({ A = 1 }) end)
kind("none", function() return q.None end)
kind("nil", function() return nil end)
kind("inner", function() local c = D.Frame { Name = "innerChild" }; CTX.innerChild = c; local i = q.Source(c); CTX.inner = i; return i end)
kind("effect", function() CTX.effRuns = 0; return q.Effect(function() CTX.effRuns += 1; return function() CTX.effClean = true end end) end)
kind("observer", function() local s = q.Source(1); CTX.obsSrc = s; return s:Observer(function() end) end)
kind("str", function() return "text" end)
kind("tween", function() return q.Tween({ Value = 1, Time = 1 }) end)

local function obs(f)
	local ks = {}
	for _, c in f:GetChildren() do table.insert(ks, c.Name) end
	local tags = mock.getTags(f)
	local at = mock.getAttributes(f)
	local as = {}
	for k, v in at do table.insert(as, k .. "=" .. tostring(v)) end
	return ("kids[%s] tags[%s] attrs[%s] ref=%s"):format(table.concat(ks, ","), table.concat(tags, ","), table.concat(as, ","), CTX.ref and tostring(CTX.ref.Value and CTX.ref.Value.Name) or "-")
end

local rows = {}
for _, from in order do
	for _, to in order do
		if from ~= to then
			CTX = {}
			local line = from .. " -> " .. to .. ": "
			local ok0, s = pcall(function() return q.Source(kinds[from]()) end)
			if not ok0 then line ..= "Source(from) ERR " .. first(s); table.insert(rows, line) continue end
			local f
			local ok1, e1 = pcall(function() f = D.Frame { Name = "host", s } end)
			if not ok1 then line ..= "mount ERR " .. first(e1); table.insert(rows, line) continue end
			local fromRef = CTX.ref
			local toVal
			local ok2, e2 = pcall(function() toVal = kinds[to](); s:Set(toVal) end)
			line ..= (ok2 and "ok " or ("ERR " .. first(e2) .. " ")) .. obs(f)
			if fromRef then line ..= " oldRef=" .. tostring(fromRef.Value and fromRef.Value.Name) end
			if CTX.effClean then line ..= " effClean" end
			-- recovery: back to a fresh inst
			local ok3, e3 = pcall(function() s:Set(D.Frame { Name = "recover" }) end)
			line ..= " | recover " .. (ok3 and "ok " or ("ERR " .. first(e3) .. " ")) .. (function() local t = {} for _, c in f:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end)()
			if CTX.inner then line ..= " innerSubs=" .. nsubs(CTX.inner) end
			table.insert(rows, line)
		end
	end
end
for _, r in rows do print(r) end
