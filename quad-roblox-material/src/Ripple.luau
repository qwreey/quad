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
	    (whole local units, rounded outward: R = ceil(r) around the whole-unit press point) intersected with the host's
	    last whole unit is the label's Position/Size (Offsets — OFFSETS IN LOCAL UNITS below), and `ImageRectSize` /
	    `ImageRectOffset` select the matching sub-rectangle of the texture (`ScaleType = Stretch`, s = 1024 / 2R texels per
	    unit): the cut circle is exact — chords cut by the edges, arcs at their ends — and nothing is drawn outside the host.
	    When the box covers the whole host (the end of every expand) it switches to the full-cover form Position 0 /
	    Size Scale 1 — the host's exact, possibly fractional, size, which whole Offsets cannot reach.
	    History: until 2026-10-07 the circle was a Frame cut to the host + ONE `UICorner` radius imitating "circle cut by
	    the host edges". A UICorner has one radius, so on a wide host (tab bar) the sliced circle showed as "a rectangle
	    with rounded corners" (Studio QA 2026-10-07, tab bar) — the disc image replaced it.
	  - OFFSETS IN LOCAL UNITS (an ancestor UIScale): the press point and `AbsoluteSize` are screen pixels; they are divided
	    by `k`, the product of every `UIScale` that applies to the host (`localScale` below: the host and each ancestor, its
	    first `UIScale` child), and the shape is computed and written in those local units.
	    Offsets are the host's LOCAL units: under a UIScale s an Offset of n draws n * s screen pixels, so absolute pixels
	    written as Offsets were shrunk a second time — the date picker modal card (UIScale .92 -> 1 on enter, times a fitting
	    factor < 1 in a small layer) drew the ripple in the top-left part of the button, cut in a straight line short of the
	    right and bottom edges (Studio QA 2026-10-08, 8th). The engine has no API for a GuiObject's effective scale, hence
	    the walk. `k` and `AbsoluteSize` are read together at press, inside input handling: the last layout used the current
	    UIScale values (tweens step before layout), so they agree; a UIScale that animates AFTER the press scales the whole
	    ripple with the host, which is right in local units.
	    NOT SCALE: the 8th fix wrote the box as `UDim2.fromScale` fractions of the host instead. A descendant whose Size or
	    Position is a partial Scale of an `AutomaticSize` ancestor is a size loop the engine does not resolve (staff, DevForum
	    "AutomaticSize is influenced by scaled UI elements", 2024-04-29: "not a valid usage for AutomaticSize and is a known
	    issue" — use a fixed offset; the AutomaticSize beta notes list "scaled children ... scale based on parent's
	    updated/automatic size ... (double-accounting)", and the max extent of an auto-sized element is "the nearest ancestor
	    ... with [a size] that isn't determined by AutomaticSize"): an auto-width Button / Chip grew to the full width of
	    its row while a ripple ran and the row wrapped (Studio QA 2026-10-08, 9th). The full-cover Scale children that have
	    always been there (the state layer and this CanvasGroup: Position 0, Size 1) did not do that; the regression came
	    exactly with the partial fractions. So every ripple descendant below the group is Offset-only (test/spec.ripple.luau
	    "no partial Scale").
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

-- The product of the UIScales that apply to `inst`: a UIScale scales its parent and everything below it, so the host's
-- own first UIScale child and each ancestor's (ScreenGui included). `FindFirstChildOfClass` where the instance has it
-- (the engine), a scan otherwise (the test mock).
local function localScale(inst: Instance): number
	local k = 1
	local node: any = inst
	while node ~= nil do
		local found: any = nil
		if node.FindFirstChildOfClass ~= nil then
			found = node:FindFirstChildOfClass("UIScale")
		else
			for _, c in node:GetChildren() do
				if c.ClassName == "UIScale" then
					found = c
					break
				end
			end
		end
		if found ~= nil then
			k *= (found :: UIScale).Scale
		end
		node = node.Parent
	end
	return k
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
		-- screen pixels per local unit (see OFFSETS IN LOCAL UNITS in the header)
		local k = localScale(h)
		if size.X <= 0 or size.Y <= 0 or k <= 0 then
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
		-- everything below is in the host's LOCAL units (screen pixels / k — OFFSETS IN LOCAL UNITS in the header): UDim
		-- Offsets are whole numbers, so the box is whole local units; the host's local size may be fractional
		local wLocal, hLocal = size.X / k, size.Y / k
		-- the last whole unit inside the host (the 1e-4 absorbs float noise from the division)
		local wMax, hMax = math.floor(wLocal + 1e-4), math.floor(hLocal + 1e-4)
		-- snap the center to a whole unit: a center with different fractions on the two axes made an uncut circle's box
		-- 1-2 px wider than tall (or the reverse) — an oval (Studio QA 2026-10-07, 3rd)
		local px: number = math.clamp(math.round(rx / k), 0, wMax)
		local py: number = math.clamp(math.round(ry / k), 0, hMax)
		-- radius = distance to the farthest corner (M3), so the circle just covers the host
		local dx = math.max(px, wLocal - px)
		local dy = math.max(py, hLocal - py)
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
			-- the circle's box is 2R square around the whole-unit center (R = ceil r); the visible box clamps it to the host
			local R = math.ceil(r)
			local x0, x1 = math.max(0, px - R), math.min(wMax, px + R)
			local y0, y1 = math.max(0, py - R), math.min(hMax, py + R)
			if R <= 0 or x1 <= x0 or y1 <= y0 then
				circle.Size = UDim2.fromOffset(0, 0)
				circle.ImageRectSize = Vector2.zero
				return
			end
			-- covering the whole host (the end of every expand): the full-cover form the state layer and the group already
			-- use (Position 0, Size Scale 1 — never a partial Scale, see NOT SCALE in the header), reaching the host's exact,
			-- possibly fractional, far edges that whole Offsets cannot
			local covers = x0 == 0 and y0 == 0 and x1 == wMax and y1 == hMax
			if covers then
				x1, y1 = wLocal, hLocal
				circle.Position = UDim2.fromScale(0, 0)
				circle.Size = UDim2.fromScale(1, 1)
			else
				circle.Position = UDim2.fromOffset(x0, y0)
				circle.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
			end
			-- texture pixels per local unit: the disc's 2R box shows the whole 1024 texture (the disc is 1023 px wide in it
			-- — 0.1 % — not corrected)
			local s = DISC_SIZE / (2 * R)
			circle.ImageRectSize = Vector2.new((x1 - x0) * s, (y1 - y0) * s)
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
	localScale = localScale,
}
