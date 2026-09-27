--!nocheck
-- E65 ownership differential fuzzer: q.Bookkeeping.claimOwnerAt / releaseOwner (+ q.dispose's held gate)
-- vs a one-table model. usage (repo root): luau .claude/audit/round13-e65-internal-ds-fuzz/fuzz-owner.luau -a <seeds> <start> [mutant]
-- Rules (Slot/Owner.luau:35-76; docs/reference/extend/02 L222, L327, L340):
--  O1 claim nil element/inst/k -> Quad0157/0158/0159 in that order
--  O2 claim by exactly the same (inst,k) -> false, no change; held by anyone else (same inst other k included) -> Quad0160
--  O3 otherwise records (inst,k) and returns true
--  O4 release nil element/owner -> Quad0161/0162; owner ~= current holder (or none) -> Quad0163; k is NOT compared
--  O5 dispose(held element) -> Quad0179 (nothing destroyed); not held -> destroyed (removed from the pool)
-- mutants: posIgnored (same inst any k re-confirms), releaseChecksNothing (release always succeeds), disposeIgnoresHold
local E = require("./env")
local RNG = require("./rng")
local args = { ... }
local SEEDS, START, MUT = tonumber(args[1]) or 100, tonumber(args[2]) or 1, args[3]
local st = { seeds = 0, ops = 0, diffs = 0, diffSeeds = 0, errs = {} }
local samples = {}
local q = E.newBase()
local BK = q.Bookkeeping
for s = START, START + SEEDS - 1 do
	local rng = RNG.new(s)
	local before = st.diffs
	local insts = {}
	for i = 1, rng:NextInteger(1, 3) do insts[i] = E.mock.Instance.new("Frame") end
	local elems = {}
	for i = 1, rng:NextInteger(1, 4) do elems[i] = E.mock.Instance.new("Frame") end
	local model = {}
	local keys = { 1, 2, 3, "Name" }
	local function pick(t, pnil) if rng:NextNumber() < pnil then return nil end return t[rng:NextInteger(1, #t)] end
	for _ = 1, rng:NextInteger(10, 40) do
		st.ops += 1
		if #elems == 0 then elems[1] = E.mock.Instance.new("Frame") end
		local r = rng:NextNumber()
		local got, exp, gotRet, expRet, what
		if r < 0.5 then
			local e, inst, k = pick(elems, 0.03), pick(insts, 0.03), pick(keys, 0.03)
			what = `claim(e,i,{tostring(k)})`
			local ok, res = pcall(BK.claimOwnerAt, e, inst, k)
			if ok then gotRet = res else got = E.id(res) end
			if e == nil then exp = "Quad0157" elseif inst == nil then exp = "Quad0158" elseif k == nil then exp = "Quad0159"
			else
				local cur = model[e]
				if cur and cur.inst == inst and (cur.k == k or MUT == "posIgnored") then expRet = false
				elseif cur then exp = "Quad0160"
				else model[e] = { inst = inst, k = k }; expRet = true end
			end
		elseif r < 0.85 then
			local e, inst = pick(elems, 0.03), pick(insts, 0.03)
			what = "release"
			local ok, res = pcall(BK.releaseOwner, e, inst)
			if not ok then got = E.id(res) end
			if e == nil then exp = "Quad0161" elseif inst == nil then exp = "Quad0162"
			elseif MUT ~= "releaseChecksNothing" and (model[e] == nil or model[e].inst ~= inst) then exp = "Quad0163"
			else model[e] = nil end
		else
			if #elems == 0 then continue end
			local idx = rng:NextInteger(1, #elems)
			local e = elems[idx]
			what = "dispose"
			local ok, res = pcall(q.dispose, e)
			if not ok then got = E.id(res) end
			if model[e] and MUT ~= "disposeIgnoresHold" then exp = "Quad0179" else table.remove(elems, idx); model[e] = nil end
		end
		if got then st.errs[got] = (st.errs[got] or 0) + 1 end
		if got ~= exp or gotRet ~= expRet then
			st.diffs += 1
			if #samples < 8 then table.insert(samples, `seed {s}: {what} got {tostring(got)}/{tostring(gotRet)} expected {tostring(exp)}/{tostring(expRet)}`) end
		end
	end
	if st.diffs > before then st.diffSeeds += 1 end
	st.seeds += 1
	-- leave nothing held for the next seed's dispose gate: release every recorded seat
	for e, rec in model do pcall(BK.releaseOwner, e, rec.inst) end
end
local es = {}
for k, v in st.errs do table.insert(es, `{k}={v}`) end
table.sort(es)
print(`owner mutant={MUT or "-"} seeds={st.seeds} ops={st.ops} diffSeeds={st.diffSeeds} diffs={st.diffs}`)
print("errors: " .. table.concat(es, " "))
for _, x in samples do print("  " .. x) end
