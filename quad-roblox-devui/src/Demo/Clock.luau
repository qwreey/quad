--!strict
--[[
	Clock — a Heartbeat tick that lives while the element it is placed on is alive AND its `Active` State is true.

		Clock.ticker(period, fn, active?)   -> Frame      -- a hidden 0-size Frame; put it among the children of a section
			fn(elapsed)  runs at most once per `period` seconds, with the time accumulated since its last run
			active       State<boolean>?   the Heartbeat connection exists only while it is true (default: always)

	An `Effect` on `active` owns the connection: it connects when `active` is true and its cleanup disconnects — on every
	switch to false, and (cleanup runs with `dying`) when the host Frame is destroyed. So a hidden window / collapsed tool
	costs no Heartbeat connection at all, and a disposed demo leaves none behind. The accumulated time restarts from zero
	each time the ticker (re)activates. Between ticks the connection only adds `dt` to a number (no table, no closure, no
	instance is created per frame); `fn` does whatever allocation it needs once per period.
	A hidden Frame is the host because the Effect rides in the array part of an element.
]]

local q = require("../Quad")
local D = q.Declaration

local RunService = game:GetService("RunService")

local Clock = {}

local ALWAYS: q.State<boolean> = q.Source(true)
local function noCleanup(_dying: boolean) end

function Clock.ticker(period: number, fn: (elapsed: number) -> (), active: q.State<boolean>?): Frame
	local gate = active or ALWAYS
	local acc = 0
	return D.Frame({
		Name = "Ticker",
		Visible = false,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		q.Effect(function()
			if not gate:Get() then
				return noCleanup
			end
			acc = 0
			local conn = RunService.Heartbeat:Connect(function(dt: number)
				acc += dt
				if acc >= period then
					local elapsed = acc
					acc = 0
					fn(elapsed)
				end
			end)
			return function(_dying: boolean)
				conn:Disconnect()
			end
		end, gate),
	})
end

return Clock
