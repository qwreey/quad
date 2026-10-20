--!strict
--[[
	Loop: a per-frame driver that exists ONLY while its owner is alive and wanted (internal to Progress).

	    local hook, effect = Loop.new(visible, function(t: number, dt: number) ... end)
	    q.Elem "Frame" { hook, effect, ... }        -- both go in the host's array part

	`step(t, dt)` runs on every `RunService.Heartbeat` with the seconds since the loop (re)started connecting and the
	frame delta — and at no other time:
	  - NOT before the host exists: an Effect runs once at construction, BEFORE its host is created, so that first run
	    must connect nothing — `hook` (a PostRef) flips `mounted` once the host's subtree and properties are set and
	    the Effect re-runs then;
	  - NOT while `active` is false (an invisible indicator costs nothing): the Effect re-runs when `active` flips
	    and its cleanup disconnects;
	  - NOT while the host is outside the GUI tree: it must hang under a LayerCollector (ScreenGui / BillboardGui /
	    SurfaceGui / DockWidgetPluginGui / QWidgetPluginGui; the DataModel is NOT a live root — GuiObjects are not
	    rendered directly under it) — a progress bar that was built but never mounted, or removed from its ScreenGui (parent chain cut,
	    `Parent = nil` for caching), drives no Heartbeat. A whole ScreenGui parked with `Parent = nil` is NOT detected
	    (its own descendants still see a LayerCollector ancestor). `AncestryChanged` re-evaluates it.
	    Caveat: an ancestor's `Visible = false` / `Enabled = false` is NOT tracked (no event covers "some ancestor
	    stopped rendering"); only the host's own `active` (its `Visible`) gates. A hidden ancestor still costs the loop;
	    drive `Visible` on the progress bar itself when its container hides;
	  - NOT after the host dies: the Effect is bound to the host (array part), its cleanup runs on destroy.
	One Heartbeat connection per live loop; `step` is the caller's own closure, so the loop allocates nothing per frame.
]]

local q = require("../Quad")
local Util = require("../Util")

local RunService = game:GetService("RunService")

local LiveRoots = { ScreenGui = true, BillboardGui = true, SurfaceGui = true, DockWidgetPluginGui = true, QWidgetPluginGui = true }

-- some ancestor is a LayerCollector: the host hangs in a GUI tree
local function isLive(inst: GuiObject): boolean
	local p: Instance? = inst.Parent
	while p ~= nil do
		if LiveRoots[p.ClassName] == true then
			return true
		end
		p = p.Parent
	end
	return false
end

local function new(active: q.State<boolean>, step: (t: number, dt: number) -> ())
	local mounted = q.Source(false)
	local hook = Util.postHook(function(inst: GuiObject)
		mounted:SetIfChanged(isLive(inst))
		inst.AncestryChanged:Connect(function()
			mounted:SetIfChanged(isLive(inst))
		end)
	end)
	local effect = q.Effect(function()
		if not (mounted:Get() and active:Get()) then
			return nil :: any
		end
		local t = 0
		local conn = RunService.Heartbeat:Connect(function(dt: number)
			t += dt
			step(t, dt)
		end)
		return function()
			conn:Disconnect()
		end
	end, mounted, active)
	return hook, effect
end

return {
	new = new,
}
