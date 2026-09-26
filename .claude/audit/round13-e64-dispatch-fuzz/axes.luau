--!nocheck
-- E64 axes (a)~(f): tie determinism, built-in competition, retractFrom index, process return values,
-- retractor throws, addHandler gates. usage: luau .claude/audit/round13-e64-dispatch-fuzz/axes.luau
local E = require("./env")
local function mk(name, prio, pred, kt, extra)
	local h = { name = name, priority = prio, keyType = kt, isHandlable = pred,
		process = function() return function() end end }
	if extra then for k, v in extra do h[k] = v end end
	return h
end
local function names(q, filter)
	local t = {}
	for _, h in q.Dispatch.listHandlers() do if not filter or filter(h) then table.insert(t, tostring(h.name)) end end
	return table.concat(t, ",")
end
local function try(label, f, ...)
	local ok, e = pcall(f, ...)
	print(label, if ok then "ok" else E.id(e) .. "  | " .. (tostring(e):gsub("\n.*", "")))
end
local isUser = function(h) return tostring(h.name):match("^U") ~= nil end

print("== (a) tie determinism ==")
-- a1: same registration sequence in two fresh modules -> same order?
local orders = {}
for rep = 1, 3 do
	local q = E.newBase()
	for i = 1, 6 do q.Dispatch.addHandler(mk("U" .. i, 7, function() return true end)) end
	orders[rep] = names(q, isUser)
end
print("a1 six tied handlers, three fresh modules:", orders[1], orders[2], orders[3], "identical:", orders[1] == orders[2] and orders[2] == orders[3])
-- a2: the tie order among U1..U6 after registering an UNRELATED handler at another priority
do
	local q = E.newBase()
	local seen = {}
	for i = 1, 6 do q.Dispatch.addHandler(mk("U" .. i, 7, function() return true end)) end
	table.insert(seen, names(q, isUser))
	for j = 1, 5 do
		q.Dispatch.addHandler(mk("Uother" .. j, 100 + j, function() return false end))
		table.insert(seen, names(q, function(h) return isUser(h) and not tostring(h.name):match("other") end))
	end
	print("a2 tie order of U1..U6 after each unrelated registration:")
	for i, s in seen do print("   ", i - 1, s) end
	-- which one actually wins a scan (getHandler)?
	local inst = E.mock.Instance.new("Frame")
	print("a2 getHandler winner now:", q.Dispatch.getHandler(inst, "Foo", 1).name)
end
-- a3: two handlers tied, the FIRST registered wins? over 200 random tie groups (count registration-order agreement)
do
	local RNG = require("./rng")
	local agree, total = 0, 0
	for seed = 1, 200 do
		local rng = RNG.new(seed)
		local q = E.newBase()
		local n = rng:NextInteger(2, 8)
		local first
		for i = 1, n do
			local pr = if rng:NextInteger(1, 2) == 1 then 7 else rng:NextInteger(-5, 20)
			local h = mk("U" .. i, pr, function(_, k) return k == "Foo" end)
			q.Dispatch.addHandler(h)
		end
		-- among handlers at the top priority, is the scan winner the earliest registered?
		local list = q.Dispatch.listHandlers()
		local top, tied = nil, {}
		for _, h in list do if isUser(h) then top = top or h.priority; if h.priority == top then table.insert(tied, h) end end end
		if #tied >= 2 then
			total += 1
			local earliest = tied[1]
			for _, h in tied do if tonumber(h.name:sub(2)) < tonumber(earliest.name:sub(2)) then earliest = h end end
			local w = q.Dispatch.getHandler(E.mock.Instance.new("Frame"), "Foo", 1)
			if w == earliest then agree += 1 end
		end
	end
	print(`a3 top-priority ties: {total}, winner = earliest registered in {agree} ({string.format("%.0f", 100 * agree / total)}%)`)
