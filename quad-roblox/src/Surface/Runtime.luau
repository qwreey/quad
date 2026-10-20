--!strict
--[[
	The value side of the 3.4.0 typed surface (`Surface/init.luau` holds the types): the class-first curried
	constructors `q.Elem "Frame" {…}`, `q.Modifier "Frame" (…)`, `q.Spread "Frame" {…}`, `q.Mapper "Frame" (key) {…}`,
	`q.OnChange "Frame" "Text" (fn)`, `q.OnEvent "Frame" "MouseEnter" (fn)`, `q.Out "Frame" "Text" (src)`, and
	`q.ForClasses<<Map>>()` returning the same functions (only the types differ — the class map is the user's).
	Canon: `.claude/research/declaration-surface-plan.md` 5절; plan `.claude/research/release-3.4.0-plan.md` 단위 4.

	The class name is checked to be a string and nothing more (사용자 2026-10-20: "커리 첫 인자 런타임 검사 = 문자열만") —
	an unknown class fails where the engine meets it (`Instance.new`, the signal lookup). The class never reaches the
	Spread/Mapper runtime: it lives in the types.

	Coexistence (unit 4 → 6): `OnChange`/`Out`/`Modifier` keep their old shapes beside the new ones until the switch —
	the old `OnChange(name, fn)`/`Out(name, src)` take two arguments, the new class stage one; base's own
	`Modifier(...)` takes the one-string form itself (no wrapper here). Unit 6 removes the old arms.
]]

local QuadTypes = require("../../luau_packages/quad_types")
local Data = require("./Data")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- the error namespace of the (first) installing quad — the descriptor stages below are MODULE-level like
-- `Handlers/OnChange.luau`'s factories (one function across quad instances — spec.events "module-level factory")
local errNS: any = nil

-- the class stage of every curried constructor
local function checkClass(fn: string, name: any)
	if type(name) ~= "string" or name == "" then
		errNS.errorBeforeNearest(`Quad0278 {fn}: the first argument must be a class name string (got {if name == "" then '""' else typeof(name)})`, SURFACE)
	end
end

-- the member and value stages of OnChange/Out/OnEvent (tagged — they are what the user's line calls). `make` is an
-- UNTAGGED descriptor body: a tagged function calling a tagged one would blame quad's own frame (quad-error header)
local function curried(make: (string, any) -> any): any
	local function member(name: any): any
		local function value(v: any): any
			return make(name, v) -- the member name is checked here (Quad0221/0223/0279)
		end
		errNS.setFuncLevel(SURFACE, value)
		return value
	end
	errNS.setFuncLevel(SURFACE, member)
	return member
end

local descriptorStages: { [string]: any } = {}
local makers: { [string]: (string, any) -> any } = {}
function descriptorStages.OnChange(className: any): any
	checkClass("OnChange", className)
	return curried(makers.OnChange)
end
function descriptorStages.OnEvent(className: any): any
	checkClass("OnEvent", className)
	return curried(makers.OnEvent)
end
function descriptorStages.Out(className: any): any
	checkClass("Out", className)
	return curried(makers.Out)
end
-- coexistence arms (removed in unit 6): one argument = the class stage; otherwise the old two-argument form
function descriptorStages.OnChangeEither(a: any, ...: any): any
	if select("#", ...) == 0 then
		checkClass("OnChange", a)
		return curried(makers.OnChange)
	end
	return makers.OnChange(a, ...)
end
function descriptorStages.OutEither(a: any, ...: any): any
	if select("#", ...) == 0 then
		checkClass("Out", a)
		return curried(makers.Out)
	end
	return makers.Out(a, ...)
end

-- install(quad, makeOnChange, makeOut, makeOnEvent) -> the extension fields (merged by `UseProvider`). The three
-- `make*` are the untagged descriptor bodies.
local function install(quad: any, makeOnChange: (string, any) -> any, makeOut: (string, any) -> any, makeOnEvent: (string, any) -> any): { [string]: any }
	if errNS == nil then
		errNS = quad.errorNamespace
		makers.OnChange = makeOnChange
		makers.Out = makeOut
		makers.OnEvent = makeOnEvent
		errNS.setFuncLevel(SURFACE, descriptorStages.OnChange, descriptorStages.OnEvent, descriptorStages.Out,
			descriptorStages.OnChangeEither, descriptorStages.OutEither)
	end
	local rawModifier = quad.Raw.Modifier
	local rawSpread = quad.Raw.Spread
	local rawMapper = quad.Raw.Mapper

	-- every `As<Class>` edge of the engine's creatable chains (DefineSubtype dedups — once per quad-base copy in effect)
	for sub, parent in Data.Superclass :: { [string]: string } do
		rawModifier.DefineSubtype(parent, sub)
	end

	local function elemOf(className: string): any
		local function stage(props: any): any
			local inst = Instance.new(className)
			quad.Backend.nativeClaim(inst) -- right after creation, before any dispatch (bind-system-plan pipeline)
			quad.Dispatch.drive(inst, props)
			return inst
		end
		errNS.setFuncLevel(SURFACE, stage)
		return stage
	end

	local surface: { [string]: any } = {}
	function surface.Elem(className: any): any
		checkClass("Elem", className)
		return elemOf(className)
	end
	function surface.Modifier(className: any): any
		checkClass("Modifier", className)
		return rawModifier.TypedFactory(className) -- cannot fail on a non-empty string
	end
	function surface.Spread(className: any): any
		checkClass("Spread", className)
		return rawSpread
	end
	function surface.Mapper(className: any): any
		checkClass("Mapper", className)
		return rawMapper(className) -- cannot fail on a non-empty string
	end
	surface.OnChange = descriptorStages.OnChange
	surface.OnEvent = descriptorStages.OnEvent
	surface.Out = descriptorStages.Out
	errNS.setFuncLevel(SURFACE, surface.Elem, surface.Modifier, surface.Spread, surface.Mapper)
	table.freeze(surface)

	local forClasses = {}
	function forClasses.ForClasses(): any
		return surface
	end
	errNS.setFuncLevel(SURFACE, forClasses.ForClasses)

	-- `Modifier` is not returned during coexistence: base's own `q.Modifier` takes the one-string form until the
	-- switch (Dispatch/Modifier `__call`), so no wrapper sits over its tagged call
	return {
		Elem = surface.Elem,
		Spread = surface.Spread,
		Mapper = surface.Mapper,
		OnChange = descriptorStages.OnChangeEither,
		OnEvent = surface.OnEvent,
		Out = descriptorStages.OutEither,
		ForClasses = forClasses.ForClasses,
	}
end

return { install = install }
