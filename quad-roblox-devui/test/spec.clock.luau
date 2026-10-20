--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local Clock = require("../gallery/Clock")

local Heartbeat = H.RunService.Heartbeat :: any
local function beats(): number
	return #Heartbeat.connections
end

H.section("ticker connects Heartbeat only while Active; cleanup on every switch off and on death", function()
	local base = beats()
	local active = q.Source(false)
	local ticks = 0
	local last = 0
	local root = Frame({
		Clock.ticker(0.1, function(elapsed: number)
			ticks += 1
			last = elapsed
		end, active),
	})
	assert(beats() == base, "inactive: no connection")
	H.advance(1)
	assert(ticks == 0)
	active:Set(true)
	assert(beats() == base + 1)
	for _ = 1, 4 do
		H.advance(0.11)
	end
	assert(ticks == 4 and last >= 0.1, `ticks {ticks}`)
	active:Set(false)
	assert(beats() == base, "switched off: disconnected")
	local n = ticks
	H.advance(1)
	assert(ticks == n)
	active:Set(true)
	assert(beats() == base + 1, "reconnects")
	q.dispose(root)
	assert(beats() == base, "death disconnects")
	H.advance(1)
	assert(ticks >= n)
	H.assertNoDebugOutput("clock")
end)

H.section("no Active given: always on, still closed on death", function()
	local base = beats()
	local ticks = 0
	local root = Frame({
		Clock.ticker(0.5, function()
			ticks += 1
		end),
	})
	assert(beats() == base + 1)
	H.advance(0.6)
	H.advance(0.6)
	assert(ticks == 2, `ticks {ticks}`)
	q.dispose(root)
	assert(beats() == base)
	H.assertNoDebugOutput("clock always")
end)

H.done()
