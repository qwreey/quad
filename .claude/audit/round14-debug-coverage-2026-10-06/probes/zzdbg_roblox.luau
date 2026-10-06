--!nocheck
-- round14 debug coverage probe (scratch, deleted after run): H-877 (Q166) corpse callbacks.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Position", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local function newQ(dbg)
	local q = Quad.New():UseProvider(QuadRoblox)
	;(getfenv(installProperty)).game = gameShim
	;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
	;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
	;(getfenv(installEvent)).game = gameShim
	;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance
	q.debug = dbg
	return q
end
local function short(e)
	local s = tostring(e)
	s = string.gsub(s, "\n.*", "")
	return string.sub(s, 1, 220)
end

for _, dbg in { false, true } do
	local q = newQ(dbg)
	print(`--- [R1 process Tween on a destroyed Instance] debug={dbg}`)
	local fired = {}
	local g = q.Declaration.Frame({ Name = "G", Size = 0 })
	g:Destroy()
	local ok, err = pcall(function()
		q.Dispatch.process(g, "Size", q.Tween({ Value = 5, Time = 0.3, Started = function() table.insert(fired, "S") end, Completed = function() table.insert(fired, "C") end, Cancelled = function() table.insert(fired, "X") end }), 1)
	end)
	print(`  process ok={ok} {if ok then "" else short(err)} fired=[{table.concat(fired, ",")}] Size={g.Size}`)
	local ok2, err2 = pcall(function()
		q.Dispatch.process(g, "Size", q.Tween({ Value = 6, Time = 0, Started = function() table.insert(fired, "S0") end, Completed = function() table.insert(fired, "C0") end }), 1)
	end)
	print(`  snap process ok={ok2} {if ok2 then "" else short(err2)} fired=[{table.concat(fired, ",")}] Size={g.Size}`)

	print(`--- [R2 drive plain props on a destroyed Instance] debug={dbg}`)
	local h = q.Declaration.Frame({ Name = "H" })
	h:Destroy()
	local ok3, err3 = pcall(function() q.Dispatch.drive(h, { Size = 3, Name = "after" }) end)
	print(`  drive ok={ok3} {if ok3 then "" else short(err3)} Size={h.Size} Name={h.Name}`)
	print(`--- [R3 State-bound Tween on an Instance destroyed outside quad, then Set] debug={dbg}`)
	local src = q.Source(1)
	local fired2 = {}
	local k = q.Declaration.Frame({ Size = src:Compute(function(x) return q.Tween({ Value = x:Get(), Time = 0.3, Started = function() table.insert(fired2, "S" .. x:Get()) end }) end) })
	src:Set(2)
	k:Destroy()
	local ok4, err4 = pcall(function() src:Set(3) end)
	print(`  Set after Destroy ok={ok4} {if ok4 then "" else short(err4)} fired=[{table.concat(fired2, ",")}]`)
end
