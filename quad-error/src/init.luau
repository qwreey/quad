--[[
	quad-error — level-tag based error raising. Design and core API are the
	user's own experiment, taken as-is (2026-08-31, round12 `H-231`).

	Why: `error(msg, n)` counts frames, so the correct `n` depends on how many
	wrappers sit between the raise site and the frame you mean — hand-counting
	(2 vs 3) breaks whenever a helper frame is added, and cannot reach through
	a variable-depth pipeline at all. Instead, tag functions with a *layer
	number* once (`setFuncLevel`); at raise time the walker inspects the live
	stack with `debug.info(i, "f")` and finds a frame whose function carries
	the requested layer tag. Two scan directions, both needed (user decision,
	same round):

	  errorAt(msg, layer)      -- OUTERMOST tagged frame: blame the line
	  errorBefore(msg, layer)  --   inside it / at its caller. Use when the
	                           --   error must climb through any number of
	                           --   wrappers to the user's entry point
	                           --   (e.g. dispatch match failure).
	  errorAtNearest(msg, layer)     -- NEAREST (innermost) tagged frame:
	  errorBeforeNearest(msg, layer) --   same meaning as a hand-written
	                           --   level 2/3, made depth-proof. Use for
	                           --   argument validation / reentrancy guards,
	                           --   where a surface call nested inside a
	                           --   callback must blame the callback's line,
	                           --   not the outer entry.

	Untagged functions count as layer 0 (`ERROR_LEVEL_DEFAULT`); untagged
	frames are *skipped*, never cut the scan short. No match falls back to the
	raise site. Errors are cold paths, so the walk cost is irrelevant.

	**Namespace shape (user decision)**: this module is a stateless
	constructor — `require(quad_error).new()` returns a namespace holding its
	own weak-keyed tag map. Package copies are the reason: pesde gives each
	depending package its own copy of this module, so a module-level map would
	silently split the tag space between quad-base and its backends. The owner
	(quad-base) creates ONE namespace and shares it (`Quad.errorNamespace`);
	consumers must tag and raise through that shared object, never through a
	namespace of their own copy.
]]

local module = {}

module.ERROR_LEVEL_DEFAULT = 0

-- Index of the topmost (outermost) live frame, from this function's own
-- perspective (callers account for their extra frames).
function module.getToplevel(): number
	local curr = 2 -- 1: getToplevel
	while debug.info(curr, "f") ~= nil do
		curr += 1
	end
	return curr - 1
end

export type Namespace = {
	setFuncLevel: (func: any, level: number) -> (),
	getFuncLevel: (func: any) -> number,
	getFirstMatch: (level: number) -> number,
	getNearestMatch: (level: number) -> number,
	errorAt: (content: any, level: number) -> never,
	errorBefore: (content: any, level: number) -> never,
	errorAtNearest: (content: any, level: number) -> never,
	errorBeforeNearest: (content: any, level: number) -> never,
}

function module.new(): Namespace
	local funcLevels = setmetatable({}, { __mode = "k" }) :: { [any]: number }

	local ns = {} :: any

	function ns.setFuncLevel(func: any, level: number)
		funcLevels[func] = level
	end

	function ns.getFuncLevel(func: any): number
		return funcLevels[func] or module.ERROR_LEVEL_DEFAULT
	end

	-- The error() level (as seen from ns.errorAt/errorBefore) that points at
	-- the OUTERMOST frame tagged `level`. Scans from the stack top down.
	-- No match -> 1, a sentinel the error* wrappers translate to the raise
	-- site so blame never lands inside quad-error (`H-269`). (A genuine 1
	-- would need a tagged ns.error* frame at i == 2 — ns functions are never
	-- tagged, so the sentinel is unambiguous in practice.)
	function ns.getFirstMatch(level: number): number
		-- getToplevel counted with its own frame still live; from this frame
		-- the stack is one shorter, so start one below — starting AT it makes
		-- the first probe a phantom nil frame, which getFuncLevel reads as
		-- layer 0 and spuriously matches an ERROR_LEVEL_DEFAULT request
		-- (`H-270`). ignore getFirstMatch (2)
		for i = module.getToplevel() - 1, 2, -1 do
			if ns.getFuncLevel(debug.info(i, "f")) == level then
				return i - 1
			end
		end

		return 1
	end

	-- Same, but the NEAREST (innermost) tagged frame — ascends from the raise
	-- site outward, skipping untagged frames. Equivalent to a hand-written
	-- level 2 on the tagged surface function, regardless of helper depth.
	-- No match -> the same 1 sentinel as getFirstMatch (`H-269`).
	function ns.getNearestMatch(level: number): number
		-- 2: skip getNearestMatch itself; walk outward until the stack ends
		local i = 2
		while true do
			local fn = debug.info(i, "f")
			if fn == nil then
				return 1
			end
			if ns.getFuncLevel(fn) == level then
				return i - 1
			end
			i += 1
		end
	end

	-- `H-269`: the raw sentinel (1) as an error() level would blame the
	-- ns.error* function's own line inside quad-error — the documented
	-- fallback is the RAISE SITE, which sits at level 2 from these frames.
	-- Both At/Before collapse to it (there is no matched frame to be
	-- "before" of).
	function ns.errorAt(content: any, level: number): never
		local at = ns.getFirstMatch(level)
		error(content, if at <= 1 then 2 else at)
	end

	function ns.errorBefore(content: any, level: number): never
		local at = ns.getFirstMatch(level)
		error(content, if at <= 1 then 2 else at + 1)
	end

	function ns.errorAtNearest(content: any, level: number): never
		local at = ns.getNearestMatch(level)
		error(content, if at <= 1 then 2 else at)
	end

	function ns.errorBeforeNearest(content: any, level: number): never
		local at = ns.getNearestMatch(level)
		error(content, if at <= 1 then 2 else at + 1)
	end

	return ns :: Namespace
end

return module
