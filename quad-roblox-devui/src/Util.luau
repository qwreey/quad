--!strict
--[[
	Small derivations shared by widgets (internal helpers, but stable for the other kit files). Each call mints one
	Compute node — call once per widget, not per frame.

		Util.px(state)        State<number>  -> State<UDim>   (offset only)
		Util.pxX(state)       State<Vector2> -> State<UDim>   (.X as offset)
		Util.pxY(state)       State<Vector2> -> State<UDim>   (.Y as offset)
		Util.offset2(state)   State<Vector2> -> State<UDim2>  (fromOffset)

	Usage errors (no Compute node):
		Util.fail(component, msg)   raise "Devui.<component>: <msg>" blaming the caller of the nearest public kit function
		Util.tagSurface(...)        mark functions (and every function reachable through plain tables given) as public
		                            kit surface — what `fail` blames past (below)
]]

local Quad = require("./Quad")

type State<T> = Quad.State<T>

local Util = {}

function Util.px(s: State<number>): State<UDim>
	local out: State<UDim> = s:Compute(function(self)
		return UDim.new(0, self:Get())
	end)
	return out
end

function Util.pxX(s: State<Vector2>): State<UDim>
	local out: State<UDim> = s:Compute(function(self)
		return UDim.new(0, self:Get().X)
	end)
	return out
end

function Util.pxY(s: State<Vector2>): State<UDim>
	local out: State<UDim> = s:Compute(function(self)
		return UDim.new(0, self:Get().Y)
	end)
	return out
end

function Util.offset2(s: State<Vector2>): State<UDim2>
	local out: State<UDim2> = s:Compute(function(self)
		local v = self:Get()
		return UDim2.fromOffset(v.X, v.Y)
	end)
	return out
end

-- ── usage errors ────────────────────────────────────────────────────────────────────────────────────────────────────
-- Errors go through quad's shared error namespace (`Quad.errorNamespace`, the one quad tags its own public functions
-- in) instead of `error(msg, n)`: a hand-counted level is right only for one call depth, and a helper frame between the
-- check and the widget silently moves the blame onto a kit line. Here every public kit function is TAGGED once, and
-- `fail` blames whoever called the nearest tagged frame — however deep the check sits.
--
-- The layer number is quad-types' `ERROR_LEVEL_SURFACE`. The setup module (`Quad.luau`) hands out only `q`, and a
-- require of quad_types here would add a second place that knows where quad lives, so the value is mirrored and
-- spec.basic pins it to quad-types.
local SURFACE = 1

-- Raise "Devui.<component>: <msg>" at the line that called the nearest tagged (public) kit function. With no tagged
-- frame on the stack (a check reached only from an engine event) the error points at this helper instead.
function Util.fail(component: string, msg: string): never
	return Quad.errorNamespace.errorBeforeNearest(`Devui.{component}: {msg}`, SURFACE)
end

-- Tag functions as public kit surface. A table argument is walked: every function reachable through tables WITHOUT a
-- metatable (module tables, not States / instances / lazy token tables) is tagged, so `init.luau` tags the whole export
-- table at once and a new export needs no hand list. Constructors tag the methods of what they build (a Style's
-- `SetScheme`, an Overlay's `Open`): those are created after the export walk. `Util.fail` itself is never tagged (it
-- would become the frame it blames past).
function Util.tagSurface(...: any)
	local seen: { [any]: boolean } = {}
	local function visit(v: any)
		if type(v) == "function" then
			if v ~= Util.fail then
				Quad.errorNamespace.setFuncLevel(SURFACE, v)
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

return Util
