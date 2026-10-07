--!strict
--[[
	Pressed ripple, clipped to a ROUNDED host — with a handful of instances, not hundreds.

	DESIGN (measured counts in test/spec.ripple.luau):
	  - `ClipsDescendants` clips to the host RECTANGLE, never to a `UICorner`, so a circle that grows past a
	    pill-shaped button would poke out of the rounded corners. The old kits (RoStrap `Rippler`, qwreey
	    MaterialUI `Round`) solve that by stacking dozens of 1px-high clip frames along the corner curve (and
	    cloning the ripple into every one on each press: 38 / 57 extra instances per press).
	  - Here each press makes ONE `CanvasGroup` (it clips its descendants to its own `UICorner` — exact
	    rounding, any radius) holding ONE disc `ImageLabel` (the circle is a texture, not a `UICorner`). That is
	    3 instances per press (CanvasGroup, its UICorner, the disc), 0 at rest.
	  - The disc texture `rbxassetid://89858938964426` is an IMAGE id (resolved from the uploaded decal): a white disc
	    on a 1024 x 1024 canvas, radius 511.5 around (512, 512), transparent outside, 1 px antialiased edge
	    (`assets/ripple-disc-1024.png`, generator `assets/gen-disc.py`).
	  - BOUNDED: the disc never reaches outside the host rectangle. `AutomaticSize` measures ALL descendants,
	    clipped ones included (an engine behavior, DevForum "AutomaticSize does not consider ClipDescendants"), so the
	    first version's circle — grown to the farthest corner, i.e. past the host's edges — made every auto-sized
	    ancestor grow while a press lasted: an auto-width Button / Chip widened, a RadioGroup row or a story holder grew
	    taller and its centered children jumped, a dialog's actions row pushed the card (Studio QA 2026-10-07, 2nd).
	    So each frame of the expand shows only the PART of the disc that lies inside the host: the circle's bounding box
	    (whole pixels, rounded outward: R = ceil(r) around the whole-pixel press point) intersected with the host is the
	    label's Position/Size (UDim Offsets are integers), and `ImageRectSize` / `ImageRectOffset` select the matching
	    sub-rectangle of the texture (`ScaleType = Stretch`, s = 1024 / 2R texels per pixel): the cut circle is exact —
	    chords cut by the edges, arcs at their ends — and nothing is drawn outside the host.
	    History: until 2026-10-07 the circle was a Frame cut to the host + ONE `UICorner` radius imitating "circle cut by
	    the host edges". A UICorner has one radius, so on a wide host (tab bar) the sliced circle showed as "a rectangle
	    with rounded corners" (Studio QA 2026-10-07, tab bar) — the disc image replaced it.
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
	connection per growing ripple (the clamped part-of-disc above is five properties computed per frame, which tweens
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
-- the uploaded disc texture (an IMAGE id; 1024 x 1024, see header)
local DISC_IMAGE = "rbxassetid://89858938964426"
local DISC_SIZE = 1024

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

		local circleRef = q.PreRef(nil :: ImageLabel?)
		local entry: Live = { group = nil :: any, held = true, fade = function() end, timer = nil, conn = nil }

		-- one frame of the expand: the part of the disc of radius `r` around the press point that lies inside the host
		-- rectangle (see BOUNDED in the header)
		local function shape(r: number)
			local circle = circleRef.Value
			if circle == nil then
				return
			end
			-- the circle's box is 2R square around the whole-pixel center (R = ceil r); the visible box clamps it to the host
			local R = math.ceil(r)
			local x0, x1 = math.max(0, px - R), math.min(wMax, px + R)
			local y0, y1 = math.max(0, py - R), math.min(hMax, py + R)
			local bw, bh = x1 - x0, y1 - y0
			if R <= 0 or bw <= 0 or bh <= 0 then
				circle.Size = UDim2.fromOffset(0, 0)
				circle.ImageRectSize = Vector2.zero
				return
			end
			-- texture pixels per screen pixel: the disc's 2R box shows the whole 1024 texture (the disc is 1023 px wide in it
			-- — 0.1 % — not corrected)
			local s = DISC_SIZE / (2 * R)
			circle.Position = UDim2.fromOffset(x0, y0)
			circle.Size = UDim2.fromOffset(bw, bh)
			circle.ImageRectSize = Vector2.new(bw * s, bh * s)
			circle.ImageRectOffset = Vector2.new((x0 - (px - R)) * s, (y0 - (py - R)) * s)
		end

		local circle = D.ImageLabel {
			Name = "RippleCircle",
			circleRef,
			Image = DISC_IMAGE,
			ScaleType = Enum.ScaleType.Stretch,
			Position = UDim2.fromOffset(px, py),
			Size = UDim2.fromOffset(0, 0),
			ImageRectSize = Vector2.zero,
			ImageColor3 = opts.Color,
			ImageTransparency = transparencySrc:Apply(fadeTween),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
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
}
