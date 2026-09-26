--!nocheck
-- E46 differential fuzzer: real Modifier vs model.luau. Run from repo root after relink:
--   luau .claude/audit/round13-e46-modifier-algebra/fuzz.luau -a <seeds> [startSeed]
local H = require("./harness")
local M = require("./model")
if os.getenv and false then end
local MUT = select(4, ...)
-- mutation sanity (the fuzzer must SEE a wrong model): pass a 4th arg
if MUT == "firstwins" then
	M.flatten = function(array, inline)
		local out = {}
		for k, v in inline do out[k] = v end
		for i = 1, #array do for k, v in array[i].f do if out[k] == nil then out[k] = v end end end
		return out
	end
elseif MUT == "keeptag" then
	local merge = M.merge
	M.merge = function(tag, args) local r = merge(tag, args); if tag == true and args[1] and args[1].tag then r.tag = args[1].tag end; return r end
elseif MUT == "upcast" then
	local cast = M.cast
	M.cast = function(m, how, name) if how == "chk" and M.KNOWN[name] then return { tag = name, f = table.clone(m.f) }, nil end return cast(m, how, name) end
elseif MUT == "eager" then
	local tr = M.transform
	M.transform = function(m, field, spec, apply)
		local old = m.f[field]
		if old and (old.k == "state" or old.k == "derived") then local n = { tag = m.tag, f = table.clone(m.f) }; n.f[field] = apply(spec, nil); return n end
		return tr(m, field, spec, apply)
	end
elseif MUT == "nilnone" then
	local set = M.set
	M.set = function(m, f, mv) if mv == nil then mv = { k = "none" } end return set(m, f, mv) end
end
local q, D, None = H.q, H.D, H.None
local mock = require("../../../quad-base/test/mock")
local isState = q.isState
local isTween = q.isTween

local args = { ... }
local NSEEDS = tonumber(args[1]) or 2000
local START = tonumber(args[2]) or 1
local VERBOSE = args[3] == "v"

local FRAMEF = { "BackgroundTransparency", "LayoutOrder", "ZIndex", "Rotation", "BorderSizePixel" }
local TBF = { "TextSize", "TextTransparency" }
local TB_ONLY = { TextSize = true, TextTransparency = true }