end
-- a4: debug tie print — which pair does it name; and a tie with a built-in HIGH handler
do
	local q = E.newBase()
	q.debug = true
	local printed = {}
	local oldPrint = print
	print = function(...) table.insert(printed, table.concat({ ... }, " ")) end
	q.Dispatch.addHandler(mk("UHigh", 1000, function(_, _, v) return v == q.None end))
	q.Dispatch.addHandler(mk("UA", 7, function() return false end))
	q.Dispatch.addHandler(mk("UB", 7, function() return false end))
	q.Dispatch.addHandler(mk("UC", 7, function() return false end))
	q.Dispatch.addHandler(mk("UStr", 7, function() return false end, "string"))
	q.Dispatch.addHandler(mk("UNum", 7, function() return false end, "number"))
	print = oldPrint
	for _, s in printed do print("a4 debug:", s) end
	-- who wins None at a string key between NoneHandler (HIGH) and UHigh (HIGH, v == None)?
	local w = q.Dispatch.getHandler(E.mock.Instance.new("Frame"), "Foo", q.None)
	print("a4 None at 'Foo' tie NoneHandler vs UHigh -> winner:", w.name, " order:", names(q, function(h) return h.priority == 1000 end))
	-- debug off at registration -> no print even when q.debug turned on later
	local q2 = E.newBase()
	local cnt = 0
	print = function() cnt += 1 end
	q2.Dispatch.addHandler(mk("UX", 7, function() return false end))
	q2.debug = true
	q2.Dispatch.addHandler(mk("UY", 3, function() return false end))
	print = oldPrint
	print("a4 tie registered while debug=false, later debug=true + untied registration -> prints:", cnt)
end

print("== (b) competition with built-ins ==")
do
	local q = E.newProv()
	local D = q.Dispatch
	local got = {}
	-- b1: a user HIGH+1 handler intercepting quad brand values at string keys (Q135 seat)
	D.addHandler({ name = "UCatchBrandsAtStringKeys", priority = D.HANDLER_PRIORITY_HIGH + 1, keyType = "string",
		isHandlable = function(_, k, v) return q.isRef(v) end,
		process = function(inst, k, v, i) table.insert(got, `caught {k}`); return q.Void end })
	local ref = q.Ref(nil)
	local ok, e = pcall(function() return q.Declaration.Frame { Size = ref, Foo = q.Ref(nil) } end)
	print("b1 D.Frame{Size = ref, Foo = ref} with user HIGH+1 Ref catcher:", ok, ok and "" or E.id(e), table.concat(got, ","))
	-- b2: user at exactly NORMAL on a reflected key competes with Property (tie, undefined) / NORMAL+2 wins
	local q2 = E.newProv()
	q2.Dispatch.addHandler({ name = "UNormal", priority = 0, keyType = "string", isHandlable = function(_, k) return k == "Size" end,
		process = function() return q2.Void end })
	local w = q2.Dispatch.getHandler(q2.Declaration.Frame {}, "Size", 1)
	print("b2 user NORMAL vs Property NORMAL on 'Size' -> winner:", w.name, "(order:", names(q2, function(h) return h.priority == 0 end) .. ")")
	-- b3: user HIGH+1 on v == None overrides NoneHandler: None no longer unwraps
	local q3 = E.newBase()
	local seen = {}
	q3.Dispatch.addHandler({ name = "UNone", priority = 1001, isHandlable = function(_, _, v) return v == q3.None end,
		process = function(_, k, v, i) table.insert(seen, `UNone@{i}`); return q3.Void end })
	q3.Dispatch.process(E.mock.Instance.new("Frame"), 1, q3.None, 1)
	print("b3 user HIGH+1 None handler:", table.concat(seen, ","))
	-- b4: user HIGH+1 catching every State (StoreBind bypassed) — value no longer unwrapped
	local q4 = E.newBase()
	local seen4 = {}
	q4.Dispatch.addHandler({ name = "UState", priority = 1001, isHandlable = function(_, _, v) return q4.isState(v) end,
		process = function(_, k, v, i) table.insert(seen4, `UState@{i}`); return q4.Void end })
	q4.Dispatch.addHandler({ name = "ULeaf", priority = 0, isHandlable = function(_, _, v) return type(v) == "number" end,
		process = function(_, k, v, i) table.insert(seen4, `ULeaf {v}@{i}`); return q4.Void end })
	local s = q4.Source(1)
	q4.Dispatch.process(E.mock.Instance.new("Frame"), "Foo", s, 1)
	s:Set(2)
	print("b4 user HIGH+1 State catcher:", table.concat(seen4, ","))
	-- b5: user FALLBACK handler vs base guards (FALLBACK) for a Slot at a string key
	local q5 = E.newBase()
	q5.Dispatch.addHandler({ name = "USlotAtString", priority = q5.Dispatch.HANDLER_PRIORITY_FALLBACK, keyType = "string",
		isHandlable = function(_, _, v) return q5.isSlot(v) end, process = function() return q5.Void end })
	local w5 = q5.Dispatch.getHandler(E.mock.Instance.new("Frame"), "Foo", q5.Slot())
	print("b5 user FALLBACK vs SlotDynamicPathGuard (FALLBACK) -> winner:", w5.name)
	-- b6: user LOW handler for 'Size' never reached (Property takes every value at reflected keys, even nil)
	local q6 = E.newProv()
	local hit = 0
	q6.Dispatch.addHandler({ name = "ULowSize", priority = -1000, keyType = "string", isHandlable = function(_, k) return k == "Size" end,
		process = function() hit += 1; return q6.Void end })
	local f6 = q6.Declaration.Frame {}
	q6.Dispatch.process(f6, "Size", nil, 1)
	q6.Dispatch.process(f6, "Size", {}, 1)
	print("b6 user LOW on 'Size' hits:", hit)
