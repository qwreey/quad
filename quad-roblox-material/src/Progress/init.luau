--!strict
--[[
	M3 progress indicators: LinearProgress and CircularProgress (Circular.luau), determinate and indeterminate. Two M3
	Expressive additions live in their own files and are re-exported here: `LoadingIndicator` (the morphing-shape
	spinner, LoadingIndicator.luau) and `WavyProgress` (the travelling-wave determinate bar, Wavy.luau).

	    Progress.LinearProgress({ Value = loaded })              -- Value: number | State<number>, 0..1  (determinate)
	    Progress.LinearProgress({})                              -- no Value = indeterminate (animated bars)
	    Progress.CircularProgress({ Value = 0.4, Size = 40 })
	    Progress.CircularProgress({ Visible = busy })            -- indeterminate; the loop stops while not Visible
	Props (all `read`): Value (nil = indeterminate), Visible (boolean | State<boolean>?, default true), Theme,
	Hooks (array-part values on the host), Modifier (Frame Modifier applied AFTER the base style: width, position, LayoutOrder ...). Circular: Size (the
	ring's diameter in px, default 40 — M3's indicator; its 48 dp container is the caller's layout slot) and
	Thickness (stroke px, default 4 — snapped to the nearest of the sheet's four strokes). Both return the host `Frame`. Colors: indicator = primary, track =
	secondaryContainer (M3 2024).

	LINEAR determinate = the M3 2024 look: a 4 px track, the active indicator (pill) from the left, a 4 px GAP, then
	the rest of the track (pill) with a 4 px STOP dot at its end (hidden at 100 %). Three tweened geometries
	(indicator size, track position, track size; Medium1 / Standard) so the gap travels with the indicator.
	7 instances (host + indicator, track, stop dot, each with a UICorner).
	LINEAR indeterminate: the host is the track; two pill bars sweep left to right (period 2 s, the second bar
	starts 35 % into the cycle; each bar's tail lags its head, so the bars stretch then shrink — an approximation of
	the M3 keyframes). 6 instances (host + UICorner + 2 bars with UICorner).

	CIRCULAR (Circular.luau, 2026-10-07): arcs built from power-of-two arc pieces of a sprite sheet (one ImageLabel
	per bit, turned with `Rotation`) + round cap Frames; M3's gap between indicator and track, round ends, the
	indeterminate 10 %..87 % arc — see that file's header. (The earlier UIStroke + UIGradient half-plane rings are gone.)

	Indeterminate loops (`Loop.luau`): ONE Heartbeat connection per live instance, connected only after the host is
	mounted and while `Visible` is true, disconnected when it hides or the host dies (the determinate circular uses
	the same loop only while a Value change is easing). No Lua tables are allocated per frame; `UDim2.fromScale`
	(linear bars, circular caps) creates an engine value per bar per frame, unavoidable for
	Position/Size. The geometry is written straight to the instances from the Heartbeat (not through States — a
	State per frame would run the whole propagation machinery for nothing).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Loop = require("@self/Loop")
local LoadingModule = require("@self/LoadingIndicator")
local WavyModule = require("@self/Wavy")
local CircularModule = require("@self/Circular")
local D = q.Declaration
local linearName = D.Modifier.Frame():Name("LinearProgress")


export type LinearProps = {
	read Value: (number | q.State<number>)?,
	read Visible: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type CircularProps = CircularModule.Props

local LINEAR_HEIGHT = 4
local GAP = 4
local STOP = 4
local LINEAR_PERIOD = 2 -- seconds per indeterminate cycle

local function clamped(value: number | q.State<number>): q.State<number>
	local s = Util.asNumberState(value, 0)
	return s:Compute(function(self)
		return math.clamp(self:Get(), 0, 1)
	end)
end

local function smooth(x: number): number
	if x <= 0 then
		return 0
	elseif x >= 1 then
		return 1
	end
	return x * x * (3 - 2 * x)
end

-- ── Linear ───────────────────────────────────────────────────────────────────────────────────────────────────

local linearBase = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, LINEAR_HEIGHT)):BackgroundTransparency(1):BorderSizePixel(0)
local full = UDim.new(0.5, 0)

local function bar(name: string, color: Theme.Animated, onHost: (inst: GuiObject) -> ()): Frame
	return D.Frame {
		Name = name,
		Size = UDim2.fromScale(0, 1),
		Visible = false,
		BorderSizePixel = 0,
		BackgroundColor3 = color,
		UICorner = full,
		Util.preHook(onHost),
	}
end

local function LinearProgress(props: LinearProps): Frame
	local theme = Theme.resolve(props.Theme)
	local visible = Util.asState(props.Visible, true)

	if props.Value == nil then
		-- indeterminate: two bars driven from Heartbeat
		local bar1: GuiObject? = nil
		local bar2: GuiObject? = nil
		local shown1, shown2 = false, false
		local function place(inst: GuiObject?, tail: number, head: number, shown: boolean): boolean
			if inst == nil then
				return shown
			end
			local width = math.min(head, 1) - math.max(tail, 0)
			local nowShown = width > 0.001
			if nowShown then
				inst.Position = UDim2.fromScale(math.max(tail, 0), 0)
				inst.Size = UDim2.fromScale(width, 1)
			end
			if nowShown ~= shown then
				inst.Visible = nowShown
			end
			return nowShown
		end
		local hook, effect = Loop.new(visible, function(t: number)
			local p = (t % LINEAR_PERIOD) / LINEAR_PERIOD
			shown1 = place(bar1, smooth((p - 0.15) / 0.6), smooth(p / 0.6), shown1)
			shown2 = place(bar2, smooth((p - 0.55) / 0.45), smooth((p - 0.35) / 0.55), shown2)
		end)
		return D.Frame {
			linearName,
			linearBase,
			props.Modifier or q.None,
			Visible = visible,
			BackgroundTransparency = 0,
			BackgroundColor3 = theme.Color.SecondaryContainer,
			UICorner = full,
			hook,
			effect,
			bar("Bar1", theme.Color.Primary, function(inst)
				bar1 = inst
			end),
			bar("Bar2", theme.Color.Primary, function(inst)
				bar2 = inst
			end),
			table.unpack(Util.hooks(props.Hooks)),
		}
	end

	-- determinate (M3 2024: indicator, gap, track, stop dot)
	local v = clamped(props.Value)
	local motion = q.Animate(Tokens.Motion.options("Medium1", "Standard"))
	local indicatorSize: q.State<UDim2> = v:Compute(function(self)
		return UDim2.new(self:Get(), 0, 1, 0)
	end)
	local trackPosition: q.State<UDim2> = v:Compute(function(self)
		local x = self:Get()
		return UDim2.new(x, if x > 0 then GAP else 0, 0, 0)
	end)
	local trackSize: q.State<UDim2> = v:Compute(function(self)
		local x = self:Get()
		return UDim2.new(1 - x, if x > 0 then -GAP else 0, 1, 0)
	end)
	local notFull: q.State<boolean> = v:Compute(function(self)
		return self:Get() < 1
	end)

	return D.Frame {
		linearName,
		linearBase,
		props.Modifier or q.None,
		Visible = visible,
		D.Frame {
			Name = "Indicator",
			Size = indicatorSize:Apply(motion),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Primary,
			UICorner = full,
		},
		D.Frame {
			Name = "Track",
			Position = trackPosition:Apply(motion),
			Size = trackSize:Apply(motion),
			Visible = notFull,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.SecondaryContainer,
			UICorner = full,
			D.Frame {
				Name = "Stop",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(STOP, STOP),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color.Primary,
				UICorner = full,
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

export type LoadingIndicatorProps = LoadingModule.Props
export type WavyProps = WavyModule.Props

return {
	LinearProgress = LinearProgress,
	CircularProgress = CircularModule.CircularProgress,
	-- M3 Expressive additions (2026-10-07): see LoadingIndicator.luau / Wavy.luau
	LoadingIndicator = LoadingModule.LoadingIndicator,
	WavyProgress = WavyModule.WavyProgress,
}
