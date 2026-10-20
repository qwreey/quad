--!nocheck
-- (type-checking off: `@lune/*` requires are unresolvable for luau-lsp; the harness is test plumbing, the specs and src stay --!strict)
--[[
	Lune test harness for quad consumer kits (quad-roblox-devui / quad-roblox-material).

	WHY LUNE (not the `luau` CLI the quad specs use): the CLI sandboxes every required module in its own
	read-only-backed env, so an engine global used at MODULE SCOPE (`local WHITE = Color3.new(1, 1, 1)` in a
	theme module) cannot be shimmed — quad's own specs get away with `getfenv(fn).X = shim` only because
	quad never touches engine globals at load time. A UI kit does, constantly. Lune shares one global
	table across modules and ships the real Roblox datatypes (`@lune/roblox`: Color3, UDim2, Vector2,
	Enum, Font, ColorSequence, …), so the kit modules run unmodified. Lune 0.10.5 does NOT parse `const`
	— kit code must not use it (see the kit README).

	What this installs (globals, before the kit is required):
	  - Roblox datatypes from `@lune/roblox`, `TweenInfo` from the quad mock shim
	  - `Instance.new` = the quad mock instance (quad-base/test/mock.luau) — events declared per class
	    from the generated `reflection.luau` (quad-roblox/dump/api-surface.json), flat (no inheritance:
	    `inst:IsA("GuiObject")` is FALSE on a mock Frame — kit code must not branch on IsA of a base class)
	  - `game:GetService` → ReflectionService/CollectionService/TweenService (quad mock shims) +
	    UserInputService / RunService / GuiService / TextService / Players fakes below
	  - `task` on a virtual clock (`H.advance(dt)`), `print` captured (quad's `q.debug` diagnostics are prints)

	Usage in a spec:
		local H = require("./support/harness")      -- FIRST (installs globals)
		local q = H.attach(require("../src/Quad"))    -- the kit's own setup module
		q.debug = true
		...
		H.assertNoDebugOutput("section name")
]]

local roblox = require("@lune/roblox")
local mock = require("../../../quad-base/test/mock")
local reflection = require("./reflection")

local G = _G :: any
local env = getfenv(1) :: any

local function setGlobal(name: string, value: any)
	env[name] = value
	G[name] = value
end

-- ── datatypes ──────────────────────────────────────────────────────────────
for _, name in
	{
		"Color3",
		"UDim",
		"UDim2",
		"Vector2",
		"Vector3",
		"Rect",
		"Enum",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"NumberRange",
		"Font",
		"BrickColor",
		"CFrame",
	}
do
	setGlobal(name, (roblox :: any)[name])
end
setGlobal("TweenInfo", mock.tweenInfoShim)
-- mock instances start with AbsolutePosition/AbsoluteSize = zero (the engine always has a value; the bare
-- mock leaves them nil, so kit code doing `input.Position - inst.AbsolutePosition` would crash in specs)
setGlobal("Instance", {
	new = function(className: string): any
		local inst = mock.Instance.new(className)
		inst.AbsolutePosition = Vector2.new(0, 0)
		inst.AbsoluteSize = Vector2.new(0, 0)
		if className == "TextBox" then
			-- TextBox focus methods (absent from the bare mock): CaptureFocus fires Focused, ReleaseFocus fires
			-- FocusLost(false) like the engine; a spec may still overwrite them on the instance
			local focused = false
			inst.CaptureFocus = function(self: any)
				if not focused then
					focused = true
					self.Focused:Fire()
				end
			end
			inst.ReleaseFocus = function(self: any)
				if focused then
					focused = false
					self.FocusLost:Fire(false, nil)
				end
			end
			inst.IsFocused = function(_self: any): boolean
				return focused
			end
		end
		return inst
	end,
})

-- ── reflection (props/events) ─────────────────────────────────────────────
local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {}
for className, entry in reflection :: any do
	local list = {}
	for _, p in entry.props do
		table.insert(list, { Name = p, Permits = W })
	end
	REFLECTED[className] = list
	mock.declareEvents(className, entry.events)
end
local baseGame = mock.gameShim(REFLECTED)

-- ── fake services ─────────────────────────────────────────────────────────
local mouse = Vector2.new(0, 0)

local UserInputService = {
	InputBegan = mock.newSignal(),
	InputChanged = mock.newSignal(),
	InputEnded = mock.newSignal(),
	WindowFocusReleased = mock.newSignal(),
	TouchEnded = mock.newSignal(),
	MouseIconEnabled = true,
	TouchEnabled = false,
	KeyboardEnabled = true,
	GamepadEnabled = false,
	MouseEnabled = true,
}
function UserInputService.GetMouseLocation(_self: any): any
	return mouse
end
function UserInputService.IsKeyDown(_self: any, _key: any): boolean
	return false
end
-- specs set `H.UserInputService.FocusedTextBox = box` to simulate a focused TextBox
function UserInputService.GetFocusedTextBox(self: any): any
	return self.FocusedTextBox
end

local RunService = {
	Heartbeat = mock.newSignal(),
	RenderStepped = mock.newSignal(),
	PreRender = mock.newSignal(),
}
function RunService.IsStudio(_self: any): boolean
	return false
end

local GuiService = { MenuOpened = mock.newSignal(), SelectedObject = nil :: any, SelectionParents = {} :: { [string]: any } }
function GuiService.AddSelectionParent(self: any, name: string, inst: any)
	self.SelectionParents[name] = inst
end
function GuiService.RemoveSelectionParent(self: any, name: string)
	self.SelectionParents[name] = nil
end
-- the engine returns the top-bar inset (topLeft, bottomRight); specs run with no inset
function GuiService.GetGuiInset(_self: any): (any, any)
	return Vector2.new(0, 0), Vector2.new(0, 0)
end

-- crude metric: every glyph is TextSize * 0.5 wide, one line tall — enough for layout math in specs
local TextService = {}
function TextService.GetTextSize(_self: any, text: string, size: number, _font: any, _frame: any): any
	return Vector2.new(#text * size * 0.5, size)
end

local Players = { LocalPlayer = nil :: any }

local services: { [string]: any } = {
	UserInputService = UserInputService,
	RunService = RunService,
	GuiService = GuiService,
	TextService = TextService,
	Players = Players,
}

local game = {}
function game.GetService(self: any, name: string): any
	local s = services[name]
	if s ~= nil then
		return s
	end
	return baseGame:GetService(name)
end
setGlobal("game", game)

-- ── task on a virtual clock ───────────────────────────────────────────────
type Timer = { at: number, thread: thread, args: { any }, seq: number }
local clock = 0
local seq = 0
local timers: { Timer } = {}
local deferred: { { thread: thread, args: { any } } } = {}

local function toThread(fnOrThread: any): thread
	if type(fnOrThread) == "thread" then
		return fnOrThread
	end
	return coroutine.create(fnOrThread)
end

local function resume(th: thread, ...: any)
	if coroutine.status(th) == "suspended" then
		local ok, err = coroutine.resume(th, ...)
		if not ok then
			error(err, 0)
		end
	end
end

local task = {}
function task.delay(delay: number?, fn: any, ...: any): thread
	local th = toThread(fn)
	seq += 1
	table.insert(timers, { at = clock + (delay or 0), thread = th, args = table.pack(...), seq = seq })
	return th
end
function task.defer(fn: any, ...: any): thread
	local th = toThread(fn)
	table.insert(deferred, { thread = th, args = table.pack(...) })
	return th
end
function task.spawn(fn: any, ...: any): thread
	local th = toThread(fn)
	resume(th, ...)
	return th
end
function task.cancel(th: thread)
	for i = #timers, 1, -1 do
		if timers[i].thread == th then
			table.remove(timers, i)
		end
	end
	for i = #deferred, 1, -1 do
		if deferred[i].thread == th then
			table.remove(deferred, i)
		end
	end
	if coroutine.status(th) == "suspended" then
		coroutine.close(th)
	end
end
function task.wait(dt: number?): number
	local th = coroutine.running()
	seq += 1
	table.insert(timers, { at = clock + (dt or 0), thread = th, args = {}, seq = seq })
	coroutine.yield()
	return dt or 0
end
setGlobal("task", task)

local function flushDeferred()
	while #deferred > 0 do
		local d = table.remove(deferred, 1) :: any
		resume(d.thread, table.unpack(d.args, 1, d.args.n))
	end
end

-- ── print capture ─────────────────────────────────────────────────────────
local realPrint = print
local captured: { string } = {}
local echo = true
setGlobal("print", function(...: any)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring((select(i, ...)))
	end
	local line = table.concat(parts, " ")
	table.insert(captured, line)
	if echo then
		realPrint("[print] " .. line)
	end
end)

-- `warn` goes to the same capture (the kit warns where a mistake would otherwise be silent, e.g. an unmounted Overlay)
setGlobal("warn", function(...: any)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring((select(i, ...)))
	end
	local line = table.concat(parts, " ")
	table.insert(captured, line)
	if echo then
		realPrint("[warn] " .. line)
	end
end)

local H = {}

H.mock = mock
H.UserInputService = UserInputService
H.RunService = RunService
H.GuiService = GuiService
H.Players = Players

-- Patch the kit's quad instance for the mock backend (the same two lines every quad-roblox spec has).
function H.attach<Q>(q: Q): Q
	local qa = q :: any
	qa.Backend.isInst = mock.isMockInstance
	local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types") :: any
	qa.errorNamespace.setFuncLevel(QuadTypes.ERROR_LEVEL_SURFACE, qa.Backend.isInst)
	return q
end

-- Advance the virtual clock: runs deferred threads, due timers (in time order), and fires
-- RunService.Heartbeat/RenderStepped once with `dt` at the end.
function H.advance(dt: number)
	flushDeferred()
	local target = clock + dt
	while true do
		local best: Timer? = nil
		local bi = 0
		for i, t in timers do
			if t.at <= target and (best == nil or t.at < best.at or (t.at == best.at and t.seq < best.seq)) then
				best, bi = t, i
			end
		end
		if best == nil then
			break
		end
		table.remove(timers, bi)
		clock = best.at
		resume(best.thread, table.unpack(best.args, 1, (best.args :: any).n))
		flushDeferred()
	end
	clock = target
	RunService.RenderStepped:Fire(dt)
	RunService.PreRender:Fire(dt)
	RunService.Heartbeat:Fire(dt)
	flushDeferred()
end

function H.now(): number
	return clock
end

function H.flushDeferred()
	flushDeferred()
end

function H.pendingTimers(): number
	return #timers
end

-- Finish every mock tween still playing: write its target props onto the instance, then fire
-- the natural-completion signal (quad's Tween callbacks run as on the engine).
function H.finishTweens()
	for _, entry in table.clone(mock.tweenLog) do
		local tw = entry.tween
		if tw.PlaybackState == "Playing" then
			for k, v in entry.props do
				entry.inst[k] = v
			end
			-- the mock's own `simulateCompleted` fires the STRING "Completed" (quad's CLI specs shim Enum so the
			-- two compare equal); under Lune `Enum` is the real one, so fire the real enum item like the engine
			tw.PlaybackState = Enum.PlaybackState.Completed
			tw.Completed:Fire(Enum.PlaybackState.Completed)
		end
	end
	mock.resetTweenLog()
end

function H.tweenLog(): { any }
	return mock.tweenLog
end

-- Fire an instance event the way the engine would (`inst.Activated:Fire(...)` works too).
function H.fire(inst: any, event: string, ...: any)
	inst[event]:Fire(...)
end

-- Fake an InputObject (only the fields kit code reads).
function H.input(fields: { [string]: any }): any
	local o = {
		UserInputType = fields.UserInputType or Enum.UserInputType.MouseButton1,
		UserInputState = fields.UserInputState or Enum.UserInputState.Begin,
		KeyCode = fields.KeyCode or Enum.KeyCode.Unknown,
		Position = fields.Position or Vector3.new(0, 0, 0),
		Delta = fields.Delta or Vector3.new(0, 0, 0),
	}
	return o
end

function H.setMouse(x: number, y: number)
	mouse = Vector2.new(x, y)
end

-- Layout stand-in: the mock has no layout engine, so specs set AbsolutePosition/AbsoluteSize by hand.
function H.setAbs(inst: any, x: number, y: number, w: number, h: number)
	inst.AbsolutePosition = Vector2.new(x, y)
	inst.AbsoluteSize = Vector2.new(w, h)
end

-- A PlayerGui stand-in for the Pointer rule (hover / tooltip / press-to-front): put ScreenGuis under it and give the
-- objects that matter a rectangle with `H.setAbs`. `GetGuiObjectsAtPosition(x, y)` lists the visible GuiObjects whose
-- rectangle holds the point, topmost first, in the engine's draw order for `ZIndexBehavior = Sibling`: ScreenGuis by
-- DisplayOrder, then a parent below its children, siblings by ZIndex then child order. No clipping.
local GUI_CLASSES = {
	Frame = true,
	ScrollingFrame = true,
	CanvasGroup = true,
	TextButton = true,
	TextLabel = true,
	TextBox = true,
	ImageButton = true,
	ImageLabel = true,
	ViewportFrame = true,
	VideoFrame = true,
}
local function ordered(list: { any }, key: (any) -> number): { any }
	local tagged = {}
	for i, c in list do
		table.insert(tagged, { c, key(c), i })
	end
	table.sort(tagged, function(a, b)
		if a[2] ~= b[2] then
			return a[2] < b[2]
		end
		return a[3] < b[3]
	end)
	local out = {}
	for _, t in tagged do
		table.insert(out, t[1])
	end
	return out
end
function H.playerGui(): any
	local pg = Instance.new("PlayerGui")
	pg.Name = "PlayerGui"
	pg.GetGuiObjectsAtPosition = function(self: any, x: number, y: number): { any }
		local painted = {} -- bottom first
		local function paint(node: any)
			local kids = {}
			for _, c in node:GetChildren() do
				if GUI_CLASSES[c.ClassName] and c.Visible ~= false then
					table.insert(kids, c)
				end
			end
			for _, c in ordered(kids, function(c)
				return c.ZIndex or 1
			end) do
				table.insert(painted, c)
				paint(c)
			end
		end
		local guis = {}
		for _, c in self:GetChildren() do
			if c.ClassName == "ScreenGui" and c.Enabled ~= false then
				table.insert(guis, c)
			end
		end
		for _, g in ordered(guis, function(g)
			return g.DisplayOrder or 0
		end) do
			paint(g)
		end
		local out = {}
		for i = #painted, 1, -1 do
			local o = painted[i]
			local p, sz = o.AbsolutePosition, o.AbsoluteSize
			if x >= p.X and y >= p.Y and x < p.X + sz.X and y < p.Y + sz.Y then
				table.insert(out, o)
			end
		end
		return out
	end
	return pg
end

-- Depth-first search by Name under `root` (mock has no FindFirstChild(name, true)).
function H.find(root: any, name: string): any?
	for _, c in root:GetChildren() do
		if c.Name == name then
			return c
		end
		local hit = H.find(c, name)
		if hit ~= nil then
			return hit
		end
	end
	return nil
end

function H.findAll(root: any, pred: (any) -> boolean, out: { any }?): { any }
	local acc = out or {}
	for _, c in root:GetChildren() do
		if pred(c) then
			table.insert(acc, c)
		end
		H.findAll(c, pred, acc)
	end
	return acc
end

function H.countDescendants(root: any): number
	local n = 0
	for _, c in root:GetChildren() do
		n += 1 + H.countDescendants(c)
	end
	return n
end

function H.isDestroyed(inst: any): boolean
	return mock.isDestroyed(inst)
end

-- Captured `print` lines since the last reset (quad `q.debug` diagnostics are prints).
function H.output(): { string }
	return captured
end

function H.resetOutput()
	table.clear(captured)
end

function H.setEcho(on: boolean)
	echo = on
end

function H.assertNoDebugOutput(label: string)
	if #captured > 0 then
		error(`{label}: expected no q.debug output, got {#captured} line(s):\n  ` .. table.concat(captured, "\n  "), 2)
	end
end

-- Run a named section; reports PASS/FAIL and keeps a tally (H.done() exits non-zero on failure).
local passed, failed = 0, 0
function H.section(name: string, fn: () -> ())
	realPrint("=== " .. name)
	H.resetOutput()
	local ok, err = xpcall(fn, function(e: any): string
		return debug.traceback(tostring(e), 2)
	end)
	if ok then
		passed += 1
		realPrint("PASS")
	else
		failed += 1
		realPrint("FAIL: " .. tostring(err))
	end
end

function H.done()
	realPrint(`--- {passed} passed, {failed} failed`)
	if failed > 0 then
		local process = require("@lune/process")
		process.exit(1)
	end
end

return H