end

print("== (c) retractFrom index = chain depth ==")
do
	local q = E.newBase()
	local D = q.Dispatch
	local log = {}
	local function W(x) return { w = x } end
	D.addHandler({ name = "UWrap", priority = 10, isHandlable = function(_, _, v) return type(v) == "table" and v.w ~= nil end,
		process = function(inst, k, v, i) table.insert(log, `Pw@{i}`); D.process(inst, k, v.w, i + 1)
			return function(n, r) table.insert(log, `Rw@{i}({tostring(r)})`) end end })
	D.addHandler({ name = "ULeaf", priority = 0, isHandlable = function(_, _, v) return type(v) == "number" end,
		process = function(inst, k, v, i) table.insert(log, `P{v}@{i}`); if type(k) == "number" then q.Bookkeeping.setEmpty(inst, k) end
			return function(n, r) table.insert(log, `R{v}@{i}(next={tostring(n)},{tostring(r)})`) end end })
	local inst = E.mock.Instance.new("Frame")
	D.process(inst, "Foo", W(W(5)), 1)
	print("c1 W(W(5)):", table.concat(log, " ")); table.clear(log)
	D.retractFrom(inst, "Foo", 2)
	print("c2 retractFrom(…, 2):", table.concat(log, " ")); table.clear(log)
	D.process(inst, "Foo", W(6), 1)
	print("c3 then W(6) at 1 (A branch, rebuild depth 2):", table.concat(log, " ")); table.clear(log)
	D.retractFrom(inst, "Foo", 5)
	print("c4 retractFrom beyond tail (5):", table.concat(log, " ") == "" and "no-op" or table.concat(log, " "))
	try("c5 retractFrom(…, 0):", D.retractFrom, inst, "Foo", 0)
	try("c6 retractFrom(…, 1.5):", D.retractFrom, inst, "Foo", 1.5)
	try("c7 retractFrom key with no chain:", D.retractFrom, inst, "Nope", 1)
	-- c8: wrapper whose value stops delegating keeps the deeper layer alive (A branch: 'deeper layers untouched')
	D.addHandler({ name = "UCond", priority = 20, isHandlable = function(_, _, v) return type(v) == "table" and v.c ~= nil end,
		process = function(inst, k, v, i) table.insert(log, `Pc({tostring(v.c)})@{i}`); if type(v.c) == "number" then D.process(inst, k, v.c, i + 1) end
			return function(n, r) table.insert(log, `Rc@{i}({tostring(r)})`) end end })
	D.retractFrom(inst, "Foo", 1); table.clear(log)
	D.process(inst, "Foo", { c = 7 }, 1)
	D.process(inst, "Foo", { c = "stop" }, 1)
	print("c8 cond-wrapper {c=7} then {c='stop'}:", table.concat(log, " ")); table.clear(log)
	D.retractFrom(inst, "Foo", 1)
	print("c8 final retract (depth-2 leaf 7 still there?):", table.concat(log, " ")); table.clear(log)
	-- c9: number-key 'index' is NOT the array position: retractFrom(inst, 2, 1) tears the chain at array key 2
	q.Bookkeeping.setEmpty(inst, 1); q.Bookkeeping.setEmpty(inst, 2)
	D.process(inst, 2, W(8), 1)
	D.retractFrom(inst, 2, 1)
	print("c9 array key 2 chain retract:", table.concat(log, " "))
