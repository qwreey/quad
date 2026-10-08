--!strict
--[[
	DrawerState: the state of a navigation drawer — Compose material3 `DrawerState` / `rememberDrawerState` (androidx/androidx
	@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/NavigationDrawer.kt 113-313).

	    local drawer = Material.DrawerState({ InitialValue = "Closed" })
	    drawer.Open() / drawer.Close()          -- animate (no veto — Compose's open() / close() do not ask confirmStateChange)
	    drawer.SnapTo("Open")                   -- jump
	    drawer.IsOpen:Get()                     -- CurrentValue == "Open" (Compose isOpen: the SETTLED value)
	    drawer.CurrentValue / drawer.TargetValue   State<"Closed" | "Open">

	Options (all optional, `read`)
	  InitialValue        ("Closed" | "Open")?        default "Closed" (rememberDrawerState has no default; the samples use Closed)
	  ConfirmStateChange  ((DrawerValue) -> boolean)?  veto for a released drag and the scrim tap (Compose confirmStateChange)
	Fields: CurrentValue, TargetValue, IsOpen (State); Open, Close, SnapTo (closures, no self).
	One drawer drives a state (the one built last takes it over); the drawer component owns the anchors and the motion
	(NavigationDrawer/Drawer.luau).
]]

local q = require("../Quad")
local Anchored = require("../Sheet/Anchored")

export type DrawerValue = "Closed" | "Open"

export type Options = {
	read InitialValue: DrawerValue?,
	read ConfirmStateChange: ((value: DrawerValue) -> boolean)?,
}

export type DrawerState = {
	read CurrentValue: q.State<DrawerValue>,
	read TargetValue: q.State<DrawerValue>,
	read IsOpen: q.State<boolean>,
	read Open: () -> (),
	read Close: () -> (),
	read SnapTo: (value: DrawerValue) -> (),
}

local function DrawerState(o: Options?): DrawerState
	local opts: Options = o or {}
	local initial: DrawerValue = opts.InitialValue or "Closed"
	if initial ~= "Closed" and initial ~= "Open" then
		error(`DrawerState: InitialValue must be "Closed" or "Open" (got {tostring(initial)})`, 2)
	end
	local confirm = opts.ConfirmStateChange
	local rec = Anchored.new(initial, { Closed = true, Open = true }, if confirm then function(v: string): boolean
		return confirm(v :: DrawerValue)
	end else nil)
	local isOpen: q.State<boolean> = rec.Current:Compute(function(self)
		return self:Get() == "Open"
	end)
	local state: DrawerState = {
		CurrentValue = rec.Current :: any,
		TargetValue = rec.Target :: any,
		IsOpen = isOpen,
		Open = function()
			Anchored.go(rec, "Open", "Show")
		end,
		Close = function()
			Anchored.go(rec, "Closed", "Hide")
		end,
		SnapTo = function(value: DrawerValue)
			if value ~= "Closed" and value ~= "Open" then
				error(`DrawerState.SnapTo: "Closed" or "Open" (got {tostring(value)})`, 2)
			end
			Anchored.snap(rec, value)
		end,
	}
	Anchored.bind(state, rec)
	return state
end

return { DrawerState = DrawerState }
