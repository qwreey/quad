--!nocheck
-- E40 probe: a gate behind a gate (S → G1(b1) → G2(b2)) re-announces an epoch it already flushed,
-- when its value map was left behind (rule 1 of state-epoch-plan §4 fires in GateImpl._receive).
local Quad = require("../../../quad-base/src")
local function mk()
	local q = Quad.New()
	q.Backend.isHeld = function() return false end
	q.Backend.isHeldBy = function() return false end
	return q
end
for _, reads in { false, true } do
	local q = mk()
	local S = q.Source(0)
	local b1, b2 = q.Blocker(), q.Blocker()
	local G1 = S:Apply(b1)
	local G2 = G1:Apply(b2)
	local fires, froms = 0, {}
	G2:Observer(function(t, _, from)
		fires += 1
		if reads then t:Get() end
		if from ~= nil then
			local ks = {}
			for e in from do ks[#ks + 1] = (e == S) and "S" or "?" end
			froms[#froms + 1] = table.concat(ks, ",")
		end
	end):Subscribe()
	local d = G2:Compute(function(s) return s:Get() end)
	local dfires = 0
	d:Observer(function() dfires += 1 end):Subscribe()
	fires, dfires = 0, 0
	b2:On()
	S:Set(1) -- G1 open → flush {S} → G2 withholds (value map S@r1)
	b1:On()
	S:Set(2) -- G1 withholds; G2 hears nothing
	b2:Off() -- G2 flushes {S}, emit map synced to the LIVE revision (r2)
	local afterB2 = fires
	b1:Off() -- G1 flushes {S} → G2: value map S@r1 ≠ r2 → rule 1 → accept → open → flush again
	print(`observer reads value in callback={reads}: G2 observer fired {afterB2} at b2:Off, {fires} total after b1:Off (froms {table.concat(froms, " | ")}); downstream Compute observer fired {dfires}; G2:Get()={G2:Get()}`)
end
