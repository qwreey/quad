--!strict
--[[
	Keyboard / gamepad key delivery for a focusable control — the ONE implementation behind the Slider, the date picker's
	day cells (keyboard keys + ButtonL1/R1; `Pin = "None"`), the color picker's hue slider and SV area.

	    KeyNav.hook(onKey, onEnd?, opts?)      -- array part of the host; the host also needs `Selectable = true`
	      onKey(input: InputObject)            a key press that should act on the control
	      onEnd()                              the selection left the host (the end of a key session — the picker records
	                                           the recent color there, once, instead of once per key press)
	      opts.Pin   "Horizontal" (default) | "All" | "Engage" | "None"
	      opts.HonorProcessed  boolean?         default false: see "processed" below
	      opts.Engaged  Source<boolean>?        ("Engage" only) written true while the control is engaged — lets the control
	                                           draw its "engaged" look (a thicker ring)

	"processed": the kit-wide premise is that the engine marks nav keys `processed` while a control holds selection — and
	those are exactly the keys a slider / the SV area / the date grid is here for, so by default `processed` is NOT consulted
	(every kit control uses the default; device-unverified on real hardware). What IS always honored is typing: while a
	`TextBox` has focus no key is delivered (an Escape / arrow typed into a field must not nudge a value). Since the engine
	would ALSO move the selection geometrically on those same keys, a control that handles the keys itself pins the
	`NextSelection*` it uses to the host (see the pin modes) so the engine has nowhere to go. `HonorProcessed = true` is
	an opt-in for a control that only wants keys the engine left alone (no kit control uses it today).

	While the host holds selection (`SelectionGained` .. `SelectionLost` / `Destroying`) ONE
	`UserInputService.InputBegan` connection (via `Input.service()`) delivers key presses; at rest there is none. It is closed on `SelectionLost`
	and on `Destroying`, so it cannot outlive the element.

	Why the two pin modes (a gamepad trap is the failure to avoid): `NextSelection*` pointing at the host swallows the
	D-pad direction, so the user can no longer walk away along that axis.
	  - "Horizontal" (the hue slider, like Slider): only Left/Right are pinned; Up/Down still move the selection to the
	    neighbouring control. The control must map Left/Right (+ PageUp/PageDown, Home/End) and NOT Up/Down.
	  - "All" (like Slider but on all four directions): every `NextSelection*` is pinned to the host for as long as it
	    exists, so the engine never moves selection geometrically — the control moves `GuiService.SelectedObject` itself from
	    `onKey`. Caveat: the D-pad cannot walk out along any axis, so use it only where something else lets the user leave
	    (a dialog's B); the date grid used it and no longer does (a Docked picker has no B) — device-unverified.
  - "None" (the date grid): nothing is pinned; the engine moves selection geometrically on the D-pad, the control
	    handles the other keys.
	  - "Engage" (the SV area needs all four directions): the area is NOT pinned while merely selected. ButtonA (or
	    Return) ENGAGES it: all four NextSelection* are pinned, the arrows / D-pad now reach `onKey`, and
	    `Overlay.holdDismiss` keeps gamepad B / Escape from dismissing a surrounding dialog. ButtonA, ButtonB, Return or
	    Escape DISENGAGE (unpin; the dismiss hold is released one frame later so the very press that disengaged cannot
	    also close the dialog). Losing selection or being destroyed disengages as well.
]]

local q = require("./Quad")
local Util = require("./Util")
local Overlay = require("./Overlay")

local Input = require("./Input")

export type Options = {
	Pin: ("Horizontal" | "All" | "Engage" | "None")?,
	HonorProcessed: boolean?,
	Engaged: q.Source<boolean>?,
}

local function hook(onKey: (input: InputObject) -> (), onEnd: (() -> ())?, opts: Options?)
	local o: Options = opts or {}
	local engageMode = o.Pin == "Engage"
	local pinMode = o.Pin or "Horizontal"
	local honorProcessed = o.HonorProcessed == true
	local engaged = o.Engaged
	local conn: RBXScriptConnection? = nil
	local release: (() -> ())? = nil
	local isEngaged = false
	local host: GuiObject? = nil

	local function pinAll(on: boolean)
		local h = host
		if h == nil then
			return
		end
		-- (the bundled type definitions declare these properties non-optional; the engine accepts nil = "no override")
		local hx: any = h
		hx.NextSelectionLeft = if on then h else nil
		hx.NextSelectionRight = if on then h else nil
		hx.NextSelectionUp = if on then h else nil
		hx.NextSelectionDown = if on then h else nil
	end
	local function engage()
		if isEngaged then
			return
		end
		isEngaged = true
		pinAll(true)
		release = Overlay.holdDismiss()
		if engaged then
			engaged:Set(true)
		end
	end
	local function disengage(immediate: boolean)
		if not isEngaged then
			return
		end
		isEngaged = false
		pinAll(false)
		local r = release
		release = nil
		if r ~= nil then
			if immediate then
				r()
			else
				task.defer(r)
			end
		end
		if engaged then
			engaged:Set(false)
		end
	end
	local function close()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end
	local function onInput(input: InputObject, processed: boolean)
		-- typing wins; `processed` is only honored on request (see the header)
		if Input.service():GetFocusedTextBox() ~= nil or (honorProcessed and processed) then
			return
		end
		local kc = input.KeyCode
		if engageMode then
			if kc == Enum.KeyCode.ButtonA or kc == Enum.KeyCode.Return then
				if isEngaged then
					disengage(false)
				else
					engage()
				end
				return
			elseif kc == Enum.KeyCode.ButtonB or kc == Enum.KeyCode.Escape then
				disengage(false)
				return
			elseif not isEngaged then
				return
			end
		end
		onKey(input)
	end

	return Util.preHook(function(inst: GuiObject)
		host = inst
		if pinMode == "Horizontal" or pinMode == "All" then
			inst.NextSelectionLeft = inst
			inst.NextSelectionRight = inst
		end
		if pinMode == "All" then
			inst.NextSelectionUp = inst
			inst.NextSelectionDown = inst
		end
		inst.SelectionGained:Connect(function()
			if conn == nil then
				conn = Input.service().InputBegan:Connect(onInput)
			end
		end)
		inst.SelectionLost:Connect(function()
			close()
			disengage(false)
			if onEnd then
				onEnd()
			end
		end)
		inst.Destroying:Connect(function()
			close()
			disengage(true)
			host = nil
		end)
	end)
end

return {
	hook = hook,
}
