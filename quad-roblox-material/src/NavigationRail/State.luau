--!strict
--[[
	WideNavigationRailState: collapsed / expanded state of a navigation rail — Compose material3 `WideNavigationRailState` /
	`rememberWideNavigationRailState` (androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/
	compose/material3/WideNavigationRailState.kt 37-164).

	    local rail = Material.WideNavigationRailState({ InitialValue = "Collapsed" })
	    rail.Expand() / rail.Collapse() / rail.Toggle()     -- animate (Compose expand / collapse / toggle)
	    rail.SnapTo("Expanded")                              -- jump (Compose snapTo)
	    rail.TargetValue / rail.CurrentValue                 State<"Collapsed" | "Expanded">

	Options (`read`, optional): InitialValue ("Collapsed" | "Expanded")?, default "Collapsed" (Compose's default).
	`TargetValue` changes at once; `CurrentValue` is the SETTLED value (Compose: the value of the animation once it reaches an
	end) — the rail that shows the state reports it when its motion ends; with no rail it settles at once. Toggle goes to the
	opposite of the TARGET value (Compose toggle). Fields are closures without self (the kit's state-object convention).
	Not here: `ModalWideNavigationRail` (its own anchored-draggable state).
]]

local q = require("../Quad")

export type Value = "Collapsed" | "Expanded"

export type Options = {
	read InitialValue: Value?,
}

export type WideNavigationRailState = {
	read TargetValue: q.State<Value>,
	read CurrentValue: q.State<Value>,
	read Expand: () -> (),
	read Collapse: () -> (),
	read Toggle: () -> (),
	read SnapTo: (value: Value) -> (),
}

-- internal: what the rail reads to drive itself
export type Internal = {
	Target: q.Source<Value>,
	Current: q.Source<Value>,
	Snap: q.Source<number>,
	Driven: boolean,
}

local records: { [any]: Internal } = setmetatable({}, { __mode = "k" }) :: any

local function check(value: any, who: string)
	if value ~= "Collapsed" and value ~= "Expanded" then
		error(`{who}: "Collapsed" or "Expanded" (got {tostring(value)})`, 3)
	end
end

local function WideNavigationRailState(o: Options?): WideNavigationRailState
	local opts: Options = o or {}
	local initial: Value = opts.InitialValue or "Collapsed"
	check(initial, "WideNavigationRailState: InitialValue must be")
	local rec: Internal = {
		Target = q.Source<<Value>>(initial),
		Current = q.Source<<Value>>(initial),
		Snap = q.Source(0),
		Driven = false,
	}
	local function go(value: Value)
		rec.Target:SetIfChanged(value)
		if not rec.Driven then
			rec.Current:SetIfChanged(value)
		end
	end
	local state: WideNavigationRailState = {
		TargetValue = rec.Target,
		CurrentValue = rec.Current,
		Expand = function()
			go("Expanded")
		end,
		Collapse = function()
			go("Collapsed")
		end,
		Toggle = function()
			go(if rec.Target:Get() == "Expanded" then "Collapsed" else "Expanded")
		end,
		SnapTo = function(value: Value)
			check(value, "WideNavigationRailState.SnapTo:")
			rec.Target:SetIfChanged(value)
			rec.Snap:Set(rec.Snap:Get() + 1)
			rec.Current:SetIfChanged(value)
		end,
	}
	records[state] = rec
	return state
end

local function recOf(state: WideNavigationRailState): Internal
	local rec = records[state]
	if rec == nil then
		error("WideNavigationRail: State must come from Material.WideNavigationRailState", 3)
	end
	return rec
end

return {
	WideNavigationRailState = WideNavigationRailState,
	recOf = recOf,
}
