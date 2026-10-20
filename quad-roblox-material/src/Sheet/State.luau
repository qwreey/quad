--!strict
--[[
	SheetState: the state of a sheet — Compose material3 `SheetState` / `rememberBottomSheetState` (androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SheetDefaults.kt 88-507, 683-692). The
	bottom sheets (`BottomSheetScaffold`, `ModalBottomSheet`) and the side sheets (`SideSheet`, `ModalSideSheet` — MDC
	SideSheetBehavior's STATE_EXPANDED / STATE_HIDDEN are the same two values) take one.

	    local sheet = Material.SheetState({ InitialValue = "Hidden" })               -- Hidden / PartiallyExpanded / Expanded
	    local side = Material.SheetState({ InitialValue = "Expanded", EnabledValues = { "Hidden", "Expanded" } })
	    sheet.Show()                    -- PartiallyExpanded when the shown sheet has that anchor, else Expanded
	    sheet.Expand() / sheet.PartialExpand() / sheet.Hide()
	    sheet.CurrentValue:Get()        -- the SETTLED value (changes when the motion ends)
	    sheet.TargetValue:Get()         -- where a motion or a released drag is heading (= CurrentValue at rest)

	Options (all optional, `read`)
	  InitialValue        SheetValue?              default "Hidden" (rememberBottomSheetState has no default; Hidden is the
	                                               SheetState constructor's)
	  EnabledValues       { SheetValue }?          the values the sheet can settle in, default all three (Compose default
	                                               setOf(Hidden, PartiallyExpanded, Expanded)); must contain "Expanded" and
	                                               the initial value (Compose `require`s both, 184-189)
	  ConfirmValueChange  ((SheetValue) -> boolean)?  veto: Expand / PartialExpand / Show / Hide and a released drag ask it
	                                               first; false = nothing happens (a drag settles back)
	Fields: CurrentValue, TargetValue (State<SheetValue>); Expand, PartialExpand, Show, Hide (closures, no self).
	PartialExpand errors when "PartiallyExpanded" is not enabled and Hide when "Hidden" is not (Compose `check`s, 269-304).
	Motion kinds (Compose 253-304): Expand and Show use the show motion, PartialExpand and Hide the hide motion; the motion
	itself belongs to the component that shows the state (BottomSheet/Sheet.luau). One component drives a state: the one built
	last takes it over (a rebuilt sheet, a modal sheet reopened with the same state).
]]

local q = require("../Quad")
local Anchored = require("./Anchored")
local Util = require("../Util")

export type SheetValue = "Hidden" | "PartiallyExpanded" | "Expanded"

export type Options = {
	read InitialValue: SheetValue?,
	read EnabledValues: { SheetValue }?,
	read ConfirmValueChange: ((value: SheetValue) -> boolean)?,
}

export type SheetState = {
	read CurrentValue: q.State<SheetValue>,
	read TargetValue: q.State<SheetValue>,
	read Expand: () -> (),
	read PartialExpand: () -> (),
	read Show: () -> (),
	read Hide: () -> (),
}

local VALID: { [string]: boolean } = { Hidden = true, PartiallyExpanded = true, Expanded = true }

local function SheetState(o: Options?): SheetState
	local opts: Options = o or {}
	local initial: SheetValue = opts.InitialValue or "Hidden"
	local enabled: { [string]: boolean } = {}
	for _, v in opts.EnabledValues or { "Hidden", "PartiallyExpanded", "Expanded" } :: { SheetValue } do
		if not VALID[v] then
			Util.fail("SheetState", `unknown value "{tostring(v)}" (Hidden | PartiallyExpanded | Expanded)`)
		end
		enabled[v] = true
	end
	if not enabled.Expanded then
		Util.fail("SheetState", "Expanded must be one of the enabled values")
	end
	if not enabled[initial] then
		Util.fail("SheetState", `the initial value "{initial}" must be one of the enabled values`)
	end
	local confirm = opts.ConfirmValueChange
	local rec = Anchored.new(initial, enabled, if confirm then function(v: string): boolean
		return confirm(v :: SheetValue)
	end else nil)

	local function request(value: SheetValue, kind: Anchored.Kind)
		if Anchored.confirm(rec, value) then
			Anchored.go(rec, value, kind)
		end
	end

	local state: SheetState = {
		CurrentValue = rec.Current :: any,
		TargetValue = rec.Target :: any,
		Expand = function()
			request("Expanded", "Show")
		end,
		PartialExpand = function()
			if not enabled.PartiallyExpanded then
				Util.fail("SheetState.PartialExpand", "PartiallyExpanded is not one of the enabled values")
			end
			request("PartiallyExpanded", "Hide")
		end,
		Show = function()
			local d = rec.Driver
			local partial = if d ~= nil then d.HasAnchor("PartiallyExpanded") else enabled.PartiallyExpanded == true
			request(if partial then "PartiallyExpanded" else "Expanded", "Show")
		end,
		Hide = function()
			if not enabled.Hidden then
				Util.fail("SheetState.Hide", "Hidden is not one of the enabled values")
			end
			request("Hidden", "Hide")
		end,
	}
	Anchored.bind(state, rec)
	Util.tagSurface(state) -- `PartialExpand` / `Hide` & co. are public surface (a usage error blames the caller)
	return state
end

return {
	SheetState = SheetState,
}
