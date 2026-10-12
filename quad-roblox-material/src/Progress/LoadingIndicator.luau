--!strict
--[[
	M3 Expressive LOADING INDICATOR: a shape that keeps morphing while it turns — for short waits whose progress is
	unknown (M3: use it under ~5 s; a progress indicator for longer or measurable work). Indeterminate only.

	    Progress.LoadingIndicator({})                               -- 48 px, primary shape
	    Progress.LoadingIndicator({ Contained = true, Size = 64 })   -- on a primaryContainer disc
	    Progress.LoadingIndicator({ Visible = busy })                -- the loop stops while not Visible

	Props (all `read`): Size (px, default 48 — M3's container; the shape is 38/48 of it), Contained (boolean?, default
	false: draws the round `PrimaryContainer` container and tints the shape `OnPrimaryContainer`; otherwise the shape is
	`Primary` on nothing), Visible (boolean | State<boolean>?, default true), Theme, Modifier (Frame Modifier after the base),
	Hooks. Returns the host `Frame` (the container).

	HOW (Roblox has no path rendering — M3 morphs seven polygon shapes, Soft Burst > Cookie 9 > Pentagon > Pill > Sunny >
	Cookie 4 > Oval). The shape here is the UNION of three rounded rectangles (same color, opaque, centered), rotated
	against each other: three squares at 0/30/60 degrees with small corners read as a 12-point burst / sunny, two at
	0/45 as an 8-lobe cookie, all three aligned as a rounded square (the 4-lobe cookie), a pill, or a circle. A morph
	interpolates the offsets, the corner radius (`UICorner` scale) and the width / height between two such keyframes:
	  burst (12, soft) > cookie (8) > rounded square > pill > sunny (12, sharp) > circle > (again)
	so the pentagon and the 9-lobe cookie have no exact counterpart (odd lobe counts need a path). Timing follows
	M3: a morph every 650 ms on a damped spring (damping ratio 0.6 — the shape overshoots a little and settles), each
	morph also turns the shape +90 degrees, on top of a constant spin of one turn per 4.666 s.
	Cost: host + UICorner + 3 x (Frame + UICorner) = 8 instances; one Heartbeat (`Loop.luau`, only while mounted and
	Visible) writing Size / Rotation / CornerRadius of the three frames (9 property writes per frame).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Loop = require("./Loop")
local D = q.Declaration
local indicatorName = D.Modifier.Frame():Name("LoadingIndicator")

export type Props = {
	read Size: number?,
	read Contained: boolean?,
	read Visible: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

-- one keyframe: rotation offsets of the 2nd and 3rd rectangle against the 1st (degrees), corner radius (UICorner
-- scale, 0..0.5), width and height (fraction of the shape box)
type Key = { o2: number, o3: number, c: number, w: number, h: number }

local KEYS: { Key } = {
	{ o2 = 30, o3 = 60, c = 0.22, w = 0.8, h = 0.8 }, -- soft burst (12 lobes)
	{ o2 = 45, o3 = 45, c = 0.3, w = 0.82, h = 0.82 }, -- cookie (8 lobes)
	{ o2 = 0, o3 = 0, c = 0.32, w = 0.84, h = 0.84 }, -- rounded square (cookie 4)
	{ o2 = 0, o3 = 0, c = 0.5, w = 1, h = 0.6 }, -- pill
	{ o2 = 30, o3 = 60, c = 0.12, w = 0.78, h = 0.78 }, -- sunny (12, sharper)
	{ o2 = 0, o3 = 0, c = 0.5, w = 0.92, h = 0.92 }, -- oval (circle)
}
local MORPH = 0.65 -- seconds per morph (M3)
local SPIN = 4.666 -- seconds per constant turn (M3)
local TURN_PER_MORPH = 90
local ZETA = 0.6 -- spring damping ratio (M3)
local OMEGA = 12 -- spring natural frequency (rad/s): settles inside one morph (e^-(0.6*12*0.65) < 1 %)
local OMEGA_D = OMEGA * math.sqrt(1 - ZETA * ZETA)
local SHAPE_RATIO = 38 / 48

-- damped spring step response 0 -> 1 (overshoots ~9 %), t in seconds
local function spring(t: number): number
	return 1 - math.exp(-ZETA * OMEGA * t) * (math.cos(OMEGA_D * t) + (ZETA * OMEGA / OMEGA_D) * math.sin(OMEGA_D * t))
end

local function lerp(a: number, b: number, k: number): number
	return a + (b - a) * k
end

-- the pose at time t, written into `out` (no allocation per frame; exposed for the spec): rotations of the three
-- frames, their size (fraction of the shape box), corner scale
export type Pose = { r1: number, r2: number, r3: number, w: number, h: number, c: number }
local function pose(t: number, out: Pose): Pose
	local n = #KEYS
	local step = math.floor(t / MORPH)
	local from = KEYS[step % n + 1]
	local to = KEYS[(step + 1) % n + 1]
	local k = spring(t - step * MORPH)
	local base = (t / SPIN) * 360 + TURN_PER_MORPH * (step + k)
	out.r1 = base % 360
	out.r2 = (base + lerp(from.o2, to.o2, k)) % 360
	out.r3 = (base + lerp(from.o3, to.o3, k)) % 360
	out.w = math.max(0.05, lerp(from.w, to.w, k))
	out.h = math.max(0.05, lerp(from.h, to.h, k))
	out.c = math.clamp(lerp(from.c, to.c, k), 0, 0.5)
	return out
end

local full = UDim.new(0.5, 0)

local function LoadingIndicator(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local visible = Util.asState(props.Visible, true)
	local size = props.Size or 48
	local box = size * SHAPE_RATIO
	local contained = props.Contained == true
	local color = if contained then theme.Color.OnPrimaryContainer else theme.Color.Primary

	local frames: { GuiObject } = {}
	local corners: { UICorner } = {}
	local function shapeFrame(i: number): Frame
		return D.Frame {
			Name = "Shape" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(box * KEYS[1].w, box * KEYS[1].h),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Util.preHook(function(inst)
				frames[i] = inst
			end),
			D.UICorner {
				CornerRadius = UDim.new(KEYS[1].c, 0),
				q.PreRef(nil :: UICorner?):Callback(function(c: UICorner?)
					if c ~= nil then
						corners[i] = c
					end
				end),
			},
		}
	end

	local p: Pose = { r1 = 0, r2 = 0, r3 = 0, w = 1, h = 1, c = 0 }
	local hook, effect = Loop.new(visible, function(t: number)
		pose(t, p)
		local sz = UDim2.fromOffset(box * p.w, box * p.h)
		local radius = UDim.new(p.c, 0)
		for i = 1, 3 do
			local f, c = frames[i], corners[i]
			if f ~= nil then
				f.Size = sz
				f.Rotation = if i == 1 then p.r1 elseif i == 2 then p.r2 else p.r3
			end
			if c ~= nil then
				c.CornerRadius = radius
			end
		end
	end)

	return D.Frame {
		indicatorName,
		D.Modifier.Frame():Size(UDim2.fromOffset(size, size)):BorderSizePixel(0),
		props.Modifier or q.None,
		BackgroundColor3 = theme.Color.PrimaryContainer,
		BackgroundTransparency = if contained then 0 else 1,
		Visible = visible,
		UICorner = full,
		hook,
		effect,
		shapeFrame(1),
		shapeFrame(2),
		shapeFrame(3),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	LoadingIndicator = LoadingIndicator,
	pose = pose,
	Keys = KEYS,
}