end

print("== (d) process return values ==")
do
	for _, case in {
		{ "nil", function() return nil end },
		{ "true", function() return true end },
		{ "number", function() return 5 end },
		{ "table", function() return {} end },
		{ "callable table", function() return setmetatable({}, { __call = function() end }) end },
		{ "q.Void", "VOID" },
	} do
		local q = E.newBase()
		local ret = case[2]
		q.Dispatch.addHandler({ name = "URet", priority = 5, isHandlable = function(_, k) return k == "Foo" end,
			process = function() if ret == "VOID" then return q.Void end return ret() end })
		local inst = E.mock.Instance.new("Frame")
		local ok1, e1 = pcall(q.Dispatch.process, inst, "Foo", 1, 1)
		local ok2, e2 = pcall(q.Dispatch.process, inst, "Foo", 2, 1)
		local ok3, e3 = pcall(q.Dispatch.retractFrom, inst, "Foo", 1)
		local ok4, e4 = pcall(q.Dispatch.retractFrom, inst, "Foo", 1)
		local function s(ok, e) return if ok then "ok" else E.id(e) .. " " .. (tostring(e):gsub("\n.*", ""):sub(1, 90)) end
		print(`d returns {case[1]}: process {s(ok1, e1)} | reprocess {s(ok2, e2)} | retract {s(ok3, e3)} | retract again {s(ok4, e4)}`)
	end
end

print("== (e) retractor throws ==")
do
	local q = E.newBase()
	local D = q.Dispatch
	local log = {}
	D.addHandler({ name = "UWrap", priority = 10, isHandlable = function(_, _, v) return type(v) == "table" and v.w ~= nil end,
		process = function(inst, k, v, i) D.process(inst, k, v.w, i + 1)
			return function(n, r) table.insert(log, `Rw@{i}`) end end })
	D.addHandler({ name = "UBad", priority = 0, isHandlable = function(_, _, v) return v == "bad" end,
		process = function(inst, k, v, i) return function(n, r) table.insert(log, `Rbad@{i}`); error("RETRACT-BOOM", 0) end end })
	D.addHandler({ name = "UOk", priority = 0, isHandlable = function(_, _, v) return v == "ok" end,
		process = function(inst, k, v, i) table.insert(log, `Pok@{i}`); return function() table.insert(log, `Rok@{i}`) end end })
	local inst = E.mock.Instance.new("Frame")
	D.process(inst, "Foo", { w = "bad" }, 1)
	try("e1 retractFrom 1 (depth-2 retractor throws):", D.retractFrom, inst, "Foo", 1)
	print("   log:", table.concat(log, " ")); table.clear(log)
	try("e2 retractFrom 1 again:", D.retractFrom, inst, "Foo", 1)
	print("   log:", table.concat(log, " ")); table.clear(log)
	try("e3 process 'ok' at depth 1 (B: retract tail first):", D.process, inst, "Foo", "ok", 1)
	print("   log:", table.concat(log, " ")); table.clear(log)
end

