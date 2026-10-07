--!strict
--[[
	Pressed ripple, clipped to a ROUNDED host — with a handful of instances, not hundreds.

	DESIGN (measured counts in test/spec.ripple.luau):
	  - `ClipsDescendants` clips to the host RECTANGLE, never to a `UICorner`, so a circle that grows past a
	    pill-shaped button would poke out of the rounded corners. The old kits (RoStrap `Rippler`, qwreey
	    MaterialUI `Round`) solve that by stacking dozens of 1px-high clip frames along the corner curve (and
	    cloning the ripple into every one on each press: 38 / 57 extra instances per press).
	  - Here each press makes ONE `CanvasGroup` (it clips its descendants to its own `UICorner` — exact
	    rounding, any radius) holding ONE circle `Frame` (round via `UICorner`, no image asset). That is
	    4 instances per press (CanvasGroup, its UICorner, circle, its UICorner), 0 at rest.
	  - BOUNDED: the circle never reaches outside the host rectangle. `AutomaticSize` measures ALL descendants,
	    clipped ones included (an engine behavior, DevForum "AutomaticSize does not consider ClipDescendants"), so the
	    first version's circle — grown to the farthest corner, i.e. past the host's edges — made every auto-sized
	    ancestor grow while a press lasted: an auto-width Button / Chip widened, a RadioGroup row or a story holder grew
	    taller and its centered children jumped, a dialog's actions row pushed the card (Studio QA 2026-10-07, 2nd).
	    Now each frame of the expand writes the circle as the circle's bounding box CLAMPED to the host (around the press
	    point snapped to a whole pixel, so an uncut box is square), with ONE UICorner radius imitating "circle cut by
	    the host edges": per box corner the inset where the circle's arc meets the box edges (`cutCorner`), the largest
	    of the four — the circle radius while it fits, small once both opposite edges cut it (a 32 px chip pressed in
	    the middle shows a circle sliced by the chip), 0 once the farthest host corner is covered (the group's corner
	    then gives the exact host shape). Until 2026-10-07 (3rd Studio QA, "the ripple starts as a slight oval") the
	    radius was the clipped box's half-side: on a 32 px chip the circle reaches both edges in ~2 frames (Quart Out
	    covers 30 % of the radius in the first 8 % of the 0.45 s), so nearly the whole grow showed as a PILL.
	    Deviation: UICorner has one radius for all four corners, so a circle cut by ONE edge (pressed near the top of a
	    tall host) keeps rounded corners on the cut side too (the uncut side wins — it stays circle-like), and the cut
	    sides of a big circle show as straight sides with rounded corners instead of shallow arcs — only during the
	    0.45 s grow.
	  - TRADE-OFF: a `CanvasGroup` renders its subtree into an offscreen texture of the host's size, so a
	    group costs texture memory + a composite pass while it exists. They are created lazily on press and
	    destroyed ~0.2-0.6 s later (and at most `Max` exist at once — the oldest is dropped), never kept at
	    rest. For a very large host (full-screen list row hundreds of px wide) the texture is large but
	    still transient. If you do not want rounded clipping at all, pass `Corner = UDim.new(0, 0)`: the
	    group is then a plain rectangle clip.

	Ripple.new(opts) -> Ripple
	  opts.Color     Color3 | State<Color3>   ripple color (the component's "on" color)
	  opts.Opacity   number                   ripple opacity (default 0.10, the M3 pressed state layer)
	  opts.Corner    UDim                     the HOST's corner radius (default UDim.new(0, 0))
	  opts.Max       number                   most ripples alive at once, fading ones included (default 3)
	Place BOTH array-part values in the host Frame/GuiObject whose geometry is the ripple area:
	  ripple.Hook    captures the host instance (OnCreated)
	  ripple.Slot    the ripples mount here (a managed Slot — nothing you need to touch)
	Drive it:
	  ripple:Press(position)   start a ripple at `position` (a Vector2 in the same space as the host's
	                           `AbsolutePosition`; nil = host center — gamepad/keyboard presses; a position
	                           outside the host's rectangle also starts at the center — a press on a label
	                           attached to the control)
	  ripple:Release()         fade every held ripple (and drop it when the fade completes)
	  ripple:Count() -> number ripples currently mounted (held or fading) — for specs/diagnostics
	`Interactive.luau` wires this to `Interaction` so a component never calls these by hand.

	Geometry: the "host" Ripple measures is the frame that carries `ripple.Hook` — in Interactive that is the state
	layer, a full-size DIRECT child of the real host with no UIPadding in between, so its AbsolutePosition /
	AbsoluteSize equal the button's (test/spec.button.luau checks the press point end to end).
	Timing: expand 0.45 s (Motion Long1, Standard easing = Quart Out, evaluated by hand) driven by ONE Heartbeat
	connection per growing ripple (the clamped shape above is three properties computed per frame, which tweens
	cannot express), disconnected when the expand ends, the ripple is dropped or the host dies; fade 0.2 s (Short4,
	linear) starting at release, an engine tween. The group is removed by a one-shot `task.delay` (fade time + 50 ms),
	cancelled if the host dies first.
	Pointer-space note: `position` is used as-is against `AbsolutePosition`. If a device shows the ripple
	offset by the top-bar inset (ScreenGui with `IgnoreGuiInset = false`), set `Ripple.Config.PointerInset`
	(module-level Vector2, default (0, 0)) — not measurable without a device.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local D = q.Declaration

local Motion = Tokens.Motion
local RunService = game:GetService("RunService")
local EXPAND_TIME = Motion.Duration.Long1

export type ColorInput = Color3 | q.State<Color3>

export type Options = {
	Color: ColorInput,
	Opacity: number?,
	Corner: UDim?,
	Max: number?,
}

local Util = require("./Util")

local _hookProto = Util.preHook(function() end)

export type Ripple = {
	read Hook: typeof(_hookProto),
	read Slot: q.Slot<Instance>,
	Press: (self: Ripple, position: Vector2?) -> (),
	Release: (self: Ripple) -> (),
	Count: (self: Ripple) -> number,
}

type Live = { group: Instance, held: boolean, fade: () -> (), timer: thread?, conn: RBXScriptConnection? }

local Module = {
	-- Subtracted from press positions before they are compared with AbsolutePosition (see header).
	PointerInset = Vector2.new(0, 0),
}

-- The corner radius that imitates ONE corner of "a circle of radius r cut by the box edges", for the box corner at
-- (hx, hy) from the circle's center: where the box's horizontal edge meets the circle, the arc starts
-- hx - sqrt(r^2 - hy^2) in from the corner, and along the vertical edge hy - sqrt(r^2 - hx^2) — a rounded corner of
-- radius c is c in along both, so c = the smaller inset. Uncut (hx = hy >= r): r, the circle itself. Cut by one edge
-- (hy < r): the inset where the cut chord ends — small once the circle is much bigger than the cut, so a ripple on a
-- 32 px chip reads as a circle sliced by the chip, not as a pill. A corner the circle covers (hx^2 + hy^2 <= r^2): 0.
local function cutCorner(hx: number, hy: number, r: number): number
	local rr = r * r
	local alongX = hx - math.sqrt(math.max(0, rr - hy * hy))
	local alongY = hy - math.sqrt(math.max(0, rr - hx * hx))
	return math.max(0, math.min(alongX, alongY))
end

local function new(opts: Options): Ripple
	local opacity = opts.Opacity or Tokens.State.Opacity.Pressed
	local corner = opts.Corner or UDim.new(0, 0)
	local max = opts.Max or 3
	local slot = q.Slot({} :: { Instance })
	local host: GuiObject? = nil
	local live: { Live } = {}

	local hook = Util.preHook(function(inst)
		host = inst
		-- pending removal timers must not outlive the host
		inst.Destroying:Connect(function()
			for _, l in live do
				if l.timer then
					task.cancel(l.timer)
				end
				if l.conn then
					l.conn:Disconnect()
				end
			end
			table.clear(live)
		end)
	end)

	local function drop(group: Instance)
		for i, l in live do
			if l.group == group then
				table.remove(live, i)
				if l.timer then
					task.cancel(l.timer)
				end
				if l.conn then
					l.conn:Disconnect()
					l.conn = nil
				end
				break
			end
		end
		local idx = slot:IndexOf(group)
		if idx ~= nil then
			slot:Remove(idx)
		end
	end

	local function press(_self: Ripple, position: Vector2?)
		local h = host
		if h == nil then
			return
		end
		local size = h.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		-- keep the number of live groups bounded: drop the oldest first
		while #live >= max do
			drop(live[1].group)
		end

		local rx: number, ry: number = size.X / 2, size.Y / 2
		if position ~= nil then
			local rel = position - Module.PointerInset - h.AbsolutePosition
			-- a press that began OUTSIDE the ripple area (a control's attached label: Checkbox/Radio `Label`) ripples from
			-- the center, as a keyboard press does
			if rel.X >= 0 and rel.Y >= 0 and rel.X <= size.X and rel.Y <= size.Y then
				rx, ry = rel.X, rel.Y
			end
		end
		-- snap the center to a whole pixel: the shape's box is whole pixels, and a center with different fractions on the
		-- two axes made an uncut circle's box 1-2 px wider than tall (or the reverse) — an oval (Studio QA 2026-10-07, 3rd)
		local wMax, hMax = math.floor(size.X), math.floor(size.Y)
		local px: number = math.clamp(math.round(rx), 0, wMax)
		local py: number = math.clamp(math.round(ry), 0, hMax)
		-- radius = distance to the farthest corner (M3), so the circle just covers the host
		local dx = math.max(px, size.X - px)
		local dy = math.max(py, size.Y - py)
		local radius = math.sqrt(dx * dx + dy * dy)

		local transparencySrc = q.Source(1 - opacity)
		local fadeOpts = Motion.options("Short4", "Linear")
		local fadeTween = q.Animate(fadeOpts)

		local circleRef = q.PreRef(nil :: Frame?)
		local roundRef = q.PreRef(nil :: UICorner?)
		local entry: Live = { group = nil :: any, held = true, fade = function() end, timer = nil, conn = nil }

		-- one frame of the expand: the circle of radius `r` around the press point, CLAMPED to the host rectangle (see
		-- BOUNDED in the header), with the rounding that best imitates "circle cut by the host edges" (`cutCorner`)
		local function shape(r: number)
			local circle = circleRef.Value
			local round = roundRef.Value
			if circle == nil or round == nil then
				return
			end
			-- the uncut box is 2 x ceil(r) square around the whole-pixel center; edges clamp it to the host (floored)
			local R = math.ceil(r)
			local x0, x1 = math.max(0, px - R), math.min(wMax, px + R)
			local y0, y1 = math.max(0, py - R), math.min(hMax, py + R)
			local bw, bh = x1 - x0, y1 - y0
			local rad = math.max(
				cutCorner(px - x0, py - y0, r),
				cutCorner(x1 - px, py - y0, r),
				cutCorner(px - x0, y1 - py, r),
				cutCorner(x1 - px, y1 - py, r)
			)
			rad = math.min(rad, bw / 2, bh / 2)
			circle.Position = UDim2.fromOffset(x0, y0)
			circle.Size = UDim2.fromOffset(bw, bh)
			round.CornerRadius = UDim.new(0, math.round(rad))
		end

		local circle = D.Frame {
			Name = "RippleCircle",
			circleRef,
			Position = UDim2.fromOffset(px, py),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = opts.Color,
			BackgroundTransparency = transparencySrc:Apply(fadeTween),
			BorderSizePixel = 0,
			D.UICorner { Name = "RippleRound", roundRef, CornerRadius = UDim.new(0, 0) },
			-- mounted at size 0, then grown frame by frame for the expand time (one Heartbeat connection per growing
			-- ripple, disconnected at the end of the expand or when the ripple is dropped)
			Util.postHook(function()
				local t = 0
				entry.conn = RunService.Heartbeat:Connect(function(dt: number)
					t += dt
					local a = math.min(t / EXPAND_TIME, 1)
					shape(radius * (1 - (1 - a) ^ 4)) -- Quart Out = the M3 Standard easing's kit mapping
					if a >= 1 and entry.conn ~= nil then
						entry.conn:Disconnect()
						entry.conn = nil
					end
				end)
			end),
		}
		local g = D.CanvasGroup {
			Name = "Ripple",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UICorner = corner,
			circle,
		}
		entry.group = g
		-- Release: start the fade tween, and remove the group once it has finished. A timer (not the tween's
		-- `Completed`) so removal does not depend on the engine tween's notification path.
		entry.fade = function()
			transparencySrc:Set(1)
			entry.timer = task.delay(fadeOpts.Time + 0.05, function()
				entry.timer = nil
				drop(g)
			end)
		end
		table.insert(live, entry)
		slot:Add(g)
	end

	local function release(_self: Ripple)
		for _, l in live do
			if l.held then
				l.held = false
				l.fade()
			end
		end
	end

	local self: Ripple = {
		Hook = hook,
		Slot = slot,
		Press = press,
		Release = release,
		Count = function(_: Ripple): number
			return #live
		end,
	}
	return self
end

return {
	new = new,
	Config = Module,
	cutCorner = cutCorner, -- pure, for specs
}
