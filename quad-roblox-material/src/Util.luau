--!strict
--[[
	Small shared helpers for kit components. Internal-ish but stable: other kit files may use them.

	asState(v, default?)  boolean | State<boolean> -> State<boolean>   (a plain value becomes a constant Source;
	                      nil -> Source(default), default false)
	asNumberState / asStringState   the same for number / string (nil -> 0-style default / "")
	peekBool(v)     read a plain-or-State boolean now (nil = false)
	negate(state)   State<boolean> -> its inverse State<boolean>
	interactable(disabled)   the `Interactable` State of a host: `negate(disabled)`
	visible(v)      Visible default: nil -> true, else the value / State as given
	hooks(h)        `Hooks?` -> a table safe to `table.unpack` into a host's array part
	frameName(name) the host-`Name` Modifier of a Frame host whose name is an argument (one Modifier per distinct name,
	                cached); a fixed name is a module-level `q.Modifier "Class" ():Name(...)` constant in the component
	preHook / postHook   lifecycle hooks (see below)
	clickSink(hooks?)   an invisible full-cover TextButton "ClickSink" for a surface shown above a dismissing scrim; it is
	                also the instance that receives the surface's presses (below)
	Hooks           the shared `Hooks = { any }` alias every component's `Hooks` prop uses: values that are placed in the
	                host's array part (a `Tooltip.hook(...).Hook`, a `q.OnChange(...)`, a `q.Ref(...)`, ...). Only the array
	                part — named properties go through `Modifier`.
	fail(component, msg)   raise a usage error "Material.<component>: <msg>" that blames the caller of the nearest public
	                kit function (below) — never `error(msg, n)` with a hand-counted level
	tagSurface(...)  mark functions (and every function reachable through plain tables given) as public kit surface,
	                so `fail` and quad's own errors see them as library frames (below)
]]

local q = require("./Quad")

export type Hooks = { any }

local function asState(v: (boolean | q.State<boolean>)?, default: boolean?): q.State<boolean>
	if v == nil then
		return q.Source(default == true)
	elseif type(v) == "boolean" then
		return q.Source(v)
	end
	return v
end

local function asNumberState(v: (number | q.State<number>)?, default: number): q.State<number>
	if v == nil then
		return q.Source(default)
	elseif type(v) == "number" then
		return q.Source(v)
	end
	return v
end

local function asStringState(v: (string | q.State<string>)?): q.State<string>
	if v == nil then
		return q.Source("")
	elseif type(v) == "string" then
		return q.Source(v)
	end
	return v
end

-- Lifecycle hooks WITHOUT explicit type arguments. The docs' `q.OnCreated<<I>>(fn)` form cannot be parsed by
-- the Lune test runtime (no `<<>>` explicit instantiation) and the unannotated generic form fails strict
-- (`*error-type*`), so the kit builds its hooks from `q.PreRef(nil :: Class?):Callback(fn)` /
-- `q.PostRef(...)`, which are the same thing (OnCreated/OnRendered ARE a PreRef/PostRef with a callback).
-- `preHook(fn)` runs `fn(inst)` right after the element is created (before its properties/children);
-- `postHook(fn)` runs after its subtree and properties are set (NOT necessarily parented).
local function preHook(fn: (inst: GuiObject) -> ())
	return q.PreRef(nil :: GuiObject?):Callback(function(inst)
		if inst ~= nil then
			fn(inst)
		end
	end)
end

local function postHook(fn: (inst: GuiObject) -> ())
	return q.PostRef(nil :: GuiObject?):Callback(function(inst)
		if inst ~= nil then
			fn(inst)
		end
	end)
end

local function peekBool(v: (boolean | q.State<boolean>)?): boolean
	if v == nil then
		return false
	elseif type(v) == "boolean" then
		return v
	end
	return v:Get()
end

local function negate(state: q.State<boolean>): q.State<boolean>
	return state:Compute(function(self)
		return not self:Get()
	end)
end

-- the `Interactable` State of a host whose `Disabled` State is given
local function interactable(disabled: q.State<boolean>): q.State<boolean>
	return negate(disabled)
end

-- `Visible` defaults to true when the prop is absent
local function visible(v: (boolean | q.State<boolean>)?): boolean | q.State<boolean>
	if v == nil then
		return true
	end
	return v
end

