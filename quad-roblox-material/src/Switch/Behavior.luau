--!strict
--[[
	Switch behaviour shared by the M3 look (`./init.luau`) and the M2 look (`../M2/Switch.luau`): the on/off model
	(`Value` two-way or `Checked` controlled), the tap toggle and the HANDLE DRAG. A look places `DragHook` on its host,
	wires `Activated = s.Activated`, and draws the handle at `DragFrac` while it is non-nil. The only look input is
	`Look.Travel`, the px the handle center moves between the off and the on end.

	    local s = Behavior.new(props, { Name = "Switch", Travel = 20 })
	    D.TextButton { s.DragHook, Activated = s.Activated, Interactable = s.Interactable, ... }
	    -- s.On (what to show), s.DragFrac (nil, or 0 = off end .. 1 = on end while dragged), s.Dragging

	Props (the public props of both looks; all `read`):
	  Value     Source<boolean>?           two-way (a toggle writes it); nil = own state
	  Checked   State<boolean>?            controlled alternative: displayed only, a toggle calls `OnChange(new)` and writes
	                                       nothing. `Value` and `Checked` together is an error.
	  IconOn, IconOff   string?            (read by the looks)
	  Disabled  boolean | State<boolean>?  no tap, no drag
	  OnChange  ((value: boolean) -> ())?  after a USER toggle (tap or drag) that changed the value
	  Theme, Modifier, Hooks               (read by the looks)

	DRAG vs TAP (one press, never both):
	  * A press (mouse button 1 / touch) on the host starts a drag session (`Interaction.drag`: three UserInputService
	    connections only while the press lasts). Until the pointer has moved SLOP = 4 px horizontally it is still a TAP:
	    the handle does not move and the release is the engine's `Activated`, which toggles as before (gamepad ButtonA /
	    keyboard activation are taps too — they never start a drag).
	  * Past 4 px it is a DRAG: the handle follows the pointer (`DragFrac`, clamped to the two ends) with no tween. The
	    drag's ORIGIN is the pointer at the moment it crosses the slop, not the press point: measured from the press point
	    the handle jumped by the slop on the first drag frame (Studio QA 2026-10-08, "툭 튐") — re-based there, it starts
	    from where it rests (displacement 0) and then moves 1:1 with the pointer. On
	    release the switch takes the far state only if the handle passed the HALF (off -> on needs frac > 0.5, on -> off
	    needs frac < 0.5; exactly half stays), otherwise it springs back; the handle then animates from the pointer to its
	    end. A cancelled drag (window focus lost, host destroyed) springs back without a change.
	  * The conflict: releasing a drag over the host ALSO fires the engine's `Activated` (it is a click on a TextButton),
	    and whether it comes before or after the UserInputService release is not something this kit can rely on. So
	    `Activated` is ignored when the press it ends has moved past the slop — while the drag is still running
	    (Activated first) or within SUPPRESS = 0.1 s after it ended (release first). A later keyboard / gamepad
	    activation is past that window and toggles normally. Without this guard a drag released past the half would
	    toggle twice (land back where it started).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Interaction = require("../Interaction")

export type Props = {
	read Value: q.Source<boolean>?,
	read Checked: q.State<boolean>?,
	read IconOn: string?,
	read IconOff: string?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: boolean) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

export type Look = {
	Name: string, -- for error messages
	Travel: number, -- px between the off and the on handle center
}

export type Switch = {
	read On: q.State<boolean>,
	read Disabled: q.State<boolean>,
	read Interactable: q.State<boolean>,
	read DragFrac: q.State<number?>,
	read Dragging: q.State<boolean>,
	read Activated: (input: InputObject, clickCount: number) -> (), -- the engine `Activated` signature
	read DragHook: Interaction.Hook,
}

local SLOP = 4
local SUPPRESS = 0.1

local function new(props: Props, look: Look): Switch
	if props.Value ~= nil and props.Checked ~= nil then
		error(look.Name .. ": pass `Value` (two-way Source) or `Checked` (controlled State), not both", 3)
	end
	local own: q.Source<boolean>? = props.Value or (if props.Checked == nil then q.Source(false) else nil)
	local on: q.State<boolean> = props.Checked or own :: q.Source<boolean>
	local disabled = Util.asState(props.Disabled)
	local travel = look.Travel

	local function write(v: boolean)
		if own ~= nil then
			own:Set(v)
		end
		if props.OnChange then
			props.OnChange(v)
		end
	end

	local dragFrac = q.Source(nil :: number?)
	local startX, startOn, moved = 0, false, false
	local suppressUntil = -math.huge
	local function fracAt(x: number): number
		return math.clamp((if startOn then 1 else 0) + (x - startX) / travel, 0, 1)
	end
	local drag = Interaction.drag({
		Disabled = disabled,
		OnBegan = function(x: number)
			startX, startOn, moved = x, on:Get(), false
		end,
		OnMoved = function(x: number)
			if not moved then
				if math.abs(x - startX) < SLOP then
					return
				end
				-- crossing the slop: re-base the origin here so the handle starts from its rest position (header DRAG vs TAP)
				startX = x
				moved = true
			end
			dragFrac:Set(fracAt(x))
		end,
		OnEnded = function(x: number, _y: number, cancelled: boolean)
			if not moved then
				return
			end
			suppressUntil = os.clock() + SUPPRESS
			local target = startOn
			if not cancelled then
				local f = fracAt(x)
				target = if startOn then f >= 0.5 else f > 0.5
			end
			-- write first (the handle still shows the pointer), then hand the handle back to the animated end position
			if target ~= on:Get() then
				write(target)
			end
			dragFrac:Set(nil)
		end,
	})

	local dragging: q.State<boolean> = dragFrac:Compute(function(self)
		return self:Get() ~= nil
	end)

	return {
		On = on,
		Disabled = disabled,
		Interactable = Util.interactable(disabled),
		DragFrac = dragFrac,
		Dragging = dragging,
		Activated = function(_input: InputObject, _clickCount: number)
			if disabled:Get() then
				return
			end
			-- the release of a moved drag (see the header): the drag decides, not the click
			if moved and (drag.Dragging:Get() or os.clock() <= suppressUntil) then
				return
			end
			write(not on:Get())
		end,
		DragHook = drag.Hook,
	}
end

return {
	new = new,
	SLOP = SLOP,
	SUPPRESS = SUPPRESS,
}