print("== (f) addHandler gates ==")
do
	local q = E.newBase()
	local D = q.Dispatch
	local base = function() return false end
	local p = function() return q.Void end
	try("f1 priority '5' (string):", D.addHandler, { priority = "5", isHandlable = base, process = p })
	try("f2 priority NaN:", D.addHandler, { priority = 0 / 0, isHandlable = base, process = p })
	try("f3 priority inf:", D.addHandler, { priority = math.huge, isHandlable = base, process = p })
	try("f4 priority nil:", D.addHandler, { isHandlable = base, process = p })
	try("f5 keyType 'Number':", D.addHandler, { priority = 1, keyType = "Number", isHandlable = base, process = p })
	try("f6 keyType 1:", D.addHandler, { priority = 1, keyType = 1, isHandlable = base, process = p })
	try("f7 keyType 'boolean':", D.addHandler, { priority = 1, keyType = "boolean", isHandlable = base, process = p })
	try("f8 isHandlable callable table:", D.addHandler, { priority = 1, isHandlable = setmetatable({}, { __call = function() return false end }), process = p })
	try("f9 name = 5 (non-string):", D.addHandler, { name = 5, priority = 1, isHandlable = base, process = p })
	try("f10 name = {} (table):", D.addHandler, { name = {}, priority = 1, isHandlable = base, process = p })
	local n0 = #D.listHandlers()
	local dup1 = { name = "Dup", priority = 2, isHandlable = base, process = p }
	local dup2 = { name = "Dup", priority = 2, isHandlable = base, process = p }
	D.addHandler(dup1); D.addHandler(dup2); D.addHandler(dup1)
	print("f11 same table twice + same name different table: registry grew by", #D.listHandlers() - n0, "(expect 2)")
	-- f12: mutate priority then re-register the same table: dedup returns before re-sort
	local mover = { name = "Mover", priority = -5, isHandlable = function(_, k) return k == "Zed" end, process = p }
	local other = { name = "Other", priority = 0, isHandlable = function(_, k) return k == "Zed" end, process = p }
	D.addHandler(mover); D.addHandler(other)
	mover.priority = 50
	D.addHandler(mover)
	local w = D.getHandler(E.mock.Instance.new("Frame"), "Zed", 1)
	print("f12 Mover priority -5 -> 50 then re-addHandler: winner", w.name, "(sorted order would give Mover)")
	-- f13: re-register same table after setting an INVALID keyType: dedup precedes the keyType gate
	mover.keyType = "bogus"
	try("f13 re-add after keyType = 'bogus':", D.addHandler, mover)
	print("   winner for 'Zed' now:", D.getHandler(E.mock.Instance.new("Frame"), "Zed", 1).name)
	-- f14: keyType declared "number" but predicate only accepts string keys -> silently never matches
	D.addHandler({ name = "Mismatch", priority = 900, keyType = "number", isHandlable = function(_, k) return k == "Mis" end, process = p })
	print("f14 keyType 'number' + string-key predicate: getHandler 'Mis' ->", D.getHandler(E.mock.Instance.new("Frame"), "Mis", 1))
	-- f15: addHandler from inside a running scan (isHandlable registers a handler)
	local q2 = E.newBase()
	local added = false
	q2.Dispatch.addHandler({ name = "Registrar", priority = 5, isHandlable = function(_, k)
		if not added then added = true; q2.Dispatch.addHandler({ name = "Late", priority = 100, isHandlable = function() return true end, process = function() return q2.Void end }) end
		return k == "X" end, process = function() return q2.Void end })
	local w15 = q2.Dispatch.getHandler(E.mock.Instance.new("Frame"), "X", 1)
	local w15b = q2.Dispatch.getHandler(E.mock.Instance.new("Frame"), "X", 1)
	print("f15 handler registered mid-scan: first scan ->", w15.name, " next scan ->", w15b.name)
end

print("== (h) before any provider (bare Quad.New()) ==")
do
	local q = E.Quad.New()
	q.Dispatch.addHandler({ name = "U", priority = 5, isHandlable = function() return true end, process = function() return q.Void end })
	try("h1 process on a mock inst with no backend:", q.Dispatch.process, E.mock.Instance.new("Frame"), "Foo", 1, 1)
	try("h2 getHandler with no backend:", function() return q.Dispatch.getHandler(E.mock.Instance.new("Frame"), "Foo", 1).name end)
end