--[[
	NAME: the child is "ClickSink", not "InputSink" — Roblox 0.742 added a GuiObject PROPERTY `InputSink` (Enum None/Activate/All),
	so `surface.InputSink` would return the property instead of the child. The engine property showed no effect in 0.742 Play
	(measured 2026-10-08), which is why the kit sinks clicks with a GuiButton child.
	clickSink(hooks?) -> TextButton. On Roblox a click goes THROUGH a plain Frame / CanvasGroup (`Active = true` only keeps
	3D / camera input out) to a GuiButton beneath, so a modal surface above a dismissing scrim (Overlay scrim, a sheet's own
	scrim) closes when it is clicked inside. Only a GuiButton sinks a GUI click. Put ONE of these as a DIRECT child of the
	surface (Size Scale 1,1 is only safe at that depth, see Ripple.luau "NOT SCALE"); ZIndex 0 keeps every other child above
	it, Selectable false keeps gamepad focus off it. The surface must not lay its children out with a UIListLayout/UIPadding
	(the sink would become a row / shrink): wrap that content in an inner Frame instead.
	INPUT RULE (Studio, 2026-10-08 — .claude/feedback/consumer-kits-studio-qa-2026-10-07.md "Studio 실측 — 바텀 시트 핸들"):
	a press is delivered as `InputBegan` to every GuiObject under the pointer from the top down, and the walk STOPS after
	the first GuiButton. Plain Frames / ScrollingFrames on the way get it and pass it on; the GuiButton gets it (and its
	MouseButton1Down / Activated); nothing below it does — not the scrim, and not the sink's own PARENT (a parent draws
	below its children). So once a surface has a sink, the surface Frame's own `InputBegan` never fires for a press
	inside it: a press hook that must see presses on the surface (a sheet's drag) goes on the SINK — pass it in `hooks`
	(array-part values, like a component's `Hooks`). A press on a GuiButton child (a list item) stops at that child and
	reaches neither the sink nor the surface.
]]
local EMPTY_HOOKS: Hooks = table.freeze({} :: Hooks)
local function clickSink(hooks: Hooks?): TextButton
	return q.Elem "TextButton" {
		Name = "ClickSink",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		ZIndex = 0,
		table.unpack(hooks or EMPTY_HOOKS),
	} :: any
end

local function hooks(h: Hooks?): Hooks
	return h or EMPTY_HOOKS
end

local frameNames: { [string]: q.Modifier<Frame> } = {}
local function frameName(name: string): q.Modifier<Frame>
	local m = frameNames[name]
	if m == nil then
		m = q.Modifier "Frame"():Name(name)
		frameNames[name] = m
	end
	return m
end

-- the factor that shrinks a modal card to fit a small layer: 1 when there is room, never below FIT_MIN (a card too
-- small to read helps nobody — past it the card overflows instead). `margin` is the total kept free on each axis.
-- Shared by Dialog and the DatePicker/TimePicker modals.
local FIT_MIN = 0.25
local function fitScale(layer: Vector2, content: Vector2, margin: number): number
	return math.max(FIT_MIN, math.min(1, (layer.X - margin) / content.X, (layer.Y - margin) / content.Y))
end

-- ── usage errors ────────────────────────────────────────────────────────────────────────────────────────────────────
-- Errors go through quad's shared error namespace (`q.errorNamespace`, the one quad tags its own public functions in)
-- instead of `error(msg, n)`: a hand-counted level is right only for one call depth, and a helper frame between the
-- check and the component (Slider -> Behavior -> config) silently moved the blame onto a kit line. Here every public
-- kit function is TAGGED once, and `fail` blames whoever called the nearest tagged frame — however deep the check sits.
--
-- The layer number is quad-types' `ERROR_LEVEL_SURFACE`. The setup module (`Quad.luau`) hands out only `q`, and a
-- require of quad_types here would add a second place that knows where quad lives, so the value is mirrored and the
-- api spec pins it to quad-types.
local SURFACE = 1

-- Raise "Material.<component>: <msg>" at the line that called the nearest tagged (public) kit function. With no tagged
-- frame on the stack (a check reached only from an engine event) the error points at this helper instead.
local function fail(component: string, msg: string): never
	return q.errorNamespace.errorBeforeNearest(`Material.{component}: {msg}`, SURFACE)
end

-- Tag functions as public kit surface. A table argument is walked: every function reachable through tables WITHOUT a
-- metatable (module tables, not States / instances / lazy token tables) is tagged, so `init.luau` tags the whole export
-- table at once and a new export needs no hand list. Constructors tag the methods of what they build (an Overlay's
-- `Open`, a state's `SnapTo`): those are created after the export walk. `fail` itself is never tagged (it would become
-- the frame it blames past).
local function tagSurface(...: any)
	local seen: { [any]: boolean } = {}
	local function visit(v: any)
		if type(v) == "function" then
			if v ~= fail then
				q.errorNamespace.setFuncLevel(SURFACE, v)
			end
		elseif type(v) == "table" and getmetatable(v) == nil and not seen[v] then
			seen[v] = true
			for _, child in v do
				visit(child)
			end
		end
	end
	for i = 1, select("#", ...) do
		visit((select(i, ...)))
	end
end

return {
	fail = fail,
	tagSurface = tagSurface,
	fitScale = fitScale,
	negate = negate,
	interactable = interactable,
	visible = visible,
	hooks = hooks,
	asState = asState,
	asNumberState = asNumberState,
	asStringState = asStringState,
	peekBool = peekBool,
	preHook = preHook,
	postHook = postHook,
	clickSink = clickSink,
	frameName = frameName,
}