-- ── rng ──
local seedState = 1
local function rnd(n) -- 1..n
	seedState = (seedState * 1103515245 + 12345) % 2147483648
	return (seedState // 65536) % n + 1
end
local function pick(t) return t[rnd(#t)] end
local counter = 0
local function fresh() counter += 1; return counter end

-- ── transform specs (the SAME pure function drives real and model) ──
local function pure(spec, v)
	if spec.kind == "inc" then
		if v == nil then return spec.k end
		if v == None then return None end
		if isTween(v) then return v end
		return v + spec.k
	elseif spec.kind == "tonil" then
		return nil
	elseif spec.kind == "toNone" then
		return None
	end
	error("spec?")
end
local function realFn(spec)
	return function(old)
		local v = if isState(old) then old:Get() else old
		return pure(spec, v)
	end
end
local function rawToMV(raw)
	if raw == nil then return nil end
	if raw == None then return { k = "none" } end
	if isTween(raw) then return { k = "tween", t = raw } end
	return { k = "lit", v = raw }
end
local function mvToRaw(mv)
	if mv == nil then return nil end
	if mv.k == "lit" then return mv.v end
	if mv.k == "tween" then return mv.t end
	if mv.k == "none" then return None end
	error("mvToRaw state")
end
local function modelApply(spec, oldMV)
	return rawToMV(pure(spec, mvToRaw(oldMV)))
end
-- evaluate an MV to the raw value a State would currently emit / a literal holds
local function evalRaw(mv)
	if mv == nil then return nil end
	if mv.k == "state" then return mv.s:Get() end
	if mv.k == "derived" then return pure(mv.fn, evalRaw(mv.base)) end
	return mvToRaw(mv)
end

-- ── diff bookkeeping ──
local diffs = {}
local STATS = { ops = 0, experr = 0, mounts = 0, propchecks = 0, tweenAnim = 0, tweenSnap = 0, derived = 0, noneW = 0, stateW = 0 }
local function diff(seed, what, detail)
	table.insert(diffs, { seed = seed, what = what, detail = detail })
end
local function errId(e)
	return string.match(tostring(e), "Quad%d%d%d%d") or ("<no id> " .. H.first(e))
end

local function cmpFields(seed, where, real, model, fields)
	if tostring(real) ~= M.tostring(model) then
		diff(seed, where .. " tostring", `real={tostring(real)} model={M.tostring(model)}`)
	end
	if real.__quadModifier ~= model.tag then
		diff(seed, where .. " tag", `real={tostring(real.__quadModifier)} model={tostring(model.tag)}`)
	end
	for _, f in fields do
		local r = real:Peek(f)
		local mv = model.f[f]
		local ok
		if mv == nil then ok = r == nil
		elseif mv.k == "lit" then ok = r == mv.v
		elseif mv.k == "tween" then ok = rawequal(r, mv.t)
		elseif mv.k == "none" then ok = r == None
		elseif mv.k == "state" then ok = rawequal(r, mv.s)
		elseif mv.k == "derived" then ok = isState(r) and not rawequal(r, mv.base.s)
		end
		if not ok then
			diff(seed, where .. " Peek " .. f, `real={tostring(r)} model={mv and mv.k or "absent"}`)
		end
	end
end

-- ── generators ──
local sources -- per seed
local function genValueMV(allowFn)
	local r = rnd(if allowFn then 7 else 5)
	if r == 1 then return "lit", fresh() end
	if r == 2 then return "state", pick(sources) end
	if r == 3 then return "tween", q.Tween { Value = fresh(), Time = 1 } end
	if r == 4 then return "none", None end
	if r == 5 then return "lit", fresh() end
	return "fn", ({ { kind = "inc", k = rnd(5) }, { kind = "inc", k = 10 }, { kind = "tonil" }, { kind = "toNone" } })[rnd(4)]
end
local function mvOf(kind, v)
	if kind == "lit" then return { k = "lit", v = v } end
	if kind == "state" then return { k = "state", s = v } end
	if kind == "tween" then return { k = "tween", t = v } end
	if kind == "none" then return { k = "none" } end
end
-- a plain field table (real) + its model twin
local function genTable(fields)
	local real, mf = {}, {}
	for _ = 1, rnd(3) - 1 do
		local f = pick(fields)
		local kind, v = genValueMV(false)
		real[f] = v
		mf[f] = mvOf(kind, v)
	end
	return real, { f = mf }
end

local CASTS = {
	{ "chk", "Frame" }, { "chk", "TextButton" }, { "chk", "GuiObject" }, { "chk", "GuiButton" },
	{ "chk", "TextLabel" }, { "chk", "Instance" }, { "chk", "Nope" },
	{ "As", nil }, { "As", "Frame" }, { "As", "TextButton" }, { "As", "Nope" }, { "As", 5 },
}
local CTORS = { "Frame", "TextButton", "GuiObject", "TextLabel" }

local function runSeed(seed)
	seedState = seed * 7919 + 17
	sources = {}
	for i = 1, 3 do table.insert(sources, q.Source(fresh())) end
	local tweenSrc = q.Source(q.Tween { Value = fresh(), Time = 1 })
	table.insert(sources, tweenSrc)

	-- field set 3..8
	local pool = table.clone(FRAMEF)
	for _, f in TBF do table.insert(pool, f) end
	local nf = 2 + rnd(6)
	local fields = {}
	while #fields < math.min(nf, #pool) do
		local f = table.remove(pool, rnd(#pool))
		table.insert(fields, f)
	end

	-- start
	local real, model
	local s = rnd(4)
	if s == 1 then real, model = q.Modifier(), M.new(true)
	elseif s == 2 then local t, mt = genTable(fields); real, model = q.Modifier(t), M.merge(true, { mt })
	else local c = pick(CTORS); local t, mt = genTable(fields); real, model = D.Modifier[c](t), M.merge(c, { mt }) end

	local history = { { real, model } }
	local nops = 5 + rnd(26) - 1
	for step = 1, nops do
		local op = rnd(10)
		local where = `step{step}`
		local ok, res
		local mres, merr
		if op <= 4 then
			local f = pick(fields)
			local kind, v = genValueMV(true)
			if kind == "fn" then
				ok, res = pcall(function() return real[f](real, realFn(v)) end)
				mres = M.transform(model, f, v, modelApply)
				where ..= ` {f}(fn:{v.kind})`
			elseif rnd(6) == 1 then
				ok, res = pcall(function() return real[f](real, nil) end)
				mres = M.set(model, f, nil)
				where ..= ` {f}(nil)`
			else
				ok, res = pcall(function() return real[f](real, v) end)
				mres = M.set(model, f, mvOf(kind, v))
				where ..= ` {f}({kind})`
			end
		elseif op == 5 then
			-- Overridden with another modifier (both forms, random order)
			local t, mt = genTable(fields)
			local c = rnd(3)
			local other, mother
			if c == 1 then other, mother = q.Modifier(t), M.merge(true, { mt })
			else local cn = pick(CTORS); other, mother = D.Modifier[cn](t), M.merge(cn, { mt }) end
			if rnd(2) == 1 then
				ok, res = pcall(function() return real:Overridden(other) end)
				mres = M.merge(true, { model, mother })
				where ..= " cur:Overridden(o)"
			else
				ok, res = pcall(function() return q.Modifier.Overridden(other, real) end)
				mres = M.merge(true, { mother, model })
				where ..= " Overridden(o,cur)"
			end
		elseif op == 6 then
			-- constructor merge (untyped or typed), random position
			local t, mt = genTable(fields)
			local cn = if rnd(2) == 1 then true else pick(CTORS)
			local ctor = if cn == true then q.Modifier else D.Modifier[cn]
			if rnd(2) == 1 then
				ok, res = pcall(function() return ctor(real, t) end)
				mres = M.merge(cn, { model, mt })
			else
				ok, res = pcall(function() return ctor(t, real) end)
				mres = M.merge(cn, { mt, model })
			end
			where ..= ` ctor<{tostring(cn)}>`
		elseif op <= 8 then
			local c = pick(CASTS)
			if c[1] == "chk" then
				ok, res = pcall(function() return real["As" .. c[2]](real) end)
				mres, merr = M.cast(model, "chk", c[2])
			else
				ok, res = pcall(function() return real:As(c[2]) end)
				mres, merr = M.cast(model, "As", c[2])
			end
			where ..= ` {c[1]}({tostring(c[2])})`
		elseif op == 9 then
			local f = pick(fields)
			local v = fresh()
			ok, res = pcall(function() return real:Apply(function(m) return m[f](m, v) end) end)
			mres = M.set(model, f, { k = "lit", v = v })
			where ..= ` Apply({f})`
		else
			-- re-call typed factory on the current modifier (same ctor object)
			local cn = pick(CTORS)
			local same = rawequal(q.Modifier.TypedFactory(cn), D.Modifier[cn])
			if not same then diff(seed, where .. " factory dedup", cn) end
			ok, res = pcall(function() return q.Modifier.TypedFactory(cn)(real) end)
			mres = M.merge(cn, { model })
			where ..= ` factory({cn})(cur)`
		end
		STATS.ops += 1
		if merr then STATS.experr += 1 end
		if merr then
			if ok then diff(seed, where, `expected {merr}, real ok`)
			elseif errId(res) ~= merr then diff(seed, where, `expected {merr}, real {errId(res)}`) end
		elseif not ok then
			diff(seed, where, `real error {errId(res)}; model ok`)
		else
			real, model = res, mres
			cmpFields(seed, where, real, model, fields)
			table.insert(history, { real, model })
		end
		if VERBOSE then print(seed, where, tostring(real)) end
	end
	-- R1: every intermediate still matches its snapshot (no sibling contamination)
	for i, h in history do cmpFields(seed, `history{i}`, h[1], h[2], fields) end

	-- ── mount ──
	local preT, preM = genTable(fields)
	local postT, postM = genTable(fields)
	local pre, post = q.Modifier(preT), q.Modifier(postT)
	local inline, minline = {}, {}
	for _ = 1, rnd(3) - 1 do
		local f = pick(fields)
		if rnd(3) == 1 then inline[f] = None; minline[f] = { k = "none" } else local v = fresh(); inline[f] = v; minline[f] = { k = "lit", v = v } end
	end
	local arr, marr = {}, {}
	if rnd(2) == 1 then table.insert(arr, pre); table.insert(marr, M.merge(true, { preM })) end
	table.insert(arr, real); table.insert(marr, model)
	if rnd(2) == 1 then table.insert(arr, post); table.insert(marr, M.merge(true, { postM })) end
	local flat = M.flatten(marr, minline)
	local needTB = false
	for f in flat do if TB_ONLY[f] then needTB = true end end
	local function build(cls)
		local p = {}
		for i, m in arr do p[i] = m end
		for k, v in inline do p[k] = v end
		return D[cls](p)
	end
	local classes = { if needTB then "TextButton" else pick({ "Frame", "TextButton" }), if needTB then "TextButton" else pick({ "Frame", "TextButton" }) }
	mock.resetTweenLog()
	local insts = {}
	for i = 1, 2 do
		local ok, inst = pcall(build, classes[i])
		if not ok then
			-- expected only if evaluating a derived/state throws; our specs never throw
			diff(seed, `mount{i}`, `real error {errId(inst)}`)
			return
		end
		insts[i] = inst
		STATS.mounts += 1
	end
	local function tweensFor(inst, f)
		local n, last = 0, nil
		for _, e in mock.tweenLog do if rawequal(e.inst, inst) and e.props[f] ~= nil then n += 1; last = e.props[f] end end
		return n, last
	end
	-- expected property: target raw
	local snapped = {} -- [inst][f] = value the property holds (for tween-fed fields)
	local function check(phase, inst, idx, initial)
		snapped[inst] = snapped[inst] or {}
		for _, f in fields do
			local mv = flat[f]
			local raw = evalRaw(mv)
			local want, isTw
			if raw == None or raw == nil then want = nil
			elseif isTween(raw) then want = raw.Value; isTw = true
			else want = raw end
			local got = inst[f]
			STATS.propchecks += 1
			if mv and mv.k == "derived" then STATS.derived += 1 end
			if mv and (mv.k == "state" or mv.k == "derived") then STATS.stateW += 1 end
			if raw == None then STATS.noneW += 1 end
			local n, last = tweensFor(inst, f)
			if isTw and not initial and snapped[inst][f] ~= nil and snapped[inst][f] ~= want then
				-- R18: later Tween emission animates — property stays, tween created toward want
				STATS.tweenAnim += 1
				if last ~= want then
					diff(seed, `{phase} inst{idx} {f}`, `tween target want={want} lastTween={tostring(last)} n={n} prop={tostring(got)}`)
				end
			else
				if got ~= want then
					diff(seed, `{phase} inst{idx} {f}`, `prop={tostring(got)} want={tostring(want)} mv={mv and mv.k or "absent"}`)
				end
				if isTw and initial and n ~= 0 then
					diff(seed, `{phase} inst{idx} {f}`, `first set should snap, got {n} tweens`)
				end
				if isTw then snapped[inst][f] = want; STATS.tweenSnap += 1 end
			end
		end
	end
	for i, inst in insts do check("mount", inst, i, true) end

	-- phase 2: Set every source, re-check both
	local function setAll()
		for _, src in sources do
			if src == tweenSrc then src:Set(q.Tween { Value = fresh(), Time = 1 })
			elseif rnd(6) == 1 then src:Set(None)
			else src:Set(fresh()) end
		end
	end
	setAll()
	for i, inst in insts do check("set1", inst, i, false) end
	insts[1]:Destroy()
	setAll()
	check("set2", insts[2], 2, false)
	insts[2]:Destroy()
end

local t0 = os.clock()
for seed = START, START + NSEEDS - 1 do
	local ok, e = pcall(runSeed, seed)
	if not ok then diff(seed, "harness", H.first(e)) end
end
local bySig = {}
for k, v in STATS do print("  stat", k, v) end
for _, d in diffs do
	local sig = d.what:gsub("step%d+", "step"):gsub("inst%d", "inst"):gsub("history%d+", "history") .. " :: " .. (d.detail:gsub("%d+", "#"))
	bySig[sig] = bySig[sig] or { n = 0, first = d }
	bySig[sig].n += 1
end
print(`seeds {START}..{START + NSEEDS - 1}  diffs {#diffs}  time {string.format("%.1f", os.clock() - t0)}s`)
for sig, b in bySig do print(`  [{b.n}] {sig}   (first seed {b.first.seed}: {b.first.what} — {b.first.detail})`) end
